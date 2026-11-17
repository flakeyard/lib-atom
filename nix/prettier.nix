# The configuration files of prettier (FY-0037), for the atoms that own it:
# atom-markdown for Markdown and atom-data-formats for YAML and JSON, whose
# defaults one file of the project replaces (FY-0017). It gives the names
# and the unsupported entries of config.
{
  # lib of the consumer's nixpkgs.
  lib,
  # The project's source, self.outPath, which for a git flake holds only
  # tracked files.
  project,
}:
{
  # The files that prettier finds by name, other than package.json and
  # package.yaml, whose key prettier the atoms do not read.
  names = [
    ".prettierrc"
    ".prettierrc.json"
    ".prettierrc.json5"
    ".prettierrc.yaml"
    ".prettierrc.yml"
    ".prettierrc.toml"
  ];
  # prettier ignores these with --config, without a message.
  unsupported = [
    ".prettierrc.js"
    ".prettierrc.cjs"
    ".prettierrc.mjs"
    ".prettierrc.ts"
    ".prettierrc.cts"
    ".prettierrc.mts"
    "prettier.config.js"
    "prettier.config.cjs"
    "prettier.config.mjs"
    "prettier.config.ts"
    "prettier.config.cts"
    "prettier.config.mts"
    # package.json is JSON without comments, which Nix reads. package.yaml
    # is YAML, which Nix does not read, so its key prettier is not
    # detected.
    {
      name = "package.json";
      label = "the key prettier of package.json";
      when = path: builtins.fromJSON (builtins.readFile path) ? prettier;
    }
  ]
  # prettier resolves the patterns of overrides[].files and excludeFiles
  # against the directory of the file of --config, a store path, so a
  # pattern with a directory matches no file of the project, without a
  # message; a pattern without one matches file names anywhere. The forms
  # that Nix parses are read: .prettierrc.json, which prettier reads as JSON
  # without comments, and .prettierrc.toml. .prettierrc, JSON5 and YAML are
  # not read.
  ++
    lib.mapAttrsToList
      (
        name: parse:
        let
          directories =
            path:
            lib.filter (lib.hasInfix "/") (
              lib.concatMap (
                override: lib.toList (override.files or [ ]) ++ lib.toList (override.excludeFiles or [ ])
              ) ((parse (builtins.readFile path)).overrides or [ ])
            );
        in
        {
          inherit name;
          label = "${name} (overrides with a directory: ${
            lib.concatStringsSep ", " (directories (project + "/${name}"))
          })";
          when = path: directories path != [ ];
        }
      )
      {
        ".prettierrc.json" = builtins.fromJSON;
        ".prettierrc.toml" = builtins.fromTOML;
      };
}
