# The guarded import of an upstream module (FY-0017): the module of an
# upstream flake, or the error of follows.nix when the consumer locks that
# flake a second time. It takes the arguments of follows.nix.
arguments:
# The name of the input and the module to import from it.
name: module:
let
  message = import ./follows.nix arguments name;
in
if message == null then module else throw message
