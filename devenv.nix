{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  packages = with pkgs; [
    kas
    podman
  ];

  env = {
    # Force KAS to use Podman as the container engine.
    KAS_CONTAINER_ENGINE = "podman";
    # Set KAS directories to be within the project directory.
    KAS_WORK_DIR = "${config.devenv.root}/_kas";
    KAS_BUILD_DIR = "${config.devenv.root}/build";
    SSTATE_DIR = "${config.devenv.root}/cache/sstate-cache";
    DL_DIR = "${config.devenv.root}/cache/downloads";
  };
}
