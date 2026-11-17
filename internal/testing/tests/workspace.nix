# checks.test-workspace: the atom in the fixture project good with
# atom-workspace. The formatters of the atom run the packages of the
# project's nixpkgs through the hook treefmt and the substitutable
# checks.treefmt, checks.pre-commit is off, and devShells.default holds the
# tools of the atom.
{ facts, fixture }:
# A function of { pkgs, flake, system }, the project's packages, the fixture
# project and the system, to:
# - formatters: the atom's formatters of treefmt, by name, to their packages;
# - packages: the tools of the atom's shell, by name, to their packages;
# - facts: the atom's own facts.
spec:
{ pkgs, system, ... }:
let
  inherit (pkgs) lib;
  flake = fixture { name = "good"; };
  values = flake.allSystems.${system};
  checks = flake.checks.${system};
  shell = flake.devShells.${system}.default;
  given = {
    formatters = { };
    packages = { };
    facts = { };
  }
  // spec { inherit pkgs flake system; };
  # The shell holds the output out of a package, not its first output.
  holds = package: lib.elem package.out shell.nativeBuildInputs;
in
{
  checks.test-workspace = facts pkgs "test-workspace" (
    lib.mapAttrs' (
      name: package:
      lib.nameValuePair "treefmt runs ${name} of the project's nixpkgs" (
        values.treefmt.settings.formatter.${name}.command == lib.getExe package
      )
    ) given.formatters
    // lib.optionalAttrs (given.formatters != { }) {
      "the hook treefmt is enabled" = values.pre-commit.settings.hooks.treefmt.enable;
      "checks.treefmt is substitutable" = checks.treefmt.allowSubstitutes;
    }
    // {
      "checks.pre-commit is off" = !(checks ? pre-commit);
    }
    // lib.mapAttrs' (
      name: package: lib.nameValuePair "the shell holds ${name}" (holds package)
    ) given.packages
    // given.facts
  );
}
