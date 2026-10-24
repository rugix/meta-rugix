"""Verify Docker Compose apps on images built with the optional feature."""

import time
from pathlib import Path

import pytest
from prepare_app_bundles import APP, BUNDLES_DIR
from rugix_testkit import RugixCtrl, VMHandle


@pytest.mark.slow
@pytest.mark.timeout(1200)
def test_compose_app_lifecycle(
    vm: VMHandle, build_dir: Path, bundle_url: str
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

    app_root = build_dir / "tmp/deploy/images" / BUNDLES_DIR
    app_url = f"{bundle_url.rsplit('/', 2)[0]}/{app_root.name}"
    _install_app(vm, app_root, "one", app_url)
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

    _install_app(vm, app_root, "two", app_url)
    _wait_for_version(vm, "two")
    vm.run(["rugix-ctrl", "apps", "activate", APP, "1"], hide=True)
    _wait_for_version(vm, "one")
    vm.run(["docker", "exec", APP, "test", "-f", "/data/sentinel"], hide=True)


def _install_app(vm: VMHandle, root: Path, version: str, url: str):
    bundle = root / f"{version}.rugixb"
    bundle_hash = bundle.with_suffix(".rugixb.hash").read_text().strip()
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
