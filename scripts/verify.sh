#!/bin/bash
# Verify one tree against every case of the payload, and write a report.
#
#   verify.sh --tree vuln  [--san all|address|undefined|memory] [--report DIR]
#   verify.sh --tree fixed [--san all|address|undefined|memory] [--report DIR]
#
# The only entry is the hand-written driver:
#     /out/hand-<profile>-<tree>/repro <coder> <poc>
# hand_repro.cc as built by build-san.sh: instrumented with that profile, so the
# SUMMARY lines are real sanitizer output.  There is no fuzz target to choose
# from — the delivery set ships none.
#
# A case is CRASH when the run prints a `SUMMARY:` line, CLEAN otherwise; the
# full SUMMARY text is kept in the report.
#
# Writes DIR/verify-<tree>.md and DIR/verify-<tree>.json: one row per case
# (localId, coder, sanitizer, format, result, SUMMARY), a `crash=N clean=M`
# totals line and the verdict.  Nothing is built here — run build-san.sh (or
# `imdt build-before|build-after`) first.
#
# Expectation: tree=vuln  -> every case CRASH (crash=N clean=0)
#              tree=fixed -> no case crashes (crash=0 clean=N)
# Exit status: 0 when the expectation holds, 1 otherwise.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/lib.sh"

TREE=""; SAN_ARG="all"; REPORT="reports"
while [ $# -gt 0 ]; do
  case "$1" in
    --tree)   TREE=${2:?}; shift 2 ;;
    --san)    SAN_ARG=${2:?}; shift 2 ;;
    --report) REPORT=${2:?}; shift 2 ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[ -n "$TREE" ] || die "usage: verify.sh --tree vuln|fixed [--san all|address|undefined|memory] [--report DIR]"
case "$TREE" in vuln|fixed) ;; *) die "tree must be vuln or fixed" ;; esac
if [ "$SAN_ARG" = "all" ]; then sans="address undefined memory"; else sans=$(san_profile "$SAN_ARG"); fi

# localId -> image format as recorded by ARVO (cases.tsv has no format column);
# the report keeps it next to the coder so the two can be told apart even when
# they differ.  Anything missing falls back to the coder.
declare -A FORMAT=()
while IFS=$'\t' read -r fid ffmt; do FORMAT[$fid]=$ffmt; done < <(
  awk '
    /"id": /     { id=$0; sub(/^[^:]*: *"/,"",id); sub(/".*/,"",id) }
    /"format": / { f=$0;  sub(/^[^:]*: *"/,"",f);  sub(/".*/,"",f)
                   if (id != "") { print id "\t" f; id="" } }
  ' "$PAYLOAD/vulnerabilities.json" 2>/dev/null
)

cases=$(mktemp)
rows=$(mktemp)
trap 'rm -f "$cases" "$rows"' EXIT
awk -F'\t' -v list=" $sans " '!/^#/ && index(list, " " $4 " ")' "$PAYLOAD/cases.tsv" > "$cases"
total=$(wc -l < "$cases" | tr -d ' ')
[ "$total" -gt 0 ] || die "no cases for sanitizer(s) '$sans' in $PAYLOAD/cases.tsv"

# Pre-flight: a missing binary or PoC is a setup error, not a case result —
# reporting it as CLEAN would silently turn the fixed run into a pass.
missing=""
while IFS=$'\t' read -r id coder _target san _frame _kind poc _rest; do
  b=$(hand_repro_bin "$TREE" "$san")
  [ -x "$b" ] || missing="$missing"$'\n'"  binary $b"
  [ -f "$PAYLOAD/$poc" ] || missing="$missing"$'\n'"  poc    $PAYLOAD/$poc"
done < "$cases"
if [ -n "$missing" ]; then
  printf 'error: missing for tree %s:%s\n' "$TREE" "$missing" >&2
  die "build them first: build-san.sh --tree $TREE --san ${SAN_ARG}"
fi

mkdir -p "$REPORT"
md="$REPORT/verify-$TREE.md"
json="$REPORT/verify-$TREE.json"
rows=$(mktemp)
entry_bin='$OUTROOT/hand-<profile>-<tree>/repro <coder> <poc>'
generated=$(date -u +%Y-%m-%dT%H:%M:%SZ)
commit=$(git -C "$REPO" rev-parse "$TREE" 2>/dev/null || echo unknown)
other=vuln; [ "$TREE" = "vuln" ] && other=fixed
other_commit=$(git -C "$REPO" rev-parse "$other" 2>/dev/null || echo unknown)

