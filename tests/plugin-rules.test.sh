#!/usr/bin/env bash
# Tests for plugins/perspective-writer/scripts/plugin-rules.sh (Academic-Toolkit/perspective-writer#25).
#
# Every case builds its own fake plugin directories and installed-plugin record under a
# temporary directory and points PW_INSTALLED_PLUGINS at it, so no case depends on the
# plugins installed on the machine running the tests.
#
# Each case checks stdout, the `pw:disclosure` lines on stderr, and the exit code. A
# failing case prints its name and what differed; the run exits non-zero if any case
# failed.
#
# Usage: bash tests/plugin-rules.test.sh
# Exit:  0 every case passed | 1 one or more cases failed | 2 the test environment is unusable

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/plugins/perspective-writer/scripts/plugin-rules.sh"

command -v jq >/dev/null 2>&1 || { echo "✗ jq is required to build the fake installed-plugin record" >&2; exit 2; }

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/pw-plugin-rules.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

passed=0
failed=0
failed_names=()

# ---------------------------------------------------------------------------
# Harness
# ---------------------------------------------------------------------------

T=""          # this case's temporary directory
WS=""         # this case's workspace rules namespace
CASE_OK=1
RC=0
ENTRIES=()    # "key|installPath|version" rows for the fake record

fail() { CASE_OK=0; printf '    ✗ %s\n' "$1"; }

new_case() {
  T="$TMP_ROOT/$1"
  WS="$T/ws/.claude/.perspective-writer"
  mkdir -p "$T/plugins" "$WS"
  export PW_INSTALLED_PLUGINS="$T/installed_plugins.json"
  ENTRIES=()
}

# plugin <key> <version>: create an installed directory for <key>, register it, and set
# PDIR to that directory. The record is written by write_record.
plugin() {
  PDIR="$T/plugins/${1//@/_}/$2"
  mkdir -p "$PDIR"
  ENTRIES+=("$1|$PDIR|$2")
}

# register <key> <installPath> <version> [<scope> <projectPath>]: add a record row
# without creating the directory. Scope defaults to user.
register() { ENTRIES+=("$1|$2|$3|${4:-user}|${5:-}"); }

# scoped_plugin <key> <version> <scope> <projectPath>: like plugin, with a scope.
scoped_plugin() {
  PDIR="$T/plugins/${1//@/_}-$3/$2"
  mkdir -p "$PDIR"
  ENTRIES+=("$1|$PDIR|$2|$3|$4")
}

write_record() {
  local json='{"version":2,"plugins":{}}' row key dir ver scope pp
  for row in "${ENTRIES[@]+"${ENTRIES[@]}"}"; do
    IFS='|' read -r key dir ver scope pp <<<"$row"
    json=$(jq --arg k "$key" --arg d "$dir" --arg v "$ver" --arg s "${scope:-user}" --arg p "$pp" \
      '.plugins[$k] += [{scope: $s, installPath: $d, version: $v} + (if $p == "" then {} else {projectPath: $p} end)]' <<<"$json")
  done
  printf '%s\n' "$json" >"$PW_INSTALLED_PLUGINS"
}

# file <path> <content>: write content verbatim (no trailing newline added).
file() { mkdir -p "$(dirname "$1")"; printf '%s' "$2" >"$1"; }

# PW_TEST_BASH selects the interpreter, so the suite can run under macOS's /bin/bash 3.2
# as well as a newer bash: PW_TEST_BASH=/bin/bash /bin/bash tests/plugin-rules.test.sh
run() {
  "${PW_TEST_BASH:-bash}" "$SCRIPT" "$@" >"$T/out" 2>"$T/err"
  RC=$?
}

sha256_of() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1
  else sha256sum "$1" | cut -d' ' -f1; fi
}

expect_rc() { [ "$RC" -eq "$1" ] || fail "exit code $RC, expected $1 (stderr: $(head -c 300 "$T/err"))"; }

expect_out() {  # exact stdout, given on stdin
  cat >"$T/expected"
  if ! cmp -s "$T/expected" "$T/out"; then
    fail "stdout differs from expected:"
    diff "$T/expected" "$T/out" | sed 's/^/      /'
  fi
}

