{
  description = "bla";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        hsPkgs =
          pkgs.haskell.packages."ghc925";

        buildInputs = [
          hsPkgs.ghc
          stack-wrapped
          pkgs.libffi.dev
          pkgs.libGL
          pkgs.libzip.dev
          pkgs.xorg.libX11.dev
          pkgs.xorg.libXrandr.dev
          pkgs.xorg.libXScrnSaver
          pkgs.discount
          pkgs.gd.dev
          pkgs.libjpeg.dev
          pkgs.imlib2.dev
          pkgs.alsa-lib.dev
          pkgs.zlib
          pkgs.geoip
          pkgs.taglib
          pkgs.freealut
          pkgs.adns
          pkgs.lame
          pkgs.leveldb.dev
          pkgs.lmdb.dev
          pkgs.fftw.dev
          pkgs.freenect
          pkgs.gtk2.dev
          pkgs.gtk3.dev
          pkgs.glew.dev
          pkgs.SDL2.dev
          pkgs.czmq
          pkgs.gobject-introspection.dev
          pkgs.secp256k1
          pkgs.ruby
          pkgs.libnfc
          pkgs.gsl
          pkgs.oath-toolkit
          pkgs.mpich
          pkgs.rdkafka
          pkgs.libsodium.dev
          pkgs.libpulseaudio.dev
          pkgs.re2.dev
          pkgs.flac.dev
          pkgs.rocksdb
          pkgs.unixODBC
          pkgs.libsndfile.dev
          pkgs.pkg-config
          pkgs.xorg.libXcursor
          pkgs.xorg.libXrandr
          pkgs.xorg.libXxf86vm
          pkgs.xorg.libXi
          pkgs.bzip2
          pkgs.curl
          pkgs.libGLU
          pkgs.xorg.libXau
          pkgs.xorg.libXinerama
          pkgs.blas
          pkgs.pcre
          pkgs.icu
          pkgs.lzlib
          pkgs.xz
          pkgs.lapack
          pkgs.expat
          pkgs.file
          pkgs.systemdMinimal
          pkgs.elfutils
          pkgs.xorg.libXext.dev
          pkgs.pango
          pkgs.glib
          pkgs.libxml2
          pkgs.numactl
          pkgs.protobuf
          pkgs.openal
        ];

        # Wrap Stack to work with our Nix integration. We don't want to modify
        # stack.yaml so non-Nix users don't notice anything.
        # - no-nix: We don't want Stack's way of integrating Nix.
        # --system-ghc    # Use the existing GHC on PATH (will come from this Nix file)
        # --no-install-ghc  # Don't try to install GHC if no matching GHC found on PATH
        stack-wrapped = pkgs.symlinkJoin {
          name = "stack"; # will be available as the usual `stack` in terminal
          paths = [ pkgs.stack ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/stack \
              --add-flags "\
                --no-nix \
                --system-ghc \
                --no-install-ghc \
              "
          '';
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = buildInputs;

          # Make external Nix c libraries like zlib known to GHC, like
          # pkgs.haskell.lib.buildStackProject does
          # https://github.com/NixOS/nixpkgs/blob/d64780ea0e22b5f61cd6012a456869c702a72f20/pkgs/development/haskell-modules/generic-stack-builder.nix#L38
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
        };
      });
}
