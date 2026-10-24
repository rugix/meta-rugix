"""Verify Docker Compose apps on images built with the optional feature."""

import io
import os
import subprocess
import tarfile
import time
from collections.abc import Generator
from pathlib import Path
from tempfile import TemporaryDirectory

import pytest
from rugix_testkit import RugixCtrl, VMHandle

APP = "rugix-compose-test"


@pytest.mark.slow
@pytest.mark.timeout(1200)
def test_compose_app_lifecycle(
    vm: VMHandle, build_dir: Path, bundle_url: str, app_root: Path
):
    """Keep a stack and its data through reboot, system update, and app rollback."""
    if not vm.run(["test", "-x", "/usr/bin/docker"], check=False, hide=True).ok:
        pytest.skip("Image was built without apps-docker-compose")

    _wait_for_service(vm, "rugix-apps-recover.service")
    vm.run(["docker", "compose", "version"], hide=True)
    component = vm.run(
        ["rugix-ctrl", "components", "info", "runtime.docker"],
        check=False,
        hide=True,
    )
    assert component.ok, str(component)
    vm.run(["docker", "pull", "busybox:1.37.0"], hide=True)

    bundlers = sorted(
        build_dir.glob(
            "tmp/work/*/core-image-minimal/*/recipe-sysroot-native/usr/bin/rugix-bundler"
        )
    )
    bundler = os.environ.get("RUGIX_BUNDLER") or (
        str(bundlers[0]) if bundlers else None
    )
    assert bundler, "Set RUGIX_BUNDLER to the native binary from the image build"

    app_url = f"{bundle_url.rsplit('/', 2)[0]}/{app_root.name}"
    _install_app(vm, bundler, app_root, "one", app_url)
    _wait_for_version(vm, "one")
    vm.run(["docker", "exec", APP, "touch", "/data/sentinel"], hide=True)
    vm.reboot()
    _wait_for_service(vm, "rugix-apps-recover.service")
    _wait_for_version(vm, "one")
    vm.run(["docker", "exec", APP, "test", "-f", "/data/sentinel"], hide=True)

    RugixCtrl(vm).update_install(bundle_url, reboot="set")
    vm.reboot()
    _wait_for_service(vm, "rugix-apps-recover.service")
    _wait_for_version(vm, "one")
    vm.run(["docker", "exec", APP, "test", "-f", "/data/sentinel"], hide=True)

    _install_app(vm, bundler, app_root, "two", app_url)
    _wait_for_version(vm, "two")
    vm.run(["rugix-ctrl", "apps", "activate", APP, "1"], hide=True)
    _wait_for_version(vm, "one")
    vm.run(["docker", "exec", APP, "test", "-f", "/data/sentinel"], hide=True)


@pytest.fixture
def app_root(build_dir: Path) -> Generator[Path]:
    with TemporaryDirectory(
        prefix="rugix-app-test-", dir=build_dir / "tmp/deploy/images"
    ) as directory:
        yield Path(directory)


def _install_app(vm: VMHandle, bundler: str, root: Path, version: str, url: str):
    directory = root / version
    payloads = directory / "payloads"
    payloads.mkdir(parents=True)
    compose = f"""services:
  app:
    image: busybox:1.37.0
    container_name: {APP}
    restart: unless-stopped
    volumes:
      - ${{RUGIX_APP_DATA_DIR}}:/data
    command: ["/bin/sh", "-c", "echo {version} >/data/version; exec tail -f /dev/null"]
    healthcheck:
      test: ["CMD-SHELL", "test $$(cat /data/version) = {version}"]
      interval: 1s
      timeout: 1s
      retries: 30
"""
    with tarfile.open(payloads / "app.tar", "w") as archive:
        for name, content in {
            "app.toml": 'orchestrator = "docker-compose"\n',
            "docker-compose.yml": compose,
        }.items():
            data = content.encode()
            header = tarfile.TarInfo(name)
            header.size = len(data)
            header.mode = 0o644
            archive.addfile(header, io.BytesIO(data))
    (directory / "rugix-bundle.toml").write_text(
        'update-type = "full"\n'
        '[[payloads]]\nfilename = "app.tar"\n'
        f'[payloads.delivery]\ntype = "app-archive"\napp = "{APP}"\n'
        '[payloads.block-encoding]\nchunker = "casync-64"\n'
        'hash-algorithm = "sha512_256"\n'
    )
    bundle = root / f"{version}.rugixb"
    subprocess.run([bundler, "bundle", str(directory), str(bundle)], check=True)
    bundle_hash = subprocess.check_output(
        [bundler, "hash", str(bundle)], text=True
    ).strip()
    result = vm.run(
        [
            "rugix-ctrl",
            "apps",
            "install",
            "--bundle-hash",
            bundle_hash,
            f"{url}/{bundle.name}",
        ],
        check=False,
        hide=True,
    )
    assert result.ok, str(result)


def _wait_for_service(vm: VMHandle, service: str):
    deadline = time.monotonic() + 180
    while time.monotonic() < deadline:
        if vm.run(["systemctl", "is-active", service], check=False, hide=True).ok:
            return
        time.sleep(2)
    journal = vm.run(
        ["journalctl", "-u", service, "--no-pager"], check=False, hide=True
    )
    pytest.fail(f"{service} did not start:\n{journal.stdout}")


def _wait_for_version(vm: VMHandle, version: str):
    deadline = time.monotonic() + 60
    while time.monotonic() < deadline:
        result = vm.run(
            ["docker", "exec", APP, "cat", "/data/version"], check=False, hide=True
        )
        if result.ok and result.stdout.strip() == version:
            return
        time.sleep(1)
    pytest.fail(f"App did not start generation {version}")
