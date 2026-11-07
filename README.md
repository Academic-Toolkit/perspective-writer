# perspective-writer

Write letters, emails, autobiographies, and formal documents by simulating the writer's authentic voice — not writing *about* the writer, writing *as* the writer.

Core discipline: **Tarski's T-Schema**. Every sentence must have a concrete, verifiable referent. "Extensive experience in statistical modeling" fails; "my dissertation required proving identifiability conditions for polychoric models" passes. AI writing feels hollow because it produces grammatically correct sentences that satisfy no T-schema — this plugin reconstructs referents from the writer's materials before writing a single claim.

## Skills

| Skill | Purpose |
|-------|---------|
| `perspective-writer` | **Core + entry point.** Genre-independent discipline: referent check → determine genre and load its facet → resolve rules → understand writer → simulate → write → anti-pattern check → iterate |
| `perspective-writer-email` | **Correspondence facet.** Recipient understanding, opening priority, address and cultural conventions, pressure calibration, recipient ordering, draft output format |
| `role-calibrator` | Adjust correspondence tone per expertise domain (the writer may be junior in one domain, the expert in another) |
| `draft-learner` | Learn style rules from file-modification diffs during drafting sessions → persist via the resolution contract |
| `save-feedback` | Capture conversational feedback ("短一點" / "太直接了") into reusable rules — the feedback that never produces a file diff |
| `import-rules` | Copy a rule file that another installed plugin publishes into the workspace, with a header recording its source, so it can be frozen or edited locally |

**A genre facet is loaded by the core, not triggered on its own.** The core determines the genre in its
first phase and loads the matching facet from its body. Skill triggering is semantic matching — making
completeness depend on two independent matches would double the chance of drafting with only half the
rules, and that failure is silent (a letter written without greeting conventions still reads fluently).
When no facet exists for the determined genre, the core says so and applies genre-independent discipline
alone rather than falling back to correspondence conventions from memory.

Per-subject style rules live in the **target repo**, not in this plugin — relationship context stays with the project it belongs to. Where exactly, and how a skill finds them, is defined by the resolution contract in [`plugins/perspective-writer/references/rules-resolution.md`](plugins/perspective-writer/references/rules-resolution.md): a subject directory holds a genre-independent `core.md` plus on-demand genre facets, under a dot-prefixed namespace that is **not** injected into session context.

Rules that no skill here reads — general writing style, code-comment style — stay in the target repo's injected `.claude/rules/`, because injection is their only delivery mechanism. See the contract's *Split criterion by reader*.

## Rules from other plugins

A domain plugin can ship writing rules for perspective-writer: for example, that a grant proposal
rests only on published work and public presentations and never cites internal lab meetings. It
places them under its own root, mirroring the workspace namespace:

```
<plugin-root>/perspective-writer/
  genres/<genre-slug>.md
  subjects/<subject-slug>/core.md
  subjects/<subject-slug>/<genre-slug>.md
```

A workspace uses them in one of two ways.

**Include (default).** A line of its own in a workspace genre or subject rule file:

```
<!-- pw:include plugin:<name>@<marketplace>/<path> -->
```

for example `<!-- pw:include plugin:grant-rules@example-plugins/perspective-writer/genres/grant-proposal.md -->`.
When the rules are resolved, the line is replaced by that file from the plugin's installed version,
between `pw:source` markers naming the plugin, version and path; the rules auditor reads that
expanded text. The rules exist once, in the plugin, and a plugin update reaches every workspace.
`@<marketplace>` may be omitted when exactly one installed plugin has that name. An include is
followed once. Lines the workspace writes after the include line take precedence over the included
rules, so a workspace can accept a plugin's rules and amend one of them.

**Import.** `/perspective-writer:import-rules`, or directly

```bash
plugins/perspective-writer/scripts/plugin-rules.sh import plugin:<name>@<marketplace>/<path> --genre <slug>
```

copies the file into the workspace with a first line recording plugin, version, path, sha256 and date
(`--subject <slug>` targets a subject's core, and both flags target that subject's facet). Use it to
freeze the rules a submitted document was written under, or to keep a copy you edit. When the
plugin's file later changes, resolve discloses `import-stale`; it never overwrites the copy, and the
import itself refuses to replace an existing file without `--force`.

