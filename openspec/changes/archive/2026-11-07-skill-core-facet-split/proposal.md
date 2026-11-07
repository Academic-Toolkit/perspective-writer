## Summary

Split the letter-specific parts of the main writing skill into a genre facet, keeping the main skill as the genre-independent core and as the entry point that loads the facet from its own body rather than relying on a second skill trigger.

## Motivation

The skill's stated scope is wider than its shape. Its description claims letters, emails, correspondence, autobiographies, and formal documents, but the phase skeleton is letter-shaped throughout: understanding the recipient, greeting conventions, social-pressure calibration, recipient ordering, and the draft wrapper are all correspondence concerns sitting in the same undifferentiated body as the genre-independent parts — the referent discipline, the fabrication traps, understanding the writer, simulating, and iterating.

The consequence is not untidiness. A genre other than correspondence has nowhere to put its own conventions, so it either inherits letter rules that do not apply or gets no structure at all. This is the same missing dimension that the storage side already fixed: rules gained a subject-independent core plus on-demand genre facets, while the skill that consumes them stayed monolithic.

Two constraints found during diagnosis determine the shape this split can take.

The main skill cannot be renamed. A downstream consumer invokes it by name and probes for it by name; renaming it to a core suffix would break that entry, and the integration degrades gracefully, so the symptom would be replies posting uncalibrated with no error.

There is no skill inheritance mechanism. A facet cannot extend a core in any language-level sense. Linking is prose: the facet declares what it inherits and the reader loads both.

## Proposed Solution

Keep the main skill in place as the core, holding everything that does not vary with genre, and move the correspondence-specific sections into a new email facet.

The load path does not rely on the facet's own trigger. Skill triggering is semantic matching — non-deterministic — so making completeness depend on two independent triggers replaces one probabilistic step with two. Instead the core's bootstrap phase identifies the genre and instructs loading the corresponding facet, and says so explicitly when no facet exists for the genre at hand. That converts the second step from a trigger into a body instruction the reader will encounter, which is the same shape the rules-resolution step already uses successfully.

The facet carries increments only. It states its inheritance in a header and adds what its genre needs; it does not restate the core's rules. Where the two could conflict, the facet may override general conventions but not the honesty boundaries — the same precedence the rules contract already defines for core and facet rule files.

The anti-pattern checklist is split row by row rather than moved as a block. Roughly two-thirds of its rows are genre-independent writing tells; the remainder are bound to letters or to draft presentation. Moving the whole table either strips the core of its general checks or leaves correspondence rules embedded in it.

The published calibration contract's phase mapping is restated by section name instead of by phase number, so it survives this and any future reordering.

## Non-Goals

- Renaming the main skill. The downstream consumer hardcodes both the invocation and the presence probe; a rename breaks the entry silently.
- Creating facets for genres with no content to move. Only correspondence has material in this repository today; a proposal or autobiography facet would be an empty shape.
- Relaxing the description's exclusion of blog posts and technical documentation. That is a triggering decision, independent of this architecture, and still has no facet behind it.
- Giving the facet a competing trigger surface. It is loaded by the core, and remains directly invocable by name for the rare case someone wants only it.
- Making facet loading mechanically verifiable. Nothing here can prove the reader followed the instruction; the change moves one step from probabilistic to deterministic-text, which is an improvement, not a guarantee.

## Alternatives Considered

**Rename the main skill to a core suffix and add facets beside it.** Rejected on the naming constraint: the downstream invocation and probe both use the current name, and the integration's graceful degrade turns the break into a silent one.

**Give both core and facet trigger-competitive descriptions.** Rejected: completeness would then depend on two independent semantic matches, and the failure — loading only the core and drafting a letter without greeting conventions or pressure calibration — produces fluent output with no signal.

**Have the facet restate the core's rules so it is self-contained.** Rejected: that reintroduces the duplication this whole line of work exists to remove, and the two copies would drift exactly as the per-subject rule files did.

**Move the anti-pattern checklist wholesale into the facet.** Rejected: the majority of its rows are genre-independent, and the core would lose its general defense against generated-text tells.

## Impact

- Affected specs: skill-genre-facets
- Affected code:
  - New:
    - plugins/perspective-writer/skills/perspective-writer-email/SKILL.md
  - Modified:
    - plugins/perspective-writer/skills/perspective-writer/SKILL.md
    - plugins/perspective-writer/references/rules-resolution.md
    - README.md
    - plugins/perspective-writer/CHANGELOG.md
    - plugins/perspective-writer/.claude-plugin/plugin.json
    - .claude-plugin/marketplace.json
  - Removed: (none)

**BREAKING**: the skill surface gains a member and the main skill's description narrows to its core scope. The published calibration entry keeps its name and behavior, but the contract's phase mapping is restated by section name, and consumers reading that mapping by phase number must re-read it.

## Capabilities

### New Capabilities

- `skill-genre-facets`: the core-and-facet skill architecture — which sections belong to the genre-independent core, how the core loads a genre facet from its own body rather than by trigger, what a facet may and may not restate or override, and how the published calibration contract refers to skill sections so it survives reordering.

### Modified Capabilities

(none)
