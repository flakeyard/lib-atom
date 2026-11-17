---
id: ADR-0001
title: Functions that atoms share
status: accepted
date: 2026-11-16
supersedes: []
superseded_by: []
related: []
affects: ["flake.nix", "nix/**", "internal/testing/**", "dev/**", "README.md"]
review_by:
---

## Context

lib-atom is step 4 of [FY-0038][fy-0038]: the library that removes the copies of
Nix code from the atoms ([FY-0035][fy-0035]). [FY-0040][fy-0040] decides that it
is a flake without inputs whose output `lib` holds plain functions: the check of
`follows` with the import of the upstream module behind it, the warning of the
next major version, the choice of a configuration file ([FY-0037][fy-0037]) and
`version`, and that Nix code that two atoms need lives in it; and that the
helpers of the atoms' tests live in `internal/testing/`, outside the public API.
Atoms pin lib-atom in their own `flake.lock`, and their dev flakes take its
revision from there.

Reading atom-workflows, atom-nix, atom-shell and atom-workspace at their `main`
and atom-markdown and atom-text at the top of their open stacks showed:

- `nix/follows.nix` of atom-workflows, atom-nix, atom-shell, atom-markdown and
  atom-text differ only in the name of the atom, and so does the helper
  `upstream` in their `nix/default.nix`, which throws the message or returns the
  module. atom-workspace has no inputs.
- `nix/warning.nix` of the six atoms differ only in the name of the atom; the
  file of atom-nix only looks different when the name is replaced as text, since
  `nix` is also a word of the file. Every atom calls it twice, for its check and
  its shell, with `lib` of the consumer's `pkgs` and `./next-major.nix`.
- The choice of a configuration file has three implementations. atom-workflows
  (`nix/hooks.nix`) takes the first project file of the standard paths that
  exists, without an error for a second one, and names the store path after the
  base name of the file. atom-markdown (`nix/config.nix`) fails on more than one
  project file and on forms the atom cannot pass to the tool, such as JavaScript
  configurations of prettier, and names the store path without a leading dot,
  since prettier chooses the parser of `--config` by the extension of the file
  name. atom-text (`nix/configs.nix`) fails on more than one configuration of
  typos, on its tables in `pyproject.toml` and `Cargo.toml` and on `.ecrc`, and
  joins all of them into one error that the file of either tool throws. The
  messages of atom-markdown and atom-text differ.
- `nix/files.nix` of atom-nix and atom-workflows, after their move to lib-atom
  0.1.0, build the source of the domain's check the same way: the project's
  files, listed from `self.outPath`, whose relative path the `files` pattern of
  a hook of the domain matches as `.*(<files>).*`, copied with `builtins.path`
  and a filter that keeps them and only the directories that hold them, under
  the name of the domain. atom-nix passes its hooks and returns the store path;
  atom-workflows names its two hooks inside the file and also returns `of`, the
  files of one hook that end in `.yml` or `.yaml`, which its app
  `workflows-online` passes to zizmor. atom-data-formats will need the same for
  hooks with patterns such as `\.ya?ml$`, `\.jsonc?$` and `\.toml$`.
- atom-markdown (`nix/formatter.nix`) passes to `config` the six names of
  prettier and, as `unsupported`, its JavaScript and TypeScript configurations,
  `package.json` with the key `prettier`, read with `builtins.fromJSON`, and
  `.prettierrc.json` and `.prettierrc.toml` whose `overrides` have a pattern
  with a directory, read with `builtins.fromJSON` and `builtins.fromTOML`.
  atom-data-formats formats YAML and JSON with prettier and needs the same,
  since a project's configuration of prettier replaces the defaults of both
  atoms ([FY-0017][fy-0017]).
- `dev/nix/facts.nix` and `dev/fixtures/next-major.nix` are identical in the six
  atoms. `dev/nix/fixture.nix` has four forms, which differ in the upstream
  inputs the atom gets, in whether a fixture imports atom-workspace or switches
  off `checks.pre-commit` itself, and, in atom-workspace, in a given source and
  a list of modules. The tests of `follows`, of the warning and of the glue of
  atom-workspace differ only in the name of the atom, its upstream inputs, the
  output that is evaluated (`checks.<domain>` or `devShells.flakeyard-nix`) and
  the formatters and tools of the atom.

