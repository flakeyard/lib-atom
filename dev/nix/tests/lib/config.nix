# lib.config: the project's file at a standard path replaces the default,
# either one as a store path of its own named without a leading dot; more
# than one file at the standard paths, and files the atom cannot pass, give
# errors that name them, and the file fails evaluation with them
# (FY-0037). The projects are in dev/fixtures/config.
{
  lib-atom,
  repository,
  root,
  testing,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      inherit (pkgs) lib;
      fixtures = root + "/dev/fixtures/config";
      chosenIn =
        project: arguments:
        lib-atom.config
          {
            inherit lib project;
            atom = "atom-example";
          }
          (
            {
              tool = "example";
              default = fixtures + "/default.json";
              names = [
                ".tool.json"
                "tool.yaml"
              ];
            }
            // arguments
          );
      chosen = name: chosenIn (fixtures + "/${name}");
      # The project as a flake gives it, self.outPath: a store path as a
      # string with context, which a name of a store path must not carry.
      source = name: "${repository}/dev/fixtures/config/${name}";
      file = name: arguments: (chosen name arguments).file;
      errors = name: arguments: (chosen name arguments).errors;
      # The store path of a file under a name, as text: comparing paths needs
      # no build.
      stored =
        path: name:
        "${builtins.path {
          inherit path name;
        }}";
      fails = name: arguments: !(builtins.tryEval "${file name arguments}").success;
      unsupported = [
        "tool.config.js"
        {
          name = "pyproject.toml";
          label = "[tool.example] of pyproject.toml";
          when = path: (builtins.fromTOML (builtins.readFile path)) ? tool.example;
        }
        {
          name = "Cargo.toml";
          when = path: (builtins.fromTOML (builtins.readFile path)) ? package.metadata.example;
        }
      ];
    in
    {
      checks.test-lib-config = testing.facts pkgs "test-lib-config" {
        "without a file, the default" =
          "${file "none" { }}" == stored (fixtures + "/default.json") "default.json";
        "without a file, no errors" = errors "none" { } == [ ];
        "the project's file, without the leading dot" =
          "${file "one" { }}" == stored (fixtures + "/one/.tool.json") "tool.json";
        "the file of a project given as a string with context" =
          "${(chosenIn (source "one") { }).file}" == stored (fixtures + "/one/.tool.json") "tool.json";
        "the default of a project given as a string with context" =
          "${(chosenIn (source "none") { }).file}" == stored (fixtures + "/default.json") "default.json";
        "a file below the root, under its base name" =
          "${file "nested" { names = [ ".github/tool.yaml" ]; }}"
          == stored (fixtures + "/nested/.github/tool.yaml") "tool.yaml";
        "two files fail" = fails "two" { };
        # Restated: the text is the interface (FY-0035).
        "the error names both files" =
          errors "two" { } == [
            "atom-example: the project has more than one configuration of example: .tool.json, tool.yaml; keep one."
          ];
        "unsupported files fail" = fails "unsupported" { inherit unsupported; };
        "the error names the unsupported files whose predicate holds" =
          errors "unsupported" { inherit unsupported; } == [
            "atom-example: the atom cannot pass these configurations of example to it: tool.config.js, [tool.example] of pyproject.toml; write the configuration in one of .tool.json, tool.yaml instead."
          ];
        "the error names the one standard path" =
          errors "unsupported" {
            names = [ ".tool.json" ];
            unsupported = [ "tool.config.js" ];
          } == [
            "atom-example: the atom cannot pass these configurations of example to it: tool.config.js; write the configuration in .tool.json instead."
          ];
        "absent unsupported files give no errors" = errors "one" { inherit unsupported; } == [ ];
        "both kinds of errors are given" =
          lib.length (
            errors "unsupported" {
              names = [
                ".tool.json"
                "tool.config.js"
              ];
              unsupported = [ "pyproject.toml" ];
            }
          ) == 2;
      };
    };
}
