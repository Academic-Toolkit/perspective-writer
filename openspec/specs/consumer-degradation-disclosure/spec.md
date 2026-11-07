# consumer-degradation-disclosure Specification

## Purpose

How an external consumer of the writing skill reads the resolution status and discloses a degraded outcome to its user.

## Requirements

### Requirement: Consumer reads the status header

A consumer of the programmatic calibration entry SHALL read the status header returned on the first line of the response. The published contract SHALL state this as an obligation in its own right, separate from the disclosure obligation, because a consumer that never reads the header cannot satisfy the disclosure obligation and would otherwise have no stated requirement it visibly fails.

#### Scenario: Consumer receives a calibrated response

- **WHEN** a consumer receives a response from the calibration entry
- **THEN** it reads the status header before using the returned draft

#### Scenario: Contract is read by a new consumer author

- **WHEN** someone implementing a new consumer reads the published contract
- **THEN** the contract states reading the status header as a requirement, not as an implication of another requirement


<!-- @trace
source: consumer-generic-disclosure-obligation
updated: 2026-11-07
code:
  - .github/workflows/contract-consistency.yml
  - plugins/perspective-writer/skills/perspective-writer-email/SKILL.md
  - .spectra.yaml
  - plugins/perspective-writer/scripts/plugin-rules.sh
  - plugins/perspective-writer/skills/draft-learner/SKILL.md
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/skills/save-feedback/SKILL.md
  - plugins/perspective-writer/agents/rules-auditor.md
  - README.md
  - plugins/perspective-writer/skills/perspective-writer/references/zh-Hant-syntax-checkpoints.md
  - plugins/perspective-writer/CHANGELOG.md
  - perspective-writer.code-workspace
  - plugins/perspective-writer/skills/perspective-writer/references/natural-writing-checklist.md
  - plugins/perspective-writer/skills/import-rules/SKILL.md
  - tests/plugin-rules.test.sh
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - plugins/perspective-writer/references/rules-resolution.md
  - plugins/perspective-writer/agents/native-syntax-reader.md
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - plugins/perspective-writer/scripts/check-contract-consistency.sh
-->

---
### Requirement: Consumer discloses a degraded outcome

When the returned status indicates that subject-specific rules were not applied, the consumer SHALL make that fact visible to its user. The contract SHALL express this with SHALL rather than SHOULD.

#### Scenario: Status indicates a generic register was used

- **WHEN** the returned status indicates the generic outcome
- **THEN** the consumer tells its user that subject-specific rules were not applied
- **AND** does not present the result as a fully calibrated one

#### Scenario: Draft reads well despite the generic outcome

- **WHEN** a generic-outcome draft is fluent and free of obvious defects
- **THEN** the disclosure is still made
- **AND** apparent quality is not accepted as evidence that calibration occurred

##### Example: Obligation strength before and after

| Clause | Before | After |
| ------ | ------ | ----- |
| read the status header | not stated | SHALL |
| disclose a degraded outcome | SHOULD | SHALL |


<!-- @trace
source: consumer-generic-disclosure-obligation
updated: 2026-11-07
code:
  - .github/workflows/contract-consistency.yml
  - plugins/perspective-writer/skills/perspective-writer-email/SKILL.md
  - .spectra.yaml
  - plugins/perspective-writer/scripts/plugin-rules.sh
  - plugins/perspective-writer/skills/draft-learner/SKILL.md
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/skills/save-feedback/SKILL.md
  - plugins/perspective-writer/agents/rules-auditor.md
  - README.md
  - plugins/perspective-writer/skills/perspective-writer/references/zh-Hant-syntax-checkpoints.md
  - plugins/perspective-writer/CHANGELOG.md
  - perspective-writer.code-workspace
  - plugins/perspective-writer/skills/perspective-writer/references/natural-writing-checklist.md
  - plugins/perspective-writer/skills/import-rules/SKILL.md
  - tests/plugin-rules.test.sh
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - plugins/perspective-writer/references/rules-resolution.md
  - plugins/perspective-writer/agents/native-syntax-reader.md
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - plugins/perspective-writer/scripts/check-contract-consistency.sh
-->

---
### Requirement: Contract enumerates the conditions producing a degraded outcome

The published consumer contract SHALL enumerate the conditions under which the degraded outcome occurs, so a consumer can turn its disclosure into an actionable message rather than a generic warning. The enumeration SHALL reference the resolution contract's outcome-status definition as the authority rather than restating the semantics, so the two cannot drift as the resolution order gains sources.

#### Scenario: Consumer author needs to write an actionable message

- **WHEN** a consumer author needs to tell the user why calibration degraded
- **THEN** the contract lists the conditions that produce the degraded outcome
- **AND** each condition is distinguishable enough to suggest a different user response

#### Scenario: Resolution order gains a new source

- **WHEN** the resolution order is extended with an additional rules source
- **THEN** the consumer contract's enumeration does not require a parallel edit to stay correct
- **AND** the enumeration continues to point at the resolution contract's definition

##### Example: Conditions producing the degraded outcome

