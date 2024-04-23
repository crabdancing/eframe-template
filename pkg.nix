{ pkgs, lib, ... }:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "{{project-name}}";
  version = "0.1.0";

  src = lib.cleanSource ./.; 
  buildInputs = [ pkgs.makeWrapper ];
  cargoBuildFlags = [ ];
  cargoLock.lockFile = ./Cargo.lock;
  meta = {
    description = "{{description}}";
    homepage = "TODO";
    license = pkgs.lib.licenses.agpl3Plus;
  };
}