expect_out_equals_file() { cmp -s "$1" "$T/out" || fail "stdout is not byte-identical to $(basename "$1")"; }
expect_out_lacks() { ! grep -qF -- "$1" "$T/out" || fail "stdout contains forbidden text: $1"; }
expect_err_has() { grep -qF -- "$1" "$T/err" || fail "stderr lacks: $1"; }

expect_no_disclosure() {
  if grep -q '^pw:disclosure ' "$T/err"; then
    fail "unexpected disclosure: $(grep '^pw:disclosure ' "$T/err" | head -3)"
  fi
}

# expect_disclosure <kind> <text...>: one disclosure line of <kind> contains every <text>.
expect_disclosure() {
  local kind="$1"; shift
  local lines
  lines=$(grep -E "^pw:disclosure $kind " "$T/err" || true)
  [ -n "$lines" ] || { fail "no $kind disclosure (stderr: $(head -c 300 "$T/err"))"; return; }
  local needle
  for needle in "$@"; do
    printf '%s\n' "$lines" | grep -qF -- "$needle" || fail "$kind disclosure lacks: $needle"
  done
}

expect_no_kind() {
  if grep -qE "^pw:disclosure $1 " "$T/err"; then fail "unexpected $1 disclosure"; fi
}

run_case() {
  CASE_OK=1
  printf '• %s\n' "$1"
  "$1"
  if [ "$CASE_OK" -eq 1 ]; then passed=$((passed + 1)); else failed=$((failed + 1)); failed_names+=("$1"); fi
}

include() { printf '<!-- pw:include plugin:%s -->' "$1"; }

# ---------------------------------------------------------------------------
# 2.1 Include line expands an installed plugin's rule file
# ---------------------------------------------------------------------------

case_expand_installed_file_present() {
  new_case expand_installed
  plugin tools@a 1.0.0
  file "$PDIR/rules.md" $'Rule A.\n'
  write_record
  file "$WS/genres/g.md" "Intro line
$(include tools@a/rules.md)
After line
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_no_disclosure
  expect_out <<'EOF'
Intro line
<!-- pw:source begin plugin:tools@a version:1.0.0 path:rules.md -->
Rule A.
<!-- pw:source end -->
After line
EOF
}

case_expand_spec_example() {
  new_case spec_example
  plugin grant-rules@example-plugins 0.7.0
  file "$PDIR/perspective-writer/genres/grant-proposal.md" $'Do not cite internal lab meetings.\n'
  write_record
  file "$WS/genres/grant-proposal.md" "$(include grant-rules@example-plugins/perspective-writer/genres/grant-proposal.md)
"
  run expand "$WS/genres/grant-proposal.md"
  expect_rc 0
  expect_no_disclosure
  expect_out <<'EOF'
<!-- pw:source begin plugin:grant-rules@example-plugins version:0.7.0 path:perspective-writer/genres/grant-proposal.md -->
Do not cite internal lab meetings.
<!-- pw:source end -->
EOF
}

case_included_file_without_trailing_newline() {
  new_case no_trailing_newline
  plugin tools@a 1.0.0
  file "$PDIR/rules.md" 'Rule A.'
  write_record
  file "$WS/genres/g.md" "$(include tools@a/rules.md)
Workspace rule.
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_out <<'EOF'
<!-- pw:source begin plugin:tools@a version:1.0.0 path:rules.md -->
Rule A.
<!-- pw:source end -->
Workspace rule.
EOF
}

# ---------------------------------------------------------------------------
# 2.2 Marketplace omitted only when unambiguous
# ---------------------------------------------------------------------------

case_marketplace_omitted_ambiguous() {
  new_case ambiguous
  plugin tools@a 1.0.0; file "$PDIR/rules.md" $'A\n'
  plugin tools@b 1.0.0; file "$PDIR/rules.md" $'B\n'
  write_record
  file "$WS/genres/g.md" "$(include tools/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_out_equals_file "$WS/genres/g.md"
  expect_disclosure include-unresolved "plugin:tools/rules.md" "tools@a" "tools@b"
}

