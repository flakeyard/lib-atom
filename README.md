# lib-atom

Nix functions that flakeyard atoms share: the check of `follows`, the warning of
the next major version and the choice of configuration files, with helpers for
the tests of atoms ([FY-0040][fy-0040], [ADR-0001][adr-0001]). Projects do not
use it directly.

## How atoms take it

lib-atom is a flake without inputs. Every atom declares it as an input of its
public flake and pins it in its own `flake.lock`; projects neither declare it
nor write a `follows` line for it, and every atom runs with the revision it was
released with ([FY-0040][fy-0040]). While lib-atom is `0.y.z`, in the form of
[FY-0016][fy-0016]:

```nix
{
  inputs = {
    treefmt-nix.url = "git+https://github.com/numtide/treefmt-nix?ref=main&rev=<commit>&shallow=1";
    git-hooks.url = "git+https://github.com/cachix/git-hooks.nix?ref=master&rev=<commit>&shallow=1";
    lib-atom.url = "git+https://github.com/flakeyard/lib-atom?ref=v0&rev=<commit>&shallow=1";
  };

  outputs = inputs: { flakeModules.default = import ./nix inputs; };
}
```

`nix/default.nix` of the atom takes the functions from
`atomInputs.lib-atom.lib`:

```nix
atomInputs:
{ inputs, ... }:
let
  root = ./..;
  shared = atomInputs.lib-atom.lib;
  upstream = shared.upstream {
    atom = "atom-shell";
    own = atomInputs;
    consumer = inputs;
  };
in
{
  imports = [
    (upstream "treefmt-nix" atomInputs.treefmt-nix.flakeModule)
    (upstream "git-hooks" atomInputs.git-hooks.flakeModule)
  ];
}
```

The dev flake of an atom takes the revision of lib-atom from the atom's root
`flake.lock`, so that the atom has one pin of it:

```nix
lock = builtins.fromJSON (builtins.readFile (root + "/flake.lock"));
source = builtins.fetchTree lock.nodes.${lock.nodes.root.inputs.lib-atom}.locked;
lib-atom = (import (source + "/flake.nix")).outputs { };
testing = import (source + "/internal/testing") { ... };
```

Renovate proposes updates of lib-atom in atoms with the commit type `fix`, and
lib-atom is released before the atoms take a new revision.

## Public API

Releases follow [semantic versioning][versioning] ([FY-0024][fy-0024]). The
public API is the output `lib`: the names of its functions, their arguments and
results, and the text of every message they make. A major release of lib-atom is
not by itself a major release of an atom. `internal/testing/` is not part of it.

The functions of `lib`, each in [`nix/`](nix):

- `version`: the released version, from `.release-please-manifest.json`.
- `follows { atom, own, consumer } name`: `null` when the consumer's inputs
  `consumer` have no input `name`, or one with the store path of the atom's
  input of that name in `own`; otherwise the error of [FY-0017][fy-0017]:

  ```text
  atom-shell: input 'git-hooks' is locked twice; add to input atom-shell:
    inputs.git-hooks.follows = "git-hooks";
  ```

- `upstream { atom, own, consumer } name module`: `module`, or a `throw` of the
  error of `follows` with the same arguments.
- `warning { lib, atom, root } value`: `value`, given with `lib.warn` of the
  consumer's nixpkgs while `nix/next-major.nix` exists under the atom's `root`
  ([FY-0038][fy-0038]):

  ```text
  atom-shell: version 1 is coming with breaking changes; support of this major
  version ends 6 months after its first release. Migration guide:
  https://github.com/flakeyard/atom-shell/blob/main/docs/migration/v1.md
  ```

  (one line, wrapped here; the version and the path of the guide come from the
  file).

- `config { lib, atom, project } { tool, default, names, unsupported ? [ ] }`:
  the configuration file of a tool that the project chose ([FY-0037][fy-0037]),
  as `{ file, errors }`. `project` is the project's source, `default` the path
  of the atom's default and `names` the standard paths of the tool, relative to
  the project's root. `unsupported` lists the files in forms the atom cannot
  pass to the tool: paths, or `{ name; label ? name; when ? path: true; }` for a
  file that configures the tool only when `when` holds for its path, such as
  `[tool.typos]` of `pyproject.toml`. `errors` lists:

  ```text
  atom-markdown: the atom cannot pass these configurations of prettier to it:
  .prettierrc.cjs; write the configuration in one of .prettierrc,
  .prettierrc.json instead.
  atom-markdown: the project has more than one configuration of prettier:
  .prettierrc.json, .prettierrc.yaml; keep one.
  ```

  (two lines, wrapped here), with `in <name>` for a tool with one standard path.
  `file` fails evaluation with the errors, one per line; without errors it is
  the project's file, or the default when the project has none, as a store path
  of its own named after the file without a leading dot.

The functions detect files with `builtins.pathExists` on the given source, which
for a git flake holds only tracked files.

## Test helpers

