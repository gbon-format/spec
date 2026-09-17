# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[Unreleased]: https://github.com/gbon-format/spec/compare/v0.0.2...HEAD
[0.0.2]: https://github.com/gbon-format/spec/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/gbon-format/spec/releases/tag/v0.0.1
