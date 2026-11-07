## MODIFIED Requirements

### Requirement: Generic outcome does not trigger refusal

A resolution that ran and returned the generic outcome SHALL NOT cause refusal. The skill SHALL proceed to draft and SHALL state that the subject has no existing rules before presenting the draft. When an include-unresolved or redirect-unresolved disclosure accompanies the generic outcome, that statement SHALL also say that a rule file refers, through an include line or a redirect placeholder, to rules that could not be loaded, naming the target, as the Outcome statuses requirement of the resolution contract specifies.

#### Scenario: First time writing to a subject

- **WHEN** resolution runs for a subject that has no rules at any location, returns the generic outcome, and produces no include-unresolved or redirect-unresolved disclosure
- **THEN** the skill proceeds to draft
- **AND** states that this subject has no existing rules before presenting the draft

#### Scenario: Generic outcome with an unresolved include

- **WHEN** resolution returns the generic outcome together with an include-unresolved disclosure
- **THEN** the skill proceeds to draft
- **AND** states both that no rules for this subject were found and that the included rule file could not be loaded

##### Example: Refusal versus disclosure

| Situation | Resolution recorded | Outcome status | Behavior |
| --------- | ------------------- | -------------- | -------- |
| lookup step skipped | no | none | refuse, name the missing lookup |
| genuine first contact | yes | generic | draft, disclose absence of rules |
| referenced rules could not be loaded | yes | generic, with include-unresolved or redirect-unresolved | draft, disclose that no rules were found and that the rules an include line or redirect placeholder refers to could not be loaded, naming the target |
| rules at legacy location | yes | legacy | draft, disclose location, offer migration |
| rules at current location | yes | subject-specific | draft, no status disclosure |

### Requirement: Disclosure is mandatory and specific

When the recorded outcome is generic, the skill SHALL state that the subject has no existing rules; when an include-unresolved or redirect-unresolved disclosure accompanies it, the skill SHALL instead state both that no rules for this subject were found and that a rule file refers, through an include line or a redirect placeholder, to rules that could not be loaded, naming the target. When the recorded outcome is legacy, the skill SHALL state which location supplied the rules and SHALL offer migration. Every additional disclosure SHALL be stated, naming its target, before the draft is presented. No disclosure SHALL be omitted on the grounds that the draft appears acceptable.

#### Scenario: Legacy outcome recorded

- **WHEN** the recorded outcome is legacy
- **THEN** the skill names the location that supplied the rules
- **AND** offers migration to the current location

#### Scenario: Draft looks acceptable under a generic outcome

- **WHEN** the recorded outcome is generic and the produced draft reads well
- **THEN** the disclosure is still stated

#### Scenario: Additional disclosure under a subject-specific outcome

- **WHEN** the recorded outcome is subject-specific and an include-unresolved disclosure was produced for a genre file
- **THEN** the skill states the include-unresolved disclosure, naming the include target, before presenting the draft
