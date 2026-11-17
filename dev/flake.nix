{
  description = "lib-atom: the tests of the library and the checks of this repository.";

  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-26.05&rev=ac588ef1c914865dad517b337ea0eb9694a4021c&shallow=1";
    flake-parts = {
      url = "git+https://github.com/hercules-ci/flake-parts?ref=main&rev=ea2630b7470978622c7689a1ff75d2b389175399&shallow=1";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "git+https://github.com/numtide/treefmt-nix?ref=main&rev=0d6d739a833ba9a9c93034862e4a7b061a062a1c&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "git+https://github.com/cachix/git-hooks.nix?ref=master&rev=204b6977e00caac19e2313015a598543ca7be150&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    atom-workflows = {
      url = "git+https://github.com/flakeyard/atom-workflows?ref=v0&rev=82957679afb098f2c36fbcc1ccdf5d52f3286ba4&shallow=1";
      inputs.git-hooks.follows = "git-hooks";
    };
    atom-nix = {
      url = "git+https://github.com/flakeyard/atom-nix?ref=v0&rev=d8e5b1d8f367d27181fbf6e2616c9e6c5ecbbafa&shallow=1";
      inputs.treefmt-nix.follows = "treefmt-nix";
      inputs.git-hooks.follows = "git-hooks";
    };
    atom-shell = {
      url = "git+https://github.com/flakeyard/atom-shell?ref=v0&rev=c6191ba89fd4b4be340cbddfc3fdbeb7f82d3cc5&shallow=1";
      inputs.treefmt-nix.follows = "treefmt-nix";
      inputs.git-hooks.follows = "git-hooks";
    };
    atom-workspace.url = "git+https://github.com/flakeyard/atom-workspace?ref=v0&rev=53d4d101ec71025dbb19da3d423455e72e10198a&shallow=1";
    import-tree.url = "git+https://github.com/vic/import-tree?ref=main&rev=eb1b52eaecc57f7c136d07ae8a93e724dfecac46&shallow=1";
  };

  outputs =
    inputs:
    let
      # The root of the repository; every other file reaches it as the module
      # argument root.
      root = ../.;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      # The library as atoms get it: the outputs of its flake, which has no
      # inputs. An input path:.. would leave the directory of this flake,
      # which the pin form of action-flake-lock forbids for path inputs.
      library = (import (root + "/flake.nix")).outputs { };
      # internal/testing for atom-example in dev/fixtures/atom, an atom that
      # takes lib-atom as atoms do, with this flake's treefmt-nix and
      # git-hooks, as with follows, and atom-workspace in every fixture.
      # example breaks the atom on purpose, for the tests that show that the
      # generated checks fail.
      example = root + "/dev/fixtures/atom";
      testingFor =
        settings:
        import (root + "/internal/testing") {
          inherit inputs systems;
          lib-atom = library.lib;
          root = example;
          atom =
            given:
            (import (example + "/flake.nix")).outputs (
              {
                inherit (inputs) treefmt-nix git-hooks;
                lib-atom = library;
                example = settings;
              }
              // given
            );
          imports = [ inputs.atom-workspace.flakeModules.default ];
        };
    in
    inputs.flake-parts.lib.mkFlake
      {
        # The project is the whole repository, not dev/.
        inputs = inputs // {
          self = inputs.self // {
            outPath = root;
          };
        };
      }
      {
        inherit systems;
        imports = [
          inputs.atom-workflows.flakeModules.default
          inputs.atom-nix.flakeModules.default
          inputs.atom-shell.flakeModules.default
          inputs.atom-workspace.flakeModules.default
          # Every file under nix/ is a flake-parts module.
          (inputs.import-tree ./nix)
        ];
        _module.args = {
          inherit root testingFor;
          testing = testingFor { };
          lib-atom = library.lib;
        };
        # The fixtures break the rules of atoms on purpose; the tests check
        # them.
        perSystem = {
          pre-commit.settings.excludes = [ "^dev/fixtures/" ];
          treefmt.settings.excludes = [ "dev/fixtures/*" ];
        };
      };
}
