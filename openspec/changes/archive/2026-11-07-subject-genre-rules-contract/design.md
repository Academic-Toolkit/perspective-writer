## Context

This plugin persists writing rules learned during drafting sessions so a later session can reproduce a writer's voice toward a given party. Four skills participate: the main writer skill persists and reads rules, a diff-learner skill writes rules extracted from user edits, a role-calibrator skill rewrites rules when the writer's expertise position changes, and a feedback-capture skill writes rules extracted from conversation.

All four construct the storage path independently. The README documents that path as an external contract, and one downstream plugin in another repository reconstructs the same path shape before handing it to this plugin's programmatic calibration entry.

Two properties of the current arrangement drive this change.

The routing is keyed inconsistently. The diff-learner routes by genre across four cases; the writer skill persists by subject. Only the correspondence case carries both keys. Every other genre drops the subject, so per-subject knowledge for a non-correspondence genre has no address. Observed consequence: one workspace holds two rule files for the same subject — one for correspondence, one for a proposal-and-slides genre — where the second is roughly twice the size of the first and barely overlaps it, yet both restate the same subject-level tone calibration, word preferences, and fact fixpoints. Those restatements drift independently.

The storage directory is injected into every session. Contents of the project rules directory reach the model regardless of task. Measured in one workspace, four subjects' correspondence rules totalled about fifteen thousand characters carried by every session, most of which never draft anything. Dot-prefixed namespace directories used by sibling plugins in the same ecosystem are not injected; they are read on demand.

Constraint: this repository contains only markdown skill definitions and JSON manifests. There is no compiled code, no test framework, and no runtime that could enforce a contract mechanically. Any contract established here is honored by the skills citing it and is checkable only by inspection.

## Goals / Non-Goals

**Goals:**

- Establish one named resolution contract, stated in a single document, that maps a subject and a genre to an ordered list of rule files, and have every participating skill cite it rather than construct paths inline.
- Give per-subject, per-genre knowledge an address, so the cross-genre shared layer for a subject has exactly one home instead of being restated per genre.
- Move rules that this plugin reads out of the injected directory, and leave rules that only injection can deliver where they are.
- Make a skipped rules lookup a hard failure while leaving genuine first contact a normal, disclosed path.
- Preserve the downstream consumer's existence check across migration without requiring that consumer to ship first.

**Non-Goals:**

- Relaxing the trigger-surface exclusion for blog posts and technical documentation. That is a triggering decision, independent of storage architecture, deferred until a facet for those genres exists.
- Machine-checkable override precedence between facet and core. No mechanical reader exists; a formal grammar would need an interpreter this repository does not have and does not warrant.
- Splitting fact fixpoints across facets. A fact does not change with genre.
- Shipping the mechanical consistency check that would detect resolution divergence between skills. Tracked separately.
- Editing the downstream consumer's source, which lives in another repository. This change ships the compatibility shim and files a tracking request.
- Migrating any existing workspace's rule files as part of this change. The migration tool is shipped; running it is the workspace owner's decision.

## Decisions

**Decision 1 — the deliverable is a resolution contract, not a directory rename.**

The architectural seam here is the question "given a subject and a genre, which files do I read, in what order, and how do I signal that I found nothing." That question currently has four independent answers, one per skill, none of them written down. Relocating storage without naming the contract would produce four independent hardcodings of a new location, which is the same defect at a different address.

Alternative considered: relocate only, leave each skill to glob. Rejected because the defect being fixed is the divergence, not the location, and because a separately-tracked mechanical consistency check has nothing to check against unless the contract is named.

**Decision 2 — the split criterion is which reader consumes the rule.**

A rule that this plugin's own workflow reads moves into the plugin namespace, because a reader exists that will fetch it. A rule that no skill reads — one that functions by being injected into general session context — stays in the injected directory, because moving it removes its only delivery mechanism.

Inspection of this repository shows the diff-learner writes four rule categories but no skill reads two of them: the code-comment style category and the general-writing style category have write sites and zero read sites. The correspondence category and the document-type style category are both read by the writer skill.

Alternative considered: split by how narrowly a rule applies. Rejected because that criterion classifies code-comment style as narrowly applicable and therefore movable, which would silently remove its only reader. The two criteria disagree precisely where the consequences are worst.

The failure modes are asymmetric and this asymmetry is the reason the criterion matters: moving a general-discipline rule into the namespace produces no error and no output change that anyone would attribute to the move, while leaving a party-specific rule in the injected directory merely continues an already-tolerated inefficiency. When the criterion is ambiguous for a given rule, leaving it in the injected directory is the safe direction.

**Decision 3 — one directory per subject, with a mandatory core file and on-demand genre facets.**

A subject's directory holds a core file carrying everything that does not vary with genre — tone calibration, word preferences, relationship position, fact fixpoints, red lines — plus zero or more genre facet files carrying that genre's structure, conventions, and formatting obligations. A subject writing in only one genre has a core file and no facet; nothing forces a split.

