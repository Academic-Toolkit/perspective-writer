#!/usr/bin/env bash
# Assert that every skill agrees with the writing-rules resolution contract.
#
# The contract (references/rules-resolution.md) is prose read by a model, so nothing
# can verify that a skill *follows* it. What this checks is the layer below that: the
# skills all point at the same contract, none of them assembles a storage path of its
# own, and every section a skill cites actually exists.
#
# That layer is where the silent failure lives. When a write site and a read site
# address different locations, nothing errors — rules get written and never load, and
# the only symptom is that drafts stop sounding like the writer.
#
# Deliberately shape-agnostic: no assertion counts skills or names them. The skill set
# grew from four to five when the core/facet split landed and will grow again with each
# genre facet. Assertions about counts would break on every such change, and a check
# that cries wolf gets ignored — which is the same as not having one.
#
# Usage: check-contract-consistency.sh [repo-root]   (default: git toplevel, else cwd)
# Exit:  0 all assertions hold | 1 one or more failed | 2 usage / layout error

set -uo pipefail

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
PLUGIN="$ROOT/plugins/perspective-writer"
SKILLS="$PLUGIN/skills"
CONTRACT="$PLUGIN/references/rules-resolution.md"
README="$ROOT/README.md"

for required in "$SKILLS" "$CONTRACT" "$README"; do
  [ -e "$required" ] || { echo "✗ layout: missing $required" >&2; exit 2; }
done

# Files allowed to contain storage-path literals. The contract defines the paths, and
# the migration script operates on them; every other mention is an inline construction.
ALLOWLIST_RE='references/rules-resolution\.md|scripts/migrate-rules\.sh|scripts/check-contract-consistency\.sh'

LEGACY_PATH='\.claude/rules/correspondence'
NS_PATH='\.perspective-writer/(subjects|genres)'

fail=0
note() { printf '  %s\n' "$1"; }
bad()  { printf '✗ %s\n' "$1"; fail=1; }
ok()   { printf '✓ %s\n' "$1"; }

# --- 1. No skill constructs the legacy path ---------------------------------
hits=$(grep -rlE "$LEGACY_PATH" "$SKILLS" 2>/dev/null | grep -vE "$ALLOWLIST_RE" || true)
if [ -n "$hits" ]; then
  bad "a skill constructs the legacy storage path inline:"
  printf '%s\n' "$hits" | sed "s|^$ROOT/|    |"
  note "resolve/persist are defined in the contract — cite them instead of a path."
else
  ok "no skill constructs the legacy storage path"
fi

# --- 2. No skill constructs the namespace path ------------------------------
hits=$(grep -rlE "$NS_PATH" "$SKILLS" 2>/dev/null | grep -vE "$ALLOWLIST_RE" || true)
if [ -n "$hits" ]; then
  bad "a skill constructs the namespace storage path inline:"
  printf '%s\n' "$hits" | sed "s|^$ROOT/|    |"
else
  ok "no skill constructs the namespace storage path"
fi

# --- 3. Every cited contract section exists ---------------------------------
# Sections are the contract's own `## ` headings. A skill cites one by naming it on a
# line that also references the contract file, or in an italicised *Section name* near
# such a reference. Compare the cited set against the defined set.
SECTIONS=$(grep '^## ' "$CONTRACT" | sed 's/^## //')
missing=""
while IFS= read -r skill; do
  grep -q 'rules-resolution' "$skill" || continue          # skill does not use the contract
  while IFS= read -r cited; do
    printf '%s\n' "$SECTIONS" | grep -qxF "$cited" || missing="$missing\n    $(basename "$(dirname "$skill")") → $cited"
  done < <(grep -oE '\*[A-Z][A-Za-z ,'"'"'-]+\*' "$skill" \
            | tr -d '*' \
            | while IFS= read -r c; do printf '%s\n' "$SECTIONS" | grep -qxF "$c" && printf '%s\n' "$c"; done \
            | sort -u)
done < <(find "$SKILLS" -name SKILL.md)
if [ -n "$missing" ]; then
  bad "a skill cites a contract section that does not exist:"; printf "$missing\n"
