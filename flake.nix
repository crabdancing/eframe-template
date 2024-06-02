{
  description = "Build a cargo project without extra checks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    crane,
    flake-utils,
    rust-overlay,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [(import rust-overlay)];
      };

      lib = pkgs.lib;
      guiInputs = with pkgs; with pkgs.xorg; [libGL libX11 libXcursor libXrandr libXi vulkan-loader libxkbcommon];
      buildInputs = with pkgs; [pkg-config systemd alsa-lib wayland cairo.dev pango.dev glib gdk-pixbuf.dev atkmm.dev gtk3.dev];
      LD_LIBRARY_PATH = lib.makeLibraryPath (buildInputs ++ guiInputs);

      commonEnvironment = {
        nativeBuildInputs = with pkgs; [
          pkg-config
          bacon
        ];
        inherit buildInputs;
      };

      rust = pkgs.rust-bin.stable.latest.default.override {
        extensions = ["rust-analyzer" "rust-src"];
      };
      crateInfo = craneLib.crateNameFromCargoToml {cargoToml = ./Cargo.toml;};
      assetsFilter = path: _type: builtins.match ".*assets$" path != null;
      assetsOrCargo = path: type: (assetsFilter path type) || (craneLib.filterCargoSources path type);

      craneLib = (crane.mkLib pkgs).overrideToolchain rust;
      TEMPLATE_PROJECT_NAME = craneLib.buildPackage (lib.recursiveUpdate commonEnvironment {
        pname = crateInfo.pname;
        version = crateInfo.version;
        nativeBuildInputs = with pkgs; [makeWrapper];
        src = lib.cleanSourceWith {
          src = craneLib.path ./.;
          filter = assetsOrCargo;
        };

        postInstall = ''
          wrapProgram "$out/bin/${crateInfo.pname}" \
            --prefix LD_LIBRARY_PATH : "${LD_LIBRARY_PATH}"
        '';
      });
      # craneLib.buildPackage {
      #   src = craneLib.cleanCargoSource (craneLib.path ./.);
      #   strictDeps = true;
      #   buildInputs =
      #     [
      #       # Add additional build inputs here
      #     ]
      #     ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
      #       # Additional darwin specific inputs can be set here
      #       pkgs.libiconv
      #     ];
      # Additional environment variables can be set directly
      # MY_CUSTOM_VAR = "some value";
      # };
    in {
      checks = {
        inherit TEMPLATE_PROJECT_NAME;
      };

      packages.default = TEMPLATE_PROJECT_NAME;

      apps.default = flake-utils.lib.mkApp {
        drv = TEMPLATE_PROJECT_NAME;
      };

      devShells.default = craneLib.devShell (lib.recursiveUpdate commonEnvironment {
        inherit LD_LIBRARY_PATH;
        shellHook = ''
          schemas_path=`echo "${pkgs.gtk3}/share/gsettings-schemas/"*`
          echo $schemas_path
          export XDG_DATA_DIRS=$XDG_DATA_DIRS:"$schemas_path"
        '';
        nativeBuildInputs = [
          (pkgs.writeShellScriptBin "xclip" ''
            # xclip wrapper that strips our LD_LIBRARY_PATH out to prevent breaking the fragile snowflake C code
            LD_LIBRARY_PATH="" ${pkgs.xclip}/bin/xclip "$@"
          '')
          (pkgs.writeShellScriptBin "run" ''
            cargo --locked run --features bevy/dynamic_linking "$@"
          '')
          (pkgs.writeShellScriptBin "test" ''
            cargo --locked test --features bevy/dynamic_linking "$@"
          '')
          (pkgs.writeShellScriptBin "build" ''
            cargo --locked build --features bevy/dynamic_linking "$@"
          '')
        ];
      });
    });
}
