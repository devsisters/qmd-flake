{
  description = "QMD - On-device search engine for text files and knowledge bases";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      pkgsFor = system: nixpkgs.legacyPackages.${system};

      # QMD source pinned to a specific revision
      qmdSrc =
        { pkgs }:
        pkgs.fetchFromGitHub {
          owner = "tobi";
          repo = "qmd";
          rev = "40610c3aa65d9d399ebb188a7e4930f6628ae51c";
          hash = "sha256-IR5lIQU+hFKyZdF5BvZHAQbkVV+Yrde6bQ/2nyJARRk=";
        };

      # SQLite with loadable extension support (required for sqlite-vec)
      sqliteWithExtensions =
        pkgs:
        pkgs.sqlite.overrideAttrs (old: {
          configureFlags = (old.configureFlags or [ ]) ++ [
            "--enable-load-extension"
          ];
        });

      mkQmd =
        pkgs:
        let
          sqlite = sqliteWithExtensions pkgs;
        in
        pkgs.stdenv.mkDerivation {
          pname = "qmd";
          version = "1.1.0";

          src = qmdSrc { inherit pkgs; };

          nativeBuildInputs = [
            pkgs.bun
            pkgs.nodejs # needed for tsc and as runtime
            pkgs.makeWrapper
            pkgs.python3 # needed by node-gyp for better-sqlite3
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
            pkgs.darwin.cctools # provides libtool for node-gyp on macOS
          ];

          buildInputs = [ sqlite ];

          buildPhase = ''
            export HOME=$(mktemp -d)

            # Point node-gyp to local Node.js headers (no network in Nix sandbox)
            export npm_config_nodedir=${pkgs.nodejs}
            mkdir -p $HOME/.node-gyp/${pkgs.nodejs.version}
            echo 9 > $HOME/.node-gyp/${pkgs.nodejs.version}/installVersion
            ln -sfv ${pkgs.nodejs}/include $HOME/.node-gyp/${pkgs.nodejs.version}

            bun install --frozen-lockfile

            # Compile TypeScript to dist/ (source repo doesn't ship compiled JS)
            ./node_modules/.bin/tsc -p tsconfig.build.json
          '';

          installPhase = ''
            mkdir -p $out/lib/qmd $out/bin

            cp -r node_modules dist package.json $out/lib/qmd/

            makeWrapper ${pkgs.nodejs}/bin/node $out/bin/qmd \
              --add-flags "$out/lib/qmd/dist/qmd.js" \
              --set DYLD_LIBRARY_PATH "${sqlite.out}/lib" \
              --set LD_LIBRARY_PATH "${sqlite.out}/lib"
          '';

          meta = with pkgs.lib; {
            description = "On-device search engine for text files, notes, and knowledge bases";
            homepage = "https://github.com/tobi/qmd";
            license = licenses.mit;
            platforms = [
              "aarch64-darwin"
              "x86_64-linux"
            ];
          };
        };
    in
    {
      packages = forAllSystems (system: {
        default = mkQmd (pkgsFor system);
        qmd = mkQmd (pkgsFor system);
      });

      overlays.default = final: _prev: {
        qmd = self.packages.${final.stdenv.hostPlatform.system}.default;
      };
    };
}
