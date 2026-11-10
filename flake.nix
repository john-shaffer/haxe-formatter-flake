{
  description = "haxe-formatter";

  inputs = {
    # Latest stable nixpkgs
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";

    haxe-formatter = {
      flake = false;
      url = "github:HaxeCheckstyle/haxe-formatter/v1.18.0";
    };
  };

  outputs =
    {
      haxe-formatter,
      nixpkgs,
      self,
    }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.haxe-formatter;
        haxe-formatter =
          let
            # The commits that haxe_libraries/*.hxml in haxe-formatter pins
            github = args: pkgs.fetchFromGitHub args;
            haxelib =
              name: version: hash:
              pkgs.fetchzip {
                inherit hash;
                extension = "zip";
                stripRoot = false;
                url = "https://lib.haxe.org/p/${name}/${version}/download/";
              };
            # name, version and class path dir, as in haxe_libraries/*.hxml
            # of haxe-formatter. haxe-formatter checks the defines with
            # e.g. #if tokentree.
            lib = name: version: src: cp: {
              inherit
                cp
                name
                src
                version
                ;
            };
            libs = [
              (lib "exception" "2.0.0" (haxelib "exception" "2.0.0"
                "sha256-+Ov3vjojk8XR3FnvoD8F8B2Q1hJy3RQgnAzVeSZ80+c="
              ) "src")
              (lib "haxeparser" "4.3.0-rc.1" (github {
                owner = "HaxeCheckstyle";
                repo = "haxeparser";
                rev = "a5fce2ecf5fb3bdfebfd7efd8b05329d456ec0d2";
                hash = "sha256-voQZT9BJRqlqyc8eFQyjAsr/LBgkY2NZJfFzpkMx/14=";
              }) "src")
              (lib "hxargs" "3.0.2" (github {
                owner = "simn";
                repo = "hxargs";
                rev = "1d8ec84f641833edd6f0cb2e4290b7524fd27219";
                hash = "sha256-iBnbVpEyNRav+b1+HD23J0SgxMBxcIr6Q/b1rx6CmwI=";
              }) "")
              (lib "hxjsonast" "1.1.0" (haxelib "hxjsonast" "1.1.0"
                "sha256-5Kbq/hDKypx29omnU8bFfd634KqBVYybEmUZh13qjYc="
              ) "src")
              (lib "hxparse" "4.3.0" (github {
                owner = "simn";
                repo = "hxparse";
                rev = "876070ec62a4869de60081f87763e23457a3bda8";
                hash = "sha256-uIsF0oAXVY+MrJDXlsYobD1pwq3HsTowK6NMMRgD2fg=";
              }) "src")
              (lib "json2object" "3.11.0" (github {
                owner = "elnabo";
                repo = "json2object";
                rev = "a75859de1e966c09e73591b6c9186086c143fe60";
                hash = "sha256-o3YNHsZrZ/Cpvh0hnSt55Pz1PoQiU/d4QUzs6mYm8O0=";
              }) "src")
              (lib "tokentree" "1.2.18" (haxelib "tokentree" "1.2.18"
                "sha256-Pgi53pqM6IVu4Q38Vf2AT+uDoZNvsCiMLVuhGFrzIXM="
              ) "src")
            ];
            flags = pkgs.lib.concatMap (l: [
              "-cp ${l.src}/${l.cp}"
              "-D ${l.name}=${l.version}"
            ]) libs;
          in
          pkgs.stdenv.mkDerivation {
            pname = "haxe-formatter";
            version = "1.18.0";
            src = haxe-formatter;
            nativeBuildInputs = [
              pkgs.haxe
              pkgs.makeWrapper
            ];
            buildPhase = ''
              runHook preBuild
              haxe ${toString flags} -cp src -dce full -D analyzer-optimize \
                -D haxe-next -main formatter.Cli -neko formatter.n
              runHook postBuild
            '';
            installPhase = ''
              runHook preInstall
              install -Dm644 formatter.n $out/lib/haxe-formatter/formatter.n
              install -Dm644 resources/default-hxformat.json \
                $out/lib/haxe-formatter/resources/default-hxformat.json
              makeWrapper ${pkgs.neko}/bin/neko $out/bin/haxe-formatter \
                --add-flags $out/lib/haxe-formatter/formatter.n
              runHook postInstall
            '';
            meta.mainProgram = "haxe-formatter";
          };
      });
    };
}