Running Nix 2.35.2 with the nixpkgs, flake-parts, treefmt-nix and git-hooks.nix
that the dev flake locks showed:

- A flake-parts module whose attributes come from a module argument, such as a
  file `{ testing, ... }: testing.follows { ... }`, fails with infinite
  recursion: the module system needs its attributes to find the arguments. The
  same file evaluates as `{ testing, ... }: { perSystem = ...; }`.
- `builtins.fetchTree` with the `locked` attributes of a node of `flake.lock`,
  `git+https` with `shallow`, fetches the source in pure evaluation, so a dev
  flake can take the revision of lib-atom from the root lock without an input.
- `nix flake check` of a flake whose only output is `lib` passes without a
  warning about an unknown output.
- `builtins.match` matches the whole string, so the pattern of a hook is wrapped
  in `.*(` and `).*` to be searched as pre-commit does with `re.search`. An
  empty pattern, the default of `files` in git-hooks.nix, matches every path.
  `lib.filesystem.listFilesRecursive` lists the files of a source in pure
  evaluation, and two sources that differ only in files outside the filter give
  the same store path.
- `builtins.tryEval` catches `throw` but not its message, and a warning of
  `lib.warn` cannot be read back. A test sees the message that an atom's module
  makes only when the atom gets a `lib` whose function gives the message as a
  value instead.
- atom-shell and atom-markdown, rewritten locally against this design, without
  their copies of `follows.nix`, `warning.nix`, `config.nix`, `facts.nix`,
  `fixture.nix` and the next-major fixture and with their tests of `follows`, of
  the warning and of atom-workspace as calls of the generators below, pass
  `nix flake check` of their dev flakes on x86_64-linux and its evaluation on
  every system. Their other tests changed only where they called the removed
  files: the expected messages of atom-markdown about configuration files.
- atom-markdown at `main` and atom-data-formats at the top of its first stack,
  rewritten locally to take `prettier` below, with a lock that points lib-atom
  at this working tree, pass `nix flake check` of their dev flakes on
  x86_64-linux; atom-markdown's tests pass unchanged, so its messages about the
  configuration files of prettier are the same.
- atom-nix and atom-workflows at `main`, rewritten locally without
  `nix/files.nix` to call `domain` below, with a lock that points lib-atom at
  this working tree, pass `nix flake check` of their dev flakes on x86_64-linux.
  The checks of their fixture projects, `checks.workflows` of atom-workflows and
  its app evaluate to the same derivations as before; only the checks of the
  changed files of the atoms themselves differ.

With the seven atoms released on lib-atom (atom-workflows, atom-workspace,
atom-nix, atom-shell, atom-markdown, atom-text and atom-data-formats, at their
latest `v0` tags), Nix 2.35.2 showed:

- The loader in each atom's `dev/flake.nix` is the same three lines: it reads
  the atom's root `flake.lock` and calls `builtins.fetchTree` with the `locked`
  attributes of its node of lib-atom. It takes no argument that could replace
  that revision, and no other `builtins.fetchTree` is called in the file.
- `builtins.scopedImport` is available in pure evaluation, also in
  `nix flake check`. A dev flake imported with it and a `builtins` whose
  `fetchTree` gives another source for the node of lib-atom runs with that
  source; the files it imports in turn see the usual `builtins`, and `../.` in
  it still names the root of the atom's source.
- `builtins.getFlake` of `git+https://github.com/flakeyard/<atom>?dir=dev` with
  `rev` evaluates in pure evaluation and gives `inputs` as the atom's
  `dev/flake.lock` locks them, without evaluating the outputs; a `path:` of a
  store path is refused.
- Every check of the seven dev flakes, evaluated this way with the working tree
  of lib-atom at `main`, builds on x86_64-linux and evaluates on every system.
  With the message of `follows` changed in the working tree, the checks of
  atom-shell and atom-markdown fail in their `test-follows`, which restates the
  message; atom-workspace, which has no upstream inputs, still passes.
- `action-flake-lock` accepts nested entries of lib-atom locked more than once
  from `v0.4.0`, which workflow-check pins from `v0.6.0`. The dev flake's atoms
  at their latest tags pin two revisions of lib-atom.

## Decision

### Flake

