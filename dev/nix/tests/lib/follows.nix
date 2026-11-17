# lib.follows and lib.upstream: an input that the consumer locks a second time
# fails with the follows line to add (FY-0017); the same input, or none in the
# consumer, gives the module.
{
  lib-atom,
  testing,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      # Inputs under two store paths; only outPath is compared.
      own = {
        outPath = "/nix/store/00000000000000000000000000000000-source";
      };
      other = {
        outPath = "/nix/store/11111111111111111111111111111111-source";
      };
      arguments = consumer: {
        atom = "atom-example";
        own.git-hooks = own;
        inherit consumer;
      };
      follows = consumer: lib-atom.follows (arguments consumer) "git-hooks";
      upstream = consumer: builtins.tryEval (lib-atom.upstream (arguments consumer) "git-hooks" "module");
    in
    {
      checks.test-lib-follows = testing.facts pkgs "test-lib-follows" {
        "the same input gives no error" = follows { git-hooks = own; } == null;
        "no input of the consumer gives no error" = follows { } == null;
        # Restated: the text is the interface (FY-0035).
        "another input names the follows line" =
          follows { git-hooks = other; } == ''
            atom-example: input 'git-hooks' is locked twice; add to input atom-example:
              inputs.git-hooks.follows = "git-hooks";'';
        "the same input gives the module" =
          upstream { git-hooks = own; } == {
            success = true;
            value = "module";
          };
        "no input of the consumer gives the module" = (upstream { }).value == "module";
        "another input fails" = !(upstream { git-hooks = other; }).success;
      };
    };
}
