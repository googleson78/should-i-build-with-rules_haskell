{
  description = "Should I build my project with rules_haskell?";

  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      packages.x86_64-linux.default = pkgs.runCommand
        "should-i-build-with-rules_haskell"
        { }
        ''
          ${pkgs.nodePackages.reveal-md}/bin/reveal-md --static $out ${./present.md}
          cp ${./gazelle.jpg} $out/gazelle.jpg
        '';
      devShell.x86_64-linux = pkgs.mkShell
        {
          packages = [
            pkgs.nodePackages.reveal-md
          ];
          shellHook = ''
            echo 'Run `reveal-md present.md --watch`'.
          '';
        };
    };
}
