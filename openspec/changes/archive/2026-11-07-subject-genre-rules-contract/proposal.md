## Summary

Replace the four independently hardcoded `.claude/rules/correspondence-*.md` path constructions with a single named resolution contract keyed on subject and genre, and relocate party-specific rules into a non-injected plugin namespace.

## Motivation

Two problems share one root, and both were traced to the same named resource: the `.claude/rules/correspondence-*.md` artifact contract.

**The data model is missing a dimension.** The draft-learner routing table keys on genre; the perspective-writer Phase 7 persistence keys on subject. Only the "Correspondence to a person" row carries both. Every other genre loses the subject axis entirely, so per-subject knowledge for a non-correspondence genre has nowhere to live. When one subject accumulates rules for two genres, the cross-genre shared layer (tone calibration, word preferences, fact fixpoints, red lines) gets written twice — not by authorial choice, but because the model offers no place to point at. Two copies drift, and a calibration applied to one copy leaves the other stale with no signal.

**Party-specific parameters are paying a session-wide context cost.** Contents of `.claude/rules/` are injected into every session regardless of task. Measured in one workspace: four subjects accumulated 15,000 characters of correspondence rules that are relevant only when writing to those subjects. Dot-prefixed namespace directories used elsewhere in the ecosystem are not injected — they are read on demand.

**The seam does not exist as a named thing.** Four skills each construct the path independently. Relocating the directory without naming the resolution contract would leave four independent hardcodings pointing at a new location instead of an old one.

## Proposed Solution

Introduce a resolution contract stated once and cited by every skill, mapping a subject and genre to an ordered list of files to read, with a defined legacy fallback order and a distinguishable not-found signal.

Party-specific rules move to a per-subject directory holding a mandatory cross-genre core file plus genre facets created on demand. Genre conventions not tied to a party get their own namespace directory. Rules that no skill reads — the ones that function by being injected — stay where they are.

The split criterion is **who reads it**, not when it applies. A rule consumed by this plugin's own workflow moves into the plugin namespace, because the skill will read it. A rule consumed by general session activity stays in the injected directory, because nothing else would ever read it. This criterion is decidable by inspection and its failure modes are asymmetric: moving a general-discipline rule into the namespace silently removes its only reader, while leaving a party-specific rule in the injected directory merely continues the existing waste.

The load gate binds refusal to **the lookup not having been performed**, not to the file being absent. Drafting refuses when no lookup ran. A lookup that ran and found nothing proceeds, but must state that the subject has no existing rules. This separates a skipped step from genuine first contact without needing a positive on-file marker.

Migration leaves a redirect line at each legacy path so a downstream consumer that checks the old location before handing over a path still succeeds, and a tracking issue asks that consumer to resolve the new location directly.

## Non-Goals

- Relaxing the trigger-surface exclusion for blog posts and technical documentation. That exclusion is a triggering decision independent of this architecture; revisiting it is deferred until a facet for those genres actually exists.
- Formalizing facet-over-core override precedence into machine-checkable syntax. There is no mechanical reader for these files, so a formal override grammar would require an interpreter that does not exist. Precedence is stated in prose in each facet header.
- Splitting fact fixpoints across facets. A fact does not change with genre; only whether it is useful in that genre changes. Fixpoints stay in core with inline genre-relevance annotation.
- Adding the mechanical consistency check that would detect resolution divergence. Tracked separately.
- Changing downstream consumer code in another repository. This change defines the contract and ships the compatibility shim; the consumer update is filed as a tracking issue.

## Alternatives Considered

**One file per subject with genre sections.** Rejected: reading rules for one genre would load every other genre's rules in the same file, which partially defeats the context-cost motivation that prompted the relocation.

**Flat compound filenames combining subject and genre.** Rejected: the core-to-facet relationship survives only as a naming convention, and a subject with a single genre still carries a compound name implying a split that does not exist.

**Splitting the criterion by when a rule applies rather than who reads it.** Rejected: that criterion classifies code-comment style rules as narrowly-applicable and therefore movable, but inspection shows no skill reads them. Moving them would silently remove their only reader.

**Relying on legacy fallback alone to preserve the downstream consumer.** Rejected: the consumer constructs the path and tests for existence before handing anything over, so it never reaches the fallback. A redirect placeholder at the legacy path is required for the handover to survive migration.

## Impact

- Affected specs: writing-rules-resolution, writing-rules-load-gate, writing-rules-migration
- Affected code:
  - New:
    - plugins/perspective-writer/references/rules-resolution.md
    - plugins/perspective-writer/scripts/migrate-rules.sh
  - Modified:
    - plugins/perspective-writer/skills/perspective-writer/SKILL.md
    - plugins/perspective-writer/skills/draft-learner/SKILL.md
    - plugins/perspective-writer/skills/role-calibrator/SKILL.md
    - plugins/perspective-writer/skills/save-feedback/SKILL.md
    - README.md
    - plugins/perspective-writer/.claude-plugin/plugin.json
    - plugins/perspective-writer/CHANGELOG.md
    - .claude-plugin/marketplace.json
  - Removed: (none)

**BREAKING**: the published artifact-path contract changes. The external consumer contract field that carries a rules path now refers to a directory-shaped location rather than a single file, and the canonical storage location moves out of the injected directory. Legacy paths remain readable and a redirect placeholder preserves existence checks, but consumers that reconstruct the canonical path themselves require updating.

## Capabilities

### New Capabilities

- `writing-rules-resolution`: the named mapping from a subject and genre to an ordered list of rule files, the on-disk layout it resolves against, the composition order of core and facet, and the split criterion determining which rules live in the plugin namespace versus the injected directory.
- `writing-rules-load-gate`: the obligation to perform a rules lookup before drafting, refusal when no lookup ran, and mandatory disclosure when a lookup ran and found nothing.
- `writing-rules-migration`: legacy path fallback, redirect placeholder generation, dual-location conflict resolution, and the one-time migration tool.

### Modified Capabilities

(none)
