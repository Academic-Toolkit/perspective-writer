#!/usr/bin/env bash
# Expand and import writing rules that other installed plugins publish
# (Academic-Toolkit/perspective-writer#25).
#
# Apart from the resolution contract (references/rules-resolution.md), this is the only
# file in perspective-writer that reads Claude Code's installed-plugin record or builds a
# path into a plugin's installed directory. Skills call this script; they never locate
# plugin files themselves. check-contract-consistency.sh enforces that.
#
#   expand <file>
#       Print <file> with every include line
#           <!-- pw:include plugin:<name>[@<marketplace>]/<path> -->
#       replaced by the named file's content, wrapped in
#           <!-- pw:source begin plugin:<key> version:<version> path:<path> -->
#           <!-- pw:source end -->
#       All other lines are printed unchanged and in order. A line that cannot be
#       expanded is printed unchanged. Lines inside a fenced code block (``` or ~~~) are
#       never include lines. Included content is not expanded again: an include line
#       inside it is printed as is and reported. Inside included content, the text
#       "pw:source" and "pw:imported" is rewritten to "pw-literal:...", so a plugin file
#       cannot forge the markers that delimit it. If the first line is an imported header
#       (see import), the named source is hashed again; a different hash, or a source
#       that can no longer be found, is reported as import-stale.
#
#       Every problem is one line on stderr:
#           pw:disclosure <kind> <target> — <reason>
#       <kind> is one of include-unresolved, include-nested, import-stale.
#
#   import plugin:<name>[@<marketplace>]/<path>
#          (--genre <slug> | --subject <slug> [--genre <slug>]) [--workspace <dir>] [--force]
#       Copy the named file into the workspace rules namespace, first line
#           <!-- pw:imported plugin:<key> version:<version> path:<path> sha256:<hex> date:<YYYY-MM-DD> -->
#       Target: --genre      -> genres/<slug>.md
#               --subject    -> subjects/<slug>/core.md
#               both         -> subjects/<subject>/<genre>.md
#       <slug> matches ^[a-z0-9][a-z0-9-]*$. Default workspace:
#       <git toplevel, else the current directory>/.claude/.perspective-writer.
#       Never writes inside an installed plugin's directory, including through a
#       symbolic link in the workspace. Prints the written path.
#
# Installed-plugin record: $PW_INSTALLED_PLUGINS, default
# $HOME/.claude/plugins/installed_plugins.json. Only the `version: 2` shape is read
# (`plugins` maps "<name>@<marketplace>" to an array of objects with a string
# `installPath` and optional string `version`, `scope`, `projectPath`); any other shape
# is a hard failure, never a guess. A file with no include line and no imported header
# is printed without reading the record.
#
# Choosing among several entries for one key: an entry whose installPath does not exist
# is ignored. A `project` or `local` entry counts only when its projectPath contains the
# directory being worked on (the rules file's directory for expand, the workspace for
# import); entries for other projects are ignored. Among the rest, local beats project
# beats every other scope (user), a longer projectPath beats a shorter one, and
# otherwise the first entry wins. A version that is not a plain token
# ([0-9A-Za-z._+-]) is recorded as "unknown".
#
# A path inside a plugin must be relative, contain no `..` segment and no whitespace,
# end in `.md`, and still lie inside the plugin's installed directory after symbolic
# links are resolved. A path that fails any of these is never read.
#
# Exit codes
#   expand  0 done (disclosures may be present) | 2 usage error or unreadable file
#           3 the record is needed but unreadable or not the version 2 shape
#   import  0 written | 2 usage error, unresolvable reference, unsafe path, or a target
#           that cannot be written | 3 the record is unreadable or not the version 2
#           shape | 4 the target exists and --force is absent
#
# Requires jq, and shasum or sha256sum. Written for bash 3.2, the version macOS ships.

set -uo pipefail

