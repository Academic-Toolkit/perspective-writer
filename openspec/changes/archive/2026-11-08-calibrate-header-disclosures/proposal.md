## Summary

Return the additional disclosures to calibrate's external consumers as a `disclosures=` attribute on the existing status header, and oblige consumers to ignore header attributes they do not recognise and to tell their user when the attribute is present.

## Motivation

Calibrate mode resolves and expands the subject's rules like any other mode, so the four additional disclosures (`include-unresolved`, `include-nested`, `import-stale`, `redirect-unresolved`) are produced. They were then dropped: the Calibrate-draft entry said they were not reported, and the return shape left no place for them. A workspace rule file that includes rules from a plugin that is not installed therefore returned `status=person` or `status=generic` exactly as if every rule had loaded. A draft written without those rules reads normally, so the consumer had no way to tell.

## Proposed Solution

- The skill adds ` disclosures=<kinds>` inside the line-1 header when the lookup produced any additional disclosure: each kind once, comma-separated without spaces, in the order of the resolution contract's table. With none, the header is unchanged.
- Kinds only, never targets. The header is invisible on GitHub but stays in the posted comment's source, and a target can be a local path.
- The header token stays `v1`; the attribute is an addition. The consumer contract gains a rule that consumers SHALL ignore header attributes they do not recognise.
- Promise 5 gains the obligation that a consumer SHALL tell its user when `disclosures=` is present, naming the kinds. The status is unchanged by a disclosure.
- A consumer that reads the attribute pins the version that writes it, so that an absent attribute means "nothing to disclose".
- The consistency check asserts that the README and the skill both specify the attribute, that the README keeps the ignore-unknown-attributes rule, and that the README's kinds equal the contract's, in order.

## Non-Goals

- Changing the three outcome statuses. A disclosure never changes the status, and consumers already depend on the closed set.
- Proving that the model writes the attribute. Like the frozen anchors, it is a prose-model obligation; the contract says so.
- Implementing the consumer side in any consumer. That is filed in the consumer's repository after this is released.

## Alternatives Considered

**A fixed-format disclosure line before the draft.** Rejected: promise 7 says everything after line 1 is draft, and the existing consumer posts it as such.

**A new status such as `partial`.** Rejected: it contradicts the rule that an additional disclosure never changes the status, and breaks consumers that branch on the two status values.

**Targets in the header.** Rejected: the header stays in the comment's source on a public repository, and a target can be a local path.

**Header version `v2`.** Rejected: every consumer would have to change before it could read the header at all, for an addition that old consumers can safely ignore.

## Impact

- Affected specs: consumer-degradation-disclosure
- Affected files: `README.md`, `plugins/perspective-writer/skills/perspective-writer/SKILL.md`, `plugins/perspective-writer/references/rules-resolution.md`, `plugins/perspective-writer/scripts/check-contract-consistency.sh`, `tests/plugin-rules.test.sh`, the changelog and both version fields
