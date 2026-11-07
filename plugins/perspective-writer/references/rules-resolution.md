# Writing-Rules Resolution Contract

This document is the single source for where writing rules live, how a skill finds
them, and what a skill must do with what it finds. Every skill in this plugin that
reads or persists writing rules cites a section of this document instead of
constructing a path of its own.

Three operations are defined:

- **resolve** — given a subject and a genre, return an ordered list of existing
  rule files, expanded, plus an outcome status and any additional disclosures.
- **persist** — given a subject and a genre, return the single file a newly
  learned rule should be written to.
- **import** — copy a rule file that another installed plugin publishes into this
  namespace, recording where it came from.

A skill names the operation it performs and cites the relevant section here. A
skill does not assemble a directory path, a filename, or a glob pattern inline,
and does not read Claude Code's installed-plugin record: files inside other
plugins are reached only through `scripts/plugin-rules.sh`.

## Storage layout

Rules this plugin reads live under a dot-prefixed namespace inside the
workspace's Claude configuration directory. Dot-prefixed namespace directories
are not injected into session context; they are read on demand.

```
.claude/.perspective-writer/
  subjects/
    <subject-slug>/
      core.md          # required whenever the subject directory exists
      <genre-slug>.md  # zero or more genre facets, created on demand
  genres/
    <genre-slug>.md    # subject-independent genre conventions
```

**core** carries everything about a subject that does not vary with genre: tone
calibration, word preferences, relationship position, fact fixpoints, and red
lines. **A facet** carries what that one genre needs: structure, conventions,
formatting obligations.

A subject that writes in only one genre has a core file and no facet. Nothing
forces a split. Facets appear when a second genre first arises.

A subject directory that exists but contains no core file is malformed. Resolve
reports it as malformed rather than treating the subject as unresolved — the
distinction matters, because "no rules for this subject" and "this subject's
rules are broken" call for different responses.

Slugs are kebab-case. A subject slug identifies a person or party; a genre slug
identifies a document kind (`email`, `proposal`, and others as they arise).

### Rules published by other plugins

A rule file in this namespace may draw on a rule file that another installed
plugin publishes, in one of two ways. Include is the default.

**Include.** A line of its own of the form

```
<!-- pw:include plugin:<name>@<marketplace>/<path> -->
```

stands for the content of `<path>` inside the installed directory of the plugin
keyed `<name>@<marketplace>` in Claude Code's installed-plugin record. The rules
therefore exist once, in the plugin, and a plugin update takes effect without
touching the workspace. `@<marketplace>` may be omitted only when exactly one
installed plugin has that name. An include is followed once: an include line
inside the included file is not expanded. Every other line of the file is the
workspace's own rules.

**Import.** A copy of the plugin's file, written into this namespace by the
**import** operation, whose first line records where it came from:

```
<!-- pw:imported plugin:<name>@<marketplace> version:<version> path:<path> sha256:<hex> date:<YYYY-MM-DD> -->
```

A copy can be frozen at one version — a submitted document can keep the rules it
was written under — or edited locally. The header lets resolve tell when the
source has changed since the copy was made; it never updates the copy.

**Where a plugin puts its rules.** A plugin that publishes rules for this plugin
places them under its own root, mirroring this namespace:

```
<plugin-root>/perspective-writer/
  genres/<genre-slug>.md
  subjects/<subject-slug>/core.md
  subjects/<subject-slug>/<genre-slug>.md
```

The `<path>` in an include or import is relative to the plugin root, ends in
`.md`, contains no `..` segment, and does not leave the plugin's installed
directory once symbolic links are resolved. A path that breaks any of these is
not read.

## Resolution order

Resolve returns files **least-specific first**, so that a later file's general
conventions override an earlier file's:

1. `genres/<genre>.md` — the subject-independent convention for this genre, when present.
2. `subjects/<subject>/core.md` — the subject's cross-genre layer, when the subject directory is present.
3. `subjects/<subject>/<genre>.md` — the subject's facet for this genre, when present.

