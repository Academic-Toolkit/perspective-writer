## Context

The main writing skill is a single file holding both genre-independent discipline and correspondence-specific convention. Three sibling skills handle learning and calibration around it; a downstream plugin in another repository invokes the main skill programmatically by name.

The storage side of this problem was solved in an earlier change: per-subject writing rules gained a genre-independent core file plus on-demand genre facets, resolved through a named contract. The skill that consumes those rules did not change shape — it remained one letter-shaped skeleton, so a subject's non-correspondence facet has rules to store but no procedure to apply them with.

Two facts constrain the solution and were established by inspection rather than assumption.

The downstream consumer hardcodes both the invocation of the main skill and the presence probe for it. Its integration degrades gracefully when the skill is absent, so a rename does not raise an error — replies post uncalibrated and nothing says so.

Skills have no inheritance mechanism. A facet cannot extend a core at the language level. Every core-and-facet arrangement in this ecosystem, including the personal-persona skills this repository's owner maintains, links them with a prose banner and a reader who loads both.

## Goals / Non-Goals

**Goals:**

- Give a genre other than correspondence a place to put its conventions, so the skill's stated scope and its actual shape stop diverging.
- Keep completeness from depending on two independent semantic triggers.
- Preserve the downstream calibration entry unchanged in name and behavior.
- Make the published contract's references to skill sections survive reordering.
- Keep the anti-pattern checklist's genre-independent rows available to every genre.

**Non-Goals:**

- Renaming the main skill.
- Creating facets for genres with nothing to move.
- Relaxing the description's exclusion of blog posts and technical documentation.
- Giving the facet a trigger surface that competes with the core's.
- Proving mechanically that a facet was loaded. Nothing in this arrangement can.

## Decisions

**Decision 1 — the core is the entry point and loads the facet from its body, not by trigger.**

Skill triggering is semantic matching against a description. It is probabilistic. If both core and facet rely on their own triggers, completeness requires two independent matches to succeed, and the failure mode is the worst kind: a letter drafted without greeting conventions or pressure calibration reads fluently, and nothing distinguishes it from a complete one.

The core instead identifies the genre during its bootstrap phase and instructs loading the corresponding facet. That converts the second step from a trigger into a body instruction — text the reader encounters in sequence rather than a match that may or may not fire.

This is not a novel mechanism. The rules-resolution step already works this way: no skill triggers on "resolve the subject's rules"; the core's phase tells the reader to do it, citing a contract document. The same shape is being reused.

Alternative considered: trigger-competitive descriptions on both. Rejected for the reason above. Alternative considered: merge the facet's content back and accept the monolith. Rejected — that is the status quo the issue exists to change.

**Decision 2 — the main skill keeps its name; the facet is additive.**

Forced by the naming constraint. The consequence is that "core" is a role, not a suffix: the main skill *is* the core. Facets are named for their genre and sit beside it.

**Decision 3 — the facet carries increments only, with an inheritance banner.**

A self-contained facet would restate the core's rules, and the two copies would drift — the exact defect the storage-side change was made to remove. The facet declares in its header what it inherits and adds only what its genre needs.

Precedence follows the rule the storage contract already states for core and facet rule files: a facet may override general conventions, and may not override honesty boundaries. Reusing that wording keeps one precedence rule in the reader's head instead of two.

**Decision 4 — the anti-pattern checklist splits row by row.**

Roughly two-thirds of its rows are generated-text tells that hold for any genre: the dash habit, the promotional summary constructions, the parallel-list reflex, the sincerity-intensifier adverbs, the external-attribution deflection, the decorative-divider reflex. The remainder are bound to letters or to draft presentation: the formal-closing habit, the topic-sentence formula, the extra horizontal rules inside a letter body.

Moving the table wholesale in either direction is wrong. Left entirely in the core, it embeds correspondence rules where other genres will inherit them. Moved entirely to the facet, the core loses its general defense and every future facet must restate it.

**Decision 5 — the published contract refers to skill sections by name, not by phase number.**

The calibration contract enumerates which phases do not apply to its mode. Those enumerations use phase numbers, which this change and any future reordering will invalidate. Restating them by section name makes them stable. No consumer parses them — they are prose for a human implementer — so the change is safe.

**Decision 6 — one facet this time.**

Only correspondence has content to move. A facet for a genre with nothing in it would be shape without substance, and would have to be maintained.

## Implementation Contract

**Behavior.** When the core skill is invoked for a writing task, its bootstrap phase determines the genre of the document being written, states that determination, and loads the matching genre facet if one exists. When no facet exists for the determined genre, the core says so explicitly and proceeds with genre-independent discipline alone rather than silently applying correspondence conventions.

**Skill surface.** The main skill retains its current name and remains the entry point, including for the programmatic calibration mode. A new facet skill exists for correspondence. The facet's description identifies it as a genre facet loaded by the core, and does not present itself as a general answer to "write me a letter"; it remains directly invocable by name.