Subject-independent genre conventions live in a parallel genres directory, which gives the diff-learner's document-type style category the address it currently has in the injected directory.

Alternatives considered: a single file per subject with genre sections, rejected because reading rules for one genre would load every other genre's rules from the same file, which erodes the context saving that motivated the relocation; and flat compound filenames encoding subject and genre, rejected because the core-to-facet relationship would survive only as a naming convention and a single-genre subject would still carry a compound name implying a split that does not exist.

**Decision 4 — refusal binds to the lookup not having run, not to the file being absent.**

Binding refusal to file absence makes genuine first contact — writing to a subject for the first time, when no rules could exist — indistinguishable from a skipped step, and blocks the former. Binding it to the lookup instead separates the two: a lookup that ran and found nothing is a normal, reportable outcome; no lookup having run is a failure.

This does not fully close the gap. A lookup performed against a wrong path returns the same not-found outcome as genuine first contact, and both are disclosed identically. Narrowing that further requires observability at the consumer boundary, which is tracked separately.

**Decision 5 — migration leaves a redirect placeholder at each legacy path.**

The downstream consumer constructs the legacy path, tests whether it exists, and hands it over only if it does. After a migration that simply moved files, that existence test fails, no path is handed over, and the calibration silently falls back to a generic register. A legacy-path fallback inside this plugin cannot help, because the consumer never reaches this plugin with a path to fall back from.

A one-line placeholder left at the legacy path keeps the existence test passing. The consumer hands over the legacy path; the resolver recognizes the placeholder and follows it. The cost is a small file per subject remaining in the injected directory — bounded, since a placeholder does not grow the way a rules file does.

Alternative considered: rely on the plugin's legacy fallback alone. Rejected for the reason above. Alternative considered: block this change until the consumer ships an update. Rejected because it couples two repositories' release schedules for a compatibility problem the placeholder already solves.

**Decision 6 — fact fixpoints stay in core with inline genre annotation.**

Whether a fact is true does not depend on genre; whether it is useful in a given genre does. Splitting fixpoints across facets would recreate the duplication this change exists to remove, because a fixpoint relevant to two genres would be written twice. A fixpoint used by only one genre is marked as such inline.

**Decision 7 — facet-over-core precedence is stated in prose in each facet header.**

A facet may override the general conventions core states. A facet may not override the honesty boundaries core states. This is written at the top of each facet file. There is no interpreter, so there is nothing for a formal syntax to be formal for.

## Implementation Contract

**Behavior.** When any participating skill needs a subject's writing rules, it performs a single resolution keyed on the subject identifier and the genre identifier. Resolution returns an ordered list of existing files to read and one of three outcome statuses. The skill reads the returned files in the returned order and reports the outcome status to the user when the outcome is anything other than a subject-specific resolution.

**Layout.** Under a dot-prefixed plugin namespace directory inside the workspace's Claude configuration directory:

- A subjects directory containing one directory per subject, named by a subject slug. Each subject directory contains a core file, which is mandatory whenever the subject directory exists, and zero or more genre facet files named by genre slug.
- A genres directory containing subject-independent genre convention files, named by genre slug.

**Resolution order.** Files are returned least-specific first, so a later file's general conventions override an earlier one's:

1. The subject-independent convention file for the requested genre, when present.
2. The requested subject's core file, when the subject directory is present.
3. The requested subject's facet file for the requested genre, when present.

When step 2 finds no subject directory, resolution consults the legacy location for that subject before concluding. A legacy file whose content is a redirect placeholder resolves to the location the placeholder names and is followed once; a placeholder pointing at a location that does not exist is reported as unresolved rather than followed further.

**Outcome statuses.**

- Subject-specific: at least the subject's core file was found. No disclosure obligation.
- Generic: no subject-specific file was found at either the current or the legacy location. The skill proceeds and must state that this subject has no existing rules before presenting a draft.
- Legacy: resolution succeeded through the legacy location or a redirect placeholder. The skill proceeds, states which location was used, and offers migration.

When both a current and a legacy location hold rules for the same subject, the current location is used and the conflict is reported. Silently choosing either side is prohibited.

**Load gate.** A skill that drafts must have performed a resolution for the subject and genre it is drafting for. Drafting without a recorded resolution outcome is refused with an explicit message naming the missing lookup. Refusal is not triggered by a generic outcome.

**Composition.** Within the returned file list, a facet may override general conventions stated by core. A facet may not override honesty boundaries stated by core. Each facet file states this precedence in its header.

**Migration tool.** A script that, for each rules file at the legacy correspondence location, creates the corresponding subject directory, writes the file's content as that subject's core file, and replaces the legacy file with a redirect placeholder naming the new subject directory. Running the script twice produces the same result as running it once: a legacy path already holding a placeholder is left untouched, and a subject directory that already exists is not overwritten.