When step 2 finds no subject directory, resolve consults two further sources before
concluding, in this order:

- a **skill-packaged** rule set for that subject — see **Skill-packaged subject rules**;
- the **legacy** single-file location — see **Legacy location remains readable**.

Example with all three levels present:

| Position | File | Overrides |
| -------- | ---- | --------- |
| 1 | genre convention | nothing |
| 2 | subject core | genre convention |
| 3 | subject facet | subject core, genre convention |

With only a core file and no genre convention or facet, resolve returns a
single-element list.

**Every file resolve returns is passed through `scripts/plugin-rules.sh expand`
before it is read, in the order above.** Expansion replaces each include line with
the included content between `<!-- pw:source begin plugin:<key> version:<version>
path:<path> -->` and `<!-- pw:source end -->`, checks an imported copy against its
source, and writes each problem to stderr as one line
`pw:disclosure <kind> <target> — <reason>` (see **Additional disclosures**). The
expanded text, not the raw file, is what the drafter and the rules auditor read. A
file with no include line and no imported header expands to itself.

When expansion exits with code 3, the installed-plugin record could not be read
and the file's includes were not expanded. Treat this as an `include-unresolved`
disclosure for that file, naming the file and the record path, and read the raw
file; do not present the result as if the file had no includes.

## Outcome statuses

Resolve returns exactly one of three statuses:

| Status | Meaning | Disclosure obligation |
| ------ | ------- | --------------------- |
| **subject-specific** | The subject's core file was found at the current location. | none |
| **legacy** | Resolution succeeded through the legacy location or a redirect placeholder. | name the location used; offer migration |
| **generic** | No subject file was found at the current location or the legacy location. | state that this subject has no existing rules |

A skill receiving a status other than subject-specific discloses it to the user
**before** presenting a draft. The disclosure is not waived because the draft
reads well — a draft produced without a subject's rules can read perfectly and
still not sound like the writer, which is precisely why the absence has to be
stated rather than inferred from the output.

These three are the only statuses. A problem with an included or imported rule
file, or a redirect that leads nowhere, does not add a status: it is an additional
disclosure reported alongside whichever status resolve returned.

## Additional disclosures

Besides its status, resolve can produce additional disclosures. The set is closed:
there are exactly these four, and no other problem is to be reported as a fifth
kind.

| Disclosure | Produced by | Meaning |
| ---------- | ----------- | ------- |
| `include-unresolved` | `plugin-rules.sh expand` | An include line was not expanded: the plugin is not installed, the file is missing, the plugin name without `@<marketplace>` matches zero or several plugins, the path is unsafe, the line is malformed, or the installed-plugin record could not be read. The rules that line names are not loaded. |
| `include-nested` | `plugin-rules.sh expand` | An included file contains an include line of its own. It was left unexpanded. |
| `import-stale` | `plugin-rules.sh expand` | An imported copy's source has changed since the copy was made, or can no longer be found. The copy is still used. |
| `redirect-unresolved` | resolve, under **Redirect placeholder is followed once** | A redirect placeholder names a subject directory that does not exist. |

A skill tells the user every additional disclosure, naming its target, **before**
presenting a draft — for the same reason as the status disclosure: a draft written
without the missing rules can read well and still be wrong.

An additional disclosure never changes the status. A subject whose core file was
found is `subject-specific` even when an included genre file is unresolved; the
user is told about both.

## Dual-location conflict

When rules for the same subject exist in more than one of the three sources — the
subject directory, a skill-packaged rule set, or the legacy location holding real
content rather than a redirect placeholder — resolve uses the **subject directory**
and **reports the conflict**, naming every source it found.

Choosing either side silently is prohibited. A half-migrated workspace is a state
the user needs to know about; picking a winner without saying so converts a
visible inconsistency into an invisible one.

## Composition precedence

A facet **may** override the general conventions its subject's core states.

A facet **may not** override the honesty boundaries its subject's core states —
the claims marked as red lines, the fact fixpoints, the limits on what may be
asserted on the writer's behalf.