else
  ok "every contract section cited by a skill exists"
fi

# --- 4. Reader-based split criterion still names its exceptions -------------
# The two categories with no read site in this plugin must stay in the injected rules
# directory, and the contract must say so with the reason. Losing this text is how the
# criterion degrades into folklore.
split_ok=1
for needed in 'Split criterion by reader' 'code-comment writing style' 'general writing style' 'no skill in this plugin reads them'; do
  grep -qF "$needed" "$CONTRACT" || { bad "contract no longer states: $needed"; split_ok=0; }
done
# Local flag, not the global one: an earlier assertion's failure must not suppress this
# assertion's result. A checker whose output makes a passing check look like a skipped
# one is a checker people stop trusting.
[ "$split_ok" -eq 1 ] && ok "split criterion and its named exceptions are intact"

# --- 5. Published contract names the three outcome statuses ----------------
for st in 'subject-specific' 'legacy' 'generic'; do
  grep -qF "\`$st\`" "$README" || bad "README does not name outcome status: $st"
done
grep -qF 'subject-specific' "$README" && grep -qF 'generic' "$README" && ok "README names the outcome statuses"

# --- 6. Blind-reader agents are actually isolated ---------------------------
# The native-syntax reader and the rules auditor are only blind if their subagent does not
# load the user's CLAUDE.md hierarchy. Claude Code ignores a frontmatter field it does not
# recognise, without any error — so a misspelt `omitClaudeMd` leaves the agent loading every
# CLAUDE.md and nothing anywhere says so. Same silent-failure shape as the rest of this file,
# so it gets the same kind of check. Shape-agnostic: loops over whatever agents exist, counts none.
#   (a) exact `omitClaudeMd: true` in the frontmatter
#   (b) an explicit `tools:` line (omitting it inherits every tool) with nothing that writes
#   (c) some skill dispatches it as perspective-writer:<name>, or it is dead weight
AGENTS="$PLUGIN/agents"
if [ -d "$AGENTS" ]; then
  agents_ok=1
  for agent in "$AGENTS"/*.md; do
    [ -e "$agent" ] || continue
    rel=${agent#"$ROOT"/}
    fm=$(awk 'NR==1 && $0!="---"{exit} NR==1{next} $0=="---"{exit} {print}' "$agent")
    aname=$(sed -n 's/^name:[[:space:]]*//p' <<<"$fm" | head -1)
    atools=$(sed -n 's/^tools:[[:space:]]*//p' <<<"$fm" | head -1)
    if ! grep -qE '^omitClaudeMd:[[:space:]]*true[[:space:]]*$' <<<"$fm"; then
      bad "$rel: frontmatter lacks exactly 'omitClaudeMd: true' (a misspelling is ignored silently)"; agents_ok=0
    fi
    if [ -z "$atools" ]; then
      bad "$rel: no 'tools:' line (an omitted tools field inherits every tool)"; agents_ok=0
    elif grep -qiE '(^|[,[:space:]\[])(Bash|Edit|Write|NotebookEdit)([,[:space:]\]]|$)' <<<"$atools"; then
      bad "$rel: a blind reader must be read-only, but tools: $atools"; agents_ok=0
    fi
    if [ -z "$aname" ]; then
      bad "$rel: frontmatter has no name"; agents_ok=0
    elif ! grep -rqF "perspective-writer:$aname" "$SKILLS"; then
      bad "$rel: no skill dispatches perspective-writer:$aname"; agents_ok=0
    fi
  done
  [ "$agents_ok" -eq 1 ] && ok "every plugin agent omits CLAUDE.md, is read-only, and is dispatched by a skill"
fi

