# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