case_marketplace_omitted_unique() {
  new_case unique
  plugin tools@a 1.0.0; file "$PDIR/rules.md" $'A\n'
  plugin toolsmith@a 1.0.0; file "$PDIR/rules.md" $'not this one\n'
  write_record
  file "$WS/genres/g.md" "$(include tools/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_no_disclosure
  expect_out <<'EOF'
<!-- pw:source begin plugin:tools@a version:1.0.0 path:rules.md -->
A
<!-- pw:source end -->
EOF
}

# ---------------------------------------------------------------------------
# 2.3 Missing plugin or file is disclosed, not dropped silently
# ---------------------------------------------------------------------------

case_plugin_not_installed() {
  new_case not_installed
  plugin tools@a 1.0.0; file "$PDIR/rules.md" $'A\n'
  write_record
  file "$WS/genres/g.md" "$(include other@a/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_out_equals_file "$WS/genres/g.md"
  expect_disclosure include-unresolved "plugin:other@a/rules.md"
}

case_file_missing_in_plugin() {
  new_case file_missing
  plugin tools@a 1.0.0; file "$PDIR/rules.md" $'A\n'
  write_record
  file "$WS/genres/g.md" "$(include tools@a/missing.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_out_equals_file "$WS/genres/g.md"
  expect_disclosure include-unresolved "missing.md"
}

case_malformed_include_disclosed() {
  # A mistyped include line must not pass silently as ordinary text: its rules would be
  # missing with no signal. It needs no record, because nothing can be resolved.
  new_case malformed
  export PW_INSTALLED_PLUGINS="$T/does-not-exist.json"
  file "$WS/genres/g.md" $'Rule one.\n<!-- pw:include tools@a/rules.md -->\n'
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_out_equals_file "$WS/genres/g.md"
  expect_disclosure include-unresolved "line:2"
}

case_install_path_missing() {
  new_case install_path_missing
  register tools@a "$T/plugins/gone" 1.0.0
  write_record
  file "$WS/genres/g.md" "$(include tools@a/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_out_equals_file "$WS/genres/g.md"
  expect_disclosure include-unresolved "plugin:tools@a/rules.md"
}

# ---------------------------------------------------------------------------
# 2.4 Nested include is not expanded
# ---------------------------------------------------------------------------

case_nested_include() {
  new_case nested
  plugin tools@a 1.0.0
  file "$PDIR/outer.md" "Outer rule.
$(include tools@a/inner.md)
"
  file "$PDIR/inner.md" $'INNER RULE\n'
  write_record
  file "$WS/genres/g.md" "$(include tools@a/outer.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_out_lacks "INNER RULE"
  expect_disclosure include-nested "plugin:tools@a/inner.md" "outer.md"
  expect_out <<'EOF'
<!-- pw:source begin plugin:tools@a version:1.0.0 path:outer.md -->
Outer rule.
<!-- pw:include plugin:tools@a/inner.md -->
<!-- pw:source end -->
EOF
}

# ---------------------------------------------------------------------------
# 2.5 Included paths stay inside the plugin and are Markdown
# ---------------------------------------------------------------------------

case_path_escapes_plugin() {
  new_case dotdot
  plugin tools@a 1.0.0
  file "$T/secret.md" $'SECRET\n'
  write_record
  file "$WS/genres/g.md" "$(include tools@a/../../../secret.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_out_lacks "SECRET"
  expect_out_equals_file "$WS/genres/g.md"
  expect_disclosure include-unresolved "secret.md"
}

case_symlink_pointing_outside() {
  new_case symlink
  plugin tools@a 1.0.0
  file "$T/secret.md" $'SECRET\n'
  ln -s "$T/secret.md" "$PDIR/link.md"
  write_record
  file "$WS/genres/g.md" "$(include tools@a/link.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_out_lacks "SECRET"
  expect_disclosure include-unresolved "link.md"
}

case_absolute_path_rejected() {
  new_case absolute
  plugin tools@a 1.0.0
  file "$T/secret.md" $'SECRET\n'
  write_record
  file "$WS/genres/g.md" "$(include "tools@a/$T/secret.md")
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_out_lacks "SECRET"
  expect_disclosure include-unresolved "secret.md"
}

case_non_markdown_rejected() {
  new_case non_markdown
  plugin tools@a 1.0.0
  file "$PDIR/rules.txt" $'TEXT RULE\n'
  write_record
  file "$WS/genres/g.md" "$(include tools@a/rules.txt)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_out_lacks "TEXT RULE"
  expect_disclosure include-unresolved "rules.txt"
}

