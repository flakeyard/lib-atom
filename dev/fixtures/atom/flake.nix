{
  # An atom as atoms use lib-atom, for the tests of internal/testing. Its
  # inputs treefmt-nix, git-hooks and lib-atom are given by the tests, and
  # example, which breaks the atom on purpose: { name; guarded; }.
  outputs = inputs: { flakeModules.default = import ./nix inputs; };
}
