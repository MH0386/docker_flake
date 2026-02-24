{ pkgs, ... }:
rec {
  docker-desktop = pkgs.callPackage ./docker-desktop.nix { };
  default = docker-desktop;
}
