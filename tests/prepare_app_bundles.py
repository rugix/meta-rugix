"""Build Compose lifecycle fixtures inside the Yocto build environment."""

import io
import os
import subprocess
import tarfile
from pathlib import Path
from tempfile import TemporaryDirectory

APP = "rugix-compose-test"
BUNDLES_DIR = "rugix-test-apps"


def main():
    build_dir = Path(os.environ["BUILDDIR"])
    bundlers = sorted(
        build_dir.glob(
            "tmp/work/*/core-image-minimal/*/recipe-sysroot-native/usr/bin/rugix-bundler"
        )
    )
    assert bundlers, "Build a QEMU example image before preparing app test bundles"
    output = build_dir / "tmp/deploy/images" / BUNDLES_DIR
    output.mkdir(exist_ok=True)
    for version in ("one", "two"):
        with TemporaryDirectory() as directory:
            _build_bundle(
                str(bundlers[0]), Path(directory), output / f"{version}.rugixb", version
            )


def _build_bundle(bundler: str, directory: Path, bundle: Path, version: str):
    payloads = directory / "payloads"
    payloads.mkdir()
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
    subprocess.run([bundler, "bundle", str(directory), str(bundle)], check=True)
    bundle_hash = subprocess.check_output(
        [bundler, "hash", str(bundle)], text=True
    ).strip()
    bundle.with_suffix(".rugixb.hash").write_text(bundle_hash + "\n")


if __name__ == "__main__":
    main()
