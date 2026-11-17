# The generator of checks.test-workspace, for atom-example.
{ testing, ... }:
{
  perSystem = testing.workspace (
    {
      pkgs,
      flake,
      system,
    }:
    {
      formatters.shfmt = pkgs.shfmt;
      packages.shfmt = pkgs.shfmt;
      facts."the shell of the atom exists" = flake.devShells.${system} ? flakeyard-example;
    }
  );
}
