# checks.test-follows: a consumer that locks an upstream flake of the atom a
# second time fails at evaluation with the follows line to add (FY-0017).
# The message is the one the atom's own module makes: the atom gets a
# lib-atom whose upstream gives the message as flake.lib-atom-follows.<name>
# instead of throwing it, since builtins.tryEval loses the text of a throw.
{
  facts,
  fixture,
  inputs,
  lib-atom,
}:
{
  # The output of the fixture project good that is evaluated, such as
  # [ "checks" "shell" ] for checks.<system>.shell.
  output,
  # The message for each upstream input of the atom, restated by the atom's
  # tests as its interface (FY-0035).
  messages,
}:
{ pkgs, system, ... }:
let
  inherit (pkgs) lib;
  # An input under another store path, as the atom's own lock gives it
  # without follows.
  other =
    name:
    inputs.${name}
    // {
      outPath = "/nix/store/00000000000000000000000000000000-source";
    };
  evaluated =
    atomInputs:
    builtins.tryEval
      (lib.getAttrFromPath
        (
          [
            (lib.head output)
            system
          ]
          ++ lib.tail output
        )
        (fixture {
          name = "good";
          inherit atomInputs;
        })
      ).drvPath;
  # The message that the atom's module makes for another input name.
  spied.lib = lib-atom // {
    upstream =
      arguments: name: module:
      let
        message = lib-atom.follows arguments name;
      in
      if message == null then module else { flake.lib-atom-follows.${name} = message; };
  };
  made =
    name:
    (fixture {
      name = "good";
      atomInputs = {
        ${name} = other name;
        lib-atom = spied;
      };
    }).lib-atom-follows.${name} or null;
in
{
  checks.test-follows = facts pkgs "test-follows" (
    {
      "the same inputs evaluate" = (evaluated { }).success;
    }
    // lib.mapAttrs' (
      name: _: lib.nameValuePair "another ${name} fails" (!(evaluated { ${name} = other name; }).success)
    ) messages
    // lib.mapAttrs' (
      name: expected:
      lib.nameValuePair "the error names the follows line of ${name}" (made name == expected)
    ) messages
  );
}
