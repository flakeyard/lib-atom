# The warning of FY-0016 that the next major version of an atom is coming,
# given while the file nix/next-major.nix of the atom exists (FY-0038). That
# file holds
# { version = <next major version>; guide = "<path of its migration guide>"; }.
{
  # lib of the consumer's nixpkgs, whose lib.warn gives the warning.
  lib,
  # The atom, such as atom-shell: the message names it, and the link to the
  # guide is in its repository of flakeyard.
  atom,
  # The root of the atom's repository.
  root,
}:
# The value that warns when it is evaluated.
value:
let
  file = root + "/nix/next-major.nix";
in
if builtins.pathExists file then
  let
    next = import file;
  in
  lib.warn (
    "${atom}: version ${toString next.version} is coming with breaking changes;"
    + " support of this major version ends 6 months after its first release."
    + " Migration guide: https://github.com/flakeyard/${atom}/blob/main/${next.guide}"
  ) value
else
  value
