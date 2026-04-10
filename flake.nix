{
  description = "Flake that provides Docker Desktop binaries wrapped and patched for NixOS.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          packages = import ./. { inherit pkgs system; };
        in
        packages
      );

      formatter = forAllSystems (system: nixpkgs.${system}.nixfmt);
    };
}
