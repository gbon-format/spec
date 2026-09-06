#!/usr/bin/env bash
# GBON spec repository gates (a)-(d) + optional factual-truth check.
# Aggregate runner (exit 0 = all green). Dictionary carrier for the
# authorial-content vocabulary scan (branch class: cycle labels).
# Modes:
#   gate.sh                 run gates a,b,c,d
#   gate.sh --sb-e DIR      also run the error-class factual check against
#                           DIR/errors.go of the Go implementation (read-only)
#   gate.sh --self-test     adversarial fixtures on a scratch copy; nothing
#                           under the repository is modified
set -u
REPO="${GBON_SPEC_REPO:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$REPO" || exit 2
MD_FILES="docs/wire-format.md docs/foundations.md docs/bindings/go.md README.md docs/meta/spec-conventions.md docs/references.md"
SCAN_FILES="docs/wire-format.md docs/foundations.md docs/bindings/go.md README.md CHANGELOG.md LICENSE scripts/gate.sh vectors/*.json manifest.json docs/meta/spec-conventions.md docs/references.md"
NR_FILES="$MD_FILES scripts/gate.sh"
status=0

red()  { printf 'RED %s: %s\n' "$1" "$2" >&2; status=1; }
note() { printf -- '-- %s\n' "$1" >&2; }

# Authorial-content vocabulary: frozen dictionary of the lab gate lineage
# (branch source: the neutralization spec of this repository family) plus
# the cycle-label class. Plain-word branches are concatenated at runtime so
# that this file does not carry matchable copies of its own patterns.
V_P1='(^|[^A-Za-z])F-[0-9]{1,4}\b|INV[- ][A-Z]?-?[0-9]|TK-[0-9]|CYC-[0-9]|RL-[0-9]|R-[0-9] of'
V_P2='topology-c[0-9]|arch-c[0-9]|product-c[0-9]|docs-c[0-9]|cyc[0-9]'
V_RU1='контр'; V_RU2='пример'; V_RU3='находк[аеу]|спек[аеу]'
V_H1='/ho'; V_H2='me/greed|meth'; V_H3='od-lab|tri'; V_H4='al-grounds|open'
V_H5='code|\\.cl'; V_H6='aude|ses_[A-Za-z0-9]{10,}|/tm'; V_H7='p/|gre'
V_H8='edyivan'
LABRE2="${V_P1}|${V_P2}|${V_RU1}${V_RU2}|${V_RU3}|${V_H1}${V_H2}${V_H3}${V_H4}${V_H5}${V_H6}${V_H7}${V_H8}|[Cc]ycle c[0-9]"

# Narrative-taxonomy dictionary: five classes of process narrative
# (stage-origin, considered-rejected, counterfactual, markers,
# temporal state), frozen design rules of the repository family.
# Words are split across adjacent literals so that this file carries
# no matchable copy of its own patterns.
NR1='origi'"nally|init"'ially|previ'"ously|form"'erly|histor'"ically|a"'t fi'"rst|w"'as fi'"rst (imple"'mented|intro'"duced|ad"'ded|desi'"gned|bu"'ilt)|w'"as (ad"'ded|intro'"duced|cre"'ated) (i'"n|la"'ter|wi'"th)|ad"'ded i'"n (mi"'nor|ver'"sion|cy"'cle)|intro'"duced i"'n (mi'"nor|ver"'sion)|pr'"ior t"'o (ver'"sion|mi"'nor)|p'"re-da"'tes|da'"tes ba"'ck'
NR2='w'"as (consi"'dered|reje'"cted|dism"'issed|disc'"ussed|eval"'uated|expl'"ored)|consi"'dered (a'"nd|b"'ut) (reje'"cted|dism"'issed|disc'"arded)|ch"'ose [a-z ]+ (ov'"er|ins"'tead)|w'"as cho"'sen ov'"er|dec"'ided (t'"o|aga"'inst|n'"ot t"'o)|a deci'"sion w"'as ma'"de|op"'ted (f'"or|aga"'inst)'
NR3='co'"uld (ha"'ve|wo'"uld|h"'ad)|wo'"uld ha"'ve be'"en|mi"'ght ha'"ve be"'en|w'"as (pla"'nned|inte'"nded|supp"'osed) t'"o|h"'ad be'"en (pla"'nned|inte'"nded)|i"'n a'"n ear"'lier (dr'"aft|des"'ign|ver'"sion)"
NR4='TO'"DO|FI"'XME|X'"XX\b|HA"'CK\b|fut'"ure (wo"'rk|ver'"sion|rel"'ease|exte'"nsion|dire"'ction)|t'"o b"'e (ad'"ded|imple"'mented|def'"ined|spec"'ified|la'"ter)|roa"'dmap'
NR5='curr'"ently|f"'or n'"ow|a"'s o'"f|a"'t pre'"sent|n"'ot y'"et|st"'ill un'"der|wo"'rk i'"n prog"'ress|i'"n prog"'ress|un'"der act"'ive devel'"opment|rema"'ining t'"o|y"'et t'"o b"'e'
NRRE="${NR1}|${NR2}|${NR3}|${NR4}|${NR5}"
# Draft-status clause of the README (product boundary): verbatim
# whitelist, split so the literals are not self-matches.
EX1M='active dev'"elopment and the documents describe work in "'pro'"gress. Draft"
EX1N='about fu'"ture ver"'sions.'