| Condition | What the consumer can suggest |
| --------- | ----------------------------- |
| rules-location field absent from the request | the caller did not supply a location |
| supplied location resolves to nothing | the location may be stale or mistyped |
| no subject rules found at any source the resolution order consults | this subject has no rules on file yet |

<!-- @trace
source: consumer-generic-disclosure-obligation
updated: 2026-11-07
code:
  - .github/workflows/contract-consistency.yml
  - plugins/perspective-writer/skills/perspective-writer-email/SKILL.md
  - .spectra.yaml
  - plugins/perspective-writer/scripts/plugin-rules.sh
  - plugins/perspective-writer/skills/draft-learner/SKILL.md
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/skills/save-feedback/SKILL.md
  - plugins/perspective-writer/agents/rules-auditor.md
  - README.md
  - plugins/perspective-writer/skills/perspective-writer/references/zh-Hant-syntax-checkpoints.md
  - plugins/perspective-writer/CHANGELOG.md
  - perspective-writer.code-workspace
  - plugins/perspective-writer/skills/perspective-writer/references/natural-writing-checklist.md
  - plugins/perspective-writer/skills/import-rules/SKILL.md
  - tests/plugin-rules.test.sh
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - plugins/perspective-writer/references/rules-resolution.md
  - plugins/perspective-writer/agents/native-syntax-reader.md
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - plugins/perspective-writer/scripts/check-contract-consistency.sh
-->

---
### Requirement: Calibrate header names the additional disclosures

In calibrate mode, when resolving the subject's rules produced at least one additional disclosure, the status header SHALL carry ` disclosures=<kinds>` before ` -->`, listing each kind that occurred once, comma-separated without spaces, in the order of the resolution contract's *Additional disclosures* table. The attribute SHALL name kinds only and never a disclosure's target. With no disclosure the attribute SHALL be absent and the header SHALL be unchanged. The header token SHALL remain `v1`, and the status SHALL be the one resolution produced.

#### Scenario: An include names a plugin that is not installed

- **WHEN** the subject's core file is found and a genre file it uses includes a plugin that is not installed
- **THEN** the header is `<!-- pw:calibrate v1 status=person disclosures=include-unresolved -->`
- **AND** the header does not contain the include's target

#### Scenario: Two kinds occur

- **WHEN** an imported copy is stale and an include is unresolved
- **THEN** the attribute reads `disclosures=include-unresolved,import-stale`

#### Scenario: No disclosure

- **WHEN** every include and import resolves and no redirect is unresolved
- **THEN** the header is `<!-- pw:calibrate v1 status=person -->` exactly


<!-- @trace
source: calibrate-header-disclosures
updated: 2026-11-08
code:
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - plugins/perspective-writer/scripts/check-contract-consistency.sh
  - README.md
  - plugins/perspective-writer/CHANGELOG.md
  - tests/plugin-rules.test.sh
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/references/rules-resolution.md
-->

---
### Requirement: Consumer ignores unrecognised header attributes

The published consumer contract SHALL state that consumers SHALL ignore header attributes they do not recognise.

#### Scenario: A consumer written before an attribute existed

- **WHEN** a consumer that reads only `status=` receives a header that also carries `disclosures=`
- **THEN** it reads the status as before and its handling of the draft is unaffected


<!-- @trace
source: calibrate-header-disclosures
updated: 2026-11-08
code:
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - plugins/perspective-writer/scripts/check-contract-consistency.sh
  - README.md
  - plugins/perspective-writer/CHANGELOG.md
  - tests/plugin-rules.test.sh
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/references/rules-resolution.md
-->

---
### Requirement: Consumer discloses rules that were not applied as written

When the header carries `disclosures=`, the consumer SHALL tell its user that some of the subject's rules were not applied as written, naming the kinds and saying that running the skill directly on the same subject shows which files, whatever the status.

#### Scenario: Status person with an unresolved include

- **WHEN** the header is `<!-- pw:calibrate v1 status=person disclosures=include-unresolved -->`
- **THEN** the consumer tells its user that rules a rule file refers to were not loaded
- **AND** does not present the reply as calibrated with all of the subject's rules


<!-- @trace
source: calibrate-header-disclosures
updated: 2026-11-08
code:
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - plugins/perspective-writer/scripts/check-contract-consistency.sh
  - README.md
  - plugins/perspective-writer/CHANGELOG.md
  - tests/plugin-rules.test.sh
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/references/rules-resolution.md
-->

---
### Requirement: Contract and skill agree on the disclosure kinds

The contract consistency check SHALL fail when the README consumer contract or the skill's Calibrate-draft entry does not specify the `disclosures=` attribute, when the README no longer states the ignore-unknown-attributes rule, or when the kinds the README lists differ from the resolution contract's table in membership or order.

#### Scenario: The contract gains a kind

- **WHEN** a fifth row is added to the resolution contract's *Additional disclosures* table and the README is not updated
- **THEN** the consistency check exits 1 and names the README's disclosure kinds

<!-- @trace
source: calibrate-header-disclosures
updated: 2026-11-08
code:
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - plugins/perspective-writer/scripts/check-contract-consistency.sh
  - README.md
  - plugins/perspective-writer/CHANGELOG.md
  - tests/plugin-rules.test.sh
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/references/rules-resolution.md
-->