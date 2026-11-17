# The generator of checks.test-follows, for atom-example.
{ root, testing, ... }:
{
  perSystem = testing.follows (import (root + "/dev/fixtures/atom/expected.nix")).follows;
}