RECORD="${PW_INSTALLED_PLUGINS:-$HOME/.claude/plugins/installed_plugins.json}"
INCLUDE_RE='^[[:space:]]*<!-- pw:include plugin:([^[:space:]]+) -->[[:space:]]*$'
IMPORTED_RE='^<!-- pw:imported plugin:([^[:space:]]+) version:([^[:space:]]+) path:([^[:space:]]+) sha256:([0-9a-f]{64}) date:([0-9]{4}-[0-9]{2}-[0-9]{2}) -->$'
FENCE_RE='^[[:space:]]*(```|~~~)'
IMPORTED_PREFIX='<!-- pw:imported '
SLUG_RE='^[a-z0-9][a-z0-9-]*$'
SEP=$'\x1f'          # field separator for record rows: not IFS whitespace, so empty fields survive
CTX_DIR=""           # physical directory the current operation works on (scope matching)

usage() {
  cat <<'EOF'
usage: plugin-rules.sh expand <file>
       plugin-rules.sh import plugin:<name>[@<marketplace>]/<path>
                      (--genre <slug> | --subject <slug> [--genre <slug>])
                      [--workspace <dir>] [--force]
EOF
}

die() { local code="$1"; shift; printf 'plugin-rules.sh: %s\n' "$*" >&2; exit "$code"; }
disclose() { printf 'pw:disclosure %s %s — %s\n' "$1" "$2" "$3" >&2; }

# --- installed-plugin record ------------------------------------------------

