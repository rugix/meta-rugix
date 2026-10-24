"""Exercise feature selection with BitBake in a configured KAS shell."""

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

CASES = [
    (
        'RUGIX_FEATURES = ""\nRUGIX_FEATURES:remove = "apps-docker-compose"',
        "",
        None,
    ),
    (
        'RUGIX_FEATURES = "apps"\nRUGIX_FEATURES:remove = "apps-docker-compose"',
        "rugix-apps",
        None,
    ),
    (
        'RUGIX_FEATURES = "apps-docker-compose"',
        "packagegroup-rugix-apps-docker-compose",
        None,
    ),
    ('RUGIX_FEATURES = "typo"', "", "Unknown RUGIX_FEATURES: typo"),
    (
        'RUGIX_FEATURES = "apps"\nDISTRO_FEATURES:remove = "systemd"',
        "",
        "RUGIX_FEATURES requires DISTRO_FEATURES: systemd",
    ),
    (
        (
            'RUGIX_FEATURES = "apps-docker-compose"\n'
            'BBFILE_COLLECTIONS:remove = "virtualization-layer"'
        ),
        "",
        "requires the meta-virtualization layer",
    ),
    (
        ('RUGIX_FEATURES = "apps-docker-compose"\nDISTRO_FEATURES:remove = "seccomp"'),
        "",
        "RUGIX_FEATURES requires DISTRO_FEATURES: seccomp",
    ),
]


@unittest.skipUnless(
    shutil.which("bitbake"), "Run in a KAS shell with the Compose fragment"
)
class FeatureTests(unittest.TestCase):
    def test_feature_selection(self):
        """Select optional image packages or fail early with a useful diagnostic."""
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / "features.conf"
            for settings, expected, error in CASES:
                with self.subTest(settings=settings):
                    config.write_text(settings + "\n")
                    result = subprocess.run(
                        ["bitbake", "-R", str(config), "-e", "core-image-minimal"],
                        check=False,
                        text=True,
                        capture_output=True,
                    )
                    output = result.stdout + result.stderr
                    if error:
                        self.assertNotEqual(result.returncode, 0)
                        self.assertIn(error, output)
                        continue

                    self.assertEqual(result.returncode, 0, output)
                    packages = next(
                        line.removeprefix('IMAGE_INSTALL="').removesuffix('"').split()
                        for line in output.splitlines()
                        if line.startswith('IMAGE_INSTALL="')
                    )
                    if expected:
                        self.assertIn(expected, packages)
                    else:
                        self.assertNotIn("rugix-apps", packages)
                        self.assertNotIn(
                            "packagegroup-rugix-apps-docker-compose", packages
                        )


if __name__ == "__main__":
    unittest.main()
