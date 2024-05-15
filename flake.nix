{
  description = "Generate a Maven repository from a gradle verification-metadata.xml file";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };
  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs ["aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux"] (system:
        function {
          inherit system;
          pkgs = nixpkgs.legacyPackages.${system};
        });
  in {
    formatter = forAllSystems ({pkgs, ...}: pkgs.alejandra);
    devShells = forAllSystems ({pkgs, ...}: {
      default =
        pkgs.mkShell {
        };
    });
  };
}