Every facet file states this precedence in its header. There is no interpreter
for these files; the precedence is prose because prose is what reads them.

**Within one file, later text overrides earlier text, and included content counts
as standing where its include line was.** The workspace's own lines that follow an
include line therefore take precedence over the included rules, just as a later
file in the resolution order overrides an earlier one. This is how a workspace
accepts a plugin's rules and amends one of them: write the amendment after the
include line. Included content is bound by the same limits as the file that
includes it; an included facet cannot override its subject core's honesty
boundaries either.

## Named resolution contract

The contract is this document. A skill cites the section it depends on:

| Skill need | Operation | Section to cite |
| ---------- | --------- | --------------- |
| read a subject's rules before drafting | resolve | Resolution order, Outcome statuses |
| write a newly learned rule for a subject | persist | Storage layout, Split criterion by reader |
| locate rules to rewrite | resolve | Resolution order, Dual-location conflict |
| tell the user what could not be loaded | resolve | Additional disclosures |
| copy another plugin's rules into the workspace | import | Storage layout, Named resolution contract |

`persist` targets `subjects/<subject>/core.md` when the rule does not vary with
genre, and `subjects/<subject>/<genre>.md` when it does. A rule with no subject —
a convention that belongs to the genre rather than to a party — targets
`genres/<genre>.md`.

`persist` writes only files in this namespace and never a file inside another
plugin. When the target file contains an include line, the new rule is written
after that line, so that it overrides the included rules (see **Composition
precedence**). An imported copy may be edited directly; its header line stays as
the first line.

`import` is performed by `scripts/plugin-rules.sh import plugin:<name>[@<marketplace>]/<path>`
with `--genre <slug>`, `--subject <slug>`, or both. It writes the same target
`persist` would choose for that subject and genre, prints the path it wrote, and
refuses with exit code 4 when that file already exists. Replacing an existing file
(`--force`) needs the user's explicit consent, because the existing file may hold
the workspace's own rules.

## Split criterion by reader

**A writing rule belongs in this plugin's namespace when a skill in this plugin
reads it. It belongs in the injected project rules directory when no skill reads
it and it functions by being injected into general session context.**

The criterion is which reader consumes the rule, not how narrowly the rule
applies. Those two criteria disagree, and they disagree exactly where the
consequences are worst.

Categories and their placement:

| Rule category | Read by a skill in this plugin | Placement |
| ------------- | ------------------------------ | --------- |
| per-subject correspondence rules | yes | plugin namespace |
| document-type genre conventions | yes | plugin namespace |
| code-comment writing style | **no** | injected project rules directory |
| general writing style | **no** | injected project rules directory |

**Code-comment writing style and general writing style stay in the injected
project rules directory because no skill in this plugin reads them.** They are
written by the diff-learner and consumed by general session activity through
injection. Moving them into this namespace would remove their only delivery
mechanism: nothing would ever fetch them, the discipline would stop applying, and
no error would be raised.

The failure modes are asymmetric:

- Moving a general-discipline rule into the namespace produces **no error and no
  attributable output change**. The rule simply stops arriving.
- Leaving a party-specific rule in the injected directory merely continues an
  already-tolerated context cost.

**When the criterion is ambiguous for a rule, the rule stays in the injected
project rules directory.** The safe direction is the one whose failure is visible.

## Load gate

A skill that drafts must have performed a resolve for the subject and genre it is
drafting for, and must have recorded the resulting outcome status.

**Drafting without a recorded resolution outcome is refused**, and the refusal
names the lookup that was not performed.

The gate is conditioned on the lookup having run, **not** on the rules file
existing. Binding refusal to file absence would block genuine first contact —
writing to a subject for the first time, when no rules could exist — which is a
normal path, not a failure. A resolve that ran and returned `generic` proceeds.

## Load gate does not close the wrong-path gap

A resolve performed against an incorrect location returns `generic`, and that
outcome is **indistinguishable from genuine first contact**. Both disclose the
same thing: this subject has no existing rules.

