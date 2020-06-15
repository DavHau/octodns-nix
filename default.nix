let
  pkgs = import <unstable> {};
  machnix_src = builtins.fetchGit {
    url = "https://github.com/DavHau/mach-nix/";
    ref = "2.0.0";
  };
  machnix = import machnix_src;
  autoPatchelfHook = import "${machnix_src}/mach_nix/nix/auto_patchelf_hook.nix" {inherit (pkgs) fetchurl makeSetupHook writeText;};
  result = machnix.machNix {
    requirements = builtins.readFile ./r.txt;
    python = pkgs.python3;
  };
  overrides_machnix = result.overrides pkgs.pythonManylinuxPackages.manylinux1 pkgs.autoPatchelfHook;
  my_python = pkgs.python3.override {
    packageOverrides = overrides_machnix;
  };
  octodns = my_python.pkgs.buildPythonApplication rec {
    pname = "octodns";
    version = "0.9.10";
    name = pname + version;
    src = pkgs.applyPatches {
      src = builtins.fetchTarball {
        url = "https://github.com/github/octodns/tarball/3e1282f250307f6085577bbbb702726474764dac";
        sha256 = "0qyqfhxgvs1y2n1kx4c1wwnfp6qmbbpb5jh8440j9kxmydq3wc2d";
      };
      name = "patched-octodns-src";
      patches = [ ./octodns-setup-fix.patch ];
    };
    propagatedBuildInputs = result.select_pkgs my_python.pkgs;
    doCheck = false;
    doInstallCheck = false;
  };
in
octodns
