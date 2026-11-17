# The helper facts: a check that passes when every fact is true; failures.nix
# shows that it fails and names the false ones otherwise.
{ testing, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks.test-facts = testing.facts pkgs "test-facts" { "a true fact" = true; };
    };
}
