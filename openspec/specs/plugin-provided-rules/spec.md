# plugin-provided-rules Specification

## Purpose

Let a workspace reference or import writing rules that another installed plugin publishes, so domain plugins can deliver genre conventions to perspective-writer without each workspace copying them by hand. Expansion and import are deterministic so their behavior can be tested, and every problem is disclosed instead of silently dropping rules.

## Requirements

### Requirement: Include line expands an installed plugin's rule file

A workspace rule file SHALL be able to contain, on a line of its own, `<!-- pw:include plugin:<name>@<marketplace>/<path> -->`. Running `plugin-rules.sh expand` on that file SHALL replace the line with the full content of `<path>` inside the installed directory of the plugin keyed `<name>@<marketplace>`, wrapped in `<!-- pw:source begin plugin:<key> version:<version> path:<path> -->` and `<!-- pw:source end -->`. All other lines SHALL be output unchanged and in their original order.

#### Scenario: Plugin installed and file present

- **WHEN** a workspace genre file contains only an include line naming an installed plugin and an existing Markdown file inside it
- **THEN** stdout contains that file's content wrapped in source markers naming the plugin key, its installed version and the path
- **AND** stderr contains no disclosure line
- **AND** the exit code is 0

##### Example: grant-proposal genre rules

- **GIVEN** the installed record maps `grant-rules@example-plugins` to a directory at version `0.7.0` containing `perspective-writer/genres/grant-proposal.md` with the text `Do not cite internal lab meetings.`
- **WHEN** `expand` runs on a file whose only line is `<!-- pw:include plugin:grant-rules@example-plugins/perspective-writer/genres/grant-proposal.md -->`
- **THEN** stdout is the begin marker naming `grant-rules@example-plugins`, `0.7.0` and the path, then `Do not cite internal lab meetings.`, then the end marker

---
### Requirement: Marketplace omitted only when unambiguous

An include line written as `plugin:<name>/<path>` SHALL resolve only when exactly one installed key starts with `<name>@`. With zero or more than one such key the line SHALL NOT be expanded and `expand` SHALL emit an `include-unresolved` disclosure that names the target and, when there are several, lists the candidate keys.

#### Scenario: Two plugins share a name

- **WHEN** two installed keys are `tools@a` and `tools@b` and an include line reads `plugin:tools/rules.md`
- **THEN** the include line is output unchanged
- **AND** stderr contains an `include-unresolved` line listing `tools@a` and `tools@b`

#### Scenario: Unique name

- **WHEN** exactly one installed key is `tools@a` and an include line reads `plugin:tools/rules.md` and the file exists
- **THEN** the line is expanded as if it named `tools@a`

---
### Requirement: Missing plugin or file is disclosed, not dropped silently

When the named plugin is not installed, or the file does not exist inside its installed directory, `expand` SHALL keep the include line unchanged, SHALL emit `pw:disclosure include-unresolved <target> — <reason>` on stderr, and SHALL exit 0.

#### Scenario: Plugin not installed

- **WHEN** an include line names a key absent from the installed record
- **THEN** stderr contains an `include-unresolved` line naming that key and path
- **AND** the exit code is 0

#### Scenario: File missing inside the plugin

- **WHEN** the plugin is installed but `<path>` does not exist in its installed directory
- **THEN** stderr contains an `include-unresolved` line naming the path

---
### Requirement: Nested include is not expanded

An include line found inside included content SHALL NOT be expanded. It SHALL appear in the output unchanged, and `expand` SHALL emit an `include-nested` disclosure naming the nested target and the file that contained it.

#### Scenario: Included file includes another

- **WHEN** an included plugin file contains its own include line
- **THEN** that line appears unchanged inside the source markers
- **AND** stderr contains an `include-nested` line

---
### Requirement: Included paths stay inside the plugin and are Markdown

The `<path>` of an include or import SHALL be relative, SHALL NOT contain a `..` segment, SHALL end in `.md`, and its resolved location after following symbolic links SHALL lie inside the plugin's installed directory. A path that violates any of these SHALL NOT be read; `expand` SHALL emit `include-unresolved`, and `import` SHALL exit with code 2.

#### Scenario: Path escapes the plugin

- **WHEN** an include line names `plugin:tools@a/../../secret.md`
- **THEN** no file outside the plugin is read
- **AND** stderr contains an `include-unresolved` line

#### Scenario: Symbolic link pointing outside

- **WHEN** `<path>` is a symbolic link inside the plugin whose target lies outside the installed directory
- **THEN** the target is not read and `include-unresolved` is emitted

---
### Requirement: Import writes a provenance header and refuses to overwrite

`plugin-rules.sh import` SHALL write the referenced file into the workspace (`genres/<slug>.md` for `--genre`, `subjects/<slug>/core.md` for `--subject`, `subjects/<subject>/<genre>.md` for both), with a first line `<!-- pw:imported plugin:<key> version:<version> path:<path> sha256:<hex> date:<YYYY-MM-DD> -->` followed by the file's content. It SHALL refuse with exit code 4 when the target exists and `--force` is absent, and SHALL print the written path on success.

#### Scenario: Import a genre file