# --- 7. Only plugin-rules.sh reads the installed-plugin record --------------
# The record is Claude Code's internal format and can change. Every read of it, and
# every path built into another plugin's installed directory to reach a file there,
# goes through scripts/plugin-rules.sh, so that a format change fails in one place and
# loudly (exit 3). A skill that read the record itself would keep working until the
# format moved, then stop loading the plugin's rules without any error.
#
# Matched: the record's filename, its `installPath` field, and a cache path that goes
# below a plugin's directory (cache/<marketplace>/<plugin>/...). Not matched: probes such
# as `ls -d ~/.claude/plugins/cache/*/<plugin>` in the core skill, which only test that
# a plugin is installed and read nothing inside it.
RECORD_RE='installed_plugins\.json|installPath|plugins/cache/[^/[:space:]]+/[^/[:space:]]+/[^[:space:]]'
RECORD_ALLOW_RE='references/rules-resolution\.md$|scripts/plugin-rules\.sh$|scripts/check-contract-consistency\.sh$'
hits=$(grep -rlE "$RECORD_RE" "$PLUGIN" 2>/dev/null | grep -vE "$RECORD_ALLOW_RE" || true)
if [ -n "$hits" ]; then
  bad "a file other than plugin-rules.sh reads the installed-plugin record or builds a path into a plugin:"
  printf '%s\n' "$hits" | sed "s|^$ROOT/|    |"
  note "call scripts/plugin-rules.sh (expand or import) instead."
else
  ok "only plugin-rules.sh reads the installed-plugin record"
fi

# A workspace rule file can be little more than one pw:include line. A skill that reads
# the raw file sees a comment and none of the rules it stands for, then proposes or
# writes rules that duplicate or contradict them. Every skill that resolves or persists
# rules must read them through plugin-rules.sh expand, as Phase 0b of the core skill
# does (#29).
READER_RE='Resolution order|resolve\(|\*\*persist\*\*|persist 只寫|Persist writes'
EXPAND_RE='plugin-rules\.sh"? expand'
unexpanded=""; ungranted=""
for skill in "$SKILLS"/*/SKILL.md; do
  grep -qE "$READER_RE" "$skill" || continue
  grep -qE "$EXPAND_RE" "$skill" || unexpanded="$unexpanded$skill"$'\n'
  # A skill that restricts its tools must be allowed to run the script it is told to
  # run; otherwise the expand step is blocked and the skill falls back to the raw file.
  # A grant matches the command text Claude sends (after ${CLAUDE_PLUGIN_ROOT} is
  # substituted in both places), so the skill must run the script in exactly the granted
  # form: no leading `bash`, no quotes around the path.
  tools=$(grep -m1 '^allowed-tools:' "$skill" || true)
  if [ -n "$tools" ]; then
    if ! printf '%s' "$tools" | grep -qF 'Bash(${CLAUDE_PLUGIN_ROOT}/scripts/plugin-rules.sh *)'; then
      ungranted="$ungranted$skill"$'\n'
    elif grep -qE '(bash[[:space:]]+"?\$\{CLAUDE_PLUGIN_ROOT\}|"\$\{CLAUDE_PLUGIN_ROOT\}/scripts/plugin-rules\.sh")' "$skill"; then
      ungranted="$ungranted$skill"$'\n'
    fi
  fi
done
if [ -n "$unexpanded" ]; then
  bad "a skill reads resolved rules without expanding them:"
  printf '%s' "$unexpanded" | sed "s|^$ROOT/|    |"
  note "run scripts/plugin-rules.sh expand on each file and read its stdout, as Phase 0b does."
else
  ok "every skill that reads resolved rules expands them first"
fi
if [ -n "$ungranted" ]; then
  bad "a skill told to run plugin-rules.sh expand restricts its tools without allowing it:"
  printf '%s' "$ungranted" | sed "s|^$ROOT/|    |"
  note "allow Bash(\${CLAUDE_PLUGIN_ROOT}/scripts/plugin-rules.sh *) and run the script in that form: \${CLAUDE_PLUGIN_ROOT}/scripts/plugin-rules.sh expand <file> 2>&1 (no leading bash, no quotes)."
else
  ok "every skill that expands rules may run plugin-rules.sh"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "contract consistency: OK"
else
  echo "contract consistency: FAILED — a write site and a read site may now disagree."
  echo "This failure mode is silent at runtime: rules get written and never load, and"
  echo "the only symptom is drafts that stop sounding like the writer."
fi
exit "$fail"
