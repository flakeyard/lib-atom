# fixture: the flake of a project that imports the atom as consumers do,
# together with the modules every fixture imports and module, the project's
# own settings. Its source is dev/fixtures/<name> of the atom, or source. The
# atom gets the dev flake's inputs, as with follows, except those in
# atomInputs.
{
  inputs,
  root,
  systems,
  atom,
  imports,
}:
{
  name ? null,
  source ? root + "/dev/fixtures/${name}",
  module ? { },
  atomInputs ? { },
}:
inputs.flake-parts.lib.mkFlake
  {
    inputs = inputs // {
      self = {
        outPath = source;
        inherit inputs;
      };
    };
  }
  {
    inherit systems;
    imports = [ (atom atomInputs).flakeModules.default ] ++ imports ++ [ module ];
    # allSystems.<system> exposes the options and values to the tests.
    debug = true;
  }
