## ADDED Requirements

### Requirement: Named resolution contract

The plugin SHALL define, in exactly one reference document, a resolution contract mapping a subject identifier and a genre identifier to an ordered list of existing rule files plus an outcome status. Every skill that reads or persists writing rules SHALL cite that document at the point where it needs a location, and SHALL NOT construct a storage path inline.

#### Scenario: A skill needs a subject's rules

- **WHEN** a skill requires the writing rules for a given subject and genre
- **THEN** it performs the resolution defined by the reference document and receives an ordered file list and an outcome status
- **AND** it does not itself assemble a directory path or glob pattern

#### Scenario: Inspection finds no inline path construction

- **WHEN** the skills directory is searched for the storage path literal
- **THEN** matches occur only in the reference document and the migration script
- **AND** no skill file contains an inline construction of that path

### Requirement: Storage layout

The plugin namespace SHALL contain a subjects directory and a genres directory. Each subject SHALL be represented by one directory named by a subject slug. A subject directory that exists MUST contain a core file. A subject directory MAY contain zero or more genre facet files, each named by a genre slug. The genres directory SHALL contain subject-independent genre convention files, each named by a genre slug.

#### Scenario: Subject writes in a single genre

- **WHEN** a subject has rules for only one genre
- **THEN** the subject directory contains a core file and no facet file
- **AND** no split is required

#### Scenario: Subject directory exists without a core file

- **WHEN** resolution encounters a subject directory that contains no core file
- **THEN** resolution reports the subject directory as malformed rather than treating the subject as unresolved

### Requirement: Resolution order

Resolution SHALL return files ordered least-specific first, so that a later file's general conventions override an earlier file's. The order SHALL be: the subject-independent convention file for the requested genre when present, then the requested subject's core file when the subject directory is present, then the requested subject's facet file for the requested genre when present.

#### Scenario: All three levels present

- **WHEN** a genre convention file, a subject core file, and a matching subject facet file all exist
- **THEN** resolution returns exactly those three files in that order

##### Example: Ordering with all levels present

| Position | File role | Overrides |
| -------- | --------- | --------- |
| 1 | genre convention for the requested genre | nothing |
| 2 | subject core | genre convention |
| 3 | subject facet for the requested genre | subject core, genre convention |

#### Scenario: Only a core file exists

- **WHEN** a subject directory holds a core file, no facet exists for the requested genre, and no genre convention file exists
- **THEN** resolution returns a single-element list containing the core file

### Requirement: Outcome statuses

Resolution SHALL return exactly one of three outcome statuses: subject-specific when at least the subject's core file was found at the current location, legacy when resolution succeeded through the legacy location or a redirect placeholder, and generic when no subject-specific file was found at either location. A skill receiving a status other than subject-specific SHALL disclose that status to the user before presenting a draft.

#### Scenario: Subject has rules at the current location

- **WHEN** resolution finds the subject's core file in the plugin namespace
- **THEN** the status is subject-specific
- **AND** no disclosure obligation applies

#### Scenario: Subject has no rules anywhere

- **WHEN** resolution finds no subject file at the current location and none at the legacy location
- **THEN** the status is generic
- **AND** the skill states that this subject has no existing rules before presenting a draft

#### Scenario: Subject has rules only at the legacy location

- **WHEN** resolution finds no subject directory but finds a rules file at the legacy location
- **THEN** the status is legacy
- **AND** the skill states which location was used and offers migration

### Requirement: Dual-location conflict

When rules for the same subject exist at both the current location and the legacy location, resolution SHALL use the current location and SHALL report the conflict. Resolution MUST NOT choose either side silently.

#### Scenario: Both locations hold rules for one subject

- **WHEN** a subject has both a subject directory in the plugin namespace and a non-placeholder file at the legacy location
- **THEN** resolution returns the current-location files
- **AND** reports that a legacy file for the same subject also exists

### Requirement: Composition precedence

A facet file MAY override the general conventions stated by the subject's core file. A facet file MUST NOT override the honesty boundaries stated by the subject's core file. Each facet file SHALL state this precedence in its header.

#### Scenario: Facet contradicts a core convention

- **WHEN** a facet states a formatting or register convention that differs from the core's general convention
- **THEN** the facet's convention applies for that genre

#### Scenario: Facet contradicts a core honesty boundary

- **WHEN** a facet states something that would relax a claim boundary the core marks as a red line
- **THEN** the core boundary applies and the facet statement is rejected

### Requirement: Split criterion by reader

The reference document SHALL state that a writing rule belongs in the plugin namespace when a skill in this plugin reads it, and belongs in the injected project rules directory when no skill reads it and it functions by being injected into general session context. The document SHALL name the rule categories that remain in the injected directory and SHALL give the absence of a read site as the reason. When the criterion is ambiguous for a rule, the rule SHALL remain in the injected directory.

#### Scenario: Rule category has a read site in this plugin

- **WHEN** a rule category is both written and read by skills in this plugin
- **THEN** that category is stored in the plugin namespace

#### Scenario: Rule category has no read site in this plugin

- **WHEN** a rule category is written by a skill in this plugin but read by no skill in this plugin
- **THEN** that category remains in the injected project rules directory
- **AND** the reference document names it and states the absence of a read site as the reason

##### Example: Category placement by read site

| Rule category | Read by a skill in this plugin | Placement |
| ------------- | ------------------------------ | --------- |
| per-subject correspondence rules | yes | plugin namespace |
| document-type genre conventions | yes | plugin namespace |
| code-comment writing style | no | injected project rules directory |
| general writing style | no | injected project rules directory |

### Requirement: External consumer contract states resolution

The published consumer contract SHALL describe the rules path field as referring to a resolved location, SHALL name the three outcome statuses, and SHALL state that a consumer reconstructing the canonical location itself must follow the resolution order rather than assume a single file.

#### Scenario: A consumer reads the published contract

- **WHEN** an external consumer implements handover of a rules location
- **THEN** the contract tells it the three possible outcome statuses and the resolution order it must follow

### Requirement: Skill-packaged subject rules resolve as core

A workspace MAY package a subject's rules as a skill rather than as files under the plugin namespace. Resolution SHALL consult that arrangement when no subject directory exists, SHALL treat a matching skill as the subject's core at the same precedence as a core file, and SHALL return the subject-specific outcome rather than the legacy outcome. Where a workspace packages one skill per genre for the same subject, resolution SHALL return every matching skill rather than treating the second as a conflict.

#### Scenario: Subject rules are packaged as a skill

- **WHEN** no subject directory exists but a skill packaging that subject's rules is present
- **THEN** resolution returns that skill's content as the subject's core
- **AND** the outcome status is subject-specific, not legacy
- **AND** no migration is offered, because the arrangement is current rather than deprecated

#### Scenario: Skill content is already loaded

- **WHEN** a skill packaging the subject's rules was triggered by its own description before this plugin ran
- **THEN** the reader uses the rules already present rather than reading the file a second time

#### Scenario: One skill per genre for the same subject

- **WHEN** a subject has two skills packaging rules for two different genres
- **THEN** resolution returns both, core-like first
- **AND** does not report a conflict

##### Example: Placement of a subject with skill-packaged rules

| Sources present for a subject | Resolution uses | Status | Conflict reported |
| ----------------------------- | --------------- | ------ | ----------------- |
| subject directory only | subject directory | subject-specific | no |
| skill only | skill | subject-specific | no |
| legacy file only | legacy file | legacy | no |
| subject directory and skill | subject directory | subject-specific | yes, naming both |
