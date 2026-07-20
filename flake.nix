{
  description = "AG2R — Antigravity 2.0 Remote";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages.${system}.default = pkgs.callPackage ./nix/package.nix { };
      homeManagerModules.ag2r = import ./nix/hm-module.nix;
    };
}
