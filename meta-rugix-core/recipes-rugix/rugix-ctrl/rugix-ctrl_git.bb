# Builds Rugix Ctrl from the `main` branch of rugix/rugix, for testing changes
# before they are released. The package version is `0+git` followed by the
# commit. Builds only select the recipe with PREFERRED_VERSION_rugix-ctrl = "0+git".
DEFAULT_PREFERENCE = "-1"
PV = "0+git"
SRCREV = "${AUTOREV}"

require rugix-ctrl.inc
