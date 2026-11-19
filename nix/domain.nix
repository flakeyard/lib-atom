# The files of a domain (FY-0017): the project's files that the `files`
# pattern of a hook of the domain matches, copied to a store path of their own,
# so that a change elsewhere keeps the domain's check cached. The filter is
# coarse: in the check, pre-commit selects among them by `files`, `types` and
# `excludes`.
{
  # lib of the consumer's nixpkgs.
  lib,
  # The project's source, self.outPath, which for a git flake holds only
  # tracked files.
  project,
}:
{
  # The name of the store path, such as the name of the domain's check.
  name,
  # The hooks of the domain, as the project's configuration holds them.
  hooks,
}:
let
  relative = path: lib.removePrefix "${toString project}/" (toString path);
  # pre-commit searches the pattern in the relative path; a hook without
  # `files` matches every file, as in pre-commit.
  matches = hook: path: builtins.match ".*(${hook.files or ""}).*" path != null;
  # The paths below directory, relative to the root, joined from the names
  # that readDir gives: a project given as self.outPath is a string with the
  # context of the source, which paths made from it would carry into every
  # derivation that names them.
  below =
    directory:
    lib.concatLists (
      lib.mapAttrsToList (
        name: type:
        let
          path = directory + name;
        in
        if type == "directory" then below "${path}/" else [ path ]
      ) (builtins.readDir (project + "/${directory}"))
    );
  # Read from the project's source, never from a store path made during
  # evaluation, which a store may not have.
  files = lib.filter (path: lib.any (hook: matches hook path) hooks) (below "");
in
{
  inherit files;
  # The files and only the directories that hold them.
  src = builtins.path {
    inherit name;
    path = project;
    filter =
      path: type:
      let
        file = relative path;
      in
      if type == "directory" then lib.any (lib.hasPrefix "${file}/") files else lib.elem file files;
  };
  # The files whose path the pattern of the hook matches.
  of = hook: lib.filter (matches hook) files;
}
