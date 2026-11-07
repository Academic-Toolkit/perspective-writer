# cross-model-polish Specification

## Purpose

The cross-model polish pass that runs before a draft is presented: the fallback ladder it degrades through, the anchored spans it must preserve, how its convergence is observed, and where its governance is resolved.

## Requirements

### Requirement: Polish pass runs before the draft is presented

The skill SHALL run a cross-model polish pass after the anti-pattern checklist and before the draft is presented to the writer. The first draft the writer sees SHALL be the polished version whenever the polish channel is available.

#### Scenario: Compose reaches the presentation step

- **WHEN** a Compose run finishes the anti-pattern checklist and the polish channel is available
- **THEN** the polish pass runs before anything is shown to the writer
- **AND** the text presented is the polished result, not the pre-polish draft

#### Scenario: Revise reaches the presentation step

- **WHEN** a Revise run finishes the anti-pattern checklist and the polish channel is available
- **THEN** the polish pass runs on the revised draft before presentation


<!-- @trace
source: cross-model-polish-pass
updated: 2026-08-13
code:
  - plugins/perspective-writer/skills/perspective-writer-email/SKILL.md
  - perspective-writer.code-workspace
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/CHANGELOG.md
  - README.md
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - .spectra.yaml
-->

---
### Requirement: Polish channel degrades through a fixed ladder and never blocks delivery

The skill SHALL attempt the polish channel in a fixed order and SHALL fall through to the next tier on failure. Delivery of a draft SHALL NOT be blocked by any tier being unavailable. The skill SHALL NOT ask the writer whether an external account exists; tier selection SHALL be driven by observed failure of the attempt.

Every tier SHALL have an exit path that ends in a delivered draft. Refusing to deliver a draft because a dependency is absent is a violation of this requirement.

#### Scenario: External model is reachable and authorized

- **WHEN** the external model dependency is present and its authorization is valid
- **THEN** the external model performs the polish
- **AND** no account question is put to the writer at any point

#### Scenario: Authorization has expired

- **WHEN** the external model attempt returns an authorization failure
- **THEN** the skill falls through to the independent-agent tier without retrying the external model
- **AND** the writer is told which tier was used

#### Scenario: No polish tier is available

- **WHEN** neither the external model nor the independent agent can run
- **THEN** the skill delivers the unpolished draft
- **AND** the delivered text is byte-identical to what the same run produced before this capability existed
- **AND** the output carries one line stating that the polish pass did not run

##### Example: tier selection by observed condition

| Observed condition | Tier used | Draft delivered |
| ------------------ | --------- | --------------- |
| dependency present, authorization valid | external model | polished |
| authorization failure returned | independent agent | polished |
| dependency absent | independent agent | polished |
| external call exceeds its time limit | independent agent | polished |
| independent agent also unavailable | none | unpolished, with notice |


<!-- @trace
source: cross-model-polish-pass
updated: 2026-08-13
code:
  - plugins/perspective-writer/skills/perspective-writer-email/SKILL.md
  - perspective-writer.code-workspace
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/CHANGELOG.md
  - README.md
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - .spectra.yaml
-->

---
### Requirement: The fallback polisher is an independent agent

When the external model tier is unavailable, the polish SHALL be performed by an agent independent of the one that produced the draft. A second pass by the drafting agent within the same session SHALL NOT satisfy this requirement.

#### Scenario: Fallback tier is selected

- **WHEN** the polish falls through to the fallback tier
- **THEN** the polish is performed by an independent agent that did not produce the draft


<!-- @trace
source: cross-model-polish-pass
updated: 2026-08-13
code:
  - plugins/perspective-writer/skills/perspective-writer-email/SKILL.md
  - perspective-writer.code-workspace
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/CHANGELOG.md
  - README.md
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - .spectra.yaml
-->

---
### Requirement: Anchored spans are preserved and verified after return

The skill SHALL send, together with the draft, a list of anchored spans as literal strings. Anchored spans SHALL cover the factual content established while building the writer's model: time references, amounts, named handlers, process details, and verbatim quoted material.

After the polished text returns, the skill SHALL verify every listed span. A span passes verification when it is still present and its occurrence count is unchanged. On any verification failure the skill SHALL discard the polished text and deliver the pre-polish draft, and SHALL name the span that failed.

Style guidance about rhythm, filler, and sentence length SHALL be additional to this obligation and SHALL NOT replace it.

#### Scenario: Polished text preserves every anchored span

- **WHEN** the polished text returns and every anchored span is present with an unchanged occurrence count
- **THEN** the polished text is accepted and carried forward

#### Scenario: Polished text alters an anchored span

- **WHEN** the polished text returns and one anchored span is altered, removed, or duplicated
- **THEN** the pre-polish draft is delivered instead of the polished text
- **AND** the output names the span that failed verification

##### Example: verification outcomes for one anchored span

| Anchored span | Occurrences before | Occurrences after | Outcome |
| ------------- | ------------------ | ----------------- | ------- |
| 5/8 在 storyline 會議時 | 1 | 1 | pass |
| 5/8 在 storyline 會議時 | 1 | 0 | fail, rollback |
| 5/8 在 storyline 會議時 | 1 | 2 | fail, rollback |
| 5/8 在 storyline 會議時 (reworded to 前幾天) | 1 | 0 | fail, rollback |


