## MODIFIED Requirements

### Requirement: Outcome statuses

Resolution SHALL return exactly one of three outcome statuses: subject-specific when at least the subject's core file was found at the current location, legacy when resolution succeeded through the legacy location or a redirect placeholder, and generic when no subject-specific file was found at either location. A problem with an included or imported rule file, or a redirect placeholder that leads nowhere, SHALL NOT add a status; it is reported as an additional disclosure alongside whichever status resolution returned. A skill receiving a status other than subject-specific SHALL disclose that status to the user before presenting a draft. When the status is generic and an include-unresolved or redirect-unresolved disclosure was also produced, the skill SHALL NOT phrase the generic disclosure as there being no rules; it SHALL state both that no rules for this subject were found and that a named rule file exists whose rules could not be loaded.

#### Scenario: Subject has rules at the current location

- **WHEN** resolution finds the subject's core file in the plugin namespace
- **THEN** the status is subject-specific
- **AND** no status disclosure applies

#### Scenario: Subject has no rules anywhere

- **WHEN** resolution finds no subject file at the current location and none at the legacy location, and produces no include-unresolved or redirect-unresolved disclosure
- **THEN** the status is generic
- **AND** the skill states that this subject has no existing rules before presenting a draft

#### Scenario: Subject has rules only at the legacy location

- **WHEN** resolution finds no subject directory but finds a rules file at the legacy location
- **THEN** the status is legacy
- **AND** the skill states which location was used and offers migration

#### Scenario: Generic status with a rule file that could not be loaded

- **WHEN** resolution returns generic and also produces include-unresolved for a genre file whose include line names a plugin that is not installed
- **THEN** the status is still generic
- **AND** the skill states that no rules for this subject were found and that the named genre file's rules could not be loaded, naming the include target
- **AND** the skill does not say only that there are no rules
