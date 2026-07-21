{
  description = "AG2R — Antigravity 2.0 Remote";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        pkgJson = builtins.fromJSON (builtins.readFile ./package.json);
      in
      {
        packages.default = pkgs.buildNpmPackage {
          pname = "ag2r";
          version = pkgJson.version;
          src = ./.;

          npmDepsHash = "sha256-YSGiJ3DqjejhR1oNaU2ihdNnHumuvS5rCxHk/HIkGB4=";

          dontNpmBuild = true;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          # Patch: certs directory needs to be writable at runtime (Nix store is read-only).
          # Redirect cert generation to ~/.config/ag2r/certs/ via getConfigPath(),
          # which is already imported in server.js from src/paths.js.
          postPatch = ''
            substituteInPlace server.js \
              --replace-fail \
                "const certDir = path.join(__dirname, 'certs');" \
                "const certDir = getConfigPath('certs');"
          '';

          postInstall = ''
            mkdir -p $out/bin
            makeWrapper ${pkgs.lib.getExe pkgs.nodejs} $out/bin/ag2r \
              --add-flags "$out/lib/node_modules/ag2r/server.js"
          '';

          meta = {
            description = "AG2R — Antigravity 2.0 Remote";
            longDescription = ''
              A lightweight mobile remote interface for monitoring and interacting
              with Antigravity AI coding sessions from your phone.
            '';
            homepage = "https://github.com/the-future-company/ag2r";
            license = pkgs.lib.licenses.mit;
            maintainers = with pkgs.lib.maintainers; [ ];
            mainProgram = "ag2r";
            platforms = pkgs.lib.platforms.linux ++ pkgs.lib.platforms.darwin;
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.nodejs ];
        };

        formatter = pkgs.nixfmt;
      }
    )
    // {
      homeManagerModules.ag2r = import ./home-manager.nix;
    };
}