# Run in the main shell (not inside $(...)) so that a failure exits the script.
load_record() {
  command -v jq >/dev/null 2>&1 || die 3 "jq is required to read the installed-plugin record $RECORD"
  [ -f "$RECORD" ] && [ -r "$RECORD" ] || die 3 "cannot read the installed-plugin record $RECORD"
  jq -e '.version == 2 and (.plugins | type == "object")
         and ([.plugins[] | type == "array" and all(.[]; type == "object"
               and (.installPath | type) == "string"
               and ((.version // "") | type) == "string"
               and ((.scope // "") | type) == "string"
               and ((.projectPath // "") | type) == "string")] | all)' \
    "$RECORD" >/dev/null 2>&1 \
    || die 3 "the installed-plugin record $RECORD is not the version 2 shape this script reads"
}

SHA_TOOL=""
pick_sha_tool() {
  if command -v shasum >/dev/null 2>&1; then SHA_TOOL="shasum -a 256"
  elif command -v sha256sum >/dev/null 2>&1; then SHA_TOOL="sha256sum"
  else die 3 "shasum or sha256sum is required to hash plugin rule files"; fi
}

sha256_of() { $SHA_TOOL "$1" | cut -d' ' -f1; }

realpath_of() {
  if command -v realpath >/dev/null 2>&1; then realpath "$1" 2>/dev/null
  else python3 -I -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"; fi
}

# nearest_existing <path>: print the closest ancestor-or-self of <path> that exists.
nearest_existing() {
  local p="$1"
  while [ ! -e "$p" ]; do
    [ "$p" = "/" ] || [ "$p" = "." ] && break
    p=$(dirname "$p")
  done
  printf '%s\n' "$p"
}

# check_path <path>: lexical safety checks; sets R_REASON on failure.
check_path() {
  local p="$1"
  case "$p" in
    "")              R_REASON="the reference has no path inside the plugin"; return 1 ;;
    /*)              R_REASON="$p is absolute; paths are relative to the plugin's installed directory"; return 1 ;;
    *[[:space:]]*)   R_REASON="$p contains whitespace"; return 1 ;;
  esac
  case "/$p/" in */../*) R_REASON="$p contains a .. segment"; return 1 ;; esac
  case "$p" in *.md) ;; *) R_REASON="$p is not a Markdown (.md) file"; return 1 ;; esac
  return 0
}

# select_install <key>: choose the record entry for <key> (see the header), setting
# S_DIR and S_VERSION. Returns 1 with R_REASON set when no entry applies.
select_install() {
  local key="$1" dir ver scope pp pp_real rank best_rank=0 best_len=-1 other_project=0
  S_DIR=""; S_VERSION=""
  while IFS="$SEP" read -r dir ver scope pp; do
    [ -n "$dir" ] && [ -d "$dir" ] || continue
    pp_real=""
    case "$scope" in
      local|project)
        if [ -z "$pp" ] || [ ! -d "$pp" ]; then other_project=1; continue; fi
        pp_real=$(realpath_of "$pp") || { other_project=1; continue; }
        case "$CTX_DIR/" in "$pp_real/"*) ;; *) other_project=1; continue ;; esac
        if [ "$scope" = local ]; then rank=3; else rank=2; fi
        ;;
      *) rank=1 ;;
    esac
    if [ "$rank" -gt "$best_rank" ] || { [ "$rank" -eq "$best_rank" ] && [ "${#pp_real}" -gt "$best_len" ]; }; then
      best_rank=$rank; best_len=${#pp_real}; S_DIR=$dir; S_VERSION=$ver
    fi
  done < <(jq -r --arg k "$key" --arg s "$SEP" \
             '.plugins[$k][] | [(.installPath // ""), (.version // ""), (.scope // ""), (.projectPath // "")] | join($s)' \
             "$RECORD")
  if [ "$best_rank" -eq 0 ]; then
    if [ "$other_project" -eq 1 ]; then
      R_REASON="plugin $key is installed only for other projects, not for $CTX_DIR"
    else
      R_REASON="plugin $key is in the record but no recorded installPath exists"
    fi
    return 1
  fi
  case "$S_VERSION" in ""|*[!0-9A-Za-z._+-]*) S_VERSION="unknown" ;; esac
  return 0
}

# resolve_ref <name>[@<marketplace>]/<path>
# Success: sets R_KEY R_VERSION R_PATH R_FILE (resolved real path), returns 0.
# Failure: sets R_REASON, returns 1. Requires load_record and CTX_DIR.
resolve_ref() {
  local ref="$1" head keys k n=0 root_real file_real
  R_KEY=""; R_VERSION=""; R_PATH=""; R_FILE=""; R_REASON=""

  case "$ref" in
    */*) head="${ref%%/*}"; R_PATH="${ref#*/}" ;;
    *)   R_REASON="the reference has no path after the plugin name"; return 1 ;;
  esac
  check_path "$R_PATH" || return 1

  case "$head" in
    "" | @* | *@)
      R_REASON="the plugin part '$head' is not <name> or <name>@<marketplace>"; return 1 ;;
    *@*)
      R_KEY="$head"
      jq -e --arg k "$R_KEY" '.plugins | has($k)' "$RECORD" >/dev/null 2>&1 \
        || { R_REASON="plugin $R_KEY is not installed"; return 1; }
      ;;
    *)
      keys=$(jq -r --arg p "$head@" '.plugins | keys[] | select(startswith($p))' "$RECORD")
      for k in $keys; do n=$((n + 1)); done
      if [ "$n" -eq 0 ]; then
        R_REASON="no installed plugin is named $head"; return 1
      elif [ "$n" -gt 1 ]; then
        R_REASON="several installed plugins are named $head: $(printf '%s\n' $keys | paste -sd ' ' - | sed 's/ /, /g'); write plugin:$head@<marketplace>/$R_PATH"
        return 1
      fi
      R_KEY="$keys"
      ;;
  esac

  select_install "$R_KEY" || return 1
  R_VERSION="$S_VERSION"

  root_real=$(realpath_of "$S_DIR") || { R_REASON="cannot resolve the installed directory of $R_KEY"; return 1; }
  [ -e "$S_DIR/$R_PATH" ] || { R_REASON="$R_PATH does not exist in $R_KEY $R_VERSION"; return 1; }
  file_real=$(realpath_of "$S_DIR/$R_PATH") || { R_REASON="cannot resolve $R_PATH in $R_KEY"; return 1; }
  case "$file_real" in
    "$root_real"/*) ;;
    *) R_REASON="$R_PATH resolves outside the installed directory of $R_KEY"; return 1 ;;
  esac
  case "$file_real" in *.md) ;; *) R_REASON="$R_PATH resolves to a file that is not Markdown"; return 1 ;; esac
  [ -f "$file_real" ] && [ -r "$file_real" ] || { R_REASON="$R_PATH is not a readable file"; return 1; }
  R_FILE="$file_real"
  return 0
}

# --- expand -----------------------------------------------------------------

# has_unfenced <ERE> <file>: true when a line outside fenced code blocks matches.
has_unfenced() {
  awk -v re="$1" '
    /^[[:space:]]*(```|~~~)/ { fence = !fence; next }
    !fence && $0 ~ re { found = 1; exit }
    END { exit !found }' "$2"
}

# check_imported <file> <first line>: disclose import-stale when the source moved on.
check_imported() {
  local f="$1" header="$2" key ver path sha target now
  if [[ "$header" =~ $IMPORTED_RE ]]; then
    key="${BASH_REMATCH[1]}"; ver="${BASH_REMATCH[2]}"; path="${BASH_REMATCH[3]}"; sha="${BASH_REMATCH[4]}"
    target="plugin:$key/$path"
    if ! resolve_ref "$key/$path"; then
      disclose import-stale "$target" "the source can no longer be found ($R_REASON); this copy was imported from version $ver"
      return
    fi
    now=$(sha256_of "$R_FILE")
    if [ "$now" != "$sha" ]; then
      disclose import-stale "$target" "the source changed since this copy was imported from version $ver (installed now: $R_VERSION); import again with --force to update, or keep the copy"
    fi
  else
    disclose import-stale "$f" "the first line starts like an imported header but does not parse, so the source cannot be checked"
  fi
}

# emit_included <line ending>: print R_FILE wrapped in source markers.
emit_included() {
  local ending="$1" inner fence=0 n=0
  printf '<!-- pw:source begin plugin:%s version:%s path:%s -->\n' "$R_KEY" "$R_VERSION" "$R_PATH"
  while IFS= read -r inner || [ -n "$inner" ]; do
    n=$((n + 1))
    if [[ "$inner" =~ $FENCE_RE ]]; then
      fence=$((1 - fence))
    elif [ "$fence" -eq 0 ]; then
      if [[ "$inner" =~ $INCLUDE_RE ]]; then
        disclose include-nested "plugin:${BASH_REMATCH[1]}" \
          "found inside plugin:$R_KEY/$R_PATH; includes are followed once, so this line is not expanded"
      else
        case "$inner" in
          *'<!--'*'pw:include'*)
            disclose include-nested "plugin:$R_KEY/$R_PATH:line:$n" \
              "a malformed include line inside the included file; it is not expanded" ;;
        esac
      fi
    fi
    inner="${inner//pw:source/pw-literal:source}"
    inner="${inner//pw:imported/pw-literal:imported}"
    printf '%s\n' "$inner"
  done <"$R_FILE"
  printf '<!-- pw:source end -->%s' "$ending"
}

cmd_expand() {
  [ $# -eq 1 ] || { usage >&2; exit 2; }
  local f="$1" first="" line ending lineno=0 ref fence=0
  [ -f "$f" ] && [ -r "$f" ] || die 2 "cannot read $f"

  IFS= read -r first <"$f" || true
  local has_header=0
  case "$first" in "$IMPORTED_PREFIX"*) has_header=1 ;; esac

  # No include line outside code fences and no imported header: print verbatim, never
  # touch the record.
  if [ "$has_header" -eq 0 ] && ! has_unfenced 'pw:include' "$f"; then
    cat "$f"
    exit 0
  fi

  CTX_DIR=$(realpath_of "$(dirname "$f")") || die 2 "cannot resolve the directory of $f"

  # Read the record before printing anything, so a record failure leaves stdout empty.
  if [ "$has_header" -eq 1 ] || has_unfenced "$INCLUDE_RE" "$f"; then
    load_record
    pick_sha_tool
  fi

  [ "$has_header" -eq 0 ] || check_imported "$f" "$first"

  while true; do
    if IFS= read -r line; then ending=$'\n'; else [ -n "$line" ] || break; ending=""; fi
    lineno=$((lineno + 1))
    if [[ "$line" =~ $FENCE_RE ]]; then
      fence=$((1 - fence))
      printf '%s%s' "$line" "$ending"
    elif [ "$fence" -eq 1 ]; then
      printf '%s%s' "$line" "$ending"
    elif [[ "$line" =~ $INCLUDE_RE ]]; then
      ref="${BASH_REMATCH[1]}"
      if resolve_ref "$ref"; then
        emit_included "$ending"
      else
        disclose include-unresolved "plugin:$ref" "$R_REASON; the line is left as is and its rules are not loaded"
        printf '%s%s' "$line" "$ending"
      fi
    else
      case "$line" in
        *'<!--'*'pw:include'*)
          disclose include-unresolved "line:$lineno" "this line mentions pw:include but is not a well-formed include line <!-- pw:include plugin:<name>[@<marketplace>]/<path> -->"
          ;;
      esac
      printf '%s%s' "$line" "$ending"
    fi
    [ -n "$ending" ] || break
  done <"$f"
}

# --- import -----------------------------------------------------------------

cmd_import() {
  local ref="" genre="" subject="" ws="" force=0 genre_set=0 subject_set=0 target

  while [ $# -gt 0 ]; do
    case "$1" in
      --genre)     [ $# -ge 2 ] || die 2 "--genre needs a slug"; genre="$2"; genre_set=1; shift 2 ;;
      --subject)   [ $# -ge 2 ] || die 2 "--subject needs a slug"; subject="$2"; subject_set=1; shift 2 ;;
      --workspace) [ $# -ge 2 ] || die 2 "--workspace needs a directory"; ws="$2"; shift 2 ;;
      --force)     force=1; shift ;;
      plugin:*)    [ -z "$ref" ] || die 2 "give exactly one plugin:<name>[@<marketplace>]/<path> reference"
                   ref="${1#plugin:}"; shift ;;
      *)           usage >&2; die 2 "unexpected argument: $1" ;;
    esac
  done

  [ -n "$ref" ] || { usage >&2; die 2 "missing the plugin:<name>[@<marketplace>]/<path> reference"; }
  [ "$genre_set" -eq 1 ] || [ "$subject_set" -eq 1 ] || { usage >&2; die 2 "give --genre, --subject, or both"; }
  if [ "$genre_set" -eq 1 ] && ! [[ "$genre" =~ $SLUG_RE ]]; then die 2 "genre slug '$genre' must match $SLUG_RE"; fi
  if [ "$subject_set" -eq 1 ] && ! [[ "$subject" =~ $SLUG_RE ]]; then die 2 "subject slug '$subject' must match $SLUG_RE"; fi

  [ -n "$ws" ] || ws="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.claude/.perspective-writer"
  if [ "$subject_set" -eq 1 ] && [ "$genre_set" -eq 1 ]; then target="$ws/subjects/$subject/$genre.md"
  elif [ "$subject_set" -eq 1 ]; then target="$ws/subjects/$subject/core.md"
  else target="$ws/genres/$genre.md"; fi

  CTX_DIR=$(realpath_of "$(nearest_existing "$ws")") || die 2 "cannot resolve the workspace $ws"

  load_record
  pick_sha_tool
  resolve_ref "$ref" || die 2 "cannot import plugin:$ref — $R_REASON"

  if [ -e "$target" ] && [ "$force" -eq 0 ]; then
    die 4 "$target already exists; pass --force to replace it"
  fi

  # Never write inside an installed plugin, including through a symbolic link somewhere
  # in the workspace path. Checked on the nearest existing ancestor, before mkdir.
  local anc_real ip ip_real
  anc_real=$(realpath_of "$(nearest_existing "$(dirname "$target")")") || die 2 "cannot resolve the directory of $target"
  while IFS= read -r ip; do
    [ -n "$ip" ] && [ -d "$ip" ] || continue
    ip_real=$(realpath_of "$ip") || continue
    case "$anc_real/" in
      "$ip_real/"*) die 2 "$target would be written inside the installed plugin directory $ip_real; refusing" ;;
    esac
  done < <(jq -r '.plugins[][] | .installPath' "$RECORD")

  local sha date tmp
  sha=$(sha256_of "$R_FILE")
  date=$(date +%Y-%m-%d)
  mkdir -p "$(dirname "$target")" || die 2 "cannot create the directory for $target"
  tmp="$target.tmp.$$"
  if { printf '<!-- pw:imported plugin:%s version:%s path:%s sha256:%s date:%s -->\n' \
         "$R_KEY" "$R_VERSION" "$R_PATH" "$sha" "$date"
       cat "$R_FILE"; } >"$tmp" && mv -f "$tmp" "$target"; then
    printf '%s\n' "$target"
  else
    rm -f "$tmp"
    die 2 "could not write $target"
  fi
}

# --- main -------------------------------------------------------------------

[ $# -ge 1 ] || { usage >&2; exit 2; }
sub="$1"; shift
case "$sub" in
  expand)    cmd_expand "$@" ;;
  import)    cmd_import "$@" ;;
  -h|--help) usage ;;
  *)         usage >&2; die 2 "unknown subcommand: $sub" ;;
esac
