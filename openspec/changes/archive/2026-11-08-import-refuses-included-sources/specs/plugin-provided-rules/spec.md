## MODIFIED Requirements

### Requirement: Import writes a provenance header and refuses to overwrite

`plugin-rules.sh import` SHALL write the referenced file into the workspace (`genres/<slug>.md` for `--genre`, `subjects/<slug>/core.md` for `--subject`, `subjects/<subject>/<genre>.md` for both), with a first line `<!-- pw:imported plugin:<key> version:<version> path:<path> sha256:<hex> date:<YYYY-MM-DD> -->` followed by the file's content. It SHALL refuse with exit code 4 when the target exists and `--force` is absent, and SHALL print the written path on success. It SHALL refuse with exit code 2, writing nothing, when the source file contains an include line outside code (a fence or an indented line), whether well formed or malformed, and the message SHALL name the source and suggest including it instead; an include line inside code does not cause a refusal. Copies imported before this rule existed are not revisited.

#### Scenario: Import a genre file

- **WHEN** `import plugin:tools@a/genres/x.md --genre x` runs in an empty workspace
- **THEN** `genres/x.md` exists, its first line is the imported header with the sha256 of the source file, and the rest is the source content

#### Scenario: Target already exists

- **WHEN** the target file exists and `--force` is not given
- **THEN** the file is unchanged and the exit code is 4

#### Scenario: Source contains an include line

- **WHEN** `import plugin:tools@a/genres/x.md --genre x` runs and `genres/x.md` in the plugin contains a `<!-- pw:include plugin:other@b/genres/y.md -->` line outside code
- **THEN** the exit code is 2, no file is written in the workspace, and the message names the source and suggests including it instead

#### Scenario: Include line only inside code

- **WHEN** the source file contains an include line only inside a fenced code block
- **THEN** the import succeeds and the copy holds the source content unchanged
