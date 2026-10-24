# Included through IMAGE_CLASSES so image-specific feature selections are supported.
python __anonymous() {
    features = set((d.getVar("RUGIX_FEATURES") or "").split())
    unknown = features - {"apps", "apps-docker-compose"}
    if unknown:
        bb.fatal("Unknown RUGIX_FEATURES: " + " ".join(sorted(unknown)))

    if not features:
        return

    required = {"systemd"}
    if "apps-docker-compose" in features:
        if "virtualization-layer" not in (d.getVar("BBFILE_COLLECTIONS") or "").split():
            bb.fatal("RUGIX_FEATURES apps-docker-compose requires the meta-virtualization layer")
        required.update({"virtualization", "seccomp", "ipv6"})

    missing = required - set((d.getVar("DISTRO_FEATURES") or "").split())
    if missing:
        bb.fatal("RUGIX_FEATURES requires DISTRO_FEATURES: " + " ".join(sorted(missing)))

    if "apps-docker-compose" in features:
        d.appendVar("IMAGE_INSTALL", " packagegroup-rugix-apps-docker-compose")
    else:
        d.appendVar("IMAGE_INSTALL", " rugix-apps")
}
