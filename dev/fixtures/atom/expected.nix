# The parameters of the generated tests of atom-example, as its tests pass
# them. Restated: the texts are the interface (FY-0035).
{
  follows = {
    output = [
      "devShells"
      "flakeyard-example"
    ];
    messages = {
      treefmt-nix = ''
        atom-example: input 'treefmt-nix' is locked twice; add to input atom-example:
          inputs.treefmt-nix.follows = "treefmt-nix";'';
      git-hooks = ''
        atom-example: input 'git-hooks' is locked twice; add to input atom-example:
          inputs.git-hooks.follows = "git-hooks";'';
    };
  };
  next-major = {
    output = [
      "devShells"
      "flakeyard-example"
    ];
    message =
      "atom-example: version 1 is coming with breaking changes;"
      + " support of this major version ends 6 months after its first release."
      + " Migration guide: https://github.com/flakeyard/atom-example/blob/main/docs/migration/v1.md";
  };
}