echo "=== verify tree=$TREE entry=hand san=[$sans] cases=$total"
crash=0; clean=0
while IFS=$'\t' read -r id coder _target san _frame _kind poc _rest; do
  res=$(run_hand "$san" "$(hand_repro_bin "$TREE" "$san")" "$coder" "$PAYLOAD/$poc")
  summary=$(printf '%s\n' "$res" | awk -F'\t' '$1=="SUMMARY"{print $2}')
  fmt=${FORMAT[$id]:-$coder}
  if [ -n "$summary" ]; then
    result=CRASH; crash=$((crash+1))
  else
    result=CLEAN; clean=$((clean+1))
  fi
  printf '%-5s %-9s %-6s %-9s %s\n' "$result" "$id" "$coder" "$san" "${summary:--}"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$coder" "$san" "$fmt" "$result" "$summary" >> "$rows"
done < "$cases"

if [ "$TREE" = "vuln" ]; then want_crash=$total; want_clean=0; else want_crash=0; want_clean=$total; fi
verdict=FAIL
[ "$crash" -eq "$want_crash" ] && [ "$clean" -eq "$want_clean" ] && verdict=PASS

md_cell() { printf '%s' "${1//|/\\|}"; }
json_str() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\t'/ }
  s=${s//$'\r'/ }
  s=${s//$'\n'/ }
  printf '%s' "$s"
}

{
  printf '# verify — tree `%s`\n\n' "$TREE"
  printf '| field | value |\n| --- | --- |\n'
  printf '| tree | `%s` = `%s` |\n' "$TREE" "$commit"
  printf '| other tree | `%s` = `%s` (%s) |\n' "$other" "$other_commit" \
    "$([ "$commit" = "$other_commit" ] && echo 'same commit — unexpected' || echo 'different commit')"
  printf '| entry | `hand` → `%s` |\n' "$entry_bin"
  printf '| sanitizers | %s |\n' "$sans"
  printf '| cases | %s |\n' "$total"
  printf '| generated | %s |\n' "$generated"
  printf '| format column | image format recorded by ARVO (`payload/vulnerabilities.json`) |\n'
  printf '\n| localId | coder | sanitizer | format | result | SUMMARY |\n'
  printf '| --- | --- | --- | --- | --- | --- |\n'
  while IFS=$'\t' read -r id coder san fmt result summary; do
    printf '| %s | %s | %s | %s | %s | %s |\n' \
      "$id" "$(md_cell "$coder")" "$san" "$(md_cell "$fmt")" "$result" "$(md_cell "${summary:--}")"
  done < "$rows"
  printf '\ncrash=%s clean=%s\n\n' "$crash" "$clean"
  printf '**verdict: %s** — expected for `%s`: crash=%s clean=%s\n' \
    "$verdict" "$TREE" "$want_crash" "$want_clean"
} > "$md"

{
  printf '{\n'
  printf '  "tree": "%s",\n' "$TREE"
  printf '  "commit": "%s",\n' "$commit"
  printf '  "entry": "hand",\n'
  printf '  "sanitizers": [%s],\n' "$(printf '"%s",' $sans | sed 's/,$//')"
  printf '  "generated": "%s",\n' "$generated"
  printf '  "cases": %s,\n' "$total"
  printf '  "totals": {"crash": %s, "clean": %s},\n' "$crash" "$clean"
  printf '  "expected": {"crash": %s, "clean": %s},\n' "$want_crash" "$want_clean"
  printf '  "verdict": "%s",\n' "$verdict"
  printf '  "results": [\n'
  sep=""
  while IFS=$'\t' read -r id coder san fmt result summary; do
    printf '%s    {"localId": "%s", "coder": "%s", "sanitizer": "%s", "format": "%s", "result": "%s", "summary": "%s"}' \
      "$sep" "$id" "$(json_str "$coder")" "$san" "$(json_str "$fmt")" "$result" "$(json_str "$summary")"
    sep=$',\n'
  done < "$rows"
  printf '\n  ]\n}\n'
} > "$json"

printf '\ncrash=%s clean=%s\n' "$crash" "$clean"
printf 'verdict: %s — expected for %s: crash=%s clean=%s\n' "$verdict" "$TREE" "$want_crash" "$want_clean"
printf 'report: %s\n' "$md"
printf 'report: %s\n' "$json"
[ "$verdict" = "PASS" ]
