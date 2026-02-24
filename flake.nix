{
  description = "Flake that provides Docker Desktop binaries wrapped and patched for NixOS.";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
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
          pkgs = import nixpkgs { inherit system; };
          packages = import ./. { inherit pkgs system; };
        in
        packages
      );

      formatter = forAllSystems (system: nixpkgs.${system}.nixfmt);
    };
}