# Locales are pinned per gate: byte semantics for the vocabulary scan,
# UTF-8 semantics for the Cyrillic class.

slug() {
  printf '%s' "$1" | sed -e 's/[A-Z]/\L&/g' -e 's/[^a-z0-9 -]//g' -e 's/ /-/g'
}

# Markdown helpers shared by the anchor gate: fenced-code stripping and
# inline-backtick stripping, leaving prose for token scans.
strip_fenced() {
  awk 'FNR==1{f=0} /^```/{f=!f; next} !f{print FILENAME"\t"FNR"\t"$0}' "$@"
}
strip_ticks() { sed -e 's/`[^`]*`//g'; }

id_defs() { # file, header-tag series (WF|GO)
  grep -hoE "^#{2,3} .*\\[$2-[0-9]+\\]$" "$1" 2>/dev/null \
    | grep -oE "\\[$2-[0-9]+\\]" | tr -d '[]' | sort
}

gate_a() { # anchor/TOC/structure integrity
  local g=a
  # Part-level headers are gone (flat spine)
  if grep -rn '^# Part ' docs/ >/dev/null 2>&1; then
    red $g "Part-level headers present:"; grep -rn '^# Part ' docs/ >&2
  fi
  # Def sets, exact and duplicate-free
  local wf go ko e
  wf=$(id_defs docs/wire-format.md WF)
  [ "$(printf '%s\n' "$wf" | wc -l)" -eq 24 ] || red $g "WF def count $(printf '%s\n' "$wf" | wc -l) != 24"
  local i exp_wf="" bad
  for i in $(seq 1 24); do exp_wf="${exp_wf}WF-$i
"; done
  bad=$(printf '%s' "$exp_wf" | sort | diff - <(printf '%s\n' "$wf") | grep '^<' | tr -d '< ')
  [ -z "$bad" ] || red $g "WF def set mismatch: $bad"
  go=$(id_defs docs/bindings/go.md GO)
  [ "$(printf '%s\n' "$go" | wc -l)" -eq 7 ] || red $g "GO def count != 7"
  local j exp_go=""
  for j in $(seq 1 7); do exp_go="${exp_go}GO-$j
"; done
  bad=$(printf '%s' "$exp_go" | sort | diff - <(printf '%s\n' "$go") | grep '^<' | tr -d '< ')
  [ -z "$bad" ] || red $g "GO def set mismatch: $bad"
  ko=$(grep -hoE '^\*\*KO-[0-9]+[ab]? ' docs/wire-format.md | tr -d '* ' | sort -u)
  [ "$(printf '%s\n' "$ko" | wc -l)" -eq 10 ] || red $g "KO def count $(printf '%s\n' "$ko" | wc -l) != 10"
  for i in 1 2 2b 2a 3 4 5 6 7 8; do
    printf '%s\n' "$ko" | grep -qx "KO-$i" || red $g "KO def KO-$i missing"
  done
  e=$(grep -hoE '^- \*\*E[0-9] ' docs/wire-format.md | grep -oE 'E[0-9]' | sort -u)
  [ "$(printf '%s\n' "$e" | wc -l)" -eq 5 ] || red $g "E def count != 5"
  # Mentions resolve (fenced and tick spans stripped); SA is mention-only
  local toks
  toks=$(strip_fenced $MD_FILES | strip_ticks | grep -oP '(?<![0-9A-Za-z-])((WF|GO|KO)-[0-9]+[ab]?|SA-[0-9]+|E[1-9])(?![0-9A-Fa-f])' || true)
  local t ser num
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    ser=${t%%-*}; num=${t#*-}
    case $ser in
      WF) printf '%s\n' "$wf" | grep -qx "WF-$num" || red $g "mention $t without def" ;;
      GO) printf '%s\n' "$go" | grep -qx "GO-$num" || red $g "mention $t without def" ;;
      KO) printf '%s\n' "$ko" | grep -qx "KO-$num" || red $g "mention $t without def" ;;
      E)  printf '%s\n' "$e" | grep -qx "E$num" || red $g "mention $t without def" ;;
      SA) [ "$num" -le 9 ] 2>/dev/null || red $g "mention $t outside known range" ;;
    esac
  done < <(printf '%s\n' "$toks")
  local sa_n; sa_n=$(printf '%s\n' "$toks" | grep -c '^SA-' || true)
  [ "${sa_n:-0}" -ge 7 ] || red $g "SA mention count $sa_n < 7"
  # Spine order (invariants: flat spine, conformance early, profiles, limits, security)
  spine_check docs/wire-format.md \
    'Scope' 'Conventions' 'Conformance' 'Stream' 'Primitive' 'Value Encodings' \
    'Graph' 'Canonical' 'Limits' 'Security' 'Appendix A' 'Appendix B'
  spine_check docs/foundations.md \
    'Introduction' 'Scope' 'Definitions' 'Model' 'Identity' 'Equality' \
    'Requirements' 'Annex A' 'Annex B'
  spine_check docs/bindings/go.md \
    'Type Mapping' 'Lifecycle' 'Error Conformance' 'Examples'
  grep -qiE 'non-normative' <(head -20 docs/bindings/go.md) \
    || red $g "go.md: status declaration missing in header"
  toc_check docs/wire-format.md
  toc_check docs/foundations.md
  toc_check docs/bindings/go.md
  # Intro claims equal the actual ID sets
  local claim exp
  claim=$(head -20 docs/bindings/go.md | grep -oE 'GO-1\.\.GO-[0-9]+' | head -1)
  exp="GO-1..GO-$(printf '%s\n' "$go" | sed 's/GO-//' | sort -n | tail -1)"
  [ "$claim" = "$exp" ] || red $g "go.md intro claim '$claim' != actual '$exp'"
  claim=$(head -30 docs/wire-format.md | grep -oE 'WF-1 through WF-[0-9]+' | head -1)
  [ "$claim" = "WF-1 through WF-24" ] || red $g "wire-format intro claim '$claim' != WF-1..WF-24"
}

