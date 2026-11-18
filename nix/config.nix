# The configuration file of a tool that the project chose (FY-0037): the
# project's file at one of the standard paths of the tool, else the atom's
# default, either one as a store path of its own. errors lists what the atom
# cannot use: files in forms the atom cannot pass to the tool, and more than
# one file at the standard paths. file fails evaluation with them.
{
  # lib of the consumer's nixpkgs.
  lib,
  # The atom, such as atom-markdown, as the messages name it.
  atom,
  # The project's source, self.outPath, which for a git flake holds only
  # tracked files.
  project,
}:
{
  # The tool, as the messages name it.
  tool,
  # The path of the atom's default file.
  default,
  # The standard paths, relative to the project's root, whose file replaces
  # the default.
  names,
  # The project's files that configure the tool in a form the atom cannot
  # pass to it. An element is a path relative to the project's root, or
  # { name; label ? name; when ? path: true; } for a file that configures
  # the tool only when the predicate is true of its path, such as a table of
  # pyproject.toml; label names it in the message.
  unsupported ? [ ],
}:
let
  exists = name: builtins.pathExists (project + "/${name}");
  found = lib.filter exists names;
  # Every element of unsupported as { name; label; when; }.
  entries = map (
    element:
    let
      entry = if lib.isString element then { name = element; } else element;
    in
    {
      label = entry.name;
      when = _: true;
    }
    // entry
  ) unsupported;
  refused = lib.filter (entry: exists entry.name && entry.when (project + "/${entry.name}")) entries;
  list = lib.concatStringsSep ", ";
  errors =
    lib.optional (refused != [ ]) (
      "${atom}: the atom cannot pass these configurations of ${tool} to it:"
      + " ${list (map (entry: entry.label) refused)}; write the configuration in"
      + " ${if lib.length names == 1 then "" else "one of "}${list names} instead."
    )
    ++ lib.optional (
      lib.length found > 1
    ) "${atom}: the project has more than one configuration of ${tool}: ${list found}; keep one.";
  # A store path of its own, named after the file without a leading dot:
  # prettier chooses the parser by the extension of the file name, which for
  # .prettierrc in a store path such as /nix/store/<hash>-.prettierrc would be
  # ".prettierrc". The name comes from name, never from path: a project given
  # as self.outPath is a string with the context of the source, which a name
  # of a store path must not carry.
  stored =
    path: name:
    builtins.path {
      inherit path;
      name = lib.removePrefix "." (baseNameOf name);
    };
in
{
  inherit errors;
  file =
    if errors != [ ] then
      throw (lib.concatStringsSep "\n" errors)
    else if found == [ ] then
      stored default (baseNameOf default)
    else
      stored (project + "/${lib.head found}") (lib.head found);
}