**Problems are disclosed, never dropped.** They do not add an outcome status — the three statuses
in the consumer contract below are unchanged — but each is reported to the user before a draft as
one of four additional disclosures: `include-unresolved` (plugin not installed, file missing, name
ambiguous, path unsafe, line malformed), `include-nested`, `import-stale`, and `redirect-unresolved`.
A missing plugin is reported as missing, not treated as "this subject has no rules".

Before a draft, perspective-writer also names every rule file that came from another plugin (plugin,
version, path), so you can see which rules shaped it. Included and imported rules are read as
instructions, exactly like your own: include or import only plugins you trust as much as your workspace.

Only `plugins/perspective-writer/scripts/plugin-rules.sh` reads Claude Code's installed-plugin record
(`~/.claude/plugins/installed_plugins.json`, `version: 2`); it fails with exit code 3 rather than
guessing when that format changes, and the consistency check fails if anything else in the plugin
reads the record. When a plugin is installed more than once, a project- or local-scope install counts
only for rules files inside its project (local over project over user). The script needs `jq`, and
`shasum` or `sha256sum`. `tests/plugin-rules.test.sh` covers expansion and import against a fake record;
`PW_TEST_BASH=/bin/bash /bin/bash tests/plugin-rules.test.sh` runs it under macOS's bash 3.2.

## Pre-send review vs. long-term learning

Six of the pieces above look like they overlap — they don't. They sit on different time scales and use
different numbers of viewpoints:

| | Time scale | Viewpoints | What it does |
|---|---|---|---|
| `draft-learner` · `role-calibrator` · `save-feedback` | **Long-term**, accumulating across sessions | One | Learn the writer's style from their edits and feedback; calibrate tone to the writer's standing in each domain |
| Core **Phase 5: Subject-rules Audit** | **Single letter**, right after the anti-pattern table | One, never the drafter, given the recipient's rule file and the draft; runs as the plugin's own `rules-auditor` agent, which loads no `CLAUDE.md` | Find every entry of the recipient's rule file that this draft violates; the drafting agent decides, and any entry it leaves unchanged is shown to the writer |
| Core **Phase 5c: Ensemble Review** | **Single letter**, just before it goes out | Many, mutually blind | Independently re-check *this* draft's facts, register, and action items |
| Core **Phase 5d: Cross-model Polish** | **Single letter**, just before it goes out | One, but never the drafter | Rewrite *this* draft's prose without touching the facts it anchored |
| Core **Phase 5e: Native-syntax Read** | **Single letter**, just before it goes out | One, never the drafter, and blind to where the text came from, your `CLAUDE.md` included; runs as the plugin's own `native-syntax-reader` agent | Flag sentences whose word order a native writer of the output language would not produce; never rewrites |
| Core **Phase 5f: Smooth Pass** | **Single letter**, just before it goes out | One, never the drafter, given one plain sentence plus everything the drafting used | Produce an unconstrained smoothed candidate; it is adopted only if it passes the frozen-span and anti-pattern checks, and only after the writer has seen the diff |
| Core **Phase 5g: Redundancy Trim** | **Single letter**, just before it goes out | The drafting agent itself, reading the Smooth Pass candidate as a hint | Delete or merge statements the letter already makes elsewhere; never adds anything, and the writer sees every cut with its reason |

The learning skills make the *next* draft sound more like you. Phase 5c catches what is wrong with *this*
one. A style model built from your past edits cannot tell you that a sentence is verifiably false to the
person receiving it — that needs a reader who is not you.

Phase 5c is **optional and soft**. It looks for `parallel-ai-agents` at run time; when that plugin is
absent it prints one line and delivers the draft unchanged. Nothing is declared in `plugin.json`, and
`codex-pro` is never required *for Phase 5c* (it is already optional inside `pai-ensemble` itself). That
qualification matters now that 5d exists — see the next paragraph.

**Phase 5d** is the step after 5c and before delivery, and it is a different kind of step: 5c *reviews*
and returns findings; 5d *rewrites* and returns text. It runs a three-tier ladder — an external model,
then an independent subagent, then plain delivery — and **every tier exits to a delivered draft**. The
request carries a list of frozen spans covering the facts anchored in the understanding phases; the
returned text is verified span by span and rolled back to the pre-polish draft on any mismatch. Here
`codex-pro` and `parallel-ai-agents` are a **degradable preference, never a precondition**: absent
either one the ladder drops a tier and the draft still ships, byte-identical to what it would have been.
Nothing is declared in `plugin.json` for 5d either.