The public `flake.nix` has no inputs and one output, `lib`; it defines the root
of the repository and passes it to `nix/default.nix` ([FY-0039][fy-0039]). It
has no `flake.lock`. Each function is a file of its own in `nix/`. The dev flake
is in `dev/` ([FY-0038][fy-0038]).

### Functions

Every function takes `lib` of the consumer's nixpkgs where it needs one and the
name of the atom, such as `atom-shell`, which every message starts with.

- `version`: the version in `.release-please-manifest.json`, read with
  `builtins.readFile` and `builtins.fromJSON`.
- `follows { atom, own, consumer } name`: `null` when the consumer's inputs
  `consumer` have no input `name` or one with the `outPath` of the atom's input
  of that name in `own`, else the message of [FY-0017][fy-0017]:

  ```text
  atom-shell: input 'git-hooks' is locked twice; add to input atom-shell:
    inputs.git-hooks.follows = "git-hooks";
  ```

- `upstream { atom, own, consumer } name module`: `module`, or a `throw` of the
  message of `follows` with the same arguments. `own` is the atom's inputs and
  `consumer` the module argument `inputs`.
- `warning { lib, atom, root } value`: `value`, given with `lib.warn` while
  `root + "/nix/next-major.nix"` exists, with the message of the atoms today:

  ```text
  atom-shell: version 1 is coming with breaking changes; support of this major
  version ends 6 months after its first release. Migration guide:
  https://github.com/flakeyard/atom-shell/blob/main/docs/migration/v1.md
  ```

  (one line; the version and the path of the guide come from the file).

- `config { lib, atom, project } { tool, default, names, unsupported ? [ ] }`:
  `{ file, errors }`. `project` is the project's source, `default` the path of
  the atom's default and `names` the standard paths of the tool, relative to the
  root of the project; each is looked for with `builtins.pathExists`.
  `unsupported` lists the files that configure the tool in a form the atom
  cannot pass to it: a path, or `{ name; label ? name; when ? path: true; }` for
  a file that configures the tool only when `when` holds for its path, such as
  `[tool.typos]` of `pyproject.toml`. `errors` holds, in this order:

  ```text
  atom-markdown: the atom cannot pass these configurations of prettier to it:
  .prettierrc.cjs; write the configuration in one of .prettierrc,
  .prettierrc.json instead.
  atom-markdown: the project has more than one configuration of prettier:
  .prettierrc.json, .prettierrc.yaml; keep one.
  ```

  (two lines, wrapped here), with `in <name>` instead of `in one of <names>` for
  one standard path, and `label` for the files of `unsupported`. `file` throws
  the errors, one per line, when there are any, and is otherwise the project's
  file or the default, copied with `builtins.path` as a store path of its own
  named after its base name without a leading dot.

- `domain { lib, project } { name, hooks }`: `{ src, files, of }`, the files of
  a domain for its check ([FY-0017][fy-0017]). `files` lists the paths of
  `project`, relative to its root, that the pattern `files` of one of `hooks`
  matches when it is searched in the path, as `.*(<files>).*`; a hook without
  `files` matches every path, as an empty pattern does in pre-commit. The paths
  are listed from `project`, never from a store path made during evaluation,
  which a store may not have. `src` is `project` copied with `builtins.path`
  under `name`, such as the name of the domain's check, with only these files
  and the directories that hold them, so that a change of other files keeps the
  check cached. `of hook` lists the elements of `files` that the pattern of
  `hook` matches, for an app that passes them to the hook's tool; a filter by
  the hook's `types`, such as `.yml` and `.yaml` for the hooks of
  atom-workflows, stays in the atom. The filter is coarse: pre-commit selects by
  `files`, `types` and `excludes` in the check, and a domain with a hook that
  sets `always_run` passes the whole source instead.

- `prettier { lib, project }`: `{ names, unsupported }` for `config`, for the
  atoms that own prettier. `names` are `.prettierrc`, `.prettierrc.json`,
  `.prettierrc.json5`, `.prettierrc.yaml`, `.prettierrc.yml` and
  `.prettierrc.toml`. `unsupported` holds the forms that prettier ignores with
  `--config`: `.prettierrc` and `prettier.config` with the extension `js`,
  `cjs`, `mjs`, `ts`, `cts` or `mts`; `package.json` when it has the key
  `prettier`, labelled `the key prettier of package.json`; and
  `.prettierrc.json` and `.prettierrc.toml` when a pattern of `files` or
  `excludeFiles` of their `overrides` has a directory, which prettier resolves
  against the directory of the chosen file, a store path, labelled
  `<name> (overrides with a directory: <patterns>)`. The other forms of
  `.prettierrc` are not read by Nix. An atom passes the result to `config` with
  its `tool` and `default`.

