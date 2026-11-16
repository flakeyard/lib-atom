# The generator of checks.test-next-major, for atom-example.
{ root, testing, ... }:
{
  perSystem = testing.next-major (import (root + "/dev/fixtures/atom/expected.nix")).next-major;
}