**Section allocation.** The core retains: the referent discipline, the fabrication traps, the compose-versus-revise mode distinction, bootstrap, rules resolution and its load gate, understanding the writer, simulation, the genre-independent anti-pattern rows, presenting and iterating, learning from edits, persistence, and the calibration entry. The facet receives: understanding the recipient, the correspondence-specific parts of drafting — opening priority, address conventions, cultural calibration, pressure calibration, recipient ordering — the draft output format, and the correspondence-specific anti-pattern rows.

**Facet contract.** A facet states in its header that it inherits the core and that the core must be loaded. It adds; it does not restate. It may override the core's general conventions and may not override the core's honesty boundaries.

**Failure modes.** A genre with no facet is disclosed, not silently defaulted to correspondence. A facet loaded without its core is out of contract; the facet's header says so, and nothing enforces it. The core's instruction to load a facet is text, not a mechanism — a reader that skips it produces a genre-independent draft, which is a real residual risk stated in the Residue section rather than claimed as solved.

**Acceptance criteria.** This repository has no test framework, so acceptance is inspection assertions a reviewer or later mechanical check can evaluate:

1. The core contains no correspondence-specific convention: searching it for greeting-convention, pressure-calibration, and recipient-ordering content returns nothing.
2. The facet contains no restatement of the core's referent discipline or fabrication traps.
3. The facet's header states inheritance and the precedence rule, using the same wording as the rules contract's composition section.
4. The core's bootstrap phase instructs genre determination and facet loading, and states what to do when no facet matches.
5. Every row of the original anti-pattern checklist appears in exactly one of the two files — none dropped, none duplicated.
6. The published calibration contract's phase mapping names sections rather than numbers, and every named section exists in the core.
7. The main skill's name is unchanged, and the downstream invocation string still resolves.

**Scope boundaries.**

In scope: the core skill's content and description; the new correspondence facet; the rules-resolution reference where its wording must align with the facet concept; the README skills table and the calibration contract's phase mapping; changelog and both manifests.

Out of scope: the three sibling skills; any file in a user workspace; the downstream consumer's source; facets for other genres; the trigger-surface exclusion; the mechanical consistency check.

## Risks / Trade-offs

**The reader loads the core and skips the facet instruction** → a letter drafted with genre-independent discipline only: fluent, and missing every convention that makes it sound like correspondence from this writer. Mitigation: partial. The instruction sits in the bootstrap phase, before any drafting, alongside the rules-resolution step that already works this way. But it is an instruction, not a gate, and this residual is stated rather than solved.

**A row of the anti-pattern checklist is dropped during the split** → a generated-text tell silently stops being checked. Mitigation: acceptance criterion 5 requires every original row to appear in exactly one file, which is countable.

**The facet is loaded without the core** → the reader gets conventions with no referent discipline behind them. Mitigation: the facet's header states the dependency. Nothing enforces it.

**The calibration contract's section names drift from the core's actual headings** → the contract describes a mapping that no longer resolves. Mitigation: acceptance criterion 6 checks that every named section exists.

**Trade-off accepted: completeness is now compositional.** Before this change, one trigger guaranteed everything a letter needed was present. After it, completeness requires the core plus one loaded facet. Decision 1 makes the second step deterministic text rather than a second trigger, which is the strongest available mitigation — but the guarantee is weaker than it was, and that is the price of giving other genres a place to exist.

## Migration Plan

1. Ship the core, the facet, the contract wording alignment, and the README changes together. There is no user-side state to migrate — the skills are the artifact.
2. The downstream consumer needs no change: the invocation name, the presence probe, and the calibration mode's behavior are all unchanged. Only the contract's phase-mapping prose is restated, and no consumer parses it.
3. Future genres add a facet and a row in the core's genre table. No core restructuring is required.

Rollback: concatenating the facet's sections back into the core and deleting the facet restores the prior shape. Nothing outside the two files depends on the split.

## Open Questions

- Whether the core should ask the user to confirm the determined genre when the determination is uncertain, rather than stating it and proceeding. Asking costs a turn on every ambiguous case; stating and proceeding risks loading the wrong facet. Deferred: no observed case yet distinguishes them, and the core states its determination either way, so a wrong one is visible.
- Whether facets should be able to depend on other facets — a formal-letter facet extending a correspondence one. Deferred: with one facet the question is unanswerable from evidence, and adding the mechanism now would be a guess.
- Whether the residual risk in Decision 1 is worth a stronger measure — for instance the core refusing to draft correspondence when the facet is not loaded. That is the same shape as the rules load gate, but the core cannot detect its own reading state the way it can detect a lookup outcome. Left open because the mechanism is not obvious, not because the risk is small.