spine_check() { # file, ordered keyword slots
  local f="$1"; shift
  local titles pos p kw
  titles=$(grep -E '^## ' "$f" | sed -e 's/^## //')
  [ -n "$titles" ] || { red a "$f: no ## sections"; return; }
  pos=0
  for kw in "$@"; do
    p=$(printf '%s\n' "$titles" | grep -nE "$kw" | head -1 | cut -d: -f1)
    if [ -z "$p" ]; then red a "$f: spine slot '$kw' missing"; continue; fi
    if [ "$p" -le "$pos" ]; then red a "$f: spine slot '$kw' out of order"; fi
    pos=$p
  done
}

toc_check() { # manual TOC <-> headers, both directions, anchors derived
  local f="$1" entry text anch hdrs hdr n_toc n_hdr
  hdrs=$(grep -E '^#{2,3} ' "$f" | sed -e 's/^#\{2,3\} //')
  n_toc=0; n_hdr=$(printf '%s\n' "$hdrs" | grep -c . || true)
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    n_toc=$((n_toc+1))
    text=${entry#*- [}; text=${text%%](#*}
    anch=${entry##*(}; anch=${anch%)}
    anch=${anch#\#}
    if ! printf '%s\n' "$hdrs" | grep -qxF "$text"; then
      red a "$f: TOC entry without header: $text"
    fi
    if [ "$(slug "$text")" != "$anch" ]; then
      red a "$f: TOC anchor '$anch' != derived '$(slug "$text")' for: $text"
    fi
  done < <(grep -E '^[[:space:]]*- \[.*\]\(#' "$f")
  while IFS= read -r hdr; do
    [ -n "$hdr" ] || continue
    if ! grep -Fq "[$hdr]" "$f"; then
      red a "$f: header missing from TOC: $hdr"
    fi
  done < <(printf '%s\n' "$hdrs")
}

gate_b() { # authorial vocabulary scan, full tracked content, byte locale
  local g=b out
  out=$(LC_ALL=C grep -En "$LABRE2" $SCAN_FILES 2>/dev/null && true)
  if [ -n "$out" ]; then red $g "vocabulary hits:"; printf '%s\n' "$out" >&2; fi
  # Narrative scan over the prose contour (the gate file included);
  # changelog, license, agent rules, and corpus data stay outside the
  # contour by design. The draft clause of the README is whitelisted
  # verbatim above.
  out=$(LC_ALL=C grep -Eni "$NRRE" $NR_FILES 2>/dev/null \
    | grep -vF "$EX1M" | grep -vF "$EX1N" || true)
  if [ -n "$out" ]; then red $g "narrative-taxonomy hits:"; printf '%s\n' "$out" >&2; fi
  out=$(LC_ALL=C grep -En 'RegisterAs|ErrUnsupported|ErrFormat|ErrBudget|ErrIO' \
    docs/wire-format.md docs/foundations.md docs/bindings/go.md README.md 2>/dev/null && true)
  if [ -n "$out" ]; then red $g "implementation identifiers outside pointers:"; printf '%s\n' "$out" >&2; fi
  # Advisory (semantic verdict is a review channel, not this gate):
  out=$(LC_ALL=C.UTF-8 grep -riEn 'ns/op|MB/s|benchmark|faster' \
    docs/wire-format.md docs/foundations.md docs/bindings/go.md README.md 2>/dev/null && true)
  [ -n "$out" ] && { note "advisory measurable-pattern report:"; printf '%s\n' "$out" >&2; }
}

gate_c() { # residual tokens, cycle labels, dates; whitelist is per-line
  local g=c out magic_ln line
  local TOK1='an'"yv"
  LC_ALL=C.UTF-8 grep -riEn "$TOK1" $SCAN_FILES 2>/dev/null > "$TMPD/gatec.tmp" && true
  magic_ln=$(grep -n '67 62 6F 6E' docs/wire-format.md | head -1 | cut -d: -f1)
  if [ -z "$magic_ln" ]; then
    red $g "current magic declaration missing in wire-format.md"
  fi
  if [ -s "$TMPD/gatec.tmp" ]; then
    red $g "residual ancestor tokens:"
    cat "$TMPD/gatec.tmp" >&2
  fi
  out=$(grep -En '[Cc]ycle c[0-9]' $SCAN_FILES 2>/dev/null && true)
  [ -n "$out" ] && { red $g "cycle labels:"; printf '%s\n' "$out" >&2; }
  out=$(grep -En '\b20[0-9]{2}-[0-9]{2}-[0-9]{2}\b' $MD_FILES 2>/dev/null && true)
  [ -n "$out" ] && { red $g "ISO dates outside the changelog exemption:"; printf '%s\n' "$out" >&2; }
}

gate_d() { # Cyrillic outside fenced code, UTF-8 locale
  local g=d out
  out=$(strip_fenced $MD_FILES CHANGELOG.md | LC_ALL=C.UTF-8 grep -P '[а-яА-ЯёЁ]' && true)
  [ -n "$out" ] && { red $g "Cyrillic outside fenced code:"; printf '%s\n' "$out" >&2; }
}

gate_f() { # conformance corpus integrity (jq required; LC_ALL pinned)
  local g=f out jqok
  command -v jq >/dev/null 2>&1 || { red $g "jq not found on PATH"; return; }
  export LC_ALL=C.UTF-8
  [ -f manifest.json ] || { red $g "manifest.json missing"; return; }
  [ -d vectors ] || { red $g "vectors/ missing"; return; }
  # JSON validity of every corpus file
  local f
  for f in vectors/*.json manifest.json; do
    jq -e . "$f" >/dev/null 2>&1 || red $g "invalid JSON: $f"
  done
  # categories <-> files, both directions
  out=$(jq -r '.categories[].file' manifest.json)
  local listed=""
  while IFS= read -r f; do
    listed="$listed $f"
    [ -f "$f" ] || red $g "manifest category file missing: $f"
  done < <(printf '%s\n' "$out")
  for f in vectors/*.json; do
    case " $listed " in *" $f "*) ;; *) red $g "corpus file not listed in manifest: $f" ;; esac
  done
  # corpus vector inventory == manifest inventory (id+verdict+category)
  local line vid num prev=0
  while IFS= read -r vid; do
    [ -n "$vid" ] || continue
    case $vid in V-[0-9]*) ;; *) red $g "bad vector id: $vid"; continue ;; esac
    num=${vid#V-}
    if [ "$num" -le "$prev" ]; then red $g "vector id not monotonic: $vid"; fi
    prev=$num
  done < <(jq -r '.vectors[].id' manifest.json)
  local mset fset cat_name
  mset=$(jq -r '.vectors[] | "\(.id) \(.verdict) \(.category)"' manifest.json | sort)
  fset=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    cat_name=${f#vectors/}; cat_name=${cat_name%.json}
    fset="${fset}$(jq -r --arg c "$cat_name" '.vectors[] | "\(.id) \(.verdict) \($c)"' "$f")
"
  done < <(jq -r '.categories[].file' manifest.json)
  fset=$(printf '%s' "$fset" | sort)
  [ "$mset" = "$fset" ] || { red $g "manifest/file vector inventory mismatch:"; diff <(printf '%s\n' "$mset") <(printf '%s\n' "$fset") | head -20 >&2; }
  # def sets for tag resolution (reuse gate_a machinery)
  local wf go ko e
  wf=$(id_defs docs/wire-format.md WF)
  go=$(id_defs docs/bindings/go.md GO)
  ko=$(grep -hoE '^\*\*KO-[0-9]+[ab]? ' docs/wire-format.md | tr -d '* ' | sort -u)
  e=$(grep -hoE '^- \*\*E[0-9] ' docs/wire-format.md | grep -oE 'E[0-9]' | sort -u)
  local S81="S81-view S81-dense S81-sliceu8 S81-esc S81-arg"
  local S91="S91-depth S91-nodes S91-bytes S91-mappairs S91-slicelen S91-namedcycle"
  # tags resolve into def sets or section anchors; verdict/direction vocab
  local ALLOWED
  ALLOWED=" $(printf '%s ' $wf $go $ko $e) $S81 $S91 "
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    red $g "unresolvable tag: $line"
  done < <(for f in vectors/*.json; do
    jq -r --arg a "$ALLOWED" '.vectors[] | . as $v | .tags[]
      | select((" \(.) " | inside($a)) | not) | "\($v.id) tag \(.)"' "$f" 2>/dev/null || true
  done)
  out=$(jq -r '.vectors[] | select((.tags | length) == 0) | .id' vectors/*.json 2>/dev/null || true)
  [ -n "$out" ] && red $g "vector without tags: $(printf '%s ' $out)"
  out=$(jq -r '.vectors[] | select(.verdict == "ok" and ((has("bytes") and has("ir") and has("direction") and has("deriv")) | not)) | .id' \
    vectors/*.json 2>/dev/null || true)
  [ -n "$out" ] && red $g "ok vectors missing required fields: $(printf '%s ' $out)"
  out=$(jq -r '.vectors[] | select(.verdict as $v | ($v == "ok" or $v == "format" or $v == "budget") | not) | "\(.id) \(.verdict)"' \
    vectors/*.json 2>/dev/null || true)
  [ -n "$out" ] && red $g "bad verdict: $out"
  out=$(jq -r '.vectors[] | select(.verdict == "ok" and .direction as $d | ($d == "both" or $d == "decode") | not) | .id' \
    vectors/*.json 2>/dev/null || true)
  [ -n "$out" ] && red $g "bad direction: $out"
  out=$(jq -r '.vectors[] | select(.bytes | test("^[0-9a-f]+$") and (.bytes | length % 2 == 0) | not) | .id' \
    vectors/*.json 2>/dev/null || true)
  [ -n "$out" ] && red $g "bad bytes hex: $out"
  # IR field vocabulary whitelist and kind enumeration (corpus contract)
  local WH=" node kind value bits bytes real imag sort elements backing off len extent pairs key fields name type ref root nodes"
  local KINDS=" int uint bool float complex string blob nil array view map struct iface bigint descriptor"
  out=$(jq -r --arg wh "$WH" '
    .vectors[] | select(.verdict == "ok") | .ir | [.. | objects | keys[]] | unique
    | map(select(. as $k | ("\($wh) " | index(" \($k) ")) | not)) | if length > 0 then "x" else empty end' \
    vectors/*.json 2>/dev/null || true)
  [ -n "$out" ] && red $g "IR field outside whitelist"
  out=$(jq -r --arg kinds "$KINDS" '
    .vectors[] | select(.verdict == "ok") | .ir | .. | objects | select(has("kind"))
    | .kind | select(. as $k | ("\($kinds) " | index(" \($k) ")) | not)' \
    vectors/*.json 2>/dev/null | sort -u || true)
  [ -n "$out" ] && red $g "unknown IR kind: $(printf '%s ' $out)"
  # coverage classes: covered + exempt == normative class universe
  local UNIVERSE
  UNIVERSE=$(for i in $(seq 1 24); do printf 'WF-%d ' $i; done; \
    printf 'KO-1 KO-2 KO-2b KO-2a KO-3 KO-4 KO-5 KO-6 KO-7 KO-8 E1 E2 E3 E4 E5 '; \
    printf '%s %s' "$S81" "$S91")
  local cov exempt
  cov=$(jq -r '.coverage.covered | keys[]' manifest.json | tr '\n' ' ')
  exempt=$(jq -r '.coverage.exempt[].id' manifest.json | tr '\n' ' ')
  local cls covset=" $cov $exempt "
  for cls in $UNIVERSE; do
    case "$covset" in *" $cls "*) ;; *) red $g "coverage class neither covered nor exempt: $cls" ;; esac
  done
  for cls in $cov $exempt; do
    [ -n "$cls" ] || continue
    case " $UNIVERSE " in *" $cls "*) ;; *) red $g "coverage class outside universe: $cls" ;; esac
  done
  # corpus pointer: Appendix A paragraph + README line, no counters there
  grep -q 'Conformance vectors (non-normative)' docs/wire-format.md \
    || red $g "Appendix A corpus pointer missing"
  grep -q 'vectors/' README.md || red $g "README corpus pointer missing"
  if grep -qE 'vectors[^.]*( [0-9]+ |[0-9]+ vectors)' docs/wire-format.md README.md; then
    red $g "corpus pointer carries counters (single-source: manifest)"
  fi
}

sb_e() { # factual truth: class inventory of the doc vs the live source
  local g=e GG="$1" live doc urls
  [ -f "$GG/errors.go" ] || { red $g "errors.go not found under $GG"; return; }
  live=$(grep -oP 'class\w+ += +"\K[a-z_]+' "$GG/errors.go" | sort -u)
  doc=$(grep -oP '^\| \`\K[a-z_]+(?=\`)' docs/bindings/go.md | sort -u)
  if [ "$live" != "$doc" ]; then
    red $g "class inventory doc vs source mismatch:"
    diff <(printf '%s\n' "$live") <(printf '%s\n' "$doc") >&2
  fi
  urls=$(grep -En 'http' docs/bindings/go.md && true)
  [ -n "$urls" ] && { red $g "URLs present in the Go binding:"; printf '%s\n' "$urls" >&2; }
}

gate_e() { # bibliography phase: anchor map <-> document citations, both ways
  local g=e card=docs/references.md rows row key regex
  [ -f "$card" ] || { red $g "anchor map missing: $card"; return; }
  rows=$(grep -E '^\|' "$card" | grep -vE '^\| ?-+ ?\|' | grep -vE '^\| [A-Z]')
  while IFS= read -r row; do
    if ! printf '%s\n' "$row" | grep -Eq \
      '^\| ([a-z0-9][a-z0-9-]*) \| ([^|]+) \| ([^|]+) \| (normative anchor|family-note|precedent-note) \| (verified|verified-bib|verify-on-write) \|$'; then
      red $g "anchor map row not in canonical form: $row"
    elif printf '%s\n' "$row" | grep -Eq '^\| [a-z0-9-]+ \| https?://'; then
      red $g "anchor map row identified by a bare URL: $row"
    fi
  done << EOF
$rows
EOF
  local dup
  dup=$(printf '%s\n' "$rows" | grep -oE '^\| [a-z0-9-]+' | sed 's/^| //' | sort | uniq -d)
  [ -n "$dup" ] && red $g "duplicate anchor keys: $dup"
  local docs_lines docs_flat keys
  docs_lines=$(strip_fenced docs/wire-format.md docs/foundations.md docs/bindings/go.md README.md docs/meta/spec-conventions.md | strip_ticks)
  docs_flat=$(printf '%s\n' "$docs_lines" | tr '\n' ' ')
  keys=$(printf '%s\n' "$rows" | grep -oE '^\| [a-z0-9-]+' | sed 's/^| //')
  while IFS= read -r key; do
    [ -n "$key" ] || continue
    regex=$(printf '%s' "$key" | tr '-' ' ' | sed -E 's/[^ ]+/\\b&\\b/g; s/ +/.*/g')
    if ! printf '%s\n' "$docs_flat" | LC_ALL=C grep -qiE "$regex"; then
      red $g "anchor map entry without a citation in the documents: $key"
    fi
  done << EOF
$keys
EOF
  local t
  # Mechanical completeness domain: RFC/IEEE/ISO citation patterns.
  # Author-year (academic) anchors are not mechanically extractable from
  # prose; completeness for those is held by the map-side cross-check
  # above (canonical rows, duplicate keys).
  for t in $(printf '%s\n' "$docs_lines" | LC_ALL=C grep -oEi 'RFC ?[0-9]{3,5}' | tr -cd '0-9\n' | sed 's/^/rfc-/'); do
    printf '%s\n' "$keys" | grep -qx "$t" || red $g "anchor without a map entry: $t"
  done
  for t in $(printf '%s\n' "$docs_lines" | LC_ALL=C grep -oEi 'IEEE (Std )?754[- ][0-9]{4}' | tr -cd '0-9-\n' | sed 's/^/ieee-/'); do
    printf '%s\n' "$keys" | grep -qx "$t" || red $g "anchor without a map entry: $t"
  done
  for t in $(printf '%s\n' "$docs_lines" | LC_ALL=C grep -oEi 'ISO/IEC ?[0-9]+([:-][0-9]+)?' | tr -cd '0-9-:\n' | sed 's/:/-/; s/^/iso-/'); do
    printf '%s\n' "$keys" | grep -qx "$t" || red $g "anchor without a map entry: $t"
  done
}

TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT

self_test() { # adversarial fixtures on scratch copies; repo untouched
  local S="$TMPD/scratch" pass=0 failn=0 rc cc label expect
  local A B C D NR1F NR2F NR3F NR4F NR5F F1T
  A='an'"yv"; B='Cy'"cle c"'7'; C='те'"ст"; D='F-'"401"
  NR1F='ori'"ginally"; NR2F='was '"consi""dered and rejected"; NR3F='could '"have been"
  NR4F='T'"ODO"; NR5F='cur'"rently"
  F1T='GBON is a language-independent binary format for serializing object graphs under three hard contracts: bitwise-faithful round-trips, always-canonical encoding, and decoding under explicit resource budgets.'
  export A B C D NR1F NR2F NR3F NR4F NR5F F1T
  mkdir -p "$S"
  run2() { # label expected-verdict [inject-command...]
    label="$1"; expect="$2"; shift 2
    cc="$S/$label"; rm -rf "$cc"; cp -r "$REPO" "$cc"
    if [ $# -gt 0 ]; then ( cd "$cc" && eval "$*" ) >/dev/null 2>&1; fi
    ( cd "$cc" && bash scripts/gate.sh ) >"$TMPD/st-$label.log" 2>&1; rc=$?
    if { [ "$expect" = red ] && [ $rc -ne 0 ]; } \
       || { [ "$expect" = green ] && [ $rc -eq 0 ]; }; then
      pass=$((pass+1)); note "self-test $label: $expect as expected (rc=$rc)"
    else
      failn=$((failn+1)); red f "self-test $label: rc=$rc, expected $expect"
      sed -n '1,12p' "$TMPD/st-$label.log" >&2
    fi
  }
  cc="$S/clean"; rm -rf "$cc"; cp -r "$REPO" "$cc"
  ( cd "$cc" && bash scripts/gate.sh ) >"$TMPD/st-clean1.log" 2>&1; rc=$?
  ( cd "$cc" && bash scripts/gate.sh ) >"$TMPD/st-clean2.log" 2>&1; rc2=$?
  if [ $rc -eq 0 ] && [ $rc2 -eq 0 ]; then
    pass=$((pass+1)); note "self-test idempotence: double green"
  else
    failn=$((failn+1)); red f "self-test idempotence: rc=$rc/$rc2"
    sed -n '1,12p' "$TMPD/st-clean1.log" >&2
  fi
  run2 fjson red    "printf '{broken' >> vectors/arg.json"
  run2 fdupid red   "jq '.vectors[1].id = \"V-1\"' vectors/arg.json > t && mv t vectors/arg.json"
  run2 ftag red     "jq '.vectors[0].tags = [\"WF-25\"]' vectors/stream.json > t && mv t vectors/stream.json"
  run2 fcov red     "jq 'del(.coverage.covered[\"KO-8\"])' manifest.json > t && mv t manifest.json"
  run2 funlisted red "cp vectors/arg.json vectors/ghost.json"
  run2 fverdict red "jq '.vectors[0].verdict = \"error\"' vectors/stream.json > t && mv t vectors/stream.json"
  run2 firfield red "jq '.vectors[0].ir.nodes[0].selector = 2' vectors/stream.json > t && mv t vectors/stream.json"
  run2 ancestor red  "printf '\nprobe %s token\n' \"\$A\" >> docs/foundations.md"
  run2 cycle red     "printf '\nprobe %s label\n' \"\$B\" >> docs/bindings/go.md"
  run2 cyrillic red  "printf '\nprobe %s line\n' \"\$C\" >> README.md"
  run2 labtoken red  "printf '\nprobe %s marker\n' \"\$D\" >> docs/wire-format.md"
  run2 tochole red   "printf '%s\n' '- [99. Ghost Section](#99-ghost-section)' >> docs/bindings/go.md"
  run2 defdrop red   "sed -i 's/ \[WF-7\]//' docs/wire-format.md"
  run2 parthead red  "printf '\n# Part IX — Probe\n' >> docs/wire-format.md"
  run2 anchororph red "printf '\nRFC 9999 probe\n' >> docs/wire-format.md"
  run2 uncited red    "sed -i 's/RFC 2119/ANCHORX/g; s/RFC 8174/ANCHORX/g' docs/wire-format.md docs/meta/spec-conventions.md"
  run2 badform red    "sed -i 's/| verified |/| |/' docs/references.md"
  run2 bareurl red    "printf '\n| url-probe | https://example.com | injected | family-note | verify-on-write |\n' >> docs/references.md"
  run2 censormap red  "printf '\nprobe %s label\n' \"\$B\" >> docs/references.md"
  # Narrative-taxonomy probes: one red fixture per class, plus
  # exemption greens (canon string verbatim, composite identifier,
  # contour-exempt surface).
  run2 nr1origin red    "printf '\nprobe %s added\n' \"\$NR1F\" >> docs/wire-format.md"
  run2 nr2chosen red    "printf '\nprobe %s\n' \"\$NR2F\" >> docs/foundations.md"
  run2 nr3could red     "printf '\nprobe %s\n' \"\$NR3F\" >> docs/bindings/go.md"
  run2 nr4mark red      "printf '\nprobe %s: extend\n' \"\$NR4F\" >> docs/wire-format.md"
  run2 nr5now red       "printf '\nprobe %s under\n' \"\$NR5F\" >> README.md"
  run2 nr1f1 green      "printf '\n%s\n' \"\$F1T\" >> docs/wire-format.md"
  run2 nr1ex3 green     "printf '\nGBON specification probe\n' >> docs/foundations.md"
  run2 nr1ex4 green     "printf '\nprobe %s added\n' \"\$NR1F\" >> CHANGELOG.md"
  note "self-test summary: $pass passed, $failn failed"
  [ $failn -eq 0 ]
}

case "${1:-}" in
  --self-test) self_test; exit $? ;;
  --sb-e)
    [ $# -ge 2 ] || { echo 'usage: gate.sh --sb-e <gbon-go-dir>' >&2; exit 2; }
    note "gate a"; gate_a; note "gate b"; gate_b; note "gate c"; gate_c
    note "gate d"; gate_d; note "gate e"; gate_e; note "gate sb-e"; sb_e "$2"; note "gate f"; gate_f ;;
  *) note "gate a"; gate_a; note "gate b"; gate_b; note "gate c"; gate_c
     note "gate d"; gate_d; note "gate e"; gate_e; note "gate f"; gate_f ;;
esac
if [ $status -eq 0 ]; then echo "GATES ALL GREEN"; else echo "GATES RED"; fi
exit $status