- **WHEN** `import plugin:tools@a/genres/x.md --genre x` runs in an empty workspace
- **THEN** `genres/x.md` exists, its first line is the imported header with the sha256 of the source file, and the rest is the source content

#### Scenario: Target already exists

- **WHEN** the target file exists and `--force` is not given
- **THEN** the file is unchanged and the exit code is 4

---
### Requirement: Stale import is disclosed by comparing the source hash

When `expand` reads a file whose first line is an imported header, it SHALL recompute the sha256 of the named source. If the hash differs, or the source can no longer be found, it SHALL emit an `import-stale` disclosure. Changes made to the workspace copy itself SHALL NOT produce `import-stale`.

#### Scenario: Source changed after import

- **WHEN** the plugin's source file changes after import and `expand` runs on the copy
- **THEN** stderr contains an `import-stale` line naming the source

#### Scenario: Only the local copy changed

- **WHEN** the workspace copy is edited but the source is unchanged
- **THEN** no `import-stale` line is emitted

---
### Requirement: Primary statuses stay three; problems are additional disclosures

The resolution contract SHALL keep exactly three primary statuses (subject-specific, legacy, generic) and SHALL define a closed set of four additional disclosures: `include-unresolved`, `include-nested`, `import-stale`, and `redirect-unresolved`. A redirect placeholder naming a subject directory that does not exist SHALL yield the `redirect-unresolved` disclosure instead of a status outside the three. A drafting skill SHALL tell the user every additional disclosure before presenting a draft; an additional disclosure SHALL NOT change the primary status.

#### Scenario: Include unresolved with subject rules present

- **WHEN** resolve finds the subject's core file and an included genre file is unresolved
- **THEN** the primary status is subject-specific
- **AND** the user is told about the `include-unresolved` disclosure before the draft

---
### Requirement: Rules auditor receives expanded content with sources

The rules auditor SHALL receive, for every file resolve returned, the output of `plugin-rules.sh expand` in resolution order, including the source markers, and SHALL NOT receive bare include lines in place of the rules they name. Workspace text that follows an include line SHALL take precedence over the included content under the contract's composition precedence.

#### Scenario: Workspace override after include

- **WHEN** a workspace genre file has an include line followed by a workspace rule that contradicts one included rule
- **THEN** the auditor's input contains both, the included rule first inside source markers and the workspace rule after it
- **AND** the contract's composition precedence names the workspace rule as the one that applies

---
### Requirement: Persist writes only workspace files

The persist operation SHALL write only files under the workspace rules namespace and SHALL NOT modify any file inside a plugin's installed directory. When the target file contains an include line, the new rule SHALL be written after that line.

#### Scenario: Learned rule for a genre with an include

- **WHEN** a rule is persisted to a genre file whose first line is an include line
- **THEN** the include line is unchanged, the new rule appears after it, and no plugin file is modified

---
### Requirement: Only plugin-rules.sh reads the installed-plugin record

Apart from the resolution contract, `plugin-rules.sh` SHALL be the only file in the plugin that names the installed-plugin record or builds a path into a plugin's installed directory. The contract consistency check SHALL fail when another file does. When the record cannot be read or is not the `version: 2` shape, `plugin-rules.sh` SHALL exit with code 3 and SHALL NOT guess a location; a file with no include line and no imported header SHALL be output unchanged without reading the record.

#### Scenario: Unexpected record shape

- **WHEN** the record's `version` is not 2 and `expand` runs on a file with an include line
- **THEN** the exit code is 3 and an error message names the record path

#### Scenario: No include lines

- **WHEN** `expand` runs on a file with no include line and no imported header and the record does not exist
- **THEN** stdout equals the file content and the exit code is 0

---
### Requirement: A plugin's published rule files are not reserved for this plugin

The resolution contract SHALL state that a file a plugin publishes under `perspective-writer/` may also be read directly by that plugin's own skills, so that one copy serves both readers. It SHALL state that perspective-writer expands nothing and discloses nothing for those other readers, that `plugin-rules.sh` is not an interface for other plugins, and that a file meant for both kinds of reader contains no include line.

#### Scenario: A plugin's own skill reads its published genre file

- **WHEN** a plugin publishes `perspective-writer/genres/<slug>.md` and one of its own skills reads that file directly
- **THEN** the contract permits it, and the plugin keeps no second copy for its own skills

#### Scenario: A shared file contains an include line

- **WHEN** a maintainer reads the contract to decide whether a file read by both the plugin's skills and perspective-writer may contain an include line
- **THEN** the contract states that such a file contains no include line, because a direct reader sees the line as a comment and perspective-writer does not expand an include line inside an included file

#### Scenario: Another plugin's skill wants expanded rules

- **WHEN** a maintainer reads the contract to learn whether another plugin's skill may call `plugin-rules.sh expand`
- **THEN** the contract says the script is not an interface for other plugins and perspective-writer makes no disclosure on their behalf

<!-- @trace
source: plugin-rules-other-readers
updated: 2026-11-08
code:
  - .claude-plugin/marketplace.json
  - README.md
  - plugins/perspective-writer/CHANGELOG.md
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - plugins/perspective-writer/references/rules-resolution.md
-->