case_import_unsafe_path() {
  new_case import_unsafe
  plugin tools@a 1.0.0
  file "$T/secret.md" $'SECRET\n'
  write_record
  run import "plugin:tools@a/../../../secret.md" --genre x --workspace "$WS"
  expect_rc 2
  [ ! -e "$WS/genres/x.md" ] || fail "import wrote a file for an unsafe path"
}

# ---------------------------------------------------------------------------
# 2.6 Import writes a provenance header and refuses to overwrite
# ---------------------------------------------------------------------------

check_imported_copy() {  # check_imported_copy <copy> <source> <key> <version> <path>
  local header rest_file="$T/rest"
  header=$(head -n 1 "$1")
  local re="^<!-- pw:imported plugin:$3 version:$4 path:$5 sha256:$(sha256_of "$2") date:[0-9]{4}-[0-9]{2}-[0-9]{2} -->$"
  printf '%s\n' "$header" | grep -qE -- "$re" || fail "header mismatch: $header"
  tail -n +2 "$1" >"$rest_file"
  cmp -s "$rest_file" "$2" || fail "body of $(basename "$1") differs from the source"
}

case_import_genre() {
  new_case import_genre
  plugin tools@a 1.2.0
  file "$PDIR/genres/x.md" $'X rules.\nSecond line.\n'
  write_record
  run import "plugin:tools@a/genres/x.md" --genre x --workspace "$WS"
  expect_rc 0
  [ -f "$WS/genres/x.md" ] || { fail "genres/x.md was not written"; return; }
  grep -qF "$WS/genres/x.md" "$T/out" || fail "stdout does not name the written path"
  check_imported_copy "$WS/genres/x.md" "$PDIR/genres/x.md" tools@a 1.2.0 genres/x.md
}

case_import_subject_core() {
  new_case import_subject
  plugin tools@a 1.2.0
  file "$PDIR/subjects/s.md" $'Subject rules.\n'
  write_record
  run import "plugin:tools@a/subjects/s.md" --subject alice --workspace "$WS"
  expect_rc 0
  [ -f "$WS/subjects/alice/core.md" ] || { fail "subjects/alice/core.md was not written"; return; }
  check_imported_copy "$WS/subjects/alice/core.md" "$PDIR/subjects/s.md" tools@a 1.2.0 subjects/s.md
}

case_import_subject_genre() {
  new_case import_subject_genre
  plugin tools@a 1.2.0
  file "$PDIR/genres/grant-proposal.md" $'Facet rules.\n'
  write_record
  run import "plugin:tools/genres/grant-proposal.md" --subject alice --genre grant-proposal --workspace "$WS"
  expect_rc 0
  [ -f "$WS/subjects/alice/grant-proposal.md" ] || { fail "subjects/alice/grant-proposal.md was not written"; return; }
  check_imported_copy "$WS/subjects/alice/grant-proposal.md" "$PDIR/genres/grant-proposal.md" tools@a 1.2.0 genres/grant-proposal.md
}

case_import_target_exists() {
  new_case import_exists
  plugin tools@a 1.2.0
  file "$PDIR/genres/x.md" $'X rules.\n'
  write_record
  file "$WS/genres/x.md" $'local rules\n'
  run import "plugin:tools@a/genres/x.md" --genre x --workspace "$WS"
  expect_rc 4
  [ "$(cat "$WS/genres/x.md")" = "local rules" ] || fail "existing target was modified"
}

case_import_force_overwrites() {
  new_case import_force
  plugin tools@a 1.2.0
  file "$PDIR/genres/x.md" $'X rules.\n'
  write_record
  file "$WS/genres/x.md" $'local rules\n'
  run import "plugin:tools@a/genres/x.md" --genre x --workspace "$WS" --force
  expect_rc 0
  check_imported_copy "$WS/genres/x.md" "$PDIR/genres/x.md" tools@a 1.2.0 genres/x.md
}

case_import_invalid_slug() {
  new_case import_slug
  plugin tools@a 1.2.0
  file "$PDIR/genres/x.md" $'X rules.\n'
  write_record
  local slug
  for slug in "../x" "X" "-x" "a/b" ""; do
    run import "plugin:tools@a/genres/x.md" --genre "$slug" --workspace "$WS"
    [ "$RC" -eq 2 ] || fail "slug '$slug': exit code $RC, expected 2"
  done
  [ -z "$(find "$T/ws" -type f)" ] || fail "an invalid slug wrote a file: $(find "$T/ws" -type f)"
}

case_import_needs_target() {
  new_case import_no_target
  plugin tools@a 1.2.0
  file "$PDIR/genres/x.md" $'X rules.\n'
  write_record
  run import "plugin:tools@a/genres/x.md" --workspace "$WS"
  expect_rc 2
}

case_import_unresolved_reference() {
  new_case import_unresolved
  plugin tools@a 1.2.0
  write_record
  run import "plugin:tools@a/genres/missing.md" --genre x --workspace "$WS"
  expect_rc 2
  run import "plugin:nope@a/genres/x.md" --genre x --workspace "$WS"
  expect_rc 2
  [ ! -e "$WS/genres/x.md" ] || fail "an unresolved import wrote a file"
}

# ---------------------------------------------------------------------------
# 2.7 Stale import is disclosed by comparing the source hash
# ---------------------------------------------------------------------------

import_fixture() {  # import tools@a/genres/x.md into genres/x.md
  plugin tools@a 1.2.0
  SRC="$PDIR/genres/x.md"
  file "$SRC" $'X rules.\n'
  write_record
  run import "plugin:tools@a/genres/x.md" --genre x --workspace "$WS"
  [ "$RC" -eq 0 ] || fail "fixture import failed (exit $RC)"
  COPY="$WS/genres/x.md"
}

case_fresh_import_not_stale() {
  new_case fresh_import
  import_fixture
  run expand "$COPY"
  expect_rc 0
  expect_no_disclosure
  expect_out_equals_file "$COPY"
}

case_stale_when_source_changed() {
  new_case stale_changed
  import_fixture
  printf 'Changed upstream.\n' >>"$SRC"
  run expand "$COPY"
  expect_rc 0
  expect_disclosure import-stale "plugin:tools@a/genres/x.md"
}

case_local_copy_edit_not_stale() {
  new_case local_edit
  import_fixture
  printf 'My local addition.\n' >>"$COPY"
  run expand "$COPY"
  expect_rc 0
  expect_no_kind import-stale
  expect_out_equals_file "$COPY"
}

case_stale_when_source_removed() {
  new_case stale_removed
  import_fixture
  rm "$SRC"
  run expand "$COPY"
  expect_rc 0
  expect_disclosure import-stale "plugin:tools@a/genres/x.md"
}

# ---------------------------------------------------------------------------
# 2.8 Only plugin-rules.sh reads the installed-plugin record
# ---------------------------------------------------------------------------

case_no_include_needs_no_record() {
  new_case no_include
  export PW_INSTALLED_PLUGINS="$T/does-not-exist.json"
  file "$WS/genres/g.md" $'Plain rule one.\nPlain rule two, no trailing newline'
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_no_disclosure
  expect_out_equals_file "$WS/genres/g.md"
}

case_record_wrong_version() {
  new_case wrong_version
  printf '{"version":1,"plugins":{}}\n' >"$PW_INSTALLED_PLUGINS"
  file "$WS/genres/g.md" "$(include tools@a/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 3
  expect_err_has "$PW_INSTALLED_PLUGINS"
  [ ! -s "$T/out" ] || fail "stdout is not empty after a record failure"
}

case_record_missing_with_include() {
  new_case record_missing
  export PW_INSTALLED_PLUGINS="$T/does-not-exist.json"
  file "$WS/genres/g.md" "$(include tools@a/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 3
  expect_err_has "$PW_INSTALLED_PLUGINS"
}

case_record_not_json() {
  new_case record_garbage
  printf 'not json at all\n' >"$PW_INSTALLED_PLUGINS"
  file "$WS/genres/g.md" "$(include tools@a/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 3
  expect_err_has "$PW_INSTALLED_PLUGINS"
}

case_import_record_wrong_shape() {
  new_case import_wrong_shape
  printf '{"version":2,"plugins":[]}\n' >"$PW_INSTALLED_PLUGINS"
  run import "plugin:tools@a/genres/x.md" --genre x --workspace "$WS"
  expect_rc 3
}

