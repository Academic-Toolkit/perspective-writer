## ADDED Requirements

### Requirement: Skills that compare against existing rules read them expanded

Every skill that resolves or persists rules SHALL read each file resolve returned, or each target it will write, through `plugin-rules.sh expand`, and SHALL compare, deduplicate and propose rules against that expansion rather than the raw file. It SHALL tell the user every additional disclosure the expansion produced. Writing SHALL still go to the raw workspace file, after any include line. The consistency check SHALL fail when a skill that mentions resolve or persist does not mention `plugin-rules.sh expand`.

#### Scenario: Workspace file is a single include line

- **WHEN** save-feedback is about to add a rule to a workspace genre file whose only content is an include line for a plugin rule that already states the same rule
- **THEN** it reads the expansion, finds the rule between the `pw:source` markers, and does not add a duplicate

#### Scenario: A rule-reading skill stops expanding

- **WHEN** a skill that mentions resolve or persist no longer mentions `plugin-rules.sh expand`
- **THEN** `check-contract-consistency.sh` exits 1 and names that skill's file
