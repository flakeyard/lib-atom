# The helpers of the tests of atoms (FY-0040), for the dev flake of one atom.
# Not part of the public API of lib-atom: atoms import this directory from the
# source of the revision of lib-atom that their root flake.lock pins.
{
  # The inputs of the dev flake, which fixture projects get as their own.
  inputs,
  # The root of the atom's repository.
  root,
  # The systems that the atom supports.
  systems,
  # The atom's outputs for its inputs: a function from an attribute set of
  # inputs that replace those of the dev flake to the outputs of the atom's
  # flake.nix.
  atom,
  # Modules that every fixture project imports next to the atom, such as
  # the module of atom-workspace.
  imports ? [ ],
  # The output lib of the same revision of lib-atom.
  lib-atom,
}:
let
  facts = import ./facts.nix;
  fixture = import ./fixture.nix {
    inherit
      inputs
      root
      systems
      atom
      imports
      ;
  };
in
{
  inherit facts fixture;
  # Generators of the tests that every atom has; each takes the atom's
  # parameters and gives a module of perSystem, since the module of a test
  # cannot take its imports from a module argument:
  # { testing, ... }: { perSystem = testing.follows { ... }; }
  follows = import ./tests/follows.nix {
    inherit
      facts
      fixture
      inputs
      lib-atom
      ;
  };
  next-major = import ./tests/next-major.nix {
    inherit
      facts
      fixture
      root
      lib-atom
      ;
    # An atom's root with nix/next-major.nix as the maintainer adds it: a
    # file of the repository, since one written during evaluation cannot be
    # imported when the store is read-only (nix flake check --no-build).
    announcing = ./fixtures/next-major;
  };
  workspace = import ./tests/workspace.nix { inherit facts fixture; };
}
