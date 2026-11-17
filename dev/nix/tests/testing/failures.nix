# The checks of internal/testing fail, and name the fact that is false, when
# their expectation does not hold: a false fact, an atom that names itself
# wrongly, an atom without the guard of follows, a wrong expected message,
# and a formatter or a tool that the project does not get.
{
  root,
  testing,
  testingFor,
  ...
}:
{
  perSystem =
    { pkgs, system, ... }:
    let
      expected = import (root + "/dev/fixtures/atom/expected.nix");
      misnamed = testingFor { name = "atom-nix"; };
      unguarded = testingFor { guarded = false; };
      # The check of a generated module.
      generated = module: name: (module { inherit pkgs system; }).checks.${name};
      # A check that passes when check fails with the false fact.
      fails =
        name: check: fact:
        pkgs.runCommand name { } ''
          log=${pkgs.testers.testBuildFailure check}/testBuildFailure.log
          cat "$log"
          grep -Fx ${pkgs.lib.escapeShellArg "false: ${fact}"} "$log"
          touch $out
        '';
    in
    {
      checks = {
        test-facts-false = fails "test-facts-false" (testing.facts pkgs "facts" {
          "a true fact" = true;
          "a false fact" = false;
        }) "a false fact";
        test-follows-misnamed =
          fails "test-follows-misnamed" (generated (misnamed.follows expected.follows) "test-follows")
            "the error names the follows line of git-hooks";
        test-follows-unguarded =
          fails "test-follows-unguarded" (generated (unguarded.follows expected.follows) "test-follows")
            "another git-hooks fails";
        test-follows-message = fails "test-follows-message" (generated (testing.follows (
          expected.follows // { messages.git-hooks = "another message"; }
        )) "test-follows") "the error names the follows line of git-hooks";
        test-next-major-misnamed =
          fails "test-next-major-misnamed"
            (generated (misnamed.next-major expected.next-major) "test-next-major")
            "the warning names the version and the guide";
        test-next-major-message = fails "test-next-major-message" (generated (testing.next-major (
          expected.next-major // { message = "another message"; }
        )) "test-next-major") "the warning names the version and the guide";
        test-workspace-formatter = fails "test-workspace-formatter" (generated (testing.workspace (_: {
          formatters.shfmt = pkgs.hello;
        })) "test-workspace") "treefmt runs shfmt of the project's nixpkgs";
        test-workspace-tool = fails "test-workspace-tool" (generated (testing.workspace (_: {
          packages.hello = pkgs.hello;
        })) "test-workspace") "the shell holds hello";
      };
    };
}
