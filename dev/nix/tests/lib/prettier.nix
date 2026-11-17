# lib.prettier: the names and the unsupported entries of prettier, passed to
# lib.config as the atoms that own prettier pass them (FY-0017, FY-0037). A
# file at a standard name is chosen; JavaScript and TypeScript
# configurations, the key prettier of package.json and overrides with a
# directory in .prettierrc.json and .prettierrc.toml give errors that name
# them; package.json without the key and overrides by file names give none.
# The projects are in dev/fixtures/prettier.
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
      fixtures = root + "/dev/fixtures/prettier";
      chosen =
        name:
        let
          project = fixtures + "/${name}";
        in
        lib-atom.config
          {
            inherit lib project;
            atom = "atom-example";
          }
          (
            {
              tool = "prettier";
              default = root + "/dev/fixtures/config/default.json";
            }
            // lib-atom.prettier { inherit lib project; }
          );
      errors = name: (chosen name).errors;
      # Restated: the text is the interface (FY-0035).
      names = ".prettierrc, .prettierrc.json, .prettierrc.json5, .prettierrc.yaml, .prettierrc.yml, .prettierrc.toml";
      refused =
        labels:
        "atom-example: the atom cannot pass these configurations of prettier to it: ${labels}; write the configuration in one of ${names} instead.";
    in
    {
      checks.test-lib-prettier = testing.facts pkgs "test-lib-prettier" {
        "without a file, no errors" = errors "none" == [ ];
        "a file at a standard name is chosen" =
          "${(chosen "one").file}" == "${builtins.path {
            path = fixtures + "/one/.prettierrc.yaml";
            name = "prettierrc.yaml";
          }}";
        "JavaScript and TypeScript configurations fail" =
          errors "js" == [ (refused ".prettierrc.cjs, prettier.config.ts") ];
        "the key prettier of package.json fails" =
          errors "package-json" == [ (refused "the key prettier of package.json") ];
        "package.json without the key prettier is fine" = errors "package-json-other" == [ ];
        "overrides with a directory fail" =
          errors "directories" == [
            (refused ".prettierrc.json (overrides with a directory: docs/**/*.md, notes/*.md)")
          ];
        "overrides with a directory in TOML fail" =
          errors "directories-toml" == [
            (refused ".prettierrc.toml (overrides with a directory: docs/*.md)")
          ];
        "overrides by file names are fine" = errors "names" == [ ];
      };
    };
}
