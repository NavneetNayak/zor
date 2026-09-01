{
  description = "zor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    zig-overlay.url = "github:mitchellh/zig-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, zig-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let pkgs = import nixpkgs {
        inherit system;
        overlays = [ zig-overlay.overlays.default ];
      };
      in
      with pkgs;
      {
        devShell = mkShell {
            packages = [
              zig
              zls
              direnv
            ];
          };
        } 
    );
}
