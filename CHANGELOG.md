# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-09-19

### Added

- wire-format.md: the per-value scope of the decode budget (MaxBytes
  guards one value, absolute stream positions); the WF-23 carve-out —
  decode-into-narrower over aliased map-records and shared backings
  rejects loudly (V-115..117 golden vectors, corpus 114→117).
- manifest.json + scripts/gate.sh + docs/meta/claims.md: verification
  ledger — the `ledger` block (schema version 2; one row per bound
  test over the claim registry), the aliased-backing fixture vectors
  and the grammar-census declaration under `vectors/`, and the ledger
  self-check as a gate stage (resolution both directions, the
  uniqueness cell, test-to-artifact resolution, adversarial
  self-test probes; `--lint <gbon-go-dir>` runs the cross-repo leg).
- docs/bindings/go.md: grounding section 5 — the four-tier source
  hierarchy with the pinned Go Language Specification (fetch record:
  page checksum, byte size, toolchain triple), the 18-construct
  denotation table over the seven canon fields with Go-spec section
  anchors, and the four-cause degeneracy register; Contents extension.
- docs/bindings/go.md: stable-class projection — section 3.1 class
  inventory rows for the encoder guard's two additive classes
  (`unstable_tie_break`, `unstable_zero_float_key`) with the 4.1
  consumption-mapping rows in lockstep, and the new section 5.4 stating
  the binding's static conservative predicate over Go types and dynamic
  exact predicate at encode time (cross-referencing wire-format.md 8.1);
  Contents row.
- docs/foundations.md: the value equivalence `≡_GBON` over the seven
  equality dimensions (new clause 5.1); the typed-views grain section
  with the six model axioms G-1..G-6 (new clause 4.1); the
  consolidated observables classification table in 6.2 (thirteen
  observables, three classes).
- docs/meta/claims.md: the claims registry carrier — CLM-1..CLM-7,
  H-1, and the verification-ledger schema; informative and
  non-normative with respect to the core documents.
- docs/meta/spec-conventions.md: SC-3 identifier-grammar sentence for
  the `CLM-n` and `H-n` families (home `docs/meta/claims.md`) and the
  `G-n` family (home `docs/foundations.md`).
- scripts/gate.sh: def-count pins CLM=7, H=1, G=6; the claims carrier
  in the gate file lists and the manual-TOC check; mention resolution
  extended with the CLM, H, and G families.

### Changed

- docs/bindings/go.md: the version statement tracks the core at
  format 0.1 (major 0, minor 1); the GO-2 stability notes open with
  the minor-1 version state.
- docs/meta/claims.md: CLM-5 status formulated to codified, home
  anchored to the Go binding grounding sections.
- docs/wire-format.md: section 7.1 vocabulary re-anchored on the
  neutral model terms — zero-size target, tracked view, layout-normal
  form, leading field, static target type — replacing the
  Go-implementation terms across sections 4.4-4.5, 6.8, 6.14, 7.1
  and the E2 axiom; the stable class and the guard contract (stable
  mode, deterministic classified error, completeness conditional on
  H-1) codified as new blocks in 8.1; docs/bindings/go.md receives
  the `underlying type` term of art; docs/meta/claims.md: CLM-2
  status clause reads codified with the 8.1 home.

## [0.1.0] - 2026-09-16

### Changed

- WF-13 canonical grain rule: each interned address opens one record at
  its canonical grain — the coarsest among the tracked reference grains
  of that address, fixed by an encoder pass ahead of emission. The
  slot-rooted record reference rule is its slot-root instance; the
  section carries the derivable descent (offset-zero fields with
  zero-size fields skipped, array element zero), grain tags on
  differing-grain openings with elision at grain equality for
  non-pointer grains and self-tags for pointer grains, layout-normal
  grains for named conversions of identical underlying layout,
  interface-grain discrimination with the declared degenerate-payload
  carve-out, the uniform single-path resolution, the closure property
  with REF-on-started-body, and skip/decode parity.
