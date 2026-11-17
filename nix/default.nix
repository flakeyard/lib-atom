# The output lib of lib-atom: the functions that atoms share (FY-0040), each
# in a file of its own.
{ root }:
{
  # The released version, as release-please writes it.
  version = (builtins.fromJSON (builtins.readFile (root + "/.release-please-manifest.json"))).".";
  follows = import ./follows.nix;
  upstream = import ./upstream.nix;
  warning = import ./warning.nix;
  config = import ./config.nix;
}