case_first_existing_install_path_wins() {
  new_case first_existing
  register tools@a "$T/plugins/stale-copy" 1.0.0
  plugin tools@a 2.0.0
  file "$PDIR/rules.md" $'Current rule.\n'
  write_record
  file "$WS/genres/g.md" "$(include tools@a/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_no_disclosure
  expect_out <<'EOF'
<!-- pw:source begin plugin:tools@a version:2.0.0 path:rules.md -->
Current rule.
<!-- pw:source end -->
EOF
}

# ---------------------------------------------------------------------------
# Verify round 1 findings (#25): scope selection, record entries, version token,
# import through a symlink, fences, forged markers, malformed nested includes,
# and the consistency check's record assertion
# ---------------------------------------------------------------------------

case_scope_other_project_ignored() {
  new_case scope_other
  mkdir -p "$T/other"
  scoped_plugin tools@a 9.9 project "$T/other"; file "$PDIR/rules.md" $'OTHER PROJECT RULE\n'
  scoped_plugin tools@a 1.0.0 user "";          file "$PDIR/rules.md" $'User rule.\n'
  write_record
  file "$WS/genres/g.md" "$(include tools@a/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_no_disclosure
  expect_out_lacks "OTHER PROJECT RULE"
  expect_out <<'EOF'
<!-- pw:source begin plugin:tools@a version:1.0.0 path:rules.md -->
User rule.
<!-- pw:source end -->
EOF
}

case_scope_matching_project_wins() {
  new_case scope_match
  scoped_plugin tools@a 1.0.0 user "";           file "$PDIR/rules.md" $'User rule.\n'
  scoped_plugin tools@a 2.0.0 project "$T/ws";  file "$PDIR/rules.md" $'Project rule.\n'
  write_record
  file "$WS/genres/g.md" "$(include tools@a/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_no_disclosure
  expect_out <<'EOF'
<!-- pw:source begin plugin:tools@a version:2.0.0 path:rules.md -->
Project rule.
<!-- pw:source end -->
EOF
}

case_scope_only_other_project() {
  new_case scope_only_other
  mkdir -p "$T/other"
  scoped_plugin tools@a 9.9 project "$T/other"; file "$PDIR/rules.md" $'OTHER PROJECT RULE\n'
  write_record
  file "$WS/genres/g.md" "$(include tools@a/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_out_lacks "OTHER PROJECT RULE"
  expect_disclosure include-unresolved "plugin:tools@a/rules.md" "other projects"
}

case_record_entry_not_object() {
  new_case entry_not_object
  printf '{"version":2,"plugins":{"tools@a":[{}]}}\n' >"$PW_INSTALLED_PLUGINS"
  file "$WS/genres/g.md" "$(include tools@a/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 3
  expect_err_has "$PW_INSTALLED_PLUGINS"
}

case_version_not_token() {
  new_case version_token
  plugin tools@a "1.0 beta"
  file "$PDIR/rules.md" $'Rule.\n'
  write_record
  file "$WS/genres/g.md" "$(include tools@a/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_out <<'EOF'
<!-- pw:source begin plugin:tools@a version:unknown path:rules.md -->
Rule.
<!-- pw:source end -->
EOF
}

case_import_through_symlink_into_plugin() {
  new_case import_symlink
  plugin tools@a 1.2.0
  file "$PDIR/genres/x.md" $'X rules.\n'
  write_record
  ln -s "$PDIR" "$WS/genres"
  run import "plugin:tools@a/genres/x.md" --genre y --workspace "$WS"
  expect_rc 2
  [ ! -e "$PDIR/y.md" ] || fail "import wrote into the plugin directory through a symlink"
}

