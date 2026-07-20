{ lib, buildNpmPackage, nodejs, makeWrapper }:

buildNpmPackage rec {
  pname = "ag2r";
  version = "1.0.0";
  src = ../.;

  npmDepsHash = "sha256-YSGiJ3DqjejhR1oNaU2ihdNnHumuvS5rCxHk/HIkGB4=";

  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

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
    makeWrapper ${lib.getExe nodejs} $out/bin/ag2r \
      --add-flags "$out/lib/node_modules/ag2r/server.js"
  '';

  meta = {
    description = "AG2R — Antigravity 2.0 Remote";
    longDescription = ''
      A lightweight mobile remote interface for monitoring and interacting
      with Antigravity AI coding sessions from your phone.
    '';
    homepage = "https://github.com/the-future-company/ag2r";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "ag2r";
    platforms = lib.platforms.linux;
  };
}