This is a known residual, not a solved case. The load gate narrows the failure
space — a skipped lookup is now a hard refusal rather than a silent default — but
it does not detect a lookup that ran against the wrong place. Closing that gap
requires observability at the consumer boundary, which is out of scope here.

Do not read the load gate as restoring the guarantee that injection provided.
Injection guaranteed the rules were present before drafting could begin. The gate
approximates that; it does not reproduce it.

## Skill-packaged subject rules

A workspace may package a subject's rules as a **skill** rather than as files under
this namespace:

```
.claude/skills/correspondence-<subject>/SKILL.md
```

This is a **legitimate current arrangement, not a deprecated one.** It exists for a
reason that is orthogonal to this contract: a skill's frontmatter `description` is
the only part that stays resident, so the body is loaded exactly when the
description matches — the same conditional-loading property this namespace achieves
by not being injected, reached by a different mechanism.

Resolve treats such a skill as the subject's **core**, at step 2's precedence, and
returns `subject-specific` — not `legacy`. There is nothing to migrate.

Two consequences the reader must handle:

- **The content may already be in context.** Unlike the other sources, a skill can be
  loaded by its own trigger before this plugin runs. Reading the file again is
  harmless but redundant; if the subject's rules are already present, use them and do
  not re-read.
- **A subject's rules can be split across skills too.** A workspace that packages one
  skill per genre (`correspondence-<subject>`, `proposal-style-<subject>`) has expressed
  the same core-and-facet split this contract describes for rule *files*, using skill
  boundaries as the split. Resolve returns every matching skill for that subject,
  core-like first. Do not treat the second one as a conflict.

  **Do not confuse this with a *genre facet* of the writing skill itself.** Those are two
  different things that both use the word "facet": here it is *one subject's rules* split
  by genre in a workspace; there it is *the skill's own procedure* split by genre in this
  plugin (`perspective-writer` core plus `perspective-writer-<genre>`). A workspace facet
  holds what to say to this person in this genre; a skill facet holds how to write this
  genre at all.

**Why this is in the contract rather than left to the migration script:** a resolution
that does not know about this arrangement returns `generic`, and the load gate then
discloses "this subject has no existing rules" — which is false, and false in the
direction that reads as reassuring. A wrong `generic` is worse than a missing source,
because the disclosure actively tells the user that nothing was lost.

## Legacy location remains readable

Before this contract, per-subject correspondence rules lived at
`.claude/rules/correspondence-<subject>.md`. Resolve consults that location for a
subject when no subject directory exists in the namespace.

A workspace that has not migrated continues to resolve its existing rules, with
the `legacy` outcome status and an offer to migrate. Upgrading the plugin does
not break an unmigrated workspace.

## Redirect placeholder is followed once

A file at the legacy location whose content is a redirect placeholder resolves to
the location the placeholder names, and is **followed exactly once**. A
placeholder naming a subject directory that does not exist produces the
`redirect-unresolved` additional disclosure (see **Additional disclosures**) and
contributes no rules, so the status is whatever the remaining sources give —
`generic` when nothing else is found. Resolve does not follow any further
redirect.

Placeholder form — a single line naming the subject directory:

```
<!-- pw:redirect subjects/<subject-slug>/ -->
```

The placeholder exists so that an external consumer which tests for the legacy
path before handing it over continues to find that path present after migration.
See the consumer-contract section of the repository README.

## Migration is reversible

To reverse a migration:

1. For each redirect placeholder at a legacy path, replace the placeholder's
   content with the content of the corresponding `subjects/<subject>/core.md`.
2. Remove the subject directory.

Because legacy consultation is retained, a reversed workspace continues to
resolve — the rules are found at the legacy location and the outcome status is
`legacy`.

Migration itself is performed by the migration script shipped with this plugin.
The script creates subject directories with core files, replaces legacy files
with placeholders, and creates no facets: separating genre-specific content out
of a migrated core file is a judgment made when a second genre for that subject
first arises, and the script cannot make it.
