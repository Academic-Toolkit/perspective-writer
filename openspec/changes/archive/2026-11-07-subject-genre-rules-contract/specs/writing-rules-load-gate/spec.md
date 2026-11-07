## ADDED Requirements

### Requirement: Resolution must run before drafting

A skill that produces a draft SHALL have performed a rules resolution for the subject and genre it is drafting for, and SHALL have recorded the resulting outcome status. Drafting without a recorded resolution outcome SHALL be refused with a message naming the lookup that was not performed.

#### Scenario: Draft attempted with no resolution recorded

- **WHEN** a skill reaches the drafting step and no resolution outcome is recorded for the subject and genre
- **THEN** the skill refuses to draft
- **AND** the refusal message names the missing lookup

#### Scenario: Draft attempted after resolution ran

- **WHEN** a skill reaches the drafting step and a resolution outcome is recorded
- **THEN** the skill proceeds to draft

### Requirement: Generic outcome does not trigger refusal

A resolution that ran and returned the generic outcome SHALL NOT cause refusal. The skill SHALL proceed to draft and SHALL state that the subject has no existing rules before presenting the draft.

#### Scenario: First time writing to a subject

- **WHEN** resolution runs for a subject that has no rules at any location and returns the generic outcome
- **THEN** the skill proceeds to draft
- **AND** states that this subject has no existing rules before presenting the draft

##### Example: Refusal versus disclosure

| Situation | Resolution recorded | Outcome status | Behavior |
| --------- | ------------------- | -------------- | -------- |
| lookup step skipped | no | none | refuse, name the missing lookup |
| genuine first contact | yes | generic | draft, disclose absence of rules |
| rules at legacy location | yes | legacy | draft, disclose location, offer migration |
| rules at current location | yes | subject-specific | draft, no disclosure |

### Requirement: Disclosure is mandatory and specific

When the recorded outcome is generic, the skill SHALL state that the subject has no existing rules. When the recorded outcome is legacy, the skill SHALL state which location supplied the rules and SHALL offer migration. Neither disclosure SHALL be omitted on the grounds that the draft appears acceptable.

#### Scenario: Legacy outcome recorded

- **WHEN** the recorded outcome is legacy
- **THEN** the skill names the location that supplied the rules
- **AND** offers migration to the current location

#### Scenario: Draft looks acceptable under a generic outcome

- **WHEN** the recorded outcome is generic and the produced draft reads well
- **THEN** the disclosure is still stated

### Requirement: Load gate does not close the wrong-path gap

The reference document SHALL state that a resolution performed against an incorrect location returns the generic outcome and is therefore indistinguishable from genuine first contact, and SHALL NOT present the load gate as closing that gap.

#### Scenario: Resolution runs against an incorrect location

- **WHEN** a resolution is performed against a location that does not hold the subject's rules although rules exist elsewhere
- **THEN** the outcome is generic and the disclosure is identical to genuine first contact
- **AND** the reference document records this as a known residual rather than a solved case