**Contract document.** A single reference document in this plugin states the layout, the resolution order, the outcome statuses, the load gate, the composition rule, and the split criterion. Each participating skill cites this document at the point where it previously constructed a path, and states which operation it performs — resolve, or persist — rather than restating the layout.

**External consumer contract.** The README section describing the programmatic calibration entry is updated to describe the rules path field as referring to a resolved location, to name the three outcome statuses, and to state that a consumer reconstructing the canonical location itself must follow the resolution order rather than assuming a single file.

**Acceptance criteria.** This repository has no test framework, so acceptance is defined as inspection assertions that a reviewer or a later mechanical check can evaluate:

1. Searching the skills directory for the legacy correspondence path literal returns matches only in the reference document's legacy-and-migration section and in the migration script. No skill file constructs that path inline.
2. Searching the skills directory for the new namespace path literal likewise returns no inline construction; each skill instead names the resolve or persist operation and cites the reference document.
3. The reference document states all six contract elements — layout, resolution order, outcome statuses, load gate, composition, split criterion — and each participating skill's citation resolves to a section that exists in it.
4. The two rule categories with no read site in this repository are named in the reference document as remaining in the injected directory, with the reader-based criterion given as the reason.
5. Running the migration script against a directory holding legacy rules files produces subject directories with core files and placeholders at the legacy paths; running it a second time changes nothing.
6. The README's consumer-contract section names the three outcome statuses.

**Scope boundaries.**

In scope: the reference document; the four skills' citations of it in place of inline path construction; the migration script; the README consumer-contract section; the plugin manifest version and changelog entry; the marketplace manifest version.

Out of scope: any file inside a user workspace, including running the migration; the downstream consumer's source in its own repository; the mechanical consistency check; the trigger-surface exclusion; any change to drafting behavior other than the load gate and the disclosure obligations.

## Risks / Trade-offs

**A general-discipline rule is misclassified and moved into the namespace** → its only reader disappears and the discipline stops applying with no error and no attributable output change. Mitigation: the reader-based criterion is decidable by searching for read sites, the two currently-unread categories are named explicitly in the reference document rather than left to judgment, and the criterion states that ambiguous cases stay in the injected directory.

**Four skills are updated to cite the contract but one keeps an inline path** → write and read sides address different locations, and the symptom is rules that appear to save but never load. Mitigation: acceptance criteria 1 and 2 are stated as searches over the skills directory, which makes the divergence detectable by inspection now and mechanically later.

**The downstream consumer's calibration silently degrades** → replies still post, with a generic register instead of the subject's voice, and nothing reports it. Mitigation: the redirect placeholder keeps the consumer's existence check passing, so degradation does not begin at migration time; the consumer-side observability gap itself is tracked separately.

**A resolution runs against a wrong path** → the not-found outcome is indistinguishable from genuine first contact, and the disclosure reads as normal. Mitigation: partial only. The legacy consultation makes a wrong current-path less likely to be silent, and the outcome status is surfaced rather than swallowed, but this residual is real and is recorded in Open Questions rather than claimed as solved.

**Trade-off accepted: the placeholder keeps files in the injected directory.** The context saving is therefore not total. A placeholder is a single line and does not grow, so the cost is bounded and far below the rules files it replaces, but the claim is reduction, not elimination.

**Trade-off accepted: safety does not return to the injection baseline.** Injection guaranteed rules were present before drafting could begin. The load gate approximates that guarantee by refusing when no lookup ran, but a lookup that ran against the wrong place still proceeds. This is a real reduction in the guarantee's strength, taken deliberately in exchange for the context cost.

## Migration Plan

1. Ship the reference document, the skill citations, the migration script, and the updated README together. Until the workspace owner runs the migration, resolution finds no subject directory, consults the legacy location, and returns the legacy outcome — existing workspaces keep working and are told migration is available.
2. The workspace owner runs the migration script when convenient. Legacy paths become placeholders; subject directories appear with core files.
3. Facets are created on demand thereafter. No facet is created by migration, because migration cannot know which parts of an existing rules file are genre-specific — that separation is a judgment the writer makes when the second genre first arises.
4. File the tracking request asking the downstream consumer to follow the resolution order rather than reconstruct a single-file path.

Rollback: the migration script's effect is reversible by replacing each placeholder with the content of the corresponding core file and deleting the subject directory. Because the plugin retains legacy consultation, a workspace that rolls back continues to resolve.

## Open Questions

- How long legacy consultation and placeholder following remain supported. Ecosystem precedent in sibling plugins is to keep a compatibility path until the next major version, but this change does not fix a removal date.
- Whether the genres directory should also accept a per-subject override, which would let a subject deviate from a project-wide genre convention without duplicating it. Deferred: no observed case requires it, and adding the lookup step is cheap later.
- Whether the boundary between what belongs in core and what belongs in a facet can be given any rule at all. It is currently a judgment made when the second genre for a subject first appears, and this change does not claim to remove that judgment — it only guarantees the judgment has two places to write its result instead of one place written twice. The drift risk is reduced from structural to judgmental; it is not eliminated.