- WF-12: selector 4 is the zero-size pointee marker — a non-nil pointer
  to a zero-size pointee with no REF and no address; selectors 5..11
  stay reserved.
- WF-21 draft-era version policy: canonical-rule revisions ride minor
  versions while the major is 0, each noted in the version ladder.
  Format version 0.1 (header `67 62 6F 6E 00 01`); a 0.1 decoder reads
  0.0 streams.
- Conformance corpus rebaselined at minor 1: 101 behavioral vectors
  re-emitted (header states after the rebase: `...0001` x 108,
  `...0002` x 1, `...0200` x 1, `67626f6f` x 1); the version-behavioral
  vectors V-3/V-4/V-5 are byte-identical.

### Added

- Six topology vectors V-106..V-111: canonical grain with grain tag and
  descent (V-106), zero-size pointee marker (V-107), layout-normal grain
  (V-108), non-derivable descent negative (V-109), interior zero-size
  collision (V-110), started-body ring (V-111). Corpus 105 -> 111,
  manifest synced.

## [0.0.5] - 2026-09-13

### Changed

- WF-13 slot-rooted record reference (the named × slot-root cell): a
  whole-value REF from a `*T` pointer position may name the slot cell
  at the start of a named record's storage when `T` is a struct whose
  leading field carries the interface grain — the normative
  leading-subvalue rule of the cell model, stated for this cell. The
  corpus gains six topology vectors (V-100..V-105: self-rings and
  two-rings over slot roots, a slot-rooted DAG, node-rooted and
  slot-side ring entries; manifest 99 -> 105, topology 9 -> 15).

## [0.0.4] - 2026-09-11

### Changed

- WF-13 reference semantics: references are type-erased handles, the
  type lives on the interned cell, and descriptor and object records
  resolve through the one intern space — chains of any depth, cycles
  through map cells, offset-zero address aliasing, cell-level
  reference compatibility, and the byte-identical re-encode
  requirement.
- Go binding: decode-target semantics for reference graphs (pointer
  chains over an interface point as legal roots, typed-nil chain
  roots) and the unnamed chain derivation note on a registry miss.
- Go binding error classes: sixth (binding-local) family
  `internal_panic` -> `ErrInternal` — the never-panic tripwire for
  foreign panics recovered at the decode boundary (companion of
  gbon-go v0.0.4); the core wire-format families are unchanged.

### Added

- Conformance corpus: topology vectors V-97..V-99 (reference chains
  over interface points: self-referential chain, nil-interface
  pointee, typed-nil pointee) bring the corpus to 99 vectors.

## [0.0.3] - 2026-09-09

### Changed

- WF-13 (pointer-to-interface positions) generalized to pointer chains
  of any depth: leading REF resolution by intern-record sort at every
  chain level; nil-selector chain resolution with outer-nil
  normalization. Go binding note (1.3) synced.

## [0.0.2] - 2026-09-09

### Added

- Core rule for pointer-to-interface value positions (WF-13): leading
  REF/NIL resolution by intern-record sort, nil selectors, format errors.
- Go binding: error class `io_write` in the class inventory (GO-5) and
  the reader/writer-symmetric environment wording.
- Go binding note on pointer-to-interface positions: nil selectors and
  the bit-exact round-trip distinctions.

## [0.0.1] - 2026-09-06

### Added

- Normative GBON format specification: wire format, canonical encoding
  rules, and decoding budgets.
- Machine-readable conformance corpus: vector pairs with per-vector
  verdict IDs (vectors/, manifest.json).
- Consolidated external anchor map (docs/references.md) with gate-verified
  two-way citations.

[Unreleased]: https://github.com/gbon-format/spec/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/gbon-format/spec/compare/v0.1.0...v0.1.1
[0.0.2]: https://github.com/gbon-format/spec/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/gbon-format/spec/releases/tag/v0.0.1
