# Foundations of the GBON Value Model

## Introduction

This document is the model standard of the GBON repository: it specifies
the neutral value model — the value-graph that serialization carries —
independently of any transfer syntax and of any host language. The
encoding of the model is specified by docs/wire-format.md, which carries
the conformance obligations of encoders and decoders; the language
projections live in companion binding documents (docs/bindings/go.md is
the Go binding), which are appendices non-normative with respect to the
core. This document prescribes nothing about bytes: where a rule of the
model has operational force on the wire, it is stated as a requirement
on the encoding (clause 6) and made normative by the wire document that
accepts it.

The document is the explicit form of a "theoretical list of structures":
every construct is tied to a primary source or registered as a declared
design freedom — the absence of an academic anchor is a registered
decision, never a silent choice.

Annex A and Annex B are informative. Annex A carries the anchor map of
the wire-format sections, the registry of declared design freedoms, and
the element index; Annex B carries the working bibliography. The
normative model text is clauses 1 through 6.

**Contents**

- [Introduction](#introduction)
- [1. Scope](#1-scope)
- [2. Definitions and Conventions](#2-definitions-and-conventions)
- [3. Model Overview](#3-model-overview)
- [4. Identity, Sharing, and Cycles](#4-identity-sharing-and-cycles)
- [5. Equality and Canonical Form](#5-equality-and-canonical-form)
- [6. Requirements on the Wire Layer](#6-requirements-on-the-wire-layer)
  - [6.1 Identity, Sharing, and Cycles Preservation](#61-identity-sharing-and-cycles-preservation)
  - [6.2 Observables Survive the Round Trip](#62-observables-survive-the-round-trip)
  - [6.3 Budgeted Decode](#63-budgeted-decode)
  - [6.4 Additive Evolution](#64-additive-evolution)
  - [6.5 Projections: Full Abstraction and the Degradation Ladder](#65-projections-full-abstraction-and-the-degradation-ladder)
- [Annex A (informative). Anchor Map, Design Freedoms, and Element Index](#annex-a-informative-anchor-map-design-freedoms-and-element-index)
  - [A.1 Per-Section Anchor Map of the Wire Document](#a1-per-section-anchor-map-of-the-wire-document)
  - [A.2 Registered Design Freedoms](#a2-registered-design-freedoms)
  - [A.3 Element Index](#a3-element-index)
  - [A.4 Historical Note: Universal Cores](#a4-historical-note-universal-cores)
- [Annex B (informative). Bibliography](#annex-b-informative-bibliography)

## 1. Scope

This document specifies the GBON value model: the domain of values — a
value-graph, not a flat record algebra — its identity, sharing, and
cycles contract, the equality and canonical-form semantics of that
domain, the requirements the model imposes on any encoding of it, and
the degradation contract of language projections.

The model is referenced by other documents that define encodings and
bindings: docs/wire-format.md defines the transfer syntax and is
normative for it; the binding documents project the model onto host
languages and are non-normative appendices with respect to both.

Scope boundaries: host-language ergonomics are binding territory; the
portable-profile frame for bindings in languages other than Go is
specified by the wire document (its clause 8.2).

## 2. Definitions and Conventions

- **Value-graph** — the subject of serialization: a graph of values
  with identity edges (backing records, map objects, addressable
  values, interned strings, type descriptors), not a flat sequence of
  records.
- **Identity, sharing, cycles** — the topology contract: records have
  stream identity, repeated encounters are references, cycles are legal
  and close through references.
- **Observable** — a property of a value that must survive a round
  trip (nil versus empty containers, slice extent, NaN payloads,
  non-UTF-8 strings, shared identity).
- **Neutral model / projection** — the model is a signature independent
  of any host language; every implementation language carries a
  projection of it.
- **Denotational assignment** — the relation between a language
  construct and its denotation in the model domain (Annex A.3; the
  normative formulation lives in the wire document, clause 8.2).
- **Degradation ladder** — the declared, ordered ways a projection may
  lose information at a language boundary (clause 6.5).
- **Anchor classes** — A1 formal semantics (primary source); A2
  normative standard; A3 established result; A4 declared design
  freedom (the registry of freedom zones is Annex A.2).
- **Anchor status** — v: position verified against an external
  bibliographic source (the `verified` and `verified-bib` statuses of
  the anchor map); w: verify-on-write position (the `verify-on-write`
  status of the anchor map); NEW: a new `verify-on-write` position. A
  supporting anchor follows a "+" and does not dilute the class of the
  row.

## 3. Model Overview

The model is defined by what it requires of any serialization of it:

1. The subject of serialization is a value-graph, not flat records.
2. The contract is topology: identity, sharing, cycles.
3. The value model is a signature independent of any host language;
   the Go implementation is a projection of it.
4. There is a canonical encoding.
5. Decoding is budgeted — hostile input is the default posture.
6. Format evolution is additive (minor bumps).
7. Native projections exist for host languages, with declared, blamed
   degradation for what a language cannot carry.
8. The family strategy is spec-first federation: the specification is
   the contract, implementations are its projections (the empirical and
   historical grounding of the strategy is Annex A.4).

## 4. Identity, Sharing, and Cycles

Identity is a first-class, observable layer of the model; its
operational form on the wire is the intern space of the wire document
(WF-13).

- All reference-nature records — backing arrays, map objects,
  addressable values (pointer targets), interned strings, and type
  descriptors — share one id space per stream.
- A record is registered when its own encoding begins, before its
  children: a reference to an enclosing record closes a cycle.
- Sharing is never silently duplicated: a repeated encounter of memory
  already encoded is a reference or a view over the registered record,
  never a fresh copy (the single, rule-governed carve-out — the backing
  join — is specified normatively by the wire document).
- Interning is value numbering: byte-bearing records share storage; the
  traversal is bounded-memory (the marking discipline behind it is the
  classical graph-marking result, Annex A.3, element 1).
- Zero-size reference identity is neither preserved nor observable:
  the model does not track it.

The theory that legitimizes the layer — term graphs, rational trees,
bounded traversal, hash-consing — is mapped in Annex A.

## 5. Equality and Canonical Form

The model carries an equality and a canonical form:

- **Canonical encoding** is a decode-side contract: there is exactly
  one legal byte sequence for every value — qualified by the
  pointer-identity tie-break (KO-2a): map pairs keyed by
  reference-carrying values order by the allocation-sequence
  discriminator, so their byte spelling is fixed within one encoding
  but not specified across processes or replays. Non-canonical
  spellings are decoder rejects. The operational clauses live in the
  wire document (WF-20, with the KO ordering contract).
- **Map-key equality** is defined by the model through axioms — key
  domain, skeleton, total order, ±0 collapse, tie-break (E1–E5 of the
  wire document); encodings implement it, they do not reinterpret it.
- **The upper bound of canonicalization.** Isomorphic-graph
  canonicalization ("isomorphic graphs map to equal bytes") is
  computationally unjustified for this model: canonical labeling is
  worst-case as hard as graph isomorphism (quasipolynomial in the
  worst case, linear only in the average case — Annex B). The model
  therefore claims traversal canonicality, qualified by the
  pointer-identity tie-break (KO-2a), not isomorphism canonicality.
  Consequence: any claim of the shape "equal values imply equal bytes"
  carries the KO-2a qualification.

## 6. Requirements on the Wire Layer

The model standard dictates to the encoding layer; the operational
acceptance of each requirement is by the wire document.

### 6.1 Identity, Sharing, and Cycles Preservation

Any encoding of this model MUST preserve the identity layer: repeated
encounters become references, cycles close through them, sharing is
observable at every hop of a projection.

### 6.2 Observables Survive the Round Trip

nil versus empty containers, slice windows with their observable
extent, NaN payloads, ±0, subnormals, non-UTF-8 strings, shared
identity — bitwise round-trip fidelity is a model requirement; no
projection may weaken it silently.

### 6.3 Budgeted Decode

Decoding MUST run under explicit resource budgets: hostile input is the
default posture of the model, and the complexity-attack dimensions
(depth, nodes, bytes, map pairs, slice length) are the contract of the
budget families (the attack taxonomy behind the dimensions is the
anchor `crosby-wallach-2003` (Crosby–Wallach and companions)).

### 6.4 Additive Evolution

Format evolution is additive (minor bumps): what an old decoder cannot
know it rejects loudly at the token, never misparses; what a new
decoder receives from an old encoder it completes with declared
defaults. A change of canonical form for an existing value class
migrates by rewrite — old streams stay readable forever — never by
forking the format.

### 6.5 Projections: Full Abstraction and the Degradation Ladder

No embedding of the model into a language preserves every observable
of every other language (typed nils, capacities, unsigned widths are
the Go examples): this is a limit of expressibility of the embedding,
not a quality of an implementation. The degradation ladder is
therefore a mandatory component of the portable profile:

| Class of loss | Examples | Policy |
|---|---|---|
| Annotations | cap/append-threshold, typed nils, unsigned widths, complex | degradation allowed |
| Core invariants | identity, sharing, cycles | preservation mandatory at every hop |
| The unrepresentable | integers beyond the receiving language's width (Python bigint, JS 2^53) | loud error, never truncation |

The principle: lossy is allowed, a silent lie is not. The formal name
of the ladder is the enumeration of the full-abstraction gaps of the
embedding (the negative results behind the limit are Milner 1977 and
Plotkin 1977 — the anchors `milner-1977` and `plotkin-1977`);
attribution of violations is the blame contract at the language
boundary.

## Annex A (informative). Anchor Map, Design Freedoms, and Element Index

### A.1 Per-Section Anchor Map of the Wire Document

The per-section grounding map of docs/wire-format.md: every section
WF-1..WF-24 carries a primary class, an anchor, and a status (the
classes and statuses are clause 2). The map is informative; the
normative text it grounds lives in the wire document.

| WF | Section statement | Class | Anchor | What it grounds | Status |
|---|---|---|---|---|---|
| WF-1 | Self-delimiting stream; observables survive the round trip; one core, a second implementation is written against it | A1 | Kraft 1949; McMillan 1956 + A3: Milner 1977; Strong et al. 1958 | Prefix-freeness without lookahead; preservation of observables is full abstraction of the embedding; the layer model is the premise of spec-first federation (element series 8, A.3) | w |
| WF-2 | Magic constant and 6-byte header; reject unknown major / read unknown minor | A4 | — (magic/layout zone, registry A.2) | The identity constant and the layout are design freedom; no-collision with adjacent signatures is a testable engineering invariant; the major/minor semantics inherits the WF-21 anchor | — |
| WF-3 | Definite-length grammar, no indefinite forms, truncation is a format error | A1 | Kraft 1949; McMillan 1956; Elias 1975 | Prefix-free grammar: self-delimitation and unique decodability without lookahead | w,v |
| WF-4 | ARG: selector ladder inline→u8/u16/u32/u64→ext (0x10), minimal length, BE comparability | A1 | Elias 1975 (universal codeword sets) + family-notes: start-step-stop (Fraenkel & Klein), LEB128/DWARF, protobuf varint — non-normative | The width ladder is a universal code of the integers; minimality is the canonical form of the code; the ext form closes the domain at ≥2^64 (successor form) | v + NEW |
| WF-5 | Zigzag bijection ℤ→ℕ (n≥0→2n, n<0→−2n−1), the int64 section plus the extension to all of ℤ | A4 | — (bijection zone, registry A.2) + precedent-note protobuf ZigZag | The concrete bijection is an engineering device: bijectivity and monotonicity modulo sign are testable invariants; the choice within the class of equivalent bijections is free; the composition with ARG inherits the A1 anchor of WF-4 | NEW-note |
| WF-6 | UINT: direct value; boundary 2^64−1, beyond it BIGINT | A1 | Goguen–Thatcher–Wagner–Wright 1977 | The finite unsigned sort of the neutral model's signature; the boundary is a derivative of the u64 rung of WF-4, not a freedom | v |
| WF-7 | Bool: selectors 0/1, the rest reserved | A1 | Goguen et al. 1977 | The two-element sort of the model; reserved selectors are the evolutionary reserve of WF-21 | v |
| WF-8 | Floats: f32/f64 form 0/1, decimal128 form 2 — raw IEEE bits, bitwise round trip | A2 | IEEE 754-2019 (IEEE Std; = ISO/IEC 60559:2020), incl. decimal128 | The normative standard of the formats: binary32/64, decimal128; bitwise preservation of NaN/±0/subnormals is the standard semantics of the formats | NEW (the decimal item is verify-on-write) |
| WF-9 | Complex: a pair of raw bit patterns per WF-8, not synthesized as a struct | A1 | Goguen et al. 1977 | The product sort as a sort of its own (irreducibility to STRUCT — a signature-sorts distinction) | v |
| WF-10 | String = a byte sequence, no UTF-8 gate; interning | A1 | Burstall 1969; Hoare 1975 | The sequence sort (the free monoid of octets); the refusal of Unicode normativity is a layer decision about observability, not a freedom zone | w,v |
| WF-11 | Blob = a backing record in the intern space; trailing-zero elision; minimal E | A1 | Ershov 1958 + Kraft 1949; McMillan 1956 | Interning/value numbering for byte backings; minimal E is canonical uniqueness (elision is semantically transparent economy, not a freedom zone) | w |
| WF-12 | Nil tokens: the core carries the selectors, the taxonomy belongs to the binding (GO-4); nil ≠ empty | A3 | Milner 1977; Plotkin 1977 | The distinctions of nil sorts are observables of projections: they must survive (adequacy); routing the taxonomy to the binding is the observability rule | w |
| WF-13 | Intern space: DFS identifiers, registration before children, backing join | A1 | Courcelle 1983; Barendregt et al. 1987; Schorr & Waite 1967; Ershov 1958 + Reynolds 1978 | Cycles are rational trees; term graphs make sharing an object of the theory; traversal with bounded memory; hash-consing of the intern space; the identity layer is observable (element series 2, A.3) | w,v |
| WF-14 | Arrays: L/E plus trailing-zero elision, a bit-level predicate (−0.0 is never elided) | A1 | Goguen et al. 1977 + Kraft 1949; McMillan 1956 | The array sort; minimal E is canonical uniqueness; the bit-level nature of the predicate follows from the bitwise round trip of WF-8 | v,w |
| WF-15 | Slice views: geometry {off,len,extent}, view-form minimality, record-then-fill | A3 | Milner 1977; Plotkin 1977; Findler & Felleisen 2002; Siek & Taha 2006 | Extent is a capacity-like annotation: degradable with blame at the language boundary (extent agreement, WF-20); the geometric invariants are derivatives and testable | w |
| WF-16 | Maps: pair count, canonical order, intern record, duplicate reject | A1 | Goguen et al. 1977 + Ershov 1958 | The finite function/associative sort; the map object as an intern record; order and duplicates are the WF-20 contract (KO) | v,w |
| WF-17 | Structs: field values in descriptor order, no per-field tags | A1 | Burstall 1969; Hoare 1975; Cardelli & Mitchell 1991 | Records are labeled products sorted by label; determinism of field order is declaration order | w,v |
| WF-18 | Type descriptors as data: kinds 0–15, name-interning, kind 15 BIGINT | A1 | Goguen et al. 1977 + Ershov 1958 + Elias 1975 (ext body) | The DESC language is the concrete syntax of the signature's universe of datatypes; descriptor interning; kind 15: the ℤ sort (Goguen) plus the ext body (Elias). The numbering of kinds is the layout zone of WF-19 | v |
| WF-19 | Opcode table: class<<4 \| arg-form, the 16 nibble classes fully allocated, ESC ranges | A4 | — (opcode/kind layout zone, registry A.2) | The class→nibble assignment and the selectors are a stable but arbitrary constant (it only needs fixing); exhaustion of the classes follows from the field width; unknown→error is the hygiene of WF-22; the ESC reserve is the evolutionary mechanism of WF-21 | — |
| WF-20 | Canonical encoding: decode-side contract, KO-1..8, axioms E1–E5 | A1 | Kraft 1949; McMillan 1956 + canonicalization complexity (clause 5): McKay 1981; Luks 1982; Babai–Luks 1983; Babai–Kucera 1979; Babai 2016 + Reynolds 1978 (the identity layer, KO-2a) | Injectivity/unique decodability of the canonical form; not claiming iso-canonicalization is the upper complexity bound (clause 5); E5 is honest intra-contract underspecification | w,v |
| WF-21 | Versioning: major breaks / minor additive-only; ESC graduation | A1 | Cardelli & Mitchell 1991 (width subtyping) + A4 sub-zone: the governance policy (registry A.2; fallback RFC 8949) | Adding a field is semantically correct for an old reader (skip/zero is the operational consequence); numbering and graduation mechanics are standards engineering, not academia | w |
| WF-22 | Decoder hygiene: budgets, validate-before-allocate, atomicity, no panic/hang | A3 | Crosby & Wallach 2003; Tarjan 1985; Miller et al. 1990 | The budget dimensions cover the classes of complexity attacks; charge-before-allocation is the potential method; fuzzing empirics; the composition of the five budgets is authorial (registry A.2) | w |
| WF-23 | Evolution: skip/zero/by-name, strict name+structure, the kind-14 channel stays readable forever | A1 | Cardelli & Mitchell 1991 + practice-note: Avro/protobuf evolution (non-normative) | Width subtyping is bidirectional wire compatibility; the kind-14 channel migrates by rewrite (a consequence of the discipline) | w + NEW |
| WF-24 | Stable section IDs, reference-lint, a dictionary computed from headings | A4 | — (editorial, registry A.2) + precedent-note RFC/STD numbering | An editorial convention of the repository, wire-invisible; the freedom of the ID scheme lays no claim to an anchor | NEW-note |

### A.2 Registered Design Freedoms

No academic primary source exists for every row; the decisions are
registered explicitly. The A4 freedom zones of the anchor map (A.1) are
registered here; the map rows point to their zones.

| Item | Status | Fallback |
|---|---|---|
| The magic constant and the 6-byte header layout (WF-2) | identity and layout are design freedom; no-collision with adjacent signatures is a testable engineering invariant | the major/minor semantics — the WF-21 anchor |
| The opcode and kind layout: class→nibble, selectors, kind numbering 0–15 (WF-19; the numbering inside WF-18) | a stable but arbitrary constant — it only needs fixing | the WF-19 opcode table |
| The zigzag bijection ℤ→ℕ (WF-5) | a choice within the class of equivalent bijections; bijectivity and monotonicity modulo sign are testable invariants | protobuf ZigZag — an engineering precedent (the anchor `protobuf-encoding`) |
| Versioning governance of the format (major/minor practice; the A4 sub-zone of the WF-21 row) | standards engineering | RFC 8949 (an IETF standard, not academia — the outermost option) |
| The composition of the five budgets | design: the dimensions come from the Crosby–Wallach taxonomy, the set is authorial | Crosby–Wallach as the map of attack classes |
| "Native ergonomics" of projections | no formal theory exists | an explicit design decision without an anchor |
| The section-ID scheme (WF-24) | an editorial convention of the repository, wire-invisible | the practice of stable RFC/STD numbering (the anchor `stable-rfc-std-numbering`) |

### A.3 Element Index

The element index over the anchor map (A.1): the eight load-bearing
constructions, their anchor series, and their coverage by the sections
of docs/wire-format.md.

| # | Element | Anchor series | Coverage |
|---|---|---|---|
| 1 | The value-graph as the subject; the intern space and traversal | Courcelle 1983; Barendregt et al. 1987 (+ Sleep & Plasmeijer 1993); Schorr & Waite 1967; Ershov 1958 | WF-11, WF-13, WF-14, WF-15 |
| 2 | Identity/sharing as an observable contract | Reynolds 1978 (SCI); Reynolds 2002 (separation logic) | WF-13, WF-20 (KO-2a) |
| 3 | The neutral value model = a universe of datatypes | Burstall 1969; Hoare 1975; Goguen–Thatcher–Wagner–Wright 1977; Backhouse et al. 1998 | WF-6, WF-7, WF-9, WF-10, WF-16, WF-17, WF-18 |
| 4 | Canonical encoding | Kraft 1949; McMillan 1956; Elias 1975; McKay 1981; Babai–Kucera 1979; Babai–Luks 1983; Luks 1982; Babai 2016 | WF-1, WF-3, WF-4, WF-20; complexity — clause 5 |
| 5 | Budgeted decode | Crosby & Wallach 2003; Tarjan 1985; Miller et al. 1990 | WF-22 |
| 6 | Additive evolution (minor bumps) | Cardelli & Mitchell 1991 | WF-21, WF-23 |
| 7 | The degradation ladder at the language boundary | Milner 1977; Plotkin 1977; Findler & Felleisen 2002; Siek & Taha 2006 | WF-12, WF-15; the portable-profile frame — clause 6.5 |
| 8 | Spec-first federation | Strong et al. 1958; Conway 1958; Steel 1961; Macrakis 1992; Goguen & Burstall 1992 | WF-1 (supporting); the document level — A.4 |

The neutral core is carried by docs/wire-format.md; the Go projection
is the binding docs/bindings/go.md. Sections outside the element
series: WF-8 (a normative IEEE standard) and the A4 zones (WF-2, WF-5,
WF-19, WF-24 — the registry A.2); their grounding is carried by the
map (A.1).

### A.4 Historical Note: Universal Cores

The strategy "one core, every implementation written by hand against
it" has a sixty-five-year organizational failure history (UNCOL 1958 →
ANDF 1992). The surviving form is a specification plus third-party
bindings (the CBOR/MessagePack path). The anchor is empirical and
historical, not formal; it grounds model-overview item 8.

## Annex B (informative). Bibliography

The external anchors of the specification live in the consolidated
anchor map, `docs/references.md`. This annex is a pointer.
