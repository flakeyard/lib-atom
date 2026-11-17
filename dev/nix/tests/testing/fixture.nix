# The helper fixture: a project in dev/fixtures/<name> of the atom, or at a
# given source, that imports the atom, the modules of every fixture and its
# own module, with the atom's inputs replaced where given.
{ inputs, testing, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      good = testing.fixture { name = "good"; };
      # git-hooks.nix under another store path, as without follows.
      other = testing.fixture {
        name = "good";
        atomInputs.git-hooks = inputs.git-hooks // {
          outPath = "/nix/store/00000000000000000000000000000000-source";
        };
      };
      own = testing.fixture {
        source = ./.;
        module.perSystem.packages.marker = pkgs.emptyFile;
      };
    in
    {
      checks.test-fixture = testing.facts pkgs "test-fixture" {
        "the source is dev/fixtures/<name> of the atom" =
          baseNameOf good.allSystems.${system}.pre-commit.settings.rootSrc == "good";
        "the source can be given" = own.allSystems.${system}.pre-commit.settings.rootSrc == ./.;
        "the module is imported" = own.packages.${system} ? marker;
        "the atom is imported" = good.devShells.${system} ? flakeyard-example;
        "the modules of every fixture are imported" = good.devShells.${system} ? default;
        "atomInputs replace the atom's inputs" =
          !(builtins.tryEval other.devShells.${system}.flakeyard-example.drvPath).success;
      };
    };
}
