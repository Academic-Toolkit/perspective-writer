# writing-rules-load-gate Specification

## Purpose

TBD - created by archiving change 'subject-genre-rules-contract'. Update Purpose after archive.

## Requirements

### Requirement: Resolution must run before drafting

A skill that produces a draft SHALL have performed a rules resolution for the subject and genre it is drafting for, and SHALL have recorded the resulting outcome status. Drafting without a recorded resolution outcome SHALL be refused with a message naming the lookup that was not performed.

#### Scenario: Draft attempted with no resolution recorded

- **WHEN** a skill reaches the drafting step and no resolution outcome is recorded for the subject and genre
- **THEN** the skill refuses to draft
- **AND** the refusal message names the missing lookup

#### Scenario: Draft attempted after resolution ran

- **WHEN** a skill reaches the drafting step and a resolution outcome is recorded
- **THEN** the skill proceeds to draft


<!-- @trace
source: subject-genre-rules-contract
updated: 2026-11-07
code:
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/agents/native-syntax-reader.md
  - plugins/perspective-writer/skills/draft-learner/SKILL.md
  - plugins/perspective-writer/skills/perspective-writer-email/SKILL.md
  - .spectra.yaml
  - plugins/perspective-writer/CHANGELOG.md
  - plugins/perspective-writer/agents/rules-auditor.md
  - plugins/perspective-writer/scripts/plugin-rules.sh
  - plugins/perspective-writer/scripts/check-contract-consistency.sh
  - perspective-writer.code-workspace
  - plugins/perspective-writer/references/rules-resolution.md
  - plugins/perspective-writer/skills/perspective-writer/references/zh-Hant-syntax-checkpoints.md
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - plugins/perspective-writer/skills/save-feedback/SKILL.md
  - .github/workflows/contract-consistency.yml
  - README.md
  - plugins/perspective-writer/skills/import-rules/SKILL.md
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - tests/plugin-rules.test.sh
  - plugins/perspective-writer/skills/perspective-writer/references/natural-writing-checklist.md
-->

---
### Requirement: Generic outcome does not trigger refusal

A resolution that ran and returned the generic outcome SHALL NOT cause refusal. The skill SHALL proceed to draft and SHALL state that the subject has no existing rules before presenting the draft. When an include-unresolved or redirect-unresolved disclosure accompanies the generic outcome, that statement SHALL also say that a named rule file exists whose rules could not be loaded, as the Outcome statuses requirement of the resolution contract specifies.

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
| named rule file could not be loaded | yes | generic, with include-unresolved or redirect-unresolved | draft, disclose that no rules were found and that the named file could not be loaded |
| rules at legacy location | yes | legacy | draft, disclose location, offer migration |
| rules at current location | yes | subject-specific | draft, no status disclosure |

---
### Requirement: Disclosure is mandatory and specific

When the recorded outcome is generic, the skill SHALL state that the subject has no existing rules; when an include-unresolved or redirect-unresolved disclosure accompanies it, the skill SHALL instead state both that no rules for this subject were found and that a named rule file exists whose rules could not be loaded. When the recorded outcome is legacy, the skill SHALL state which location supplied the rules and SHALL offer migration. Every additional disclosure SHALL be stated, naming its target, before the draft is presented. No disclosure SHALL be omitted on the grounds that the draft appears acceptable.

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

---
### Requirement: Load gate does not close the wrong-path gap

The reference document SHALL state that a resolution performed against an incorrect location returns the generic outcome and is therefore indistinguishable from genuine first contact, and SHALL NOT present the load gate as closing that gap.

#### Scenario: Resolution runs against an incorrect location

- **WHEN** a resolution is performed against a location that does not hold the subject's rules although rules exist elsewhere
- **THEN** the outcome is generic and the disclosure is identical to genuine first contact
- **AND** the reference document records this as a known residual rather than a solved case

<!-- @trace
source: subject-genre-rules-contract
updated: 2026-11-07
code:
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/agents/native-syntax-reader.md
  - plugins/perspective-writer/skills/draft-learner/SKILL.md
  - plugins/perspective-writer/skills/perspective-writer-email/SKILL.md
  - .spectra.yaml
  - plugins/perspective-writer/CHANGELOG.md
  - plugins/perspective-writer/agents/rules-auditor.md
  - plugins/perspective-writer/scripts/plugin-rules.sh
  - plugins/perspective-writer/scripts/check-contract-consistency.sh
  - perspective-writer.code-workspace
  - plugins/perspective-writer/references/rules-resolution.md
  - plugins/perspective-writer/skills/perspective-writer/references/zh-Hant-syntax-checkpoints.md
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - plugins/perspective-writer/skills/save-feedback/SKILL.md
  - .github/workflows/contract-consistency.yml
  - README.md
  - plugins/perspective-writer/skills/import-rules/SKILL.md
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - tests/plugin-rules.test.sh
  - plugins/perspective-writer/skills/perspective-writer/references/natural-writing-checklist.md
-->