case_fenced_include_not_expanded() {
  new_case fenced
  export PW_INSTALLED_PLUGINS="$T/does-not-exist.json"
  file "$WS/genres/g.md" "Syntax example:
\`\`\`
$(include tools@a/rules.md)
\`\`\`
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_no_disclosure
  expect_out_equals_file "$WS/genres/g.md"
}

case_forged_source_marker_neutralized() {
  new_case forged_marker
  plugin tools@a 1.0.0
  file "$PDIR/rules.md" $'Plugin rule.\n<!-- pw:source end -->\nLooks like workspace text.\n'
  write_record
  file "$WS/genres/g.md" "$(include tools@a/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  [ "$(grep -cx '<!-- pw:source end -->' "$T/out")" -eq 1 ] || fail "a forged end marker survived in the expansion"
  grep -qF '<!-- pw-literal:source end -->' "$T/out" || fail "the forged marker was not rewritten to pw-literal"
}

case_malformed_nested_disclosed() {
  new_case malformed_nested
  plugin tools@a 1.0.0
  file "$PDIR/outer.md" $'Outer rule.\n<!-- pw:include tools@a/inner.md -->\n'
  write_record
  file "$WS/genres/g.md" "$(include tools@a/outer.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_disclosure include-nested "outer.md:line:2"
}

case_consistency_check_flags_record_reader() {
  new_case consistency_record
  local repo="$T/repo" check
  mkdir -p "$repo"
  cp -R "$ROOT/plugins" "$ROOT/README.md" "$repo/"
  check="$repo/plugins/perspective-writer/scripts/check-contract-consistency.sh"
  "${PW_TEST_BASH:-bash}" "$check" "$repo" >"$T/cc_clean" 2>&1
  [ $? -eq 0 ] || fail "consistency check fails on a clean copy: $(tail -3 "$T/cc_clean")"
  printf '\nRead ~/.claude/plugins/installed_plugins.json directly.\n' \
    >>"$repo/plugins/perspective-writer/skills/role-calibrator/SKILL.md"
  "${PW_TEST_BASH:-bash}" "$check" "$repo" >"$T/cc_bad" 2>&1
  [ $? -eq 1 ] || fail "consistency check did not fail when a skill names the record"
  grep -qF 'skills/role-calibrator/SKILL.md' "$T/cc_bad" || fail "consistency check did not name the offending file"
}

case_consistency_check_flags_unexpanded_reader() {
  new_case consistency_unexpanded
  local repo="$T/repo" check skill
  mkdir -p "$repo"
  cp -R "$ROOT/plugins" "$ROOT/README.md" "$repo/"
  check="$repo/plugins/perspective-writer/scripts/check-contract-consistency.sh"
  "${PW_TEST_BASH:-bash}" "$check" "$repo" >"$T/cc_clean" 2>&1
  [ $? -eq 0 ] || fail "consistency check fails on a clean copy: $(tail -3 "$T/cc_clean")"
  skill="$repo/plugins/perspective-writer/skills/save-feedback/SKILL.md"
  sed 's/plugin-rules\.sh" expand/plugin-rules.sh" read/g; s/plugin-rules\.sh expand/plugin-rules.sh read/g' "$skill" >"$T/sf" && cp "$T/sf" "$skill"
  "${PW_TEST_BASH:-bash}" "$check" "$repo" >"$T/cc_bad" 2>&1
  [ $? -eq 1 ] || fail "consistency check did not fail when a rule-reading skill stops expanding"
  grep -qF 'skills/save-feedback/SKILL.md' "$T/cc_bad" || fail "consistency check did not name the unexpanded skill"
}

case_consistency_check_flags_reader_without_bash_grant() {
  new_case consistency_bash_grant
  local repo="$T/repo" check skill
  mkdir -p "$repo"
  cp -R "$ROOT/plugins" "$ROOT/README.md" "$repo/"
  check="$repo/plugins/perspective-writer/scripts/check-contract-consistency.sh"
  "${PW_TEST_BASH:-bash}" "$check" "$repo" >"$T/cc_clean" 2>&1
  [ $? -eq 0 ] || fail "consistency check fails on a clean copy: $(tail -3 "$T/cc_clean")"
  skill="$repo/plugins/perspective-writer/skills/role-calibrator/SKILL.md"
  sed 's/Bash(\${CLAUDE_PLUGIN_ROOT}\/scripts\/plugin-rules\.sh \*), //' "$skill" >"$T/rc" && cp "$T/rc" "$skill"
  "${PW_TEST_BASH:-bash}" "$check" "$repo" >"$T/cc_bad" 2>&1
  [ $? -eq 1 ] || fail "consistency check did not fail when a rule-reading skill cannot run plugin-rules.sh"
  grep -qF 'skills/role-calibrator/SKILL.md' "$T/cc_bad" || fail "consistency check did not name the skill without the grant"
}

case_consistency_check_flags_invocation_outside_the_grant() {
  # A grant matches the command text, so `bash "<path>" expand` is not covered by
  # Bash(<path> *); the step would be blocked in a skill that restricts its tools.
  new_case consistency_invocation_form
  local repo="$T/repo" check skill
  mkdir -p "$repo"
  cp -R "$ROOT/plugins" "$ROOT/README.md" "$repo/"
  check="$repo/plugins/perspective-writer/scripts/check-contract-consistency.sh"
  skill="$repo/plugins/perspective-writer/skills/role-calibrator/SKILL.md"
  sed 's|^\${CLAUDE_PLUGIN_ROOT}/scripts/plugin-rules\.sh expand|bash "${CLAUDE_PLUGIN_ROOT}/scripts/plugin-rules.sh" expand|' "$skill" >"$T/rc" && cp "$T/rc" "$skill"
  grep -qF 'bash "${CLAUDE_PLUGIN_ROOT}/scripts/plugin-rules.sh" expand' "$skill" || fail "test setup: role-calibrator has no invocation to rewrite"
  "${PW_TEST_BASH:-bash}" "$check" "$repo" >"$T/cc_bad" 2>&1
  [ $? -eq 1 ] || fail "consistency check did not fail on an invocation the grant does not cover"
  grep -qF 'skills/role-calibrator/SKILL.md' "$T/cc_bad" || fail "consistency check did not name the skill with the mismatched invocation"
}

# ---------------------------------------------------------------------------
# Verify round 2 findings (#25): fence lengths, indented code, plain comments,
# import onto a directory
# ---------------------------------------------------------------------------

case_nested_fence_lengths() {
  new_case fence_lengths
  plugin tools@a 1.0.0
  file "$PDIR/rules.md" $'Real rule.\n'
  write_record
  file "$WS/genres/g.md" "\`\`\`\`markdown
\`\`\`
$(include tools@a/example.md)
\`\`\`
\`\`\`\`
$(include tools@a/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_no_disclosure
  grep -qF 'Real rule.' "$T/out" || fail "the include after a four-backtick fence was not expanded"
  grep -qF '<!-- pw:include plugin:tools@a/example.md -->' "$T/out" || fail "the fenced example include was altered"
}

case_indented_include_is_code() {
  new_case indented
  export PW_INSTALLED_PLUGINS="$T/does-not-exist.json"
  file "$WS/genres/g.md" "Example:

    $(include tools@a/rules.md)
"
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_no_disclosure
  expect_out_equals_file "$WS/genres/g.md"
}

case_plain_comment_not_flagged() {
  new_case plain_comment
  export PW_INSTALLED_PLUGINS="$T/does-not-exist.json"
  file "$WS/genres/g.md" $'Rule.\n<!-- note: the pw:include syntax is described in the README -->\n'
  run expand "$WS/genres/g.md"
  expect_rc 0
  expect_no_disclosure
  expect_out_equals_file "$WS/genres/g.md"
}

case_import_force_onto_directory() {
  new_case import_dir
  plugin tools@a 1.2.0
  file "$PDIR/genres/x.md" $'X rules.\n'
  write_record
  mkdir -p "$WS/genres/x.md"
  run import "plugin:tools@a/genres/x.md" --genre x --workspace "$WS" --force
  expect_rc 2
  [ -z "$(find "$WS/genres" -type f)" ] || fail "import left a file behind: $(find "$WS/genres" -type f)"
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

case_usage_errors() {
  new_case usage
  run
  expect_rc 2
  run expand
  expect_rc 2
  run expand "$T/no-such-file.md"
  expect_rc 2
  run frobnicate x
  expect_rc 2
}

# ---------------------------------------------------------------------------

for c in $(declare -F | awk '{print $3}' | grep '^case_'); do
  run_case "$c"
done

echo
echo "passed: $passed | failed: $failed"
if [ "$failed" -gt 0 ]; then
  printf 'failed cases:\n'
  printf '  %s\n' "${failed_names[@]}"
  exit 1
fi
