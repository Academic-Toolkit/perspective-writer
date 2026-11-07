## MODIFIED Requirements

### Requirement: Redirect placeholder is followed once

A file at the legacy location whose content is a redirect placeholder SHALL resolve to the location the placeholder names, and SHALL be followed exactly once. A placeholder naming a subject directory that does not exist SHALL produce the redirect-unresolved additional disclosure and SHALL contribute no rules, so the status is whatever the remaining sources give, generic when nothing else is found. Resolution SHALL NOT follow any further redirect.

#### Scenario: Placeholder names an existing subject directory

- **WHEN** resolution reads a legacy path containing a redirect placeholder that names an existing subject directory
- **THEN** resolution continues at that subject directory and returns the legacy outcome

#### Scenario: Placeholder names a location that does not exist

- **WHEN** a redirect placeholder names a subject directory that is absent and no other source supplies rules for the subject
- **THEN** resolution produces the redirect-unresolved disclosure naming the placeholder's target
- **AND** the status is generic
- **AND** resolution does not follow any further redirect
