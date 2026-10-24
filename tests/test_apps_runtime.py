"""Tests for publishing Docker capabilities without partial metadata."""

import os
import subprocess
import tomllib
from pathlib import Path

from conftest import PROJECT_ROOT

SCRIPT = (
    PROJECT_ROOT
    / "meta-rugix-core/recipes-rugix/rugix-apps-docker-compose/files"
    / "rugix-docker-runtime-components"
)


def test_docker_component_metadata(tmp_path: Path):
    """Publish real version output atomically and preserve it on command failure."""
    docker = tmp_path / "docker"
    docker.write_text(
        "#!/bin/sh\n"
        'if [ "$1" = version ]; then\n'
        '    printf "%s\\n" "$TEST_DOCKER_VERSION"\n'
        "else\n"
        '    [ "$TEST_COMPOSE_VERSION" != fail ] || exit 1\n'
        '    printf "%s\\n" "$TEST_COMPOSE_VERSION"\n'
        "fi\n"
    )
    docker.chmod(0o755)
    components = tmp_path / "components"
    env = {
        **os.environ,
        "PATH": f"{tmp_path}:{os.environ['PATH']}",
        "RUGIX_COMPONENTS_DIR": str(components),
        "TEST_DOCKER_VERSION": "29.3.0",
        "TEST_COMPOSE_VERSION": "v5.1.0",
    }

    subprocess.run(["sh", str(SCRIPT)], env=env, check=True)
    output = components / "docker.toml"
    assert tomllib.loads(output.read_text()) == {
        "id": "runtime.docker",
        "version": "29.3.0",
        "provides": [{"id": "runtime.docker-compose", "version": "5.1.0"}],
    }

    env["TEST_COMPOSE_VERSION"] = "dev"
    subprocess.run(["sh", str(SCRIPT)], env=env, check=True)
    assert tomllib.loads(output.read_text())["provides"] == [
        {"id": "runtime.docker-compose", "value": "dev"}
    ]

    env["TEST_DOCKER_VERSION"] = "vNext"
    subprocess.run(["sh", str(SCRIPT)], env=env, check=True)
    assert tomllib.loads(output.read_text()) == {
        "id": "runtime.docker",
        "provides": [
            {"id": "runtime.docker", "value": "vNext"},
            {"id": "runtime.docker-compose", "value": "dev"},
        ],
    }

    original = output.read_bytes()
    for version in ("fail", '5.1.0"\nid = "injected'):
        env["TEST_COMPOSE_VERSION"] = version
        result = subprocess.run(
            ["sh", str(SCRIPT)], env=env, capture_output=True, check=False
        )
        assert result.returncode != 0
        assert output.read_bytes() == original
    assert sorted(path.name for path in components.iterdir()) == ["docker.toml"]
