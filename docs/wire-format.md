# GBON Wire Format Specification

Normative specification of the GBON wire format — the binary transfer
syntax of the GBON value model (the model itself is specified by
docs/foundations.md).

This document defines the format contract: the core grammar plus the
CODER descriptor extension (WF-22). A change to an opcode or a descriptor
rule of the core requires a new major version of the format; additive
extensions enter through minor versions from major 1 (WF-5); a change to
a canonical rule of the core requires a new major version after
finalization and rides a minor version while the format is in its draft
era (WF-5). Sections carry stable IDs — core sections WF-1 through
WF-26 — that are the reference keys of the repository (WF-1); the
displayed section numbers are reader cosmetics.

```
Format version: 0.2 (major 0, minor 2)
Document scope: token-level grammar, topology, canonical rules
```

**Layer model.** This specification is organized in layers. The
**core** is the neutral, language-independent contract: a second
implementation is written against it alone. An **annotation** is a
projection remark inside a core rule (a degradation a projection may
take without lying). Language projections live in companion binding
documents (docs/bindings/go.md — the Go value model); the portable
profile — the reserved frame for implementations in other languages —
is clause 8.2 of this document. Every section carries its layer in the
heading: `(core)` or `(core+annotation)`.

**Contents**
- [1. Scope and Layering](#1-scope-and-layering)
- [2. Conventions](#2-conventions)
  - [2.1 Requirements Language](#21-requirements-language)
  - [2.2 Layer Tags](#22-layer-tags)
  - [2.3 Section IDs and References [WF-1]](#23-section-ids-and-references-wf-1)
- [3. Conformance](#3-conformance)
- [4. Stream Structure and Versioning](#4-stream-structure-and-versioning)
  - [4.1 Overview (core) [WF-2]](#41-overview-core-wf-2)
  - [4.2 Stream Header (core) [WF-3]](#42-stream-header-core-wf-3)
  - [4.3 Value Stream Grammar (core) [WF-4]](#43-value-stream-grammar-core-wf-4)
  - [4.4 Versioning (core) [WF-5]](#44-versioning-core-wf-5)
  - [4.5 Decoder Evolution Contract (core) [WF-6]](#45-decoder-evolution-contract-core-wf-6)
- [5. Primitive Field Formats](#5-primitive-field-formats)
  - [5.1 Integer Arguments — ARG (core) [WF-7]](#51-integer-arguments--arg-core-wf-7)
- [6. Value Encodings by Kind](#6-value-encodings-by-kind)
  - [6.1 Signed Integers — INT (core+annotation) [WF-8]](#61-signed-integers--int-coreannotation-wf-8)
  - [6.2 Unsigned Integers — UINT (core+annotation) [WF-9]](#62-unsigned-integers--uint-coreannotation-wf-9)
  - [6.3 Booleans (core) [WF-10]](#63-booleans-core-wf-10)
  - [6.4 Floats (core+annotation) [WF-11]](#64-floats-coreannotation-wf-11)
  - [6.5 Complex Numbers (core+annotation) [WF-12]](#65-complex-numbers-coreannotation-wf-12)
  - [6.6 Strings (core) [WF-13]](#66-strings-core-wf-13)
  - [6.7 Blobs (core) [WF-14]](#67-blobs-core-wf-14)
  - [6.8 Nil Layer (core) [WF-15]](#68-nil-layer-core-wf-15)
  - [6.9 Arrays and Trailing-Zero Elision (core+annotation) [WF-16]](#69-arrays-and-trailing-zero-elision-coreannotation-wf-16)
  - [6.10 Slice Views (core) [WF-17]](#610-slice-views-core-wf-17)
  - [6.11 Maps (core) [WF-18]](#611-maps-core-wf-18)
  - [6.12 Structs (core+annotation) [WF-19]](#612-structs-coreannotation-wf-19)
  - [6.13 Tuples (core) [WF-20]](#613-tuples-core-wf-20)
  - [6.14 Variants (core) [WF-21]](#614-variants-core-wf-21)
  - [6.15 Type Descriptors (core) [WF-22]](#615-type-descriptors-core-wf-22)
  - [6.16 Opcode Table and Partitioning (core) [WF-23]](#616-opcode-table-and-partitioning-core-wf-23)
- [7. Graph Encodings: Identity, Sharing, and Cycles](#7-graph-encodings-identity-sharing-and-cycles)
  - [7.1 Topology: Intern Space and References (core) [WF-24]](#71-topology-intern-space-and-references-core-wf-24)
- [8. Canonical and Portable Profiles](#8-canonical-and-portable-profiles)
  - [8.1 Canonical Encoding (core) [WF-25]](#81-canonical-encoding-core-wf-25)
  - [8.2 Portable Profile (Frame)](#82-portable-profile-frame)
- [9. Limits and Budgeted Decode](#9-limits-and-budgeted-decode)
  - [9.1 Decoder Hygiene (core) [WF-26]](#91-decoder-hygiene-core-wf-26)
- [10. Security Considerations](#10-security-considerations)
- [Appendix A. Examples](#appendix-a-examples)
- [Appendix B. References](#appendix-b-references)

## 1. Scope and Layering

This document specifies the GBON transfer syntax: the stream structure,
the token-level grammar, the graph-topology machinery, the canonical
encoding profile, and the decode limits of the GBON wire format. It is
the encoding standard of the repository, and the conformance
obligations of encoders and decoders are defined here (clause 3).

The document family splits by role. The value model underneath the
wire — the neutral value-graph, its identity/sharing/cycles contract,
and the requirements the model imposes on any encoding of it — is
specified in docs/foundations.md; this document is referenced by that
model standard and does not redefine it. Language projections live in
companion binding documents; docs/bindings/go.md is the Go binding, an
appendix that is non-normative with respect to this core. The reserved
frame for bindings in languages other than Go is clause 8.2.

## 2. Conventions

### 2.1 Requirements Language

The key words MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, and
MAY are to be interpreted as described in RFC 2119/8174.

### 2.2 Layer Tags

Every section of this specification carries its layer in its heading:
`(core)` or `(core+annotation)`. The tags have the meaning fixed by the
layer model in the introduction: core rules bind every implementation;
annotations record, inside a core rule, a degradation a projection may
take without lying.

### 2.3 Section IDs and References [WF-1]


Every section of this specification and of its binding documents carries
a stable section ID in its heading: core sections WF-1 through WF-26,
binding sections GO-1 and up (docs/bindings/go.md). The ID is the
reference key of the repository; the displayed section number is reader
cosmetics.

- IDs are assigned once and never reused: a removed section retires its
  ID, a new section receives a fresh one. Section numbers may be
  renumbered freely — references do not follow numbers.
- References across the repository (code comments, documents, tests,
  scripts) cite sections by ID token: WF-n for the core, GO-n for a
  binding.
- The ID dictionary is computed from the headings at check time; the
  reference-lint gate resolves every ID token occurring in any tracked
  file against that dictionary and rejects unknown, duplicate, or reused
  IDs.
- Spec documents carry the normative layer alone: a document of docs/*.md
  does not reference implementation files or implementation identifiers.
  The single legal form of a file reference is an explicit non-normative
  pointer, "(non-normative: see <target>)"; implementation identifiers
  have no legal form at all. The gate semantics live with the
  reference-lint checker (non-normative: see referencelint_test.go).
## 3. Conformance

**Well-formedness and validity.** A byte sequence is well-formed when
it satisfies the grammar of this document (definite lengths, known
opcodes, known argument forms); it is valid when, in addition, its
records satisfy the semantic rules the grammar routes to them —
reference resolution (WF-24), view geometry (WF-17), duplicate-key
rejection (WF-18, KO-8), and canonical minimality (WF-7, WF-25). A
decoder MUST reject ill-formed and invalid input with a format error;
it MUST NOT repair, skip silently, or guess (WF-23: an unknown value
never decodes as success).

**Encoder obligations.** An encoder produces canonical bytes or fails:
minimal arguments (WF-7), minimal view forms (WF-17), minimal dense
prefixes (WF-14, WF-16), registration before children in the intern
order (WF-24). A second implementation of this specification produces
identical bytes or fails (WF-25).

**Decoder obligations.** A decoder validates geometry, widths, and
lengths before any type-introspection or allocation; budgets every
derived allocation at its production point; and answers crafted input
with exactly one of format error, budget error, or a correct value —
never a panic and never a hang (WF-26, clause 9). Truncated input is a
format error; no partial values are returned (WF-4).

**Budgeted decode.** Decoding runs under explicit resource budgets on
every implementation — as a conformance requirement, not a quality
mark: the budget families and their default values are normative
(clause 9.1).

**Unsupported material.** What a decoder cannot represent — an unknown
version component, major always and minor in the draft era (WF-3), a
reserved descriptor kind (WF-22), a NaN map key or a key-reachable cycle
(KO-3, KO-5), an unskippable coder body (WF-6) — is a loud rejection,
never a
lossy default: unsupported-reject is the evolution discipline of the
format (WF-5, WF-6).

The normative rules of this document are enforced by an executable
suite — magic-collision absence (WF-3), canonical map ordering (WF-18,
WF-25), decoder hygiene under crafted input (WF-26), and the
opcode-table absences of GO-1.

## 4. Stream Structure and Versioning

### 4.1 Overview (core) [WF-2]

A stream is a self-describing sequence of values. The format is byte-oriented
and prefix-free: the encoding of each value is self-delimiting, and the whole
stream resolves left to right without lookahead past a token boundary.
Canonical form is always on — there is exactly one legal byte sequence for
every value (see WF-25). The format carries the observable value semantics of
its projections: nil versus empty containers, slice windows with their
observable extent, shared identity, NaN payloads, and non-UTF-8 strings all
survive a round trip.
### 4.2 Stream Header (core) [WF-3]
Every stream begins with a 6-byte header:

```
magic(4B) ‖ major(u8) ‖ minor(u8)
```

- `magic` MUST be the four bytes `67 62 6F 6E` (ASCII "gbon").
- `major` is the major version; this document specifies major `00`,
  the draft era of the format (WF-5). Finalization — the first
  stability commitment of the format — is major 1 (WF-5).
- `minor` is the minor version; this document specifies minor `02`.
  An encoder emits the minor it implements.
A decoder MUST reject with a format error any stream whose magic does not
match, whose major version is unknown, or — while the major is 0 — whose
minor version is unknown (WF-5): the draft era carries no cross-minor
compatibility promises.

The magic shares no prefix with known offset-0 file signatures (PNG, GIF,
ZIP, ELF, PDF, JPEG, RIFF, BMP, gzip, bzip2, xz, 7z, RAR, SQLite, XML, UTF
BOMs, JSON `{`/`[`). Formats with no offset-0 magic (gob, CBOR,
protobuf) are not sniffable and cannot collide by construction.

### 4.3 Value Stream Grammar (core) [WF-4]


The value grammar is prefix-free: every record uses definite lengths and no
indefinite forms exist. A stream is the concatenation of value encodings; a
decoder consumes exactly the bytes of one value per step. A strict prefix of
any well-formed stream is never itself well-formed at a value boundary that
expects more input — truncation is a format error, never a hang.

"Bare" argument bytes (0x00..0x0D) occur only inside record bodies where
grammar fixes the position; a value position always begins with a class
byte (WF-23). The byte-level coincidence between a NIL token and an inline
argument is not a conflict: the positions are distinct.

### 4.4 Versioning (core) [WF-5]


The version ladder: major 0 is the draft era; major 1 is finalization,
the first stability commitment of the format.

- In major 0 a decoder rejects unknown minors: the draft era carries
  no cross-minor compatibility promises, so a canonical-rule revision
  rides a minor bump without stranding older decoders — they reject
  the unknown minor outright (WF-3).
- From major 1 on, minors are additive only: new escape subclasses and
  new descriptor kinds enter through a minor bump, and an older
  decoder either knows the extension or fails on the specific token
  (WF-23).
- Major version changes may break decoding; a decoder rejects unknown
  majors outright (WF-3). After finalization a canonical-rule change
  requires a new major.
- The 16 first-byte nibble classes (0x0..0xF) are fully allocated: no
  new value class can enter through a minor bump directly. New value
  classes appear only through ESC graduation — an experimental
  subclass of the escape class, itself a minor-version addition,
  promoted to core semantics by a subsequent minor bump; private
  subclasses never graduate (WF-23).
- The reserved-kind space (descriptor kinds 16..255, WF-22) is the
  refusal surface of this rule: a decoder that does not know a
  reserved kind fails on the token exactly as WF-22 demands.

### 4.5 Decoder Evolution Contract (core) [WF-6]


Decoding targets a descriptor that may differ from the stream's encoder-side
descriptor. The decoder matches struct fields **by name**: fields present in
the stream but absent in the target are **skipped** (parse-only consumption,
no target materialization, exact boundary), fields absent from the stream are left at
their **default value**, and a field present in both with an incompatible kind
is rejected with a format error. Skipped values honor every token class the
encoder may legitimately emit for that position (built-in coder bodies skip by
grammar; custom coder bodies reject with an unsupported-type error): nil selectors, intern REFs,
view tokens over already-consumed backings, and full records. The stream's
type name must match the target's type name (strict name+structure match,
see WF-22) — names of non-stdlib types carry their package path (WF-22); a
cross-package evolution pair binds both versions to a common wire name
through the name-binding mechanism (WF-22). The gate is nominal outright:
a nameless stream root — structural kinds carry no name (WF-22) — matches
no target, and a chain without a name cannot serve as the target of a kept
reference (WF-22). Skipped values mirror the intern space of WF-24
exactly as the writer allocated it: string and descriptor literals intern
(a subsequent REF from a kept position resolves), while backings, map objects,
and pointer targets stay unmaterialized (GO-3). Adding fields to a struct
is therefore wire-compatible in
both directions (new encoder → old target: skip; old encoder → new target:
zero), matching the Avro/protobuf evolution discipline. The
compatibility has one carve-out: an evolution pair whose kept position
resolves a reference — a REF token or a view token — whose target
stayed unmaterialized under narrowing rejects loudly, a format error
of class `evolution_ref_unmaterialized` firing at the kept reference.
The affected shapes are the aliased ones: a REF naming an aliased map
record opened by a skipped field, a view over a shared backing a
skipped field left unmaterialized, and a reference to a record opened
inside the skipped region — narrowing that cuts a pointer cycle across
fields. Non-aliased narrowing stays wire-compatible: skip and zero,
the Avro/protobuf discipline above. Skipped coder
bodies of user-registered coders stay unskippable: what the format cannot
express on the skip path is a loud error, never a lossy default (§8.2).

## 5. Primitive Field Formats

### 5.1 Integer Arguments — ARG (core) [WF-7]


An integer argument is a selector byte, optionally followed by big-endian
payload bytes:

| Selector | Form | Payload |
|---|---|---|
| 0x0..0x7 | inline | none — the value is the selector |
| 0x8 | u8 | 1 byte, big-endian |
| 0x9 | u16 | 2 bytes, big-endian |
| 0xA | u32 | 4 bytes, big-endian |
| 0xB | u64 | 8 bytes, big-endian |
| 0xC | u128 | 16 bytes, big-endian |
| 0xD | ext | ARG n (n ≥ 9); n bytes, big-endian |
| 0xE, 0xF | reserved | unknown argument form — a decoder rejects it |

Rules:

- Every argument position of every record — lengths, counts, tags, ids,
  offsets, widths — encodes through this one ladder.
- One ladder, both positions: the rung nibble is the low nibble of a
  bare argument byte and of a fused value token's first byte (WF-23)
  alike — a rung spells identically in both. Selectors 0xE/0xF are
  reserved in both positions; a decoder rejects them as unknown
  argument forms.
- Big-endian: bytewise comparison of equal-width arguments agrees with
  numeric comparison.
- Minimal rung is the only legal form: an encoder MUST emit the
  narrowest rung that carries the value; a decoder MUST reject, with a
  format error, any rung whose value fits a narrower rung (leading
  zeros of a wider rung). Boundaries: 7 → inline, 8 → u8; 255 → u8,
  256 → u16; 65535 → u16, 65536 → u32; 2^32−1 → u32, 2^32 → u64;
  2^64−1 → u64, 2^64 → u128; 2^128−1 → u128, 2^128 → ext (17 bytes).
- The u128 rung (0xC) is the 128-bit rung: one fixed 16-byte payload
  carries every value from 2^64 to 2^128−1 (the width-16 INT/UINT
  value bodies, WF-8, WF-9). The ext form (0xD) is the continuation
  beyond: one selector serves every value from 2^128 up — payloads of
  17 bytes and up, the arbitrary-precision rung of INT (WF-8). The
  ext form keeps the length floor n ≥ 9; a payload of 9..16 bytes
  carries a value the u128 rung spans, so under minimality the least
  legal ext payload is 17 bytes. The ext form inherits minimality
  twice over: the payload floor just stated and a nonzero leading
  byte (leading zeros of the payload are non-canonical).

## 6. Value Encodings by Kind

### 6.1 Signed Integers — INT (core+annotation) [WF-8]


Class 0x2. The value body is one argument (WF-7) carrying `zz(n)`, where
`zz` is the zigzag bijection

```
zz(n) = (n << 1) XOR (n >> 63)      (arithmetic shift)
```

mapping 0→0, −1→1, 1→2, −2→3, MinInt64→0xFFFFFFFFFFFFFFFF. The zigzag
bijection itself is defined over the whole integer domain —
n ≥ 0 → 2n, n < 0 → −2n−1 — of which the 64-bit formula above is the
int64 section; every INT value body, at every width, carries the image
of this one bijection under WF-7 minimality.

INT is one ladder of descriptor widths — ARG width (1/2/4/8/16/arb)
(WF-22):

- Widths 1, 2, 4, 8 are the machine sections: width w carries the
  w-byte signed domain, and the value body is the minimal argument of
  the zigzag image.
- Width 16 is the 128-bit section: it carries the i128 domain, whose
  zigzag image is exactly 0..2^128−1 (zz(−2^127) = 2^128−1,
  zz(2^127−1) = 2^128−2). The value body uses the width rungs of
  WF-7 — from 2^64 up the u128 rung (0xC), one fixed 16-byte
  payload; the boundary is minimality itself (WF-7).
- Width arb is the arbitrary-precision rung: every value beyond the
  width-16 domain. The value body is one minimal argument (WF-7) of
  the zigzag image — the ext rung (0xD), payloads of 17 bytes and
  up, riding the token's low nibble like every rung (WF-23).
  There is no separate unbounded kind: arb is a rung of this ladder,
  and nil and zero are distinct tokens (nil is the selector 0 of
  WF-15; zero is an INT value body).

### 6.2 Unsigned Integers — UINT (core+annotation) [WF-9]


Class 0x3. The value body is one argument (WF-7) carrying the value
directly — no zigzag. UINT is the machine ladder, ARG width (1/2/4/8/16)
(WF-22): width w carries the w-byte unsigned domain;
width 16 tops out at 2^128−1 (u128), its body using the width rungs
of WF-7 — from 2^64 up the u128 rung (0xC) — direct values, not
zigzag images. There is no unbounded unsigned rung: every value beyond
2^128−1 — of either sign — is the INT arb rung's domain (WF-8).

(Annotation) The core defines no character kind: a character-typed
value is a UINT under the binding's range rule — Rust `char` is a
Unicode scalar value (≤ 0x10FFFF), Java `char` a UTF-16 code unit;
the range rules are binding content (docs/bindings).

### 6.3 Booleans (core) [WF-10]


Class 0x1. Selector 0 encodes false, 1 encodes true. All other selectors of
this class are reserved; a decoder MUST reject them.

### 6.4 Floats (core+annotation) [WF-11]


Class 0x4. FLOAT carries the binary IEEE 754-2019 forms and only them:
binary16, binary32, binary64, binary128 — widths 2, 4, 8, 16 bytes.
Width equals the form, bijectively: the descriptor width argument
selects the form (WF-22), no two forms share a width, and no form
index exists; no narrowing or widening exists. The value body is the
raw big-endian bits of the form's width. NaN payloads, ±0,
subnormals, and infinities of every form are preserved bit-for-bit;
equality after a round trip is bitwise.

(Annotation) A projection without a native binary16 or binary128
degrades with blame on receive; the per-binding degradation tables
are binding content (docs/bindings).

(Annotation) The canonical decimal interchange is not a FLOAT form.
It is the structural composition (unscaled: INT-arb, scale: INT-32)
under the reserved interchange name `std.decimal`; bindings map
their decimal types onto it by default name-binding (BigDecimal,
rust_decimal). The composition is lossless — no degradation row —
and introduces no new primitive: the unscaled value rides the INT
arb rung (WF-8), the scale the INT-32 machine section.

### 6.5 Complex Numbers (core+annotation) [WF-12]


The core defines no complex kind and allocates no class row for one: a
complex value decomposes as TUPLE(re, im) — a positional pair whose
components are FLOAT forms (WF-11) — under the tuple grammar (WF-20).
Bindings project their complex types onto that composition; a nominal
wrapper where the language needs one is binding content
(docs/bindings). A complex number's components are FLOAT values at
descriptor-borne width (WF-11): the component width is carried by the
descriptor, there is no implicit default, and a binding declares the
width it writes — a complex64 and a complex128 of the same value are
distinct descriptors, never distinct spellings of one default.

### 6.6 Strings (core) [WF-13]


Class 0x6. The argument is the byte length — one ARG of the WF-7
ladder — followed by that many raw bytes. Any byte sequence is legal — there is no UTF-8 validity gate: a
string is a byte sequence, not mandated text. Strings participate in the intern
space (WF-24): the first occurrence is a STRING literal, subsequent occurrences
are REF tokens.

### 6.7 Blobs (core) [WF-14]


Class 0x7. A blob is a byte-slice backing record: `ARG L` (backing
length), `ARG E` (dense prefix length) — each an ARG per WF-7 — then E
raw bytes. Bytes at [E, L) are
implicit zeros (trailing-zero elision, WF-16). E MUST NOT exceed L, and E
MUST be minimal — the byte at position E−1 MUST be nonzero: a zero dense
tail byte is non-canonical and a decoder reject (checked on materialized
and skipped blobs alike; the skipped payload is byte-visible). A blob is
an intern-space record: slices of bytes are VIEW tokens over the blob id,
with the same mechanics as any other slice (WF-17).

### 6.8 Nil Layer (core) [WF-15]


Class 0x0 carries a nil selector: 0=absent; 4=zero-size marker; all
other selectors reserved.
Selector 4 is the zero-size target marker of section 7.1
(WF-24) — a non-nil pointer to a zero-size target. Selector 0 is the
one nil state, and no selector encodes a nil sort: the sort of a nil
is derived, never read from the token — from the static type of the
position or, for a typed nil in an interface or reference position,
from the dynamic descriptor carried with the nil body (WF-24); the
descriptor that is present resolves the chain, and no depth rule
exists. Which nil sorts a projection distinguishes is binding
content (docs/bindings).

nil is never confused with empty: an empty non-nil slice is a VIEW
with len 0 (WF-17); an empty non-nil map is a MAP with count 0
(WF-18).

### 6.9 Arrays and Trailing-Zero Elision (core+annotation) [WF-16]


Class 0x8. An array record is `ARG L; ARG E;` — each an ARG per WF-7 —
followed by E element tokens.
L is the backing length; E is the dense prefix; elements at [E, L) are
implicit zeros and E ≤ L. The elision predicate is bit-level: an element is
elision fodder only when its bit pattern is zero — for floats,
`Float64bits(x) == 0` — so −0.0 is never elided and materializes as a dense
element (±0 survive a round trip bit-for-bit in every position, WF-2/WF-11);
aggregates (structs, arrays) recurse over their components. E MUST be
minimal: element [E−1] MUST NOT be bitwise zero — a materialized record
whose last dense element is zero-valued (nil pointers, empty strings,
+0.0) is non-canonical and a decoder reject. The decoder materializes L
elements (zero-filled) and fills [0, E). An array is an intern-space
record registered before its elements. The element type is not part of the
array record — it comes from the type descriptor context (WF-22).

### 6.10 Slice Views (core) [WF-17]


Class 0x9. A slice value is always a view token over a registered backing
record (array or blob). The geometry of a view is {off, len, extent}:
the window [off, off+len) of visible elements and the addressable extent
window [off, off+extent) with len ≤ extent — the reserved reach beyond the
length that the token carries. Every field of a view body — id, off,
len, extent — encodes as an ARG per WF-7:

| Form | Body | Implied fields |
|---|---|---|
| 0 | id | off=0, len=extent=L |
| 1 | id, off, len | extent=len |
| 2 | id, off, len, extent | — |

Record invariant: `0 ≤ off ≤ off+len ≤ off+extent ≤ L`, where L is
`max(offᵢ+extentᵢ)` over all views of the backing — the encoder truncates the
backing to L, which is semantically transparent (no view can extend a
window past extent). A nil slice is the nil token of WF-15, not a view. Form 0 is
a compaction of fields, not a branching of the model. A view is not itself
an intern-space record: a repeated slice header re-emits the token.

**View-form minimality.** The token MUST use the smallest form that
carries the geometry: form 0 exactly when `off = 0 ∧ len = extent = L`; form
1 when `extent = len` but the form-0 geometry does not hold; form 2 otherwise.
A form-1 token with the form-0 geometry, or a form-2 token with `extent = len`
(which includes the form-0 geometry), is non-canonical and a decoder
reject: there is exactly one legal byte sequence per view.

A view may reference its own backing record while that record's element
list is still being decoded: the backing registers before its elements
(record-then-fill, mirroring WF-24), so a slice reachable from its own
elements — a slice stored as its own element through an interface —
resolves against the mid-fill backing.

**Decoder hygiene.** The decoder MUST validate {off, len, extent}
against L — and the width, length, and budget constraints of every record —
before any type-introspection or allocation: a malformed view is a format error, a
backing length above the slice budget is a budget error, and a decoder MUST
NEVER panic on crafted input.

### 6.11 Maps (core) [WF-18]


Class 0xA. The argument is the pair count — one ARG of the WF-7
ladder — followed by that many key/value pairs. Keys are encoded in canonical order per WF-25 (KO contract);
duplicate key slots — key encodings equal including the identity layer
(KO-8) — are a decoder reject. On materialized maps the check is
value-level: pointer-free keys reject equal skeleton bytes, pointer-carrying
keys collapse at value-model insertion (pair count ≠ final slot count →
reject). On the
skip path (WF-6) the check is byte-level: byte-identical key token
sequences for pointer-free key types are a reject; pointer-carrying keys
carry no skip-path duplicate check (distinct pointers may share byte
identical encodings, KO-2a, and values are not materialized there).

A map literal is an intern-space record (WF-24): it receives its id at the
moment its header is emitted — before its pairs (record-then-fill) — so a
value position inside the pairs may close a cycle through a REF to the map
itself. A repeated encounter of one map object, anywhere else in the
stream, is a REF to that record; duplicating a map body in one stream is
forbidden. An empty non-nil map is a record like any other (count 0); a
nil map is the nil token of WF-15 and never interns.

**Reference hygiene.** A REF in a map-typed position must resolve to a map
record; a REF to any other record sort is a format error, never a type
confusion.

### 6.12 Structs (core+annotation) [WF-19]


Class 0xB. A struct value carries only the field values, strictly in
canonical name-sorted order — the descriptor's field table order (WF-22) —
no per-field tags. Blank fields (`_`) are not part
of the descriptor and are not encoded. Unexported fields are a codec-policy
matter, not a format matter.

### 6.13 Tuples (core) [WF-20]


Class 0x5. A tuple is a positional product: its arity and positional
element types are part of the descriptor's structure (WF-22), and the
value body carries exactly arity element values in positional order —
no tags, no names. A body whose element count differs from the
descriptor's arity is a format error. Positions are never reordered:
canonical name-sorted order governs named tables (struct fields,
variants), not positional products (WF-19, WF-21).

### 6.14 Variants (core) [WF-21]


Class 0xC. A variant value carries its alternative as a leading tag
argument — one ARG per WF-7 — followed by the payload body: `ARG tag;
payload`. The tag is
an index into the variant table of the value's own in-stream
descriptor (WF-22) — self-describing, with no cross-stream index
stability — and is subject to ARG minimality (WF-7): a tag argument
wider than its minimal form is non-canonical and a decoder reject.
The payload is the value of the alternative's type-ref — an anonymous
STRUCT or TUPLE where the alternative carries named or positional
fields: the sum composes over the product kinds, never inside them.
An alternative with no payload fields carries the empty TUPLE(0) —
the unit of positional payload composition, a zero-element payload
body.

The variant table is canonically sorted by variant name, under the
sort key of WF-22; a table emitted in any other order is
non-canonical. A decoder matches alternatives by name: it resolves
the tag through the stream descriptor's table, then binds the named
alternative to its local type. A stream variant whose name is absent
from the decoding descriptor's table is a format error for that
value — evolution is by-name (WF-6), never by position.

A sum with no alternatives cannot be instantiated: a VARIANT
descriptor whose variant table is empty is ill-formed, and a decoder
rejects it. Option and Result are library-level two-variant sums
under this grammar; nesting (Some(None)) resolves naturally through
the payload positions.

### 6.15 Type Descriptors (core) [WF-22]


Class 0xE. A DESC record defines a type; it is self-delimiting and
participates in the intern space (registered before its children, so
recursive types close through REF). Layout:

```
DESC-record := 0xE ‖ kind-selector ‖ [name] ‖ body(kind)
kind-selector := `D0`..`D7` | `D8` u8
```

- **kind** — 16 kinds; kinds 16..255 are reserved (unknown → format error).
  Kinds 0..7 ride one inline selector byte (`D0`..`D7`); kinds 8..15 use
  the u8 form (`D8 08` .. `D8 0F`). The kind selector is subject to
  minimality (WF-7): kind 8 is only `D8 08`, and no kind that fits the
  inline rung rides the u8 form.

| kind | Selector | Type | Body |
|---|---|---|---|
| 0 | `D0` | STRUCT | ARG n; n × {field name, type-ref} |
| 1 | `D1` | VARIANT | ARG n; n × {variant name, type-ref} |
| 2 | `D2` | TUPLE | ARG n; n × type-ref (positional) |
| 3 | `D3` | SLICE | 1 × type-ref (elem) |
| 4 | `D4` | ARRAY ([N]T) | ARG N; 1 × type-ref (elem) |
| 5 | `D5` | MAP | 2 × type-ref (key, elem — in this order) |
| 6 | `D6` | NAMED (defined type) | 1 × type-ref (base) |
| 7 | `D7` | POINTER | 1 × type-ref (target) |
| 8 | `D8 08` | INTERFACE | empty |
| 9 | `D8 09` | BOOL | empty |
| 10 | `D8 0A` | INT | ARG width (1/2/4/8/16/arb) |
| 11 | `D8 0B` | UINT | ARG width (1/2/4/8/16) |
| 12 | `D8 0C` | FLOAT | ARG width (2/4/8/16) |
| 13 | `D8 0D` | STRING | empty |
| 14 | `D8 0E` | BLOB | empty |
| 15 | `D8 0F` | CODER | ARG coderTag |

Every `ARG n` of a descriptor body — kind counts, array lengths, coder
tags — is one argument of the WF-7 ladder.

- **width argument** — the numeric kinds' width (INT 1/2/4/8/16/arb,
  UINT 1/2/4/8/16, FLOAT 2/4/8/16) is one WF-7 argument: 0 = arb (the
  INT rung only — no fixed width), widths 1, 2, 4 the machine widths
  as inline selectors (`01`/`02`/`04`), widths 8 and 16 via the u8
  rung (`08 08`/`08 10` — the inline rung caps at 7, WF-7).

- **name** — a string position of the unified intern space (WF-24): STRING
  literal on first encounter of the string, REF on repeat. The name
  position exists exactly for the nominal kinds — VARIANT, NAMED, CODER;
  structural kinds omit it (no empty-name sentinel exists). A nominal name
  is qualified by the binding's namespace grammar (binding content,
  docs/bindings) and is injective within one stream: one qualified name
  maps to exactly one descriptor, and name matching — including evolution
  pairing (WF-6) — holds within one qualified name. Instantiation is
  unified under the grammar `Name[args]`: a type expression's wire name
  is the constructor name followed by its bracketed argument list, the
  arguments being canonical structural names.
- **collision** — the name policy is hybrid. Derived qualified names stay
  clean: no renaming and no disambiguation suffixes. If two distinct
  nominal types derive one qualified name within one stream
  (crate-version duplicates, same-named namespaces), the encoder rejects
  at registry start with an unsupported-type error naming both origins —
  the decode-side counterpart is a format error at the colliding
  descriptor — and the resolution is explicit name binding (below). The
  reserved standard namespace `std.` cannot collide with a
  language-derived name: `std.decimal` names the decimal interchange
  composition (WF-11) and is reserved — a binding may not rebind it.
- **type-ref** — a type position: DESC literal (first encounter of the
  type) or REF to a descriptor id (repeat). NAMED, POINTER, and INTERFACE
  wrappers each occupy exactly one type-ref position.
- **identity** — descriptors intern by canonical structure (hash-consing).
  Two structural descriptors with the same kind, the same arguments, and
  the same child type-refs, recursively, are one intern record; the second
  occurrence in a stream is a REF. Nominal names do not participate in the
  structural key: a nominal wrapper and its base intern independently —
  one structural record per structure, one wrapper per name, the body
  structure shared. A FLOAT descriptor's width argument is part of its
  structure: structurally identical FLOATs of different forms are
  distinct. The children of a DESC record (name strings, nested
  descriptors) receive ids in DFS encounter order, deterministic in the
  structure of the type.
- **STRUCT body** — ARG n, then n pairs {field name (string position),
  type-ref}. Field order is canonical name-sorted order — the
  bytewise-lexicographic ascending order of the field-name byte
  sequences; the descriptor's field table is emitted in that order and
  value bodies follow it. The sort key is the raw byte sequence,
  case-sensitive ("A" sorts before "a"); no locale, case, or collation
  folding applies. Blank fields do not appear in the descriptor. A
field table emitted in any other order is a decoder reject of class
`field_table_unsorted`.
- **VARIANT body** — ARG n, then n pairs {variant name (string position),
  type-ref}; the table is emitted sorted by variant name under the STRUCT
  sort key, and a table with zero alternatives is ill-formed (WF-21).
- **TUPLE body** — ARG n, then n type-refs, positional. Arity is part of
  the structure; positions are never sorted or reordered (WF-20).
- **CODER** — the body is defined by the coder registered for the type
  name under per-Encoder/per-Decoder registration; the tag binds 1:1 to
  the name per stream — a tag rebound to another name, or a name rebound
  to another tag, is a format error.
- **INTERFACE** — an opaque position type: method sets are a binding
  concern and are not encodable.
- **BLOB** — the canonical byte-sequence kind: a byte slice encoded as a
  SLICE of UINT-8 is non-canonical (WF-25).
- The element type is never duplicated inside an ARRAY record: the
  descriptor context fixes it; self-describing positions carry a descriptor
  REF plus the value body.

**Envelope spellings (normative).** A structural descriptor is
nameless: its DESC record is `E0 ‖ kind selector ‖ body` — no name
position exists for a structural kind (the name bullet above); a
nominal descriptor alone carries the name-ARG between the kind
selector and the body. Two canonical root envelopes, each the stream
header `67 62 6F 6E 00 02` (WF-3) followed by bytes derived from the
tables above. The anonymous INT-8 root descriptor:

    E0 D8 0A 08 08

— `E0` the DESC token (WF-23), `D8 0A` kind 10 INT, `08 08` the width
argument: width 8 rides the u8 rung (the width bullet, WF-7). The
nominal root `std.decimal` (WF-11) — NAMED over its structural
composition, fields in canonical name-sorted order:

    E0 D6 68 0B 73 74 64 2E 64 65 63 69 6D 61 6C
    E0 D0 02 65 73 63 61 6C 65 E0 D8 0A 04
    68 08 75 6E 73 63 61 6C 65 64 E0 D8 0A 00

— `E0 D6` kind 6 NAMED, `68 0B …` the name STRING literal
"std.decimal", then the base type-ref as a first-encounter DESC
literal: `E0 D0 02 …` STRUCT of scale: INT-32 (`E0 D8 0A 04`) and
unscaled: INT-arb (`E0 D8 0A 00`). Nested type-refs inside a DESC
body are DESC literals (first encounter) or REF (repeat); the intern
key is the canonical structure (identity above), and name-ARGs appear
only at nominal positions.

A decoder or encoder may bind a wire name to a local type through name
binding: the binding overrides the derived name on both sides of the wire
without changing the encoding of types that use their derived name. One
chain carries one name: a wire name bound into a pointer chain covers the
whole chain — a second binding touching an existing binding's chain under
a different name rejects with the `name_binding_conflict` class, and
re-binding the same name at another level of the chain is a no-op. A
name bound to two different types, or a binding that conflicts with a
reserved standard name, is rejected with an unsupported-type error.

### 6.16 Opcode Table and Partitioning (core) [WF-23]


The first byte of every token is `class << 4 | arg-form`:

| 0x0 | NIL | selector: 0=absent; 4=zero-size marker; all others reserved |
| 0x1 | BOOL | selector: 0=false, 1=true |
| 0x2 | INT | ARG = zigzag(n); width from descriptor; arb rung via ext |
| 0x3 | UINT | ARG; width from descriptor |
| 0x4 | FLOAT | width per descriptor (2/4/8/16); raw IEEE bits |
| 0x5 | TUPLE | element values in positional order |
| 0x6 | STRING | ARG = byte length; raw bytes; interned |
| 0x7 | BLOB | ARG L; ARG E; E bytes |
| 0x8 | ARRAY | ARG L; ARG E; E elements |
| 0x9 | VIEW | form 0/1/2 geometry |
| 0xA | MAP | ARG = pair count |
| 0xB | STRUCT | field values in canonical name-sorted order |
| 0xC | VARIANT | ARG tag; payload body (tag = index into variant table) |
| 0xD | REF | ARG = intern id |
| 0xE | DESC | type descriptor record |
| 0xF | ESC | second byte = subclass (experimental/private ranges) |

Every `ARG` of this table is one argument of the WF-7 ladder.

Partitioning: classes 0x0..0xE are core; 0xF is the escape class. For an
ESC token the low nibble of the first byte is reserved: an emitter MUST
write zero (byte `F0`); a decoder MUST reject a nonzero nibble — a second
legal spelling of one token would break the one-legal-byte-sequence
contract the moment a subclass graduates. The second byte selects the
subclass and splits the escape space: 0x00..0x7F is the experimental
range, 0x80..0xFF the private range for embedders. An unknown subclass
is a format error.

The same reservation governs class bytes that carry no argument
selector: for the FLOAT, TUPLE, STRUCT, and DESC value tokens (`40`,
`50`, `B0`, `E0`) the low nibble of the first byte is reserved — an
emitter MUST write zero; a decoder MUST reject a nonzero nibble.

An unknown opcode — any selector or form not defined for its class and
position — in a known position is a format error. Silent skipping is
forbidden: an unknown value never decodes as success.

## 7. Graph Encodings: Identity, Sharing, and Cycles

### 7.1 Topology: Intern Space and References (core) [WF-24]


All first-encounter records of reference nature share one per-stream id
space; ids are ARG-encoded per WF-7 and assigned in depth-first preorder from
0 — the first record in the preorder receives id 0:

- backing arrays (including blobs),
- map objects,
- addressable values (pointer targets),
- interned strings,
- type descriptors.

Every record — backing records included — lives for the whole stream: the
intern space is a property of the value sequence, not of one value. A
value's repeated encounter of memory already closed by an earlier
backing record is a view over that record, never a silently new record.

Rules:

- **Registration before children.** A record receives its id at the moment
  its own encoding begins — before any child is encoded. Cyclic structures
  therefore encode: a reference to an enclosing record closes through a REF
  token.
- **REF token** (class 0xD): the argument is the id of a registered
  record. A repeated encounter MUST be a REF or a view over an
  already-registered record; duplicating a record body in one stream is
  forbidden, with one carve-out for backing records (the join rule below).
  A REF to an unregistered id is a format error. A REF names a record
  whose body encoding has started: where the encoder reaches a reference
  to an address whose record body has not started, it starts that body —
  at the record's canonical grain, fixed ahead of emission by the
  canonical grain rule below — before emitting any REF to it; an id
  reserved without a body emits no bytes. The stream is closed under
  reference topology: a REF that a decoder resolves always names a record
  present in the stream with a started body, and a locally legal emission
  whose REF would break this closure is not a legal encoding.
- **Reference positions (type on the cell).** A value position holding
  a pointer — to an interface, to a concrete value, or to a map object
  — encodes the pointer's own state through one leading token of the
  body. A leading NIL token: selector 0 is the nil state — absent —
  and the sort of the nil is derived, never read from the token: from
  the static type of the position or, for a typed nil in an interface
  or reference position, from the dynamic descriptor carried with the
  nil body (WF-15). A typed nil in an interface position is the
  dynamic type's descriptor followed by a nil body: the descriptor
  that is present resolves the chain at its top level, and no depth
  rule exists. Selector 4 is the zero-size marker of the zero-size
  target rule below; any other selector is a format error (WF-15).
  A leading REF is a type-erased
  handle: the argument names one intern record, and the record itself
  carries the type — its sort, and for object records the descriptor
  under which the cell was opened. Descriptor and object records share
  the one id space of this section; that sharing lets a single token
  serve both roles. Resolution is by the sort of the named record,
  uniform across every position and depth: a descriptor record makes
  the REF the dynamic-type tag of the target, with the tagged value
  body following — the first encounter of the dynamic type writes the
  DESC literal, and resolution is the same; an object record makes the
  REF an identity edge to that cell — a cycle or a shared reference,
  no value body following. Reference positions nest: the body of a
  tagged target opens by the same rule, so chains of any depth
  resolve level by level, and a cycle closes by a REF naming an
  enclosing record from any depth and any entry point — a root, an
  interface slot, a field, an element, or a map value. A map object is
  an addressable cell in the same space: a pointer to a map opens the
  map's record, and an identity edge naming a map cell closes a cycle
  through that map. A REF naming a record of any other sort is a
  format error.
- **Cell compatibility and re-encode fidelity.** The consuming position
  fixes the type contract; the named cell fixes the type. A resolution
  the cell's sort or type cannot serve is a format error at the cell,
  never a silent coercion to a neighboring type. Reference levels
  between the position and its named cell materialize as the stream
  reserved them, one cell per reserved id; levels without an id of
  their own carry none. Identity interning is by address: values
  equal in address are one record. A subvalue reachable from the
  record's canonical grain by the derivable descent of this section
  therefore resolves through the record — the record serves a position
  either as that position's own target or through a derivable subvalue,
  and the consuming position fixes the reference grain of the
  materialized handle. Conformance requires the round trip: a decoder
  reconstructs the encoded record-and-edge graph exactly — structure,
  types, identity — so that encoding the decoded value reproduces the
  stream byte for byte; a resolution that cannot re-encode identically
  is a format error, not a decode result. A value skipped by a decoder
  resolves its grain by the one resolution rule of this section: the
  skip and the decode paths share it, and a grain a decoded position
  resolves is a grain a skipped position steps over.
- **Canonical grain rule.** Each address held by the stream's tracked
  reference grains carries one record, opened at the canonical grain of
  the address: the coarsest grain among the tracked grains the stream
  holds for that address, fixed by an encoder pass over the value ahead
  of emission. A tracked grain is the grain of a tracked view a
  reference position of the stream denotes; zero-size target grains
  track nothing (the zero-size rule below). Opening one address at two
  grains is forbidden: the record opens once, at the canonical grain,
  and every position of that address resolves through it.
- **Layout-normal grain.** Where one address carries two or more
  tracked grains that are distinct named views of identical
  structure, the canonical grain is the layout-normal form: the
  intern key, the record's grain, and the record's descriptor use
  the layout-normal form, and a position of a named grain
  materializes through the legal value conversion of the projection.
  The scope of normalization is the intern key and the record's grain
  alone; the type descriptors of positions (WF-22) keep their names —
  the nominal overlay over the structural identity of WF-22, not a
  name-keyed intern.
- **Grain tags, elision, self-tags.** Where a pointer position is the
  opening — the first encounter — of a record whose canonical grain
  differs from the position's static target type, the opening carries
  an explicit grain tag: a REF naming the canonical grain's type
  descriptor, or a first-encounter DESC literal of it, ahead of the
  record body. Where the canonical grain equals the position's static
  target type and that grain is not itself a pointer type, the tag is
  elided and the body follows directly: the grain is statically
  derivable at the position. Where the record's canonical grain is
  itself a pointer type, the opening carries the explicit tag at grain
  equality too — a self-tag — so an opening and a repeat of a
  pointer-grain record stay byte-distinct. A repeated encounter of an
  open record is a bare REF without a tag: the record's grain rides on
  the descriptor under which the record opened. The grain of a record
  is derivable from the stream alone — at an opening by the tag and the
  body's sort and content tag, at grain equality by the position's
  static type, on a repeat by the named record's descriptor;
  resolution never depends on which position asks.
- **Derivable descent.** Where a reference position of static target
  grain Pg resolves against a record of canonical grain Cg with Pg
  distinct from Cg, Pg MUST be derivable from Cg by descent: following
  struct leading fields — every leading field, with
  zero-size fields skipped — and array elements at index zero, each
  step fixed by the type of the pair plus the record's content
  tag. The descent carries no bytes, and a position whose grain is not
  derivable this way leaves the REF a format error at the cell.
- **Interface-grain discrimination.** Where a pointer position of
  interface grain reads a leading descriptor that names both a
  compatible container grain — a struct whose leading-field chain
  reaches the position grain — and a compatible dynamic type of the
  interface value, the container reading wins: the record opens at the
  named container grain. The byte shape of a degenerate payload form —
  a dynamic type that is itself a struct with a leading interface-field
  — read this way is a declared carve-out of the dynamic reading's
  round-trip identity, and encoders MUST NOT emit the interface-dynamic
  reading of that shape on interface-grain positions.
- **Uniform resolution.** Every REF of the stream resolves through the
  one resolution rule of this section: the sort and content tag of the
  named record, the grain tags and descent above, and no other path.
  Rings entered through a root, an interface slot, a field, an element,
  or a map value; double-pointer chains; shared cells; and containers
  reached through their leading storage all resolve by it, at any depth
  and from any entry point.
- **Backing join rule (guard).** A slice/blob position over memory already
  closed by a backing record joins that record — and emits a view over it —
  exactly when: (a) its whole extent-window [ptr, ptr+extent·es) lies
  inside the record's region [origin, origin+L·es); and (b) every element
  of its len-window at record index ≥ E (the record's implicit zero tail
  [E, L)) is bitwise zero in the live memory. The extent of a view is the
  width of its addressable window — the geometry field of WF-17, with
  len ≤ extent. A repeat that fails either condition is unrepresentable
  over the closed record and MUST open a fresh record — the sole
  body-duplication carve-out. Candidate records are considered in
  encounter order; the first that satisfies the rule wins.
- **First-encounter snapshot.** A record's body is a snapshot taken when
  its encoding begins: the dense prefix [0, E) is not re-read on subsequent
  encounters, mirroring pointer and map identity interning — mutations of
  already-encoded content between values are invisible, exactly as they
  are within one value.
- **Zero-size target rule.** A target type of zero size tracks no
  record. A non-nil pointer to a zero-size target encodes as the
  zero-size marker — the NIL-class token of selector 4 (WF-15) — with
  no REF and no address, and decodes into a fresh zero-size allocation
  whose nil-ness is preserved: the marker and the nil token of
  selector 0 stay byte-distinct. Reference identity of zero-size
  targets is neither preserved nor observable. Where a zero-size grain
  and a non-zero-size tracked grain share an interior address, the
  tracked grain keeps the record — opened at its own grain, never at a
  struct grain of the unrelated container — and the zero-size alias
  carries the marker.

## 8. Canonical and Portable Profiles

### 8.1 Canonical Encoding (core) [WF-25]


Canonical mode is always on, and it is a decode-side contract: the
non-canonical byte classes defined normatively above — non-minimal view
forms (WF-17); non-minimal dense prefixes E — checked on materialization
for arrays and slices (WF-16) and on both paths for blobs (WF-14); a SLICE
of UINT-8 in a byte-slice position (WF-22) — the canonical-grain position
classes are checked at descriptor parse, the descriptor spelling alone
decides them, no value materialization required; a nonzero ESC reserved nibble
(WF-23); and non-minimal arguments (WF-7) — are decoder rejects, not encoder
conventions.

**Stability tiers.** Byte determinism of the canonical encoding is a
three-rung ladder, monotone by construction: a higher tier only fixes
what lower tiers leave unspecified, never alters fixed bytes. The
grounding dichotomy: value determinants are fixed by the core; identity
determinants are instantiated by binding declaration.

- **Stability tier T1 (cross-language).** Over the stable class — the
  decidable predicate defined below — the encoding is a function of the
  value alone: any process, any construction order, any conforming
  implementation produces identical bytes.
- **Stability tier T2 (cross-machine, one language).** Where a binding
  declares an instantiation of the identity determinants — the E5
  tie-break and the E4 zero-sign — and their determinism conditions,
  encodings agree across machines of that language within the declared
  conditions. Tier-2 governs only decoder-unverifiable determinants:
  no canonicality rule forks between tiers.
- **Stability tier T3 (intra-process).** Re-encoding a value within one
  process reproduces the bytes bit-for-bit: the E5 discriminator is
  deterministic within one encoding.

The decode-side contract is tier-invariant: the canonicality rejects
of this section hold in every tier. A binding's tier-2 declaration
states, per determinant: the determinant form, its determinism scope,
and its verification hook. The tier-1 claim covers the whole integer
domain (the arb rung of the INT ladder and its ext argument, WF-8/WF-7)
and every FLOAT form (WF-11), with two scoped qualifications. (i)
*Extent agreement:* the tier-1 claim holds between implementations
that bind the same value to the view extent (WF-24); two projections
may differ on join boundaries only through their extent binding, and
that difference is a documented projection annotation, not a core
divergence. (ii) *±0 map keys:* the stored sign of a zero float key is
a projection concern (axiom E4 below — the zero-sign determinant,
tier-2 instantiable) and is excluded from the tier-1 claim.

The byte sequence of a stream is a deterministic function of the
value sequence, including the memory-encounter
history across values: the backing join rule of WF-24 is normative — fully
determined by the closed geometry and the live bytes — so a second
implementation joins (or declines to join) identically. No timestamps,
addresses, or randomness enter the encoded bytes; intern tables are
deterministic in DFS order (WF-24); map order is fixed by the three-phase KO
scheme (KO-1, KO-2b, KO-2a below). The one place identity
determinants participate is the E5 tie-break, which fixes the ORDER of
otherwise indistinguishable map pairs, never byte content.

**Key equality axioms (core).** The core owns the equality and order of
map keys through five axioms; the KO clauses below are their operational
contract.

- **E1 Key domain.** A map key is any encodable value. Sequence values
  and VARIANT values are inside the key domain: they compare by value
  equality, and byte-equal skeletons of such keys are true duplicates —
  a decoder reject (KO-8). Map values in key position and float keys
  are carried by the core and admitted per binding: where the binding's
  language lacks the equality, the binding rejects (KO-4). NaN is the
  only core-level ban: the encoder rejects a NaN key with a typed error
  naming the path to the offender — a NaN slot is unreachable and
  undeletable through every observable operation (lookup, range, and
  deletion cannot name it), and two slots carrying identical raw bits
  could not be told apart, breaking injectivity (KO-2). A cycle
  reachable from a key position is a core-level encoder reject with a
  classified termination error: value equality over a cyclic key does
  not terminate (KO-5).
- **E2 Skeleton.** The skeleton of a key is its literal, non-interning
  encoding: repeated pointers are collapsed to the nil token (WF-15)
  — equality of reference-kind components is decided by the identity
  layer (KO-2), never by dereferencing the target. Sequences and
  VARIANTs in key position recurse by value into their components, and
  the E1 cycle guard is what keeps their key encoding and comparison
  finite.
- **E3 Total order.** Map keys are totally ordered by bytewise
  lexicographic comparison of their skeletons.
- **E4 ±0 collapse.** At most one zero float key of a given float key
  type may occupy a map: +0 and −0 are one key of the order (E3 sees
  distinct raw bits, the domain sees one slot). Which sign is stored in
  the slot is not fixed by the core — it is the zero-sign determinant,
  the projection's key-overwrite semantics instantiated by binding
  declaration — and the encoder never normalizes ±0 in any position: the
  stored representation is observable and round-trips bit-for-bit (KO-3).
- **E5 Tie-break.** Pairs equal in (skeleton, value bytes) — legal when
  their keys occupy distinct identity slots (E2) — are ordered by a
  stable discriminator over the tie-break identity determinant — a form
  instantiated by binding declaration — that never enters the encoded
  bytes. Within one encoding the discriminator is deterministic;
  between processes it is fixed only where the binding declares the
  determinant's tier-2 instantiation.

**KO-1 Base order.** The total order of map keys is bytewise lexicographic
over the key **skeleton** (axiom E2): the literal, non-interning canonical
encoding of the key value — strings as STRING literals (never REF tokens),
repeated pointer components collapsed to the nil token (WF-15), interfaces as
(dynamic-type
tag, value), headers and tags included. The skeleton is a sort key, not a wire
artifact: on the wire, keys use the regular canonical encoding (interned
strings, REFs). Requires definite lengths and minimal-length arguments
(both normative above).

**KO-2 Injectivity + identity layer.** A key encoding is the canonical
value encoding plus an identity discriminator for reference-kind
components: distinct map slots yield distinct key skeletons; emission is
independent of the iteration order of the in-memory map (the pair sort
precedes emission, then discriminators apply deterministically); the
decoder materializes
slot keys separately, so a round trip preserves the slot count of the
materialized map and every equality relation observable in the value
model. The identity layer
encodes value equality (axioms E1/E2), not addresses.

**KO-2b Value-bytes tie-break.** Pairs whose key skeletons are byte-equal
are ordered by the canonical bytes of the pair VALUE: a full scoped
sub-marshal of the value body (the same encoder, a nested budget). The
phase is deterministic and value-derived — it never consults
implementation-run identity. It exists because byte-equal skeletons are legal (KO-2a below),
and the pair order must stay a total order.

**KO-2a Pointer tie-break** *(instantiation of axiom E5).* Keys whose
skeletons are identical yet occupy distinct map slots (byte-equal keys
carrying distinct identities, after KO-2b left their values equal or the
values themselves are byte-equal) are ordered among themselves by an
identity-sequence discriminator: for each key, a sequence derived from
the identities of its reference-kind components, compared
lexicographically. The discriminator never enters the encoded bytes — it
fixes only the order of the tied pairs; within one encoding it is
deterministic, and its cross-process guarantee is fixed only by the
binding's declared determinism scope (E5). The concrete instantiation —
the identity form and the component tie rules — is the binding's
tier-2 declaration: determinant form, determinism scope, verification
hook.

**KO-3 Float keys.** Encoded as raw bits, big-endian, type width. −0.0 is
not normalized (axiom E4: ±0 cannot coexist in one map; the stored representation is
observable through range and is encoded as-is; round-trip equality for
float keys is bitwise). NaN keys are FORBIDDEN: the encoder rejects them
with a typed error carrying the path to the offender (axiom E1: NaN is
outside the key domain — unreachable and undeletable through observable
operations; identical raw bits across slots would
break injectivity, KO-2). NaN values outside key positions are legal.

**KO-4 Interface keys.** A key encoding of an interface is (dynamic-type
tag, canonical value) — the type tag is part of the key bytes: int64(1) and
int32(1) are different keys. A nil interface key and a typed-nil key are
byte-distinct: the nil token of WF-15 against a dynamic descriptor plus
nil body. Map values in key position are admitted per binding (axiom E1);
a cycle reachable from the key is the encoder reject of KO-5.

**KO-5 Cyclic keys.** A cycle reachable from a key position — through any
reference a key's value graph reaches, at any depth — is a core-level
encoder reject with a classified termination error (axiom E1): sequences
and VARIANTs compare by value, and value equality over a cycle does not
terminate. The guard is loud and names the path; it never hangs and never
silently truncates the comparison.

**KO-6 Canonical forms.** Integers: minimal length — one line for the
whole integer domain, the minimal bare or ext argument of the zigzag image
(WF-7/WF-8/WF-22), the arb rung included, so key order agrees with the
argument-byte order over the integers. Floats: raw bits BE at type width.
Strings: length-prefixed raw bytes, ordered bytewise. Structs: fields
strictly in the descriptor's canonical name-sorted order (WF-19, WF-22);
blank fields neither encode nor compare. Sequences: arrays by ascending
index, tuples positionally — elementwise, in position order. Variants:
tag argument, then the payload skeleton (WF-21). Interfaces: (dynamic-type
tag, value). Pointers: KO-2 identity layer. Nil: the one nil token
(WF-15); a typed nil carries its dynamic descriptor plus nil body.
Canonicalization never reorders structure except maps.

**KO-7 Non-serializable categories.** chan is rejected in every position,
including keys (live resources are not data). Key-position admission is
E1's domain: sequence and VARIANT keys inside; NaN and key-reachable
cycles core rejects; map-in-key per binding (KO-3, KO-4, KO-5).

**KO-8 Duplicate keys.** Duplicate key slots — key encodings equal
including the identity layer — are a decoder reject. On materialized maps:
pointer-free keys reject equal skeleton bytes; pointer-carrying keys
collapse at value-model insertion (pair count ≠ final slot count →
reject). Byte-equal
skeletons in distinct slots are legal and are ordered by KO-2b/KO-2a —
that is the tie-break's raison d'être; on the skip path, byte-identical
key token sequences for pointer-free key types are a reject (WF-18). A
duplicate is always an attack or corruption.

**Stable class.** The stable class is the tier-1 class: a decidable
predicate over the value domain. A value is stable when no map anywhere in its graph
applies the E5 tie-break — no two of its map pairs are byte-equal in
skeleton and value bytes across distinct identity slots — and no map in
its graph holds a zero float key (axiom E4: the stored sign of a zero
float key is a projection concern, excluded from the tier-1
claim). Pointer-carrying keys whose pair value
bytes differ are inside the stable class: KO-2b orders such pairs
deterministically by value bytes before any identity discriminator
applies, so the E5 tie-break never fires for them. The class is not
enlarged by any domain change: the KO-2a tie-break stays excluded from
the class, and no discriminator is added to the value model to
stabilize tied pairs. An application MAY restore membership by moving
identity into value (a declared discriminator inside the key), without
any format change.

**Guard contract (stable mode).** Encoders offer a stable mode — one
mode, the tier-1 guarantee; tier-2 and tier-3 are declarations, not
encoder modes. WHEN invoked on a value outside the stable class, the
encoder MUST reject the value with a deterministic classified error
naming the path to the offender; the classification is a function of
the offending rule alone (E5 tie-break applied, or a zero float key
present), never of process state. The completeness of the guard is
conditional on H-1: the declaration that exactly the declared identity
determinants exhaust the sources of process-dependence. A binding
projects the class (a static conservative predicate over types, a
dynamic exact predicate at encode time); the projection lives in the
binding document, not here.

### 8.2 Portable Profile (Frame)

The portable profile — the binding of the core to a language other
than Go — is a frame, not a catalogue of projections. This clause
fixes the frame: the normative formulation of the domain, the classes
of bindings, the indirection contract of native projections, the
obligations of a binding, and the status of the binding documents. The
companion reference map (docs/foundations.md) remains in force: full
abstraction at the language boundary and the degradation ladder
(foundations, clause 6.5).

**Domain (normative).** The formulation below is normative for the
portable profile and for every future binding document; it is quoted
verbatim and may not be paraphrased.

> The core is an autonomous, language-independent model of values: a
> **domain** given by a signature of sorts and constructors (a term
> algebra), by axioms (E1–E5 and their development), and by the
> canonicalizing encoding function — a bijection between the canonical
> forms of values and byte strings. The core neither contains nor
> generalizes languages: every binding is a **partial denotational
> assignment** — a language construct receives a denotation in the core
> domain, or a declared degradation on a rung of the ladder
> (wire-visible, as a core annotation), or a refusal (a loud error).
> Where the assignment is total, the axioms are preserved; where it
> degrades, the weakening of an axiom is declared on the rung, with
> blame on the projection. Membership in the domain is decided by the
> anchor committee (A1–A3, and A4 for declared design freedom).

Non-normative reading keys:

- Relation to languages: not subsumption (a "superclass"), but
  factorization — language value models are interpretations of
  fragments of the domain with declared loss.
- Pattern terminology: language mapping (CORBA / ASN.1 / protobuf) —
  the same thing as the federation view.
- Verifiability: a cell of the CVA matrix receives the answer type
  `denotation exists | degradation(rung) | refusal`; the A1 anchor is
  the substance of the core (signature + axioms), the wire grammar is
  the canonicalizing function; the admission criterion for the core is
  operational.

**Classes of bindings.**

| Binding class | Membership criterion |
|---|---|
| Native projection | The language carries its own value model; every construction of its serializable fragment receives a denotation in the core domain, or a declared degradation on the ladder, or a loud error. |
| Codegen | The projection is materialized by generated code from a declarative schema; membership follows the value model of the target language. |
| Manual runtime | The language carries no value model to project; the binding is a hand-written runtime library over the wire primitives. |

C carries no value model — a C binding is a manual runtime, a different
binding class rather than a lesser native projection. C++ adds no axis
beyond the frozen cross-language set: sharing and cycles are covered,
value semantics is covered, binary128 is a rung of the ladder; which
C++ to bind is a dialect choice and therefore binding design, not core
business.

**Indirection contract.**

Sharing and cycles are first-class core invariants (WF-24: the intern
space and references), not an optional capability of a profile. The
indirection constructions of a native projection — references and
wrapper types such as Rust's `&`/`Box`/`Rc`/`Arc` — map onto the intern
space and REF. The residual decode-side angle, materializing typed
wrappers in the target language's types, is binding territory and lives
in the binding documents, not in the core.

**Obligations and polarity.**

Every binding, on every rung of the ladder, preserves the core
invariants of identity, sharing, and cycles at each hop; may degrade
annotations only with blame attributed to the projection, never
silently; rejects what it cannot represent with a loud error, never a
lossy coercion; keeps every norm — including rejections and
degradations — on the specification side, where the binding documents
are a series of contracts of this specification and an implementation's
legitimate acts are a conformance statement, a change request, and
non-normative engineering documentation, never a unilateral normative
statement; and the implementation owns its unobservable engineering —
allocations, pools, layout, API ergonomics.

**Status of the frame.** The portable profile is a frame: concrete
projections are not developed here. `bindings/<lang>.md` is the series
name for binding documents; the owner of the binding documents is the
specification side.
A second implementation binds its own projection against the core plus
this frame; the extent-agreement and ±0 stored-sign qualifications of
WF-25 apply as written.

## 9. Limits and Budgeted Decode

### 9.1 Decoder Hygiene (core) [WF-26]


- Validate every {off, len, extent} triple against the backing L, every
  width, and every length — all ARG-carried values of WF-7 — before any
  type-introspection or allocation (WF-17).
- Budget the backing length L — not the view length — against the slice
  budget; exceeding it is a budget error (a crafted L of 2^50 must fail by
  budget, not by allocation).
- Charge derived backing allocations at their production point:
  a slice/blob backing is booked as L·elemsize — the implicit zero tail
  [E,L) included, the Binary adapter BLOB body included, the arb/ext
  integer value body booked by its advertised ext length — against the
  same MaxBytes
  counter as input bytes, before the allocation happens; a crafted
  L·es or ext length exceeding the budget fails by budget, never by
  allocation.
- The MaxBytes counter's scope is one value — the grammar's own
  top-level unit (§4.3: a decoder consumes exactly the bytes of one
  value per step): it opens at the value's start and resets when the
  next value begins, so cumulative consumption beyond MaxBytes across
  the values of a stream is conformant — there is no per-stream
  cumulative cap. Within one value, input bytes and charged
  allocations share the counter.
- Truncated input is a format error; no partial values are returned. No
  partial state is exposed either: decode is atomic with respect to the
  target — on any decode error, including a budget error raised from a
  recovered decoder panic, the target is left unmodified, so a failed
  decode never leaves a mixed old/new value. How a binding meets this
  guarantee — staging into codec-owned storage with a single committing
  assignment, in-place materialization with snapshot-restore, or another
  equivalent mechanism — is binding territory: the implementation owns its
  unobservable engineering (§8.2, Obligations and polarity).
- NAMED-wrapper budget accounting is asymmetric by side, deliberately: the
  encoder charges 1 output node per wrapper, the decoder 2 nodes and 2
  depth frames (the descriptor unwrap recurses through the value body).
  The sides count different resources — output nodes on encode,
  materialization frames on decode — so the asymmetry is correct; it is
  pinned here so a second implementation's budgets do not diverge silently.
- A REF in a typed position must resolve to a record of the matching
  sort: map positions take map records (WF-18), pointer positions take
  object records (WF-24); a REF to any other sort is a format error,
  never a type confusion.
- A degenerate NAMED cycle — a wrapper chain closing onto itself
  through a crafted REF, at the root or in an element-descriptor
  position — is a format error, never a hang and never a budget
  overdraft: no limit value can legalize a self-referential wrapper.
- Crafted input yields exactly one of: format error, budget error, or a
  correct value. Panics and hangs are defects. A failing underlying read
  is neither: it is attributed as an environment (io) fault with the
  original error reachable as the cause. The three families — format,
  budget, environment — are distinct attribution channels; a binding
  keeps them distinguishable in its public error surface, where stable
  class identities are contract and diagnostic text is not.

**Default budgets (normative).** A zero Limits value resolves to these
defaults on each side; the names are the Limits fields, the powers are
the contract (encode-side entries marked — do not apply: the input side
is trusted, only derived resources are capped):

| Budget | Decode default | Encode default |
|---|---|---|
| MaxDepth | 10^4 | 10^6 |
| MaxNodes | 10^6 | 10^7 |
| MaxBytes | 10^8 | 10^9 |
| MaxMapPairs | 10^6 | — |
| MaxSliceLen | 10^8 | — |

## 10. Security Considerations

GBON input is hostile by default: a byte stream from an untrusted peer
is an attack surface, and this specification places the defenses in
the format contract itself rather than in implementation goodwill.

- **Resource exhaustion.** Crafted lengths, depths, and counts are the
  primary complex-attack surface — amplification via
  declared-but-never-delivered backing storage. The budgeted-decode
  contract (clause 9) requires every derived allocation to be charged
  against an explicit budget at its production point and rejects the
  oversized before the allocation: decode fails by budget, never by
  allocation. The budget families cover the classical
  complexity-attack dimensions (depth, nodes, bytes, map pairs, slice
  length); their default values are normative (clause 9.1).
- **Non-termination.** The grammar is prefix-free with definite
  lengths only (WF-4): truncation is a format error, never a hang;
  cyclic structures close through references (WF-24), so decoding
  terminates on them; a degenerate descriptor cycle is a format error
  (WF-26).
- **Silent data fabrication.** Unknown opcodes, unknown subclasses,
  and reserved selectors are format errors (WF-15, WF-22, WF-23); no
  value is ever silently skipped, defaulted, or coerced into existence —
  the format never turns crafted bytes into a plausible wrong value
  (WF-6).
- **Error-channel hygiene.** Decoded values, keys, and stream names
  never enter the one-line error text (GO-5): the diagnostic channel
  is not a data-exfiltration or log-injection surface.
- **Stream identity.** The magic constant makes GBON bytes sniffable
  and collision-checked against known offset-0 signatures (WF-3).
  Content security — confidentiality, authenticity — is out of scope:
  the format carries no cryptography and composes with a wrapping
  secure channel.

## Appendix A. Examples

Worked micro-examples live with each construct (clauses 4–9); this
appendix collects the baseline illustrations. Every byte below follows
directly from the normative tables of this document.

**Stream header.** Every stream of this specification begins with the
same six bytes — the magic, major `00`, minor `02` (WF-3):

    67 62 6F 6E 00 02

**Inline arguments.** An ARG whose value is 0..7 is the selector
itself (WF-7): the value `5` in a bare argument position is the single
byte `05`; `8` needs the u8 form `08 08`; `255` is `08 FF`; `256`
crosses the u16 boundary and is `09 01 00`.

**Zigzag.** INT carries `zz(n)` — 0→0, −1→1, 1→2, −2→3 (WF-8): the
argument of `−1` is the value `1`, the argument of `−2` the value `3`.

**Booleans.** The first byte of every token is `class << 4 |
arg-form` (WF-23): with class `0x1` and selectors 0/1, false is the
byte `10` and true the byte `11`.

**Conformance vectors (non-normative).** A machine-readable conformance
corpus lives in this repository: per-category vector files under
`vectors/` with a `manifest.json` index — vector identifiers `V-n`,
verdicts `ok`/`format`/`budget`, and per-vector derivation chains from
the normative tables of this document. The corpus is data for
implementations and their test readers; it is not normative prose, and
the tables and rules of this document remain the sole source of byte
prescriptions.

## Appendix B. References

The consolidated external anchor map — every cited source with its
support and verification status — is `docs/references.md`. This
document's normative citations: RFC 2119, RFC 8174 (clause 2.1), and
IEEE 754-2019 (clause 6.4).