<!-- @trace
source: cross-model-polish-pass
updated: 2026-08-13
code:
  - plugins/perspective-writer/skills/perspective-writer-email/SKILL.md
  - perspective-writer.code-workspace
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/CHANGELOG.md
  - README.md
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - .spectra.yaml
-->

---
### Requirement: Convergence is observable and is not bounded by a round limit

The polish exchange SHALL continue until it converges. Convergence holds when all three conditions are met: the returned text differs from the previous round only in wording that does not change meaning, anchored-span verification passes, and no factual claim absent from the previous round has been introduced.

The skill SHALL NOT impose a fixed maximum number of rounds. The skill SHALL emit, for every round, the round number and a summary of what changed, so that a non-converging exchange is visible rather than accumulating cost silently.

#### Scenario: Exchange converges

- **WHEN** a returned round differs from the previous round only in meaning-preserving wording, passes span verification, and introduces no new factual claim
- **THEN** the exchange stops and the result is carried forward

#### Scenario: Exchange has not converged

- **WHEN** a returned round still changes meaning or introduces a factual claim absent from the previous round
- **THEN** another round runs
- **AND** the round number and a summary of the differences are emitted before that round begins


<!-- @trace
source: cross-model-polish-pass
updated: 2026-08-13
code:
  - plugins/perspective-writer/skills/perspective-writer-email/SKILL.md
  - perspective-writer.code-workspace
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/CHANGELOG.md
  - README.md
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - .spectra.yaml
-->

---
### Requirement: Polish does not run in calibrate mode

The polish pass SHALL NOT run when the skill is invoked through the programmatic calibration entry. The published consumer contract SHALL list this section among the core sections that do not apply in that mode, so that the section mapping stays a complete enumeration.

#### Scenario: Skill is invoked through the calibration entry

- **WHEN** the skill is invoked with a calibration request block
- **THEN** the polish pass does not run
- **AND** the returned content is the status header followed by the calibrated draft and nothing else
- **AND** the observable behavior is unchanged from before this capability existed

#### Scenario: A contract reader checks whether the polish pass applies

- **WHEN** someone implementing a consumer reads the published contract's section mapping
- **THEN** the polish section appears in the enumeration
- **AND** its classification is stated rather than left to inference


<!-- @trace
source: cross-model-polish-pass
updated: 2026-08-13
code:
  - plugins/perspective-writer/skills/perspective-writer-email/SKILL.md
  - perspective-writer.code-workspace
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/CHANGELOG.md
  - README.md
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - .spectra.yaml
-->

---
### Requirement: Polish governance is resolved at run time by reference

The skill SHALL resolve the external polish channel's governance values at run time from the upstream governance contract, and SHALL cite the upstream canonical resolution document rather than embedding a copy of the resolution logic in this repository. No model identifier SHALL appear as a literal anywhere in this repository.

The skill SHALL gate the external tier on a declared minimum upstream version. When the dependency is absent or below that version, the skill SHALL fall through to the fallback tier and SHALL emit a one-step installation hint.

#### Scenario: Governance values are needed for a polish call

- **WHEN** the external tier is about to run
- **THEN** the governance values are read at run time from the upstream contract
- **AND** no model identifier is read from any file inside this repository

#### Scenario: Upstream dependency is below the declared minimum version

- **WHEN** the upstream dependency is present but below the declared minimum version
- **THEN** the skill falls through to the fallback tier
- **AND** the output carries a one-step installation hint

#### Scenario: Upstream changes how the channel is invoked

- **WHEN** the upstream canonical resolution document changes
- **THEN** this repository requires no edit to its resolution logic, because it cites that document rather than copying it


<!-- @trace
source: cross-model-polish-pass
updated: 2026-08-13
code:
  - plugins/perspective-writer/skills/perspective-writer-email/SKILL.md
  - perspective-writer.code-workspace
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/CHANGELOG.md
  - README.md
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - .spectra.yaml
-->

---
### Requirement: Absence of the polish dependency is surfaced before drafting begins

The skill SHALL check for the polish dependency when a run starts and, when it is absent, SHALL emit one non-blocking line stating that the dependency can be installed. The notice SHALL NOT block the run, SHALL NOT pose a question, and SHALL NOT appear when the dependency is present.

The notice belongs at the start rather than at the point of degradation because installing a plugin generally requires a reload: a notice emitted at the polish step arrives after the draft is already written, too late to affect that run.

#### Scenario: Dependency is absent when a run starts

- **WHEN** a run starts and the polish dependency is absent
- **THEN** one line stating that it can be installed is emitted before drafting begins
- **AND** the run continues without waiting for an answer

#### Scenario: Dependency is present when a run starts

- **WHEN** a run starts and the polish dependency is present
- **THEN** no notice is emitted

#### Scenario: Dependency is absent and the run reaches the polish step

- **WHEN** the dependency was reported absent at the start and the run reaches the polish step
- **THEN** the ladder falls through to the fallback tier as specified
- **AND** the draft is still delivered

<!-- @trace
source: cross-model-polish-pass
updated: 2026-08-13
code:
  - plugins/perspective-writer/skills/perspective-writer-email/SKILL.md
  - perspective-writer.code-workspace
  - plugins/perspective-writer/.claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - plugins/perspective-writer/CHANGELOG.md
  - README.md
  - plugins/perspective-writer/skills/perspective-writer/SKILL.md
  - .spectra.yaml
-->