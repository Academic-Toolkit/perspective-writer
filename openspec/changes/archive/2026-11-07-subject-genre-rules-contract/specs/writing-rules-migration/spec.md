## ADDED Requirements

### Requirement: Legacy location remains readable

Resolution SHALL consult the legacy correspondence location for a subject when no subject directory exists for that subject in the plugin namespace. A workspace that has not migrated SHALL continue to resolve its existing rules.

#### Scenario: Workspace has not migrated

- **WHEN** a workspace holds rules only at the legacy location and the plugin is upgraded
- **THEN** resolution finds those rules, returns the legacy outcome, and drafting proceeds

### Requirement: Redirect placeholder is followed once

A file at the legacy location whose content is a redirect placeholder SHALL resolve to the location the placeholder names, and SHALL be followed exactly once. A placeholder naming a location that does not exist SHALL be reported as unresolved rather than followed further.

#### Scenario: Placeholder names an existing subject directory

- **WHEN** resolution reads a legacy path containing a redirect placeholder that names an existing subject directory
- **THEN** resolution continues at that subject directory and returns the legacy outcome

#### Scenario: Placeholder names a location that does not exist

- **WHEN** a redirect placeholder names a subject directory that is absent
- **THEN** resolution reports the subject as unresolved
- **AND** does not follow any further redirect

### Requirement: Migration tool converts legacy files and leaves placeholders

The plugin SHALL provide a migration tool that, for each rules file at the legacy correspondence location, creates the corresponding subject directory, writes that file's content as the subject's core file, and replaces the legacy file with a redirect placeholder naming the new subject directory.

#### Scenario: Migrating a workspace with legacy rules

- **WHEN** the migration tool runs against a workspace holding rules files at the legacy location
- **THEN** each subject has a directory containing a core file with the original content
- **AND** each legacy path holds a redirect placeholder naming that subject directory

### Requirement: Migration is idempotent

Running the migration tool a second time SHALL produce the same result as running it once. A legacy path already holding a redirect placeholder SHALL be left untouched. A subject directory that already exists SHALL NOT be overwritten.

#### Scenario: Migration tool runs twice

- **WHEN** the migration tool is run a second time against an already-migrated workspace
- **THEN** no file content changes

### Requirement: Migration creates no facets

The migration tool SHALL write migrated content only as a subject's core file and SHALL NOT create any facet file. Separating genre-specific content out of a migrated core file is a judgment made when a second genre for that subject first arises.

#### Scenario: Legacy file mixes cross-genre and genre-specific content

- **WHEN** a legacy rules file contains both subject-level tone calibration and correspondence-specific structure
- **THEN** migration writes the whole file as the subject's core file
- **AND** creates no facet file

### Requirement: Migration is reversible

The reference document SHALL state the steps that reverse a migration: replacing each redirect placeholder with the content of the corresponding core file and removing the subject directory. Because legacy consultation is retained, a reversed workspace SHALL continue to resolve.

#### Scenario: Workspace reverses a migration

- **WHEN** each placeholder is replaced by its subject's core file content and the subject directories are removed
- **THEN** resolution finds the restored legacy files and returns the legacy outcome

### Requirement: Downstream consumer handover survives migration

Because a redirect placeholder occupies each legacy path, an external consumer that tests for the existence of the legacy path before handing it over SHALL continue to find that path present after migration, and the handover SHALL continue to resolve to the subject's current rules.

#### Scenario: Consumer checks the legacy path after migration

- **WHEN** an external consumer tests for the legacy path and hands it over because it exists
- **THEN** resolution follows the placeholder and returns the subject's current rules with the legacy outcome
