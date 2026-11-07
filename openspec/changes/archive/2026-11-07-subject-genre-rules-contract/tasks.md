## 1. Contract document

- [x] 1.1 A single reference document states the resolution contract so every skill has one place to cite. It covers the Storage layout, the Resolution order, the Outcome statuses, Dual-location conflict handling, Composition precedence, and the Named resolution contract itself. Verification: content review confirms each of those six elements has a section heading a skill can cite by name.
- [x] 1.2 The reference document states the Split criterion by reader, names the code-comment style and general-writing style categories as remaining in the injected project rules directory, gives the absence of a read site in this plugin as the reason, and states that ambiguous cases stay in the injected directory. Verification: content review against the placement table in the writing-rules-resolution spec.
- [x] 1.3 The reference document records that Load gate does not close the wrong-path gap: a resolution run against an incorrect location returns the generic outcome and is indistinguishable from genuine first contact. Verification: content review confirms the residual is recorded as known rather than presented as solved.

## 2. Skill citations replace inline path construction

- [x] 2.1 The main writer skill obtains recipient rules by naming the resolve operation and obtains its persistence target by naming the persist operation, citing the reference document at both sites, so neither the understanding phase nor the persistence phase assembles a path. Verification: reading the skill shows a citation at each site and no path literal.
- [x] 2.2 The diff-learner skill routes a learned rule by naming the persist operation for the categories this plugin reads, and continues writing the two categories with no read site to the injected project rules directory, consistent with the Split criterion by reader. Verification: reading the skill shows all four categories still distinguished, the two moved ones citing the contract and the two retained ones unchanged.
- [x] 2.3 The role-calibrator skill locates the rules it rewrites by naming the resolve operation instead of globbing a directory, so a subject whose rules live in the plugin namespace is found. Verification: reading the skill shows a citation and no glob pattern over the legacy directory.
- [x] 2.4 The feedback-capture skill writes captured rules by naming the persist operation, so conversation-derived rules land where drafting reads from. Verification: reading the skill shows a citation and no path literal.
- [x] 2.5 The Named resolution contract is the only place a storage path appears: searching the skills directory for the legacy path literal returns matches only in the reference document and the migration script, and searching for the new namespace path literal returns no inline construction in any skill. Verification: run both searches and confirm the match sets.

## 3. Load gate and disclosure

- [x] 3.1 Resolution must run before drafting: the main writer skill records a resolution outcome and refuses to draft when none is recorded, naming the missing lookup in the refusal. Generic outcome does not trigger refusal. Verification: reading the skill shows the gate conditioned on a recorded outcome existing, not on a rules file existing.
- [x] 3.2 Disclosure is mandatory and specific: a generic outcome makes the skill state that the subject has no existing rules before presenting a draft, and a legacy outcome makes it name the location used and offer migration. Verification: reading the skill shows both disclosures stated as obligations that survive a draft that reads well.

## 4. Migration tool

- [x] 4.1 Migration tool converts legacy files and leaves placeholders, creating for each legacy rules file a subject directory holding a core file with the original content. Migration is idempotent, so a second run leaves an existing placeholder untouched and does not overwrite an existing subject directory. Migration creates no facets. Verification: run the script against a scratch directory holding two legacy files, confirm the resulting structure, run it again and confirm no content changes.
- [x] 4.2 The reference document states that Legacy location remains readable, that a Redirect placeholder is followed once and a placeholder naming an absent location is reported unresolved, and that Migration is reversible by replacing each placeholder with its core file content and removing the subject directory. Verification: content review confirms the reversal steps are concrete enough to follow without reading the script.

## 5. Published contract and release

- [x] 5.1 External consumer contract states resolution: the README consumer-contract section describes the rules path field as referring to a resolved location, names the three outcome statuses, and states that a consumer reconstructing the location itself must follow the resolution order rather than assume a single file. Verification: content review against the external consumer contract requirement in the writing-rules-resolution spec.
- [x] 5.2 The plugin manifest and the marketplace manifest carry a major version increment reflecting the breaking artifact-path contract change, and the changelog entry names the contract change, the reader-based split, and the migration path. Verification: both manifests report the same new version and the changelog entry is present.
- [x] 5.3 Downstream consumer handover survives migration is confirmed and a tracking request is filed against the downstream consumer's repository asking it to follow the resolution order rather than reconstruct a single-file path. Verification: the placeholder keeps the consumer's existence check passing, and the filed request exists and links to the contract section.

## 6. Skill-packaged rules

- [x] 6.1 Skill-packaged subject rules resolve as core: the contract recognises a workspace that packages a subject's rules as a skill, consults it when no subject directory exists, returns the subject-specific outcome rather than legacy, offers no migration, and returns every matching skill when a subject has one per genre. Verification: content review confirms the contract states the precedence, the status, the already-in-context case, and the multi-skill case; and that Dual-location conflict names all three sources.
