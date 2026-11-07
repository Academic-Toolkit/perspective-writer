## Summary

Raise the published consumer contract's degradation-disclosure clauses from SHOULD to SHALL, and add the list of conditions that produce the `generic` outcome so a consumer can turn the disclosure into something actionable.

## Motivation

The contract defines a degradation signal and then leaves consuming it optional.

When a subject's writing rules cannot be resolved, calibration falls back to a conservative generic register and marks the returned status accordingly. That status header is the **only** signal distinguishing an uncalibrated reply from a calibrated one — the output itself does not differ in any inspectable way. A generic draft reads perfectly well; it simply does not sound like the writer.

The v3.0.0 contract revision added a consumer-facing sentence saying consumers SHOULD surface a generic return rather than treating it as success. That is the right content at the wrong strength. In normative language SHOULD means "there may be valid reasons not to"; applied to a failure whose output looks normal, it reads as permission to skip — and most implementations will. A contract that defines a signal without requiring anyone to consume it has defined nothing.

The contract also does not say what causes the generic outcome. A consumer that receives it therefore cannot tell the user anything more useful than "something was missing" — it cannot distinguish "this subject has no rules on file yet" from "the path handed over resolved to nothing", which call for different user responses.

## Proposed Solution

Two changes to the consumer-contract section of the repository README, which that section declares to be the contract's single source.

Raise the disclosure obligation to SHALL, and state the check as its own obligation rather than leaving it implied by the disclosure. A consumer that never reads the status header cannot disclose anything, so the two are separable requirements and the weaker one is currently unstated.

Add the conditions that produce the generic outcome. These already exist in the resolution contract but have never been collected in one place for the consumer's benefit: the rules-location field absent from the request; a supplied location that resolves to nothing; and no subject rules found at any of the sources the resolution order consults. The list SHALL point at the resolution contract's outcome-status definition rather than restating it, so the two cannot drift apart as the resolution order gains sources.

## Non-Goals

- Implementing the disclosure in any consumer. The obligation lives in this repository; the implementation lives in the consumer's, and is tracked there.
- Making the obligation mechanically enforceable. This contract is prose read by a model; there is no runtime that can reject a non-compliant consumer. The change alters the normative basis, not the observed behavior.
- Restating the resolution order or the outcome-status semantics in the consumer contract. The consumer section points at the resolution contract; duplicating the definitions would create a second copy that drifts.
- Revisiting the fallback behavior itself. Falling back to a conservative register rather than guessing intimacy remains correct and is out of scope.

## Alternatives Considered

**Leave the clause at SHOULD and rely on the downstream tracking request.** Rejected: the tracking request asks one consumer to do one thing. Without a SHALL in the contract, the next consumer starts from the same permissive baseline, and the request has no normative backing to cite.

**State the generic-producing conditions inline in the consumer section as a self-contained list.** Rejected: the resolution order already gained a source once in this release cycle and will gain more. A self-contained copy would silently fall behind. Pointing at the definition costs the reader one hop and cannot drift.

**Add a machine-readable field alongside the status header carrying a reason code.** Rejected as premature: no consumer currently reads the status header at all, so a richer payload solves a problem nobody has yet. Worth revisiting once at least one consumer consumes the existing field.

## Impact

- Affected specs: consumer-degradation-disclosure
- Affected code:
  - Modified:
    - README.md
    - plugins/perspective-writer/CHANGELOG.md
    - plugins/perspective-writer/.claude-plugin/plugin.json
    - .claude-plugin/marketplace.json
  - New: (none)
  - Removed: (none)

The change adds an obligation to existing consumers. No consumer breaks — a non-compliant one keeps working exactly as before, it is merely now out of compliance. Version treatment is therefore additive rather than breaking.

## Capabilities

### New Capabilities

- `consumer-degradation-disclosure`: the consumer's obligation to read the returned status header, to disclose a degraded outcome to its user, and the enumerated conditions under which that outcome occurs.

### Modified Capabilities

(none)