Checks that only one atom needs stay in that atom and are written as entries of
`unsupported`: the tables of typos in `pyproject.toml` and `Cargo.toml` as
`when` predicates that read the file with `builtins.fromTOML`, and `.ecrc` as a
path of editorconfig-checker. Each tool gets its own errors, which only its file
throws.

### Test helpers

`internal/testing/default.nix` takes the inputs of the atom's dev flake, the
root of the atom, its systems, a function `atom` from inputs that replace those
of the dev flake to the atom's outputs, the modules that every fixture imports,
such as that of atom-workspace or
`{ perSystem.pre-commit.check.enable = false; }`, and `lib` of the same revision
of lib-atom. It gives:

- `facts pkgs name facts`: a check that fails and names every false fact;
- `fixture { name, source, module, atomInputs }`: the flake of a project at
  `source`, by default `dev/fixtures/<name>` of the atom, that imports the atom
  with the inputs of the dev flake except those in `atomInputs`, the modules of
  every fixture and `module`, with `debug = true`;
- `follows { output, messages }`, `next-major { output, message }` and
  `workspace spec`: the `perSystem` modules of `checks.test-follows`,
  `checks.test-next-major` and `checks.test-workspace`, which an atom's test
  file sets as `{ testing, ... }: { perSystem = testing.follows { ... }; }`.
  `messages` and `message` are restated by the atom's test with the comment of
  FY-0035. The generators compare them with the messages that the atom's own
  module makes, as consumers import it, for the `output`, such as
  `[ "checks" "shell" ]`: the fixture gives the atom a lib-atom whose `upstream`
  returns the message of `follows` as `flake.lib-atom-follows.<name>` instead of
  throwing it, and whose `warning` adds the message for the file of
  `internal/testing/fixtures/next-major` and the root that the atom passes to
  the output as `lib-atom-warning`. An atom that passes a wrong name, root or
  inputs fails its test. `spec` is a function of `{ pkgs, flake, system }` to
  the atom's formatters and tools, by name, and its own facts.

An atom's dev flake reads `flake.lock` of the atom's root, fetches the locked
node of `lib-atom` with `builtins.fetchTree`, imports `flake.nix` of that source
for the atom and `internal/testing` of it for the tests. These few lines cannot
come from the library they load and stay in each atom, as the loader of
[FY-0035][fy-0035] does.

### Tests

`dev/flake.nix` checks every function with pass and failure cases, failures
through the messages and through `builtins.tryEval`, and `version` against the
manifest. It checks `internal/testing` on `dev/fixtures/atom`, an atom that
takes lib-atom as atoms do, with every generator and `fixture`, and shows that
each generated check fails, naming the false fact, for a false fact, for the
atom under a wrong name, for the atom without the guard of `follows`, for a
wrong expected message and for a formatter or tool the project does not get. It
checks this repository with the released atom-workflows, atom-nix, atom-shell
and atom-workspace.

### The released atoms

`dev/nix/tests/released.nix` runs the tests of the released atoms with the
working tree of lib-atom in place of the revision they pin, as FY-0040 requires
of every pull request. The dev flake locks each released atom once, at its
latest `v0` tag: the atoms that check this repository as flake inputs, the
others as sources with `flake = false`, so that Renovate updates them as any
input. For each, `checks.test-released-<atom>` builds every check of the atom's
dev flake: its `outputs` are called with the inputs that `builtins.getFlake`
gives for the atom's `dev/flake.lock` and with `self`, and its `dev/flake.nix`
is imported with `builtins.scopedImport` and a `fetchTree` that gives the root
of this repository for the node of lib-atom and throws for any other source. The
atoms themselves do not change. The check also fails, naming the fact, when the
atom no longer pins lib-atom in its root `flake.lock` or its loader no longer
calls `builtins.fetchTree`, either of which would leave the pinned revision in
place unnoticed. A newly released atom is added to the list and as an input.

