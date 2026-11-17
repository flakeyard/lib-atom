# lib.domain: the files whose path the `files` pattern of a hook matches, as
# pre-commit searches it, and only the directories that hold them, as a store
# path of its own under the given name, which a change of other files keeps
# (FY-0017). The projects are in dev/fixtures/domain; expected holds the tree
# that src of one has for the hook of .nix files.
{
  lib-atom,
  root,
  testing,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      inherit (pkgs) lib;
      fixtures = root + "/dev/fixtures/domain";
      hook = files: { inherit files; };
      nix = hook ''\.nix$'';
      workflows = hook ''^\.github/workflows/'';
      markdown = hook ''\.md$'';
      domain =
        project: hooks:
        lib-atom.domain
          {
            inherit lib;
            project = fixtures + "/${project}";
          }
          {
            name = "example";
            inherit hooks;
          };
      files = project: hooks: (domain project hooks).files;
      # Store paths as text: comparing them needs no build and reads nothing
      # from the store, which a store other than /nix/store would not allow.
      src = project: hooks: "${(domain project hooks).src}";
      # A fixture directory as a store path under a name, with the files that
      # the filter keeps.
      stored =
        directory: name: filter:
        "${builtins.path {
          inherit name filter;
          path = fixtures + "/${directory}";
        }}";
      same = a: b: lib.sort lib.lessThan a == lib.sort lib.lessThan b;
      sources = [
        "a.nix"
        "sub/b.nix"
        "sub/deep/c.nix"
      ];
      every = sources ++ [
        ".github/workflows/test.yaml"
        "docs/guide.md"
        "sub/deep/notes.txt"
      ];
    in
    {
      checks.test-lib-domain = testing.facts pkgs "test-lib-domain" {
        "the files of a hook, in nested directories" = same (files "one" [ nix ]) sources;
        "the files of every hook" = same (files "one" [
          nix
          workflows
        ]) (sources ++ [ ".github/workflows/test.yaml" ]);
        "src holds only these files and the directories that hold them" =
          src "one" [ nix ] == stored "expected" "example" (_: _: true);
        "the pattern is searched anywhere in the path" =
          files "one" [ (hook ''b\.nix'') ] == [ "sub/b.nix" ];
        "an anchor of the pattern holds" = files "one" [ (hook ''^b\.nix'') ] == [ ];
        "of gives the files of one hook" =
          (domain "one" [
            nix
            workflows
          ]).of
            workflows == [ ".github/workflows/test.yaml" ];
        "of a hook that matches none gives none" = (domain "one" [ nix ]).of markdown == [ ];
        "no matching files give an empty src" =
          files "none" [ nix ] == [ ] && src "none" [ nix ] == stored "none" "example" (_: _: false);
        "no hooks give no files" = files "one" [ ] == [ ];
        "a hook without files matches every file" =
          same (files "one" [ { } ]) every && same (files "one" [ (hook "") ]) every;
        "src is named after the domain" = lib.hasSuffix "-example" (src "one" [ nix ]);
        "a change of other files keeps src" = src "one" [ nix ] == src "changed" [ nix ];
        "a change of the files changes src" = src "one" [ markdown ] != src "changed" [ markdown ];
      };
    };
}