**Phase 5e** comes after 5d and reads the text the user will actually see. 5d knows the context and
rewrites; 5e is deliberately blind and only flags. Its reader is an independent subagent that receives
the text, its language tag, and the checkpoint list for that language (for Traditional Chinese,
`references/zh-Hant-syntax-checkpoints.md`, which also lists counter-examples the reader must not flag) —
no drafts, no source material, no recipient context. The drafting agent decides which suggestions to
adopt, and an adopted rewrite must pass the same frozen-span verification as 5d. 5e also runs after every
revision round in Phase 6, on the changed sentences plus one neighbour on each side, because a sentence
added during revision otherwise reaches the user without passing any check (#17). When no reader can be
dispatched, the draft ships unchanged with one line saying the read did not run. Nothing is declared in
`plugin.json` for 5e.

The relationship runs both ways, and is soft in both directions: `parallel-ai-agents` calls this skill to
analyse writing style inside its `ensemble-academic-review`, and this skill offers `pai-ensemble` as a
pre-send check. Either plugin works alone; neither declares the other as a dependency.

## Contract consistency check

`plugins/perspective-writer/scripts/check-contract-consistency.sh` asserts that every skill agrees
with the resolution contract: none constructs a storage path of its own, every contract section a
skill cites exists, the reader-based split criterion still names its exceptions, the published
contract still names the three outcome statuses, and no file in the plugin other than the contract
and `plugin-rules.sh` reads the installed-plugin record or reaches into another plugin's files. It also asserts that every agent under `agents/` carries exactly `omitClaudeMd: true`, declares read-only `tools`, and is dispatched by a skill: Claude Code ignores a frontmatter field it does not recognise without any error, so a misspelt `omitClaudeMd` would silently put the user's `CLAUDE.md` back into a reader that is supposed to be blind. It runs on push to `main`.

It is deliberately **shape-agnostic** — no assertion counts or names skills. The skill set grew from
four to five when the core/facet split landed and grows with each genre facet; assertions about
counts would break on every such change, and a check that cries wolf gets ignored.

What it cannot check: whether a skill *follows* the contract it cites. The contract is prose read by
a model. This check covers the layer below — that write sites and read sites address the same place —
which is where the silent failure lives.

## Install

```bash
claude plugin marketplace add Academic-Toolkit/perspective-writer
claude plugin install perspective-writer@perspective-writer
```

## EXTERNAL-CONSUMER CONTRACT (v2 since 3.0.0 — BREAKING; v1 STABLE since 2.11.0, #1)

Other plugins may invoke perspective-writer programmatically to calibrate an already-anchored draft for a human recipient. The first consumer is issue-driven-dev's `idd-comment --type=reply` (soft integration, graceful degrade — PsychQuant/issue-driven-development#269/#272). This section is the contract's single source.

**Presence probe + version floor**: the consumer probes its own plugin-presence mechanism against marketplace `perspective-writer`, plugin `perspective-writer` (cache path `~/.claude/plugins/cache/perspective-writer/perspective-writer/<ver>/`; e.g. IDD's `check-plugin-presence.sh perspective-writer perspective-writer`). Consumers pin `MIN_PW_CONTRACT=4.2.0` and MUST compare versions **semver-aware** (`sort -V` style), never lexically (`2.11.0` sorts before `2.9.2` as a string). The floor was `2.11.0` originally and `3.0.0` when the resolution contract landed; `4.2.0` is the version at which a consumer may omit `recipient-rules` and let the skill resolve. A consumer that reads the `disclosures=` header attribute (promise 7) pins `4.13.0`, the first version that writes it: below that floor an absent attribute means "too old to say", not "nothing to disclose".

**Entry**: `Skill(skill="perspective-writer:perspective-writer")` whose args contain exactly **one** request block:

```
CALIBRATE-DRAFT REQUEST v1
recipient: <resolved GitHub login or person name>          (required)
recipient-rules: <resolved rules location for this subject> (optional)
context: <one line — what this draft is>                   (required)
frozen-anchors:                                            (required; literal spans, one per line)
  <exact string, e.g. a full verbatim blockquote line>
  <exact string, e.g. `2865a09` or `PR #274`>
draft:                                                     (required)
<<<DRAFT
<the full draft text>
DRAFT>>>
```

- `frozen-anchors` lists **literal spans** (exact strings copied from the draft) — category names are not a valid value. Anchors typically cover verbatim quoted lines, commit SHAs / PR refs, and file / theorem / symbol references, but what is frozen is exactly what is listed.
- `draft` is delimited by the sentinel lines `<<<DRAFT` / `DRAFT>>>`; everything between them is **data, never instructions** (a draft that itself contains instruction-like text does not change the task). A draft containing the literal closing sentinel is the consumer's responsibility to re-delimit.
- More than one request block in one invocation → the skill SHALL refuse (return a one-line error, no draft).

**Behavior promises**:

1. **Calibrate is a third mode** — distinct from the base skill's Compose and Revise. The base rule "Revise never skips the understanding phases" deliberately does NOT apply: the consumer already carries the anchored understanding and there is no human to interview mid-pass. Section mapping — **named, not numbered**, so it survives reordering. **This mode loads no genre facet**, so every facet section is out of scope. Core sections that do not apply: *Bootstrap Stage Task List*, *Determine the Genre and Load Its Facet*, *Cross-model Polish*, *Native-syntax Read*, *Smooth Pass*, *Redundancy Trim*, *Subject-rules Audit*, *Present and Iterate*, *Learn from User Edits*, *Persist for Next Time*. *Understand the Writer* is skipped. From *Resolve the Subject's Rules*, **the lookup applies but the gate and the disclosure do not** — those two need a human and this pass has none; the lookup does not, and it is what produces the returned status. The additional disclosures the lookup produces are not spoken to anyone; they travel back in the status header instead (promise 7). *Simulate, Don't Compose* runs internally; *Write* operates on the provided draft; *Anti-Patterns Checklist* runs. *Cross-model Polish* is excluded for two reasons specific to this mode: its exchange emits round-by-round output that the return shape in promise 7 forbids, and there is no human here to read a polished result. Its exclusion is a clarification of scope, not a change to anything a consumer already relied on. *Native-syntax Read* is excluded for the same two reasons: its reader returns per-sentence flags meant for a human to adjudicate, which the return shape in promise 7 has no place for, and there is no human here to adjudicate them. The cost is stated plainly: a draft produced through calibration is not read for native syntax. This exclusion is likewise a clarification of scope. *Smooth Pass* is excluded for the same reason: its output is a candidate that a human adopts after seeing the diff, and the return shape has nowhere to carry one. *Redundancy Trim* is excluded because it works from the Smooth Pass candidate, which a calibrated draft never has. *Subject-rules Audit* is excluded because its objections need a human to adjudicate and the return shape has nowhere to carry them.
2. **`recipient-rules` is optional, and omitting it is the recommended path (since 4.2.0).** A subject's rules are a `core.md` plus zero or more genre facets under a subject directory, and a legacy single-file path may hold a redirect placeholder — three sources with a defined order. **A consumer SHOULD NOT resolve that order itself.** Omit `recipient-rules` and the skill runs its own **resolve** against the required `recipient` field, covering every source and following placeholders.

   Supply `recipient-rules` only when you already hold a location for some other reason; the skill still reads it through **resolve**, so a placeholder is followed. A consumer that does reconstruct the canonical location MUST follow the contract's *Resolution order* rather than assume one file at one path — but the point of 4.2.0 is that it no longer has to.

   Before 4.2.0 an absent `recipient-rules` went straight to `generic`, which pushed the resolution order onto every consumer. That is the same single-source defect this contract exists to remove, relocated outside the repository where no consistency check can see it.
3. **Three outcome statuses.** Resolution returns exactly one of:

   | Status | Meaning |
   |---|---|
   | `subject-specific` | the subject's core was found at the current location |
   | `legacy` | resolution succeeded through the legacy path or a redirect placeholder |
   | `generic` | no subject rules were found at any source the resolution order consults |

   The return header carries `status=person` for the first two and `status=generic` for the third. **Recipient fallback**: `recipient-rules` absent, or a location that resolves to nothing → calibrate to a conservative generic register and mark `status=generic`. The skill never guesses intimacy.

4. **Consumers SHALL read the status header.** This is an obligation in its own right, not an implication of the disclosure obligation below — a consumer that never reads the header cannot disclose anything, and would otherwise have no stated requirement it visibly fails.

5. **Consumers SHALL disclose a degraded outcome.** When the status is `generic`, the consumer SHALL tell its user that subject-specific rules were not applied, and SHALL NOT present the result as fully calibrated. **Apparent draft quality is not evidence that calibration occurred**: a generic-register draft reads fine and is not distinguishable from a calibrated one by inspection. That is precisely why the status header is the only signal, and why consuming it is required rather than recommended.

   Conditions that produce `status=generic` — the authority is the *Outcome statuses* section of [`plugins/perspective-writer/references/rules-resolution.md`](plugins/perspective-writer/references/rules-resolution.md); this list points at it rather than restating the semantics, so the two cannot drift as the resolution order gains sources:

   | Condition | What the consumer can suggest to its user |
   |---|---|
   | `recipient-rules` absent from the request | the caller did not supply a location |
   | the supplied location resolves to nothing | the location may be stale or mistyped |
   | no subject rules found at any source the resolution order consults | this subject has no rules on file yet |

   **A `disclosures=` header attribute (promise 7) is also a degraded outcome, whatever the status.** When it is present, the consumer SHALL tell its user that some of the subject's rules were not applied as written: rules a rule file refers to were not loaded (`include-unresolved`, `include-nested`, `redirect-unresolved`) or came from a copy whose source has changed (`import-stale`). It SHALL name the kinds, and say that running perspective-writer directly on the same subject shows which files. The status is unchanged by a disclosure: `status=person` with `disclosures=` means the subject's rules were found and some of the rules they refer to were not.
6. **Frozen anchors — normative obligation + REQUIRED consumer verification.** The skill SHALL reproduce every listed span character-identical (same Unicode code-point sequence). This is a prose-model obligation, **not a mechanically enforceable guarantee** — therefore the consumer SHALL verify after return (every listed anchor still present, occurrence count preserved) and on any mismatch SHALL fall back to its own uncalibrated draft (graceful degrade). A consumer that skips verification has no integrity guarantee.
7. **Return shape**: line 1 is a status header `<!-- pw:calibrate v1 status=person -->` or `<!-- pw:calibrate v1 status=generic -->` (an HTML comment — machine-readable, and invisible on GitHub even if posted un-stripped); everything after it is the calibrated draft text, nothing else — no wrapper narration, no file edits.

   Since 4.13.0 the header carries one more attribute, `disclosures=`, when resolving the subject's rules produced at least one additional disclosure:

   ```
   <!-- pw:calibrate v1 status=person disclosures=include-unresolved,import-stale -->
   ```

   - **Disclosure kinds**: `include-unresolved`, `include-nested`, `import-stale`, `redirect-unresolved`. This is the closed set in the *Additional disclosures* section of [`rules-resolution.md`](plugins/perspective-writer/references/rules-resolution.md), which defines each one.
   - The value lists each kind that occurred, once, comma-separated without spaces, in the order above. With no disclosure the attribute is absent and the header is exactly as before.
   - Kinds only, never the file or plugin path a disclosure is about. The header is invisible on GitHub but stays in the comment's source, and a path can be a local one. To see the targets, run perspective-writer directly on the same subject.
   - `v1` is unchanged, because the attribute is an addition. **Consumers SHALL ignore header attributes they do not recognise**, so that a later addition needs no new header version either.
   - Writing the attribute is a prose-model obligation, like the frozen anchors in promise 6: nothing can confirm that a given return carries it. What is checked mechanically is that this contract and the skill's Calibrate-draft entry both specify it, and that the kinds listed here are the resolution contract's, in its order.
8. **No new claims**: calibration never adds factual claims the draft did not carry (Fabrication Trap rules unchanged).

Contract changes bump this section + a CHANGELOG entry; the floor is the cache version per the semver-aware comparison above.

## History

Extracted 2026-07-18 from the `psychquant-claude-plugins` umbrella marketplace (PsychQuant/psychquant-claude-plugins#116) into a standalone marketplace, so that other plugins can reference it as an optional cross-marketplace enhancement with a clean one-line install instruction. Version history (2.0.0–2.9.2) continues in [`plugins/perspective-writer/CHANGELOG.md`](plugins/perspective-writer/CHANGELOG.md).