[`internal/testing`](internal/testing) holds the helpers of the tests of atoms.
The dev flake of an atom imports it from the revision of lib-atom that the atom
pins, with the inputs of the dev flake, the atom's root and systems, a function
from inputs to the atom's outputs, the modules every fixture imports and `lib`
of lib-atom. It gives `facts`, `fixture` and the generators `follows`,
`next-major` and `workspace` of the checks `test-follows`, `test-next-major` and
`test-workspace`; a test of an atom sets its `perSystem` to one. The generators
check the messages that the atom's own module makes for an output against the
ones the test restates:

```nix
{ testing, ... }:
{
  perSystem = testing.next-major {
    output = [
      "checks"
      "shell"
    ];
    # Restated: the text is the interface (FY-0035).
    message = "atom-shell: version 1 is coming with breaking changes; ...";
  };
}
```

The helpers may change in any release.

## Develop in the container

Open the repository in the flakeyard dev container: the editor reads
[`.devcontainer/devcontainer.json`](.devcontainer/devcontainer.json), and
`direnv` loads the shell of [`dev/flake.nix`](dev/flake.nix) through
[`.envrc`](.envrc) ([FY-0012][fy-0012]). [atom-workspace][atom-workspace] builds
the shell and installs the git hooks each time it starts. The container runs
`direnv allow` when it is created; run it once in every other worktree, and run
`direnv block` before you check out a branch you do not trust, since entering
the directory runs that branch's shell hook. Commit inside the container, whose
Nix store has the tools of the hooks. With Nix on the host, `direnv allow` or
`nix develop ./dev` gives the same shell.

The public [`flake.nix`](flake.nix) holds only the output `lib`.
[`dev/flake.nix`](dev/flake.nix), with its own lock, imports the library as
atoms do, checks this repository with [atom-workflows][atom-workflows],
[atom-nix][atom-nix], [atom-shell][atom-shell] and atom-workspace, and holds the
tests:

- `workflows`, `nix`, `shell`, `treefmt`: the checks of the atoms of this
  repository;
- `test-lib-version`, `test-lib-follows`, `test-lib-warning`, `test-lib-config`:
  the functions of `lib`, with their messages and failures, over the fixture
  projects in [`dev/fixtures/config`](dev/fixtures/config);
- `test-facts`, `test-fixture`, `test-follows`, `test-next-major`,
  `test-workspace`: the helpers of `internal/testing` on
  [`dev/fixtures/atom`](dev/fixtures/atom), an atom that takes lib-atom as atoms
  do;
- `test-facts-false`, `test-follows-misnamed`, `test-follows-unguarded`,
  `test-follows-message`, `test-next-major-misnamed`, `test-next-major-message`,
  `test-workspace-formatter`, `test-workspace-tool`: each generated check fails
  and names the false fact for a false fact, the atom under another name or
  without the guard of `follows`, a wrong expected message, or a formatter or
  tool the project does not get.

Run the same commands as CI:

```sh
nix flake check --no-update-lock-file ./dev
nix flake check --no-update-lock-file --no-build --all-systems ./dev
```

CI runs [`test.yaml`](.github/workflows/test.yaml), which calls
[workflow-check][workflow-check] with `./dev`: it checks `dev/flake.lock`,
builds every check on x86_64 and arm64 runners, checks the pull request title
and `renovate.json`, fails on configuration files of atom tools at their
standard root paths ([FY-0037][fy-0037]), and reports `check / required`
([FY-0034][fy-0034]). Its weekly run builds the checks against the current
branches of nixpkgs, treefmt-nix, git-hooks.nix and flake-parts instead of the
locked revisions ([FY-0038][fy-0038]).
[`scorecard.yaml`](.github/workflows/scorecard.yaml) runs OpenSSF Scorecard, and
[`release.yaml`](.github/workflows/release.yaml) releases the repository with
[workflow-release][workflow-release].

The check of the released atoms with the working tree of lib-atom
([FY-0040][fy-0040]) comes once atoms take lib-atom. Before a pull request, also
run prettier, markdownlint, typos and `reuse lint`; the atoms that will provide
them are not released yet ([FY-0038][fy-0038]).

## License

[MIT](LICENSE).

[adr-0001]: docs/adr/records/0001-functions-that-atoms-share.md
[atom-nix]: https://github.com/flakeyard/atom-nix
[atom-shell]: https://github.com/flakeyard/atom-shell
[atom-workflows]: https://github.com/flakeyard/atom-workflows
[atom-workspace]: https://github.com/flakeyard/atom-workspace
[fy-0012]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0012-develop-in-container.md
[fy-0016]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0016-pin-form.md
[fy-0017]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0017-atom-contract.md
[fy-0024]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0024-versioning-and-support.md
[fy-0034]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0034-check-every-repository-with-workflow-check.md
[fy-0037]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0037-atoms-ship-default-configs-that-projects-replace.md
[fy-0038]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0038-roll-out-the-atoms.md
[fy-0040]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0040-share-code-through-lib-repositories.md
[versioning]: https://github.com/flakeyard/.github/blob/main/VERSIONING.md
[workflow-check]: https://github.com/flakeyard/workflow-check
[workflow-release]: https://github.com/flakeyard/workflow-release
