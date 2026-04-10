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
    qemu
    uv
    just
  ];
}