## Constraints

- The public flake MUST have no inputs and MUST have no output other than `lib`.
- Every function MUST take what it needs as arguments. Functions MUST NOT import
  anything from a consumer's inputs; `follows` and `upstream` MUST compare only
  `outPath`.
- The names, arguments and results of the functions of `lib`, and the text of
  every message they make, are the public API ([FY-0024][fy-0024]). A change
  that breaks any of them MUST NOT be released within a major version.
- `config` MUST detect whether a file exists only with `builtins.pathExists` on
  the given source and MUST give the chosen file as a store path of its own
  whose name has no leading dot.
- `domain` MUST select files only by the `files` patterns of the given hooks, as
  pre-commit searches them, MUST read the list of files from the given source
  and MUST name its store path only after `name`.
- `prettier` MUST give the configuration files of prettier for every atom that
  owns prettier, and those atoms MUST pass it to `config`.
- Checks that one atom needs MUST stay in that atom.
- `internal/testing/` MUST NOT be part of the public API and MUST NOT be an
  output of the flake.
- Every function and helper MUST be checked by `dev/flake.nix` with pass and
  failure cases.
- Every pull request MUST build every check of the dev flake of every released
  atom with the working tree of lib-atom in place of the revision the atom pins,
  and that check MUST fail when it cannot replace the revision.

## Consequences

- (+) One implementation of the follows check, the warning, the choice of
  configuration files and the files of a domain, and one of the atoms' common
  tests.
- (+) The messages of the follows check and the warning stay as they are, so
  atoms move without a change visible to projects.
- (−) atom-workflows fails on two files of one tool, where it took the first,
  and the messages of atom-markdown and atom-text about configuration files
  change; all three are `0.y.z` ([FY-0040][fy-0040]).
- (−) Every atom keeps a few lines that load lib-atom in its dev flake.
- (−) A test of an atom sets `perSystem` to the generator's module instead of
  being that module.
- (±) The helpers of the tests change with any release; an atom takes them with
  the revision it pins.
- (+) A change of lib-atom that breaks a released atom fails its pull request,
  before any atom takes it.
- (−) The check depends on the form of the atoms' loader and on
  `builtins.scopedImport`, which the Nix manual does not document; a change of
  either fails the check rather than passing it.

## Alternatives considered

- **Functions bound to one atom once, such as `lib.for "atom-shell"`.** Saves
  the argument `atom` in each call, but adds a layer to the API.
- **`default` as a name in `config/` of the atom's root.** Ties the library to
  the layout of atoms; a path serves any layout.
- **`warning` with the path of the file.** The path `nix/next-major.nix` is set
  by FY-0038 and is written once in the library.
- **Each atom's messages about configuration files.** Three formats for the same
  errors.
- **`domain` that rejects a hook without `files`.** git-hooks.nix gives every
  hook an empty pattern by default, which pre-commit applies to every file; the
  function does the same, so the check and the hook select the same files.
- **`domain` that filters by `types` for `of`.** Selection by `types` belongs to
  pre-commit (FY-0017); the one app that needs it keeps the filter.
- **Test helpers as flake output.** FY-0040 keeps them out of the public API.
- **Generators that give whole modules.** The module system recurses infinitely
  when a module comes from a module argument.
- **An argument of the atoms' loader for another source of lib-atom**, such as
  `inputs.lib-atom-source or (builtins.fetchTree ...)`. Explicit, but every atom
  would have to change and be released before lib-atom could check it, and the
  loader of FY-0040 would do more than load.
- **The atoms' dev flakes as inputs of this flake with `dir=dev`.** Their inputs
  would be locked again in `dev/flake.lock`, once per atom, and the loader would
  still fetch the pinned lib-atom.
- **Only the `test-` checks of the atoms.** Their checks of their own repository
  also run the atom's module with lib-atom.

[fy-0017]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0017-atom-contract.md
[fy-0024]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0024-versioning-and-support.md
[fy-0035]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0035-extract-logic-that-has-two-users.md
[fy-0037]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0037-atoms-ship-default-configs-that-projects-replace.md
[fy-0038]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0038-roll-out-the-atoms.md
[fy-0039]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0039-reach-repository-files-in-nix-from-one-root.md
[fy-0040]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0040-share-code-through-lib-repositories.md
