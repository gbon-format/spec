# GBON Wire Format Specification

Normative specification of the GBON wire format — the binary transfer
syntax of the GBON value model (the model itself is specified by
docs/foundations.md).

This document defines the format contract: the core grammar plus the
CODER descriptor extension (kind 14) and the BIGINT descriptor
extension (kind 15). A change to an opcode, descriptor rule, or
canonical rule of the core requires a new major version of the format;
additive extensions enter through minor versions only (WF-21). Sections
carry stable IDs — core sections WF-1 through WF-24 — that are the
reference keys of the repository (WF-24); the displayed section numbers
are reader cosmetics.

```
Format version: 0.0 (major 0, minor 0)
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
  - [2.3 Section IDs and References [WF-24]](#23-section-ids-and-references-wf-24)
- [3. Conformance](#3-conformance)
- [4. Stream Structure and Versioning](#4-stream-structure-and-versioning)
  - [4.1 Overview (core) [WF-1]](#41-overview-core-wf-1)
  - [4.2 Stream Header (core) [WF-2]](#42-stream-header-core-wf-2)
  - [4.3 Value Stream Grammar (core) [WF-3]](#43-value-stream-grammar-core-wf-3)
  - [4.4 Versioning (core) [WF-21]](#44-versioning-core-wf-21)
  - [4.5 Decoder Evolution Contract (core) [WF-23]](#45-decoder-evolution-contract-core-wf-23)
- [5. Primitive Field Formats](#5-primitive-field-formats)
  - [5.1 Integer Arguments — ARG (core) [WF-4]](#51-integer-arguments--arg-core-wf-4)
- [6. Value Encodings by Kind](#6-value-encodings-by-kind)
  - [6.1 Signed Integers — INT (core+annotation) [WF-5]](#61-signed-integers--int-coreannotation-wf-5)
  - [6.2 Unsigned Integers — UINT (core+annotation) [WF-6]](#62-unsigned-integers--uint-coreannotation-wf-6)
  - [6.3 Booleans (core) [WF-7]](#63-booleans-core-wf-7)
  - [6.4 Floats (core+annotation) [WF-8]](#64-floats-coreannotation-wf-8)
  - [6.5 Complex (core+annotation) [WF-9]](#65-complex-coreannotation-wf-9)
  - [6.6 Strings (core) [WF-10]](#66-strings-core-wf-10)
  - [6.7 Blobs (core) [WF-11]](#67-blobs-core-wf-11)
  - [6.8 Nil Tokens (core) [WF-12]](#68-nil-tokens-core-wf-12)
  - [6.9 Arrays and Trailing-Zero Elision (core+annotation) [WF-14]](#69-arrays-and-trailing-zero-elision-coreannotation-wf-14)
  - [6.10 Slice Views (core) [WF-15]](#610-slice-views-core-wf-15)
  - [6.11 Maps (core) [WF-16]](#611-maps-core-wf-16)
  - [6.12 Structs (core+annotation) [WF-17]](#612-structs-coreannotation-wf-17)
  - [6.13 Type Descriptors (core) [WF-18]](#613-type-descriptors-core-wf-18)
  - [6.14 Opcode Table and Partitioning (core) [WF-19]](#614-opcode-table-and-partitioning-core-wf-19)
- [7. Graph Encodings: Identity, Sharing, and Cycles](#7-graph-encodings-identity-sharing-and-cycles)
  - [7.1 Topology: Intern Space and References (core) [WF-13]](#71-topology-intern-space-and-references-core-wf-13)
- [8. Canonical and Portable Profiles](#8-canonical-and-portable-profiles)
  - [8.1 Canonical Encoding (core) [WF-20]](#81-canonical-encoding-core-wf-20)
  - [8.2 Portable Profile (Frame)](#82-portable-profile-frame)
- [9. Limits and Budgeted Decode](#9-limits-and-budgeted-decode)
  - [9.1 Decoder Hygiene (core) [WF-22]](#91-decoder-hygiene-core-wf-22)
- [10. Security Considerations](#10-security-considerations)
- [Appendix A. Examples](#appendix-a-examples)
- [Appendix B. Declared Origins](#appendix-b-declared-origins)
- [Appendix C. References](#appendix-c-references)

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

### 2.3 Section IDs and References [WF-24]


Every section of this specification and of its binding documents carries
a stable section ID in its heading: core sections WF-1 through WF-24,
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
reference resolution (WF-13), view geometry (WF-15), duplicate-key
rejection (WF-16, KO-8), and canonical minimality (WF-4, WF-20). A
decoder MUST reject ill-formed and invalid input with a format error;
it MUST NOT repair, skip silently, or guess (WF-19: an unknown value
never decodes as success).

**Encoder obligations.** An encoder produces canonical bytes or fails:
minimal arguments (WF-4), minimal view forms (WF-15), minimal dense
prefixes (WF-11, WF-14), registration before children in the intern
order (WF-13). A second implementation of this specification produces
identical bytes or fails (WF-20).

**Decoder obligations.** A decoder validates geometry, widths, and
lengths before any type-introspection or allocation; budgets every
derived allocation at its production point; and answers crafted input
with exactly one of format error, budget error, or a correct value —
never a panic and never a hang (WF-22, clause 9). Truncated input is a
format error; no partial values are returned (WF-3).

**Budgeted decode.** Decoding runs under explicit resource budgets on
every implementation — as a conformance requirement, not a quality
mark: the budget families and their default values are normative
(clause 9.1).

**Unsupported material.** What a decoder cannot represent — an
unknown major version (WF-2), a reserved descriptor kind (WF-18), a
dynamically uncomparable map key (KO-4), an unskippable coder body
(WF-23) — is a loud rejection, never a lossy default:
unsupported-reject is the evolution discipline of the format (WF-21,
WF-23).

The normative rules of this document are enforced by an executable
suite — magic-collision absence (WF-2), canonical map ordering (WF-16,
WF-20), decoder hygiene under crafted input (WF-22), and the
opcode-table absences of GO-1.

## 4. Stream Structure and Versioning

### 4.1 Overview (core) [WF-1]

A stream is a self-describing sequence of values. The format is byte-oriented
and prefix-free: the encoding of each value is self-delimiting, and the whole
stream resolves left to right without lookahead past a token boundary.
Canonical form is always on — there is exactly one legal byte sequence for
every value (see WF-20). The format carries the observable value semantics of
its projections: nil versus empty containers, slice windows with their
observable extent, shared identity, NaN payloads, and non-UTF-8 strings all
survive a round trip.
### 4.2 Stream Header (core) [WF-2]
Every stream begins with a 6-byte header:

```
magic(4B) ‖ major(u8) ‖ minor(u8)
```

- `magic` MUST be the four bytes `67 62 6F 6E` (ASCII "gbon").
- `major` is the major version; this document specifies major `00`,
  the draft era of the format (WF-21). Finalization — the first
  stability commitment of the format — is major 1 (WF-21).
- `minor` is the minor version; this document specifies minor `00`.
  Minors are additive within a major: an encoder emits the minor it
  implements.
A decoder MUST reject with a format error any stream whose magic does not
match or whose major version is unknown. A stream with an unknown minor
version (minor greater than the decoder knows) MUST be read normally:
minor-version changes are additive-only.

The magic shares no prefix with known offset-0 file signatures (PNG, GIF,
ZIP, ELF, PDF, JPEG, RIFF, BMP, gzip, bzip2, xz, 7z, RAR, SQLite, XML, UTF
BOMs, JSON `{`/`[`). Formats with no offset-0 magic (gob, CBOR,
protobuf) are not sniffable and cannot collide by construction.

### 4.3 Value Stream Grammar (core) [WF-3]


The value grammar is prefix-free: every record uses definite lengths and no
indefinite forms exist. A stream is the concatenation of value encodings; a
decoder consumes exactly the bytes of one value per step. A strict prefix of
any well-formed stream is never itself well-formed at a value boundary that
expects more input — truncation is a format error, never a hang.

"Bare" argument bytes (0x00..0x10) occur only inside record bodies where
grammar fixes the position; a value position always begins with a class
byte (WF-19). The byte-level coincidence between a NIL token and an inline
argument is not a conflict: the positions are distinct.

### 4.4 Versioning (core) [WF-21]


The version ladder: major 0 is the draft era — minors are additive
within it, and a decoder reads every stream of a known major. Major 1
is finalization, the first stability commitment of the format; within
the draft era a decoder rejects only unknown majors. The ladder carries
no content history: every descriptor kind, token class, and argument form
specified in this document is a start condition of 0.0, not an
addition attributed to a minor.

- Major version changes may break decoding; a decoder rejects unknown
  majors outright (WF-2).
- Minor version changes are additive: new escape subclasses and new
  descriptor kinds appear only through a minor bump; an older decoder
  either knows the extension or fails on the specific token (WF-19).
- The 16 first-byte nibble classes (0x0..0xF) are fully allocated: no new
  value class can enter through a minor bump directly. New value classes
  appear only through ESC graduation — an experimental 0xE subclass
  (itself a minor-version addition) promoted to core semantics by a subsequent
  minor bump; private 0xF subclasses never graduate.
- The reserved-kind space (descriptor kinds 16..255, WF-18) is the refusal
  surface of this rule: a decoder that does not know a reserved kind fails
  on the token exactly as WF-18 demands.

### 4.5 Decoder Evolution Contract (core) [WF-23]


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
see WF-18) — names of non-stdlib types carry their package path (WF-18); a
cross-package evolution pair binds both versions to a common wire name
through the name-binding mechanism (WF-18). Skipped values mirror the intern space of WF-13
exactly as the writer allocated it: string and descriptor literals intern
(a subsequent REF from a kept position resolves), while backings, map objects,
and pointer targets stay unmaterialized (GO-3). Adding fields to a struct
is therefore wire-compatible in
both directions (new encoder → old target: skip; old encoder → new target:
zero), matching the Avro/protobuf evolution discipline.
A change of canonical form for an existing value class follows the same
discipline through migration by rewrite: streams encoded under the
earlier spelling stay readable forever (the kind-14 "big.Int" spelling,
WF-18), while every re-encode emits the canonical form (kind 15) — a
stream rewritten once through a decode and encode pair carries only the
canonical form. Skipped coder bodies of user-registered coders stay
unskippable. The skip semantics of the kind-14 big-integer spelling are
fixed as unsupported-reject: a decoder that encounters a skipped
kind-14 big-integer field rejects it loudly, exactly like any
unskippable coder body — what the format cannot express on the skip
path is a loud error, never a lossy default (§8.2). A subsequent minor
version may open a skip form through the change process (WF-21); until
then the loud reject is the norm.

## 5. Primitive Field Formats

### 5.1 Integer Arguments — ARG (core) [WF-4]


An integer argument is a selector byte, optionally followed by big-endian
payload bytes:

| Selector | Form | Payload |
|---|---|---|
| 0x00..0x0B | inline | none — the value is the selector |
| 0x0C | u8 | 1 byte, big-endian |
| 0x0D | u16 | 2 bytes, big-endian |
| 0x0E | u32 | 4 bytes, big-endian |
| 0x0F | u64 | 8 bytes, big-endian |
| 0x10 | ext | ARG n (n ≥ 9); n bytes, big-endian |

Rules:

- ARG is the single mechanism for all nested integer fields of records
  (lengths, counts, ids, offsets, widths).
- Big-endian: bytewise comparison of equal-width arguments agrees with
  numeric comparison.
- Minimal length is the only legal form: an encoder MUST emit the
  narrowest form that carries the value; a decoder MUST reject, with a
  format error, any width form whose value fits a narrower form (leading
  zeros of a wider width). Boundaries: 11 → inline, 12 → u8; 255 → u8,
  256 → u16; 65535 → u16, 65536 → u32; 2^32−1 → u32, 2^32 → u64; and
  2^64−1 → u64, 2^64 → ext.
- The ext form serves the BIGINT value body (WF-18). Its selector is legal only
  where the grammar routes it — the BIGINT value body (WF-18). In every
  token position the low nibble of the first byte cannot exceed 0xF, so
  the selector is unreachable there by construction; in every other bare
  position it is an unknown argument form and a decoder rejects it at the
  token. The ext form inherits minimality twice over: n ≥ 9 (nine bytes
  are the least that carries a value ≥ 2^64) and a nonzero leading byte
  (leading zeros of the payload are non-canonical).

## 6. Value Encodings by Kind

### 6.1 Signed Integers — INT (core+annotation) [WF-5]


Class 0x2. The argument carries `zz(n)` where `zz` is the zigzag bijection

```
zz(n) = (n << 1) XOR (n >> 63)      (arithmetic shift)
```

mapping 0→0, −1→1, 1→2, −2→3, MinInt64→0xFFFFFFFFFFFFFFFF, encoded per WF-4.
Signed values up to the full int64 range use this class.

The zigzag bijection itself is defined over the whole integer domain —
n ≥ 0 → 2n, n < 0 → −2n−1 — of which the 64-bit formula above is the
int64 section. Values outside the int64 range travel as the BIGINT
descriptor kind (WF-18), whose value body carries the zigzag image as a
bare argument (WF-4): inline and width forms below 2^64, the ext form at
and above.

### 6.2 Unsigned Integers — UINT (core+annotation) [WF-6]


Class 0x3. The argument carries the value directly. UINT exists for values
above MaxInt64, whose zigzag image needs 65 bits; such values have no INT
form. UINT tops out at 2^64−1: everything wider — of either sign — is the
BIGINT kind's domain (WF-5, WF-18).

### 6.3 Booleans (core) [WF-7]


Class 0x1. Selector 0 encodes false, 1 encodes true. All other selectors of
this class are reserved; a decoder MUST reject them.

### 6.4 Floats (core+annotation) [WF-8]


Class 0x4. Form 0 carries a float32 as 4 raw IEEE 754-2019 bits, form 1
carries a float64 as 8 raw bits, both big-endian. Form 2 (width 16)
carries a decimal128 as 16 raw IEEE 754-2019 bits; the width-16
FLOAT descriptor and form 2 are a fixed pair, as width 4 ↔ form 0 and
width 8 ↔ form 1. Width equals the type: no narrowing or widening exists
(no float16). NaN payloads, ±0, subnormals, and infinities of the binary
forms are preserved bit-for-bit; equality after a round trip is bitwise.

### 6.5 Complex (core+annotation) [WF-9]

Class 0x5. Form 0 carries complex64, form 1 complex128: the raw bits of the
real part followed by the raw bits of the imaginary part, each per WF-8.
A complex is not synthesized as a struct.

### 6.6 Strings (core) [WF-10]


Class 0x6. The argument is the byte length, followed by that many raw
bytes. Any byte sequence is legal — there is no UTF-8 validity gate: a
string is a byte sequence, not mandated text. Strings participate in the intern
space (WF-13): the first occurrence is a STRING literal, subsequent occurrences
are REF tokens.

### 6.7 Blobs (core) [WF-11]


Class 0x7. A blob is a byte-slice backing record: `ARG L` (backing length),
`ARG E` (dense prefix length), then E raw bytes. Bytes at [E, L) are
implicit zeros (trailing-zero elision, WF-14). E MUST NOT exceed L, and E
MUST be minimal — the byte at position E−1 MUST be nonzero: a zero dense
tail byte is non-canonical and a decoder reject (checked on materialized
and skipped blobs alike; the skipped payload is byte-visible). A blob is
an intern-space record: slices of bytes are VIEW tokens over the blob id,
with the same mechanics as any other slice (WF-15).

### 6.8 Nil Tokens (core) [WF-12]

Class 0x0 carries a nil-kind selector. The taxonomy of nil kinds — which
nil sorts a projection distinguishes and which selector each occupies —
is defined by the binding (GO-4 for the Go value model). Selectors 4..11
are reserved. nil is never confused with empty: an empty non-nil slice is
a VIEW with len 0 (WF-15); an empty non-nil map is a MAP with count 0
(WF-16).

### 6.9 Arrays and Trailing-Zero Elision (core+annotation) [WF-14]


Class 0x8. An array record is `ARG L; ARG E;` followed by E element tokens.
L is the backing length; E is the dense prefix; elements at [E, L) are
implicit zeros and E ≤ L. The elision predicate is bit-level: an element is
elision fodder only when its bit pattern is zero — for floats,
`Float64bits(x) == 0` — so −0.0 is never elided and materializes as a dense
element (±0 survive a round trip bit-for-bit in every position, WF-1/WF-8);
aggregates (structs, arrays) recurse over their components. E MUST be
minimal: element [E−1] MUST NOT be bitwise zero — a materialized record
whose last dense element is zero-valued (nil pointers, empty strings,
+0.0) is non-canonical and a decoder reject. The decoder materializes L
elements (zero-filled) and fills [0, E). An array is an intern-space
record registered before its elements. The element type is not part of the
array record — it comes from the type descriptor context (WF-18).

### 6.10 Slice Views (core) [WF-15]


Class 0x9. A slice value is always a view token over a registered backing
record (array or blob). The geometry of a view is {off, len, extent}:
the window [off, off+len) of visible elements and the addressable extent
window [off, off+extent) with len ≤ extent — the reserved reach beyond the
length that the token carries:

| Form | Body | Implied fields |
|---|---|---|
| 0 | id | off=0, len=extent=L |
| 1 | id, off, len | extent=len |
| 2 | id, off, len, extent | — |

Record invariant: `0 ≤ off ≤ off+len ≤ off+extent ≤ L`, where L is
`max(offᵢ+extentᵢ)` over all views of the backing — the encoder truncates the
backing to L, which is semantically transparent (no view can extend a
window past extent). A nil slice is the nil token of WF-12, not a view. Form 0 is
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
(record-then-fill, mirroring WF-13), so a slice reachable from its own
elements — a slice stored as its own element through an interface —
resolves against the mid-fill backing.

**Decoder hygiene.** The decoder MUST validate {off, len, extent}
against L — and the width, length, and budget constraints of every record —
before any type-introspection or allocation: a malformed view is a format error, a
backing length above the slice budget is a budget error, and a decoder MUST
NEVER panic on crafted input.

### 6.11 Maps (core) [WF-16]


Class 0xA. The argument is the pair count, followed by that many
key/value pairs. Keys are encoded in canonical order per WF-20 (KO contract);
duplicate key slots — key encodings equal including the identity layer
(KO-8) — are a decoder reject. On materialized maps the check is
value-level: pointer-free keys reject equal skeleton bytes, pointer-carrying
keys collapse at value-model insertion (pair count ≠ final slot count →
reject). On the
skip path (WF-23) the check is byte-level: byte-identical key token
sequences for pointer-free key types are a reject; pointer-carrying keys
carry no skip-path duplicate check (distinct pointers may share byte
identical encodings, KO-2a, and values are not materialized there).

A map literal is an intern-space record (WF-13): it receives its id at the
moment its header is emitted — before its pairs (record-then-fill) — so a
value position inside the pairs may close a cycle through a REF to the map
itself. A repeated encounter of one map object, anywhere else in the
stream, is a REF to that record; duplicating a map body in one stream is
forbidden. An empty non-nil map is a record like any other (count 0); a
nil map is the nil token of WF-12 and never interns.

**Reference hygiene.** A REF in a map-typed position must resolve to a map
record; a REF to any other record sort is a format error, never a type
confusion.

### 6.12 Structs (core+annotation) [WF-17]


Class 0xB. A struct value carries only the field values, strictly in
descriptor order (WF-18) — no per-field tags. Blank fields (`_`) are not part
of the descriptor and are not encoded. Unexported fields are a codec-policy
matter, not a format matter.

### 6.13 Type Descriptors (core) [WF-18]


Class 0xD. A DESC record defines a type; it is self-delimiting and
participates in the intern space (registered before its children, so
recursive types close through REF). Layout:

```
DESC-record := 0xD‖ARG(kind) ‖ name ‖ body(kind)
```

- **kind** — 16 kinds; kinds 16..255 are reserved (unknown → format error).
  Kinds 0..11 ride inline in the first byte (`D0`..`DB`); kinds 12..15 use
  the u8 form (`DC 0C`, `DC 0D`, `DC 0E`, `DC 0F`). The kind argument is
  subject to minimality (WF-4): kind 12 is only `DC 0C`.

| kind | Selector | Type | Body after name |
|---|---|---|---|
| 0 | `D0` | STRUCT | ARG n; n × {field name, type-ref} |
| 1 | `D1` | SLICE | 1 × type-ref (elem) |
| 2 | `D2` | ARRAY ([N]T) | ARG N; 1 × type-ref (elem) |
| 3 | `D3` | MAP | 2 × type-ref (key, elem — in this order) |
| 4 | `D4` | NAMED (defined type) | 1 × type-ref (base) |
| 5 | `D5` | POINTER | 1 × type-ref (pointee) |
| 6 | `D6` | INTERFACE | empty (an opaque, interface-like wrapper; method sets are a binding concern and are not encodable) |
| 7 | `D7` | BOOL | empty |
| 8 | `D8` | INT | ARG width (1/2/4/8) |
| 9 | `D9` | UINT | ARG width (1/2/4/8) |
| 10 | `DA` | FLOAT | ARG width (4/8/16; 16 ↔ form 2) |
| 11 | `DB` | COMPLEX | ARG width (4/8, per component) |
| 12 | `DC 0C` | STRING | empty |
| 13 | `DC 0D` | BLOB | empty (canonical []byte/[]uint8; a SLICE of UINT-8 is non-canonical, WF-20) |
| 14 | `DC 0E` | CODER | ARG coderTag — the body is defined by the coder registered for the type name under per-Encoder/per-Decoder registration; the tag binds 1:1 to the name per stream (a tag rebound to another name or a name rebound to another tag is a format error); kind 14 is a start condition of 0.0 (WF-21) |
| 15 | `DC 0F` | BIGINT | empty — the value body is one bare argument (WF-4): inline/width forms for a zigzag image (WF-5) below 2^64, the ext form (n ≥ 9, nonzero leading byte) at and above; a nil value is the nil selector 0 (WF-12), byte-identical to the inline zero it coincides with (WF-3). Kind 15 — and the BIGINT grammar — is a start condition of 0.0 (WF-21) |

- **name** — a string position of the unified intern space (WF-13): STRING
  literal on first encounter of the string, REF on repeat. Named types
  carry the full name; unnamed composites carry the canonical type string
  ("[]T", "[N]T", "map[K]V", "*T"); []byte/[]uint8 is the name "[]byte"
  with kind BLOB. The name is the descriptor-intern key (WF-13): names
  are qualified by namespace — the short form (pkg.Type) for a type
  inside the implementation platform's own namespace (its standard
  library, and the program's main package), the import-path-qualified
  form (import/path/pkg.Type) for a type outside it. The short form
  alone collides across same-named namespaces and would collapse
  distinct types into one descriptor REF. Evolution pairs (WF-23)
  therefore hold only within one namespace path. Origin of the split:
  the reference implementation's platform (Go) introduced the
  standard-library/main-package short form; the rule above states the
  same observable behavior as a namespace rule, with that platform
  convention declared as its origin, not as the norm itself.
- **built-in BIGINT name** — the wire name of kind 15 is the platform
  integer name "big.Int": the bytes are frozen and renaming is
  impossible — the name is reserved and cannot be bound. Origin: the
  name is the reference platform's standard-library short form, as with
  time in kind 14 — a declared origin fact, not a normative preference
  for that platform. The kind-14 coder form under this name is
  readable forever, never emitted again — the canonical encoding of a
  big integer is kind 15 (WF-23). A stream mixing the two forms under
  the one name cannot leave an encoder: the descriptor name claim is
  structural, so a writer that has committed one form under the name
  rejects the other as a rebinding.
  A decoder holds no such claim — each position dispatches by its own
  descriptor kind, so a crafted mixed stream decodes (each element through
  its own form) exactly as the same bytes would decode apart.
- **type-ref** — a type position: DESC literal (first encounter of the
  type) or REF to a descriptor id (repeat). NAMED, POINTER, and INTERFACE
  wrappers each occupy exactly one type-ref position.
- **STRUCT body** — ARG n, then n pairs {field name (string position),
  type-ref}; field order is the owning type's declaration order
  (deterministic); blank
  fields do not appear in the descriptor.
- **id order** — the children of a DESC record (name strings, nested
  descriptors) receive ids in DFS encounter order, deterministic in the
  structure of the type.
- The element type is never duplicated inside an ARRAY record: the
  descriptor context fixes it; self-describing positions carry a descriptor
  REF plus the value body.



A decoder or encoder may bind a wire name to a local type through name
binding: the binding overrides the derived name on both sides of the wire
without changing the encoding of types that use their derived name. A
name bound to two different types, or a binding that conflicts with a
built-in name, is rejected with an unsupported-type error.

### 6.14 Opcode Table and Partitioning (core) [WF-19]


The first byte of every token is `class << 4 | arg-form`:

| 0x0 | NIL | selector: 0=nil-ptr, 1=nil-slice, 2=nil-map, 3=nil-iface; 4..11 reserved |
| 0x1 | BOOL | selector: 0=false, 1=true |
| 0x2 | INT | ARG = zigzag(n) (WF-5); the whole integer domain beyond int64 is the BIGINT kind (WF-18) |
| 0x3 | UINT | ARG (WF-6) |
| 0x4 | FLOAT | form 0: f32 (4B); form 1: f64 (8B); form 2: decimal128 (16B) (WF-8) |
| 0x5 | COMPLEX | form 0: c64; form 1: c128 (WF-9) |
| 0x6 | STRING | ARG = byte length; raw bytes; interned (WF-10) |
| 0x7 | BLOB | ARG L; ARG E; E bytes (WF-11) |
| 0x8 | ARRAY | ARG L; ARG E; E elements (WF-14) |
| 0x9 | VIEW | form 0: {id}; form 1: {id,off,len}; form 2: {id,off,len,extent} (WF-15) |
| 0xA | MAP | ARG = pair count (WF-16) |
| 0xB | STRUCT | field values in descriptor order (WF-17) |
| 0xC | REF | ARG = intern id (WF-13) |
| 0xD | DESC | type descriptor record (WF-18) |
| 0xE | ESC-EXP | second byte = experimental subclass |
| 0xF | ESC-PRIV | second byte = private subclass |

Partitioning: classes 0x0..0xD are core; 0xE is the experimental escape
range; 0xF is the private escape range for embedders. For classes 0xE/0xF
the low nibble of the first byte is reserved: an emitter MUST write zero
(bytes `E0`/`F0`); a decoder MUST reject a nonzero nibble — a second legal
spelling of one token would break the one-legal-byte-sequence contract the
moment a subclass graduates. The second byte selects the subclass; an
unknown experimental or private subclass is a format error.

An unknown opcode — any selector or form not defined for its class and
position — in a known position is a format error. Silent skipping is
forbidden : an unknown value never decodes as success.

## 7. Graph Encodings: Identity, Sharing, and Cycles

### 7.1 Topology: Intern Space and References (core) [WF-13]


All first-encounter records of reference nature share one per-stream id
space; ids are ARG-encoded and assigned in depth-first preorder:

- backing arrays (including blobs),
- map objects,
- addressable values (pointer targets),
- interned strings,
- type descriptors.

Every record — backing records included — lives for the whole stream: the
intern space is a property of the value sequence, not of one value. A
a value's repeated encounter of memory already closed by an earlier
backing record is a view over that record, never a silently new record.

Rules:

- **Registration before children.** A record receives its id at the moment
  its own encoding begins — before any child is encoded. Cyclic structures
  therefore encode: a reference to an enclosing record closes through a REF
  token.
- **REF token** (class 0xC): the argument is the id of a record
  registered record. A repeated encounter MUST be a REF or a view over an
  already-registered record; duplicating a record body in one stream is
  forbidden, with one carve-out for backing records (the join rule below).
  A REF to an unregistered id is a format error.
- **Pointer-to-interface positions.** A value position holding a pointer
  to an interface encodes the pointer's own state through one leading
  token of the body. A leading REF resolves by the sort of the named
  intern record: a descriptor record names the dynamic type of the
  pointee — the REF is the dynamic-type tag, and the tagged value body
  follows; an object record is the pointer target itself — a cycle or
  shared reference, and no value body follows. A REF naming a record of
  any other sort, or an object record that is not the target of this
  pointer, is a format error. A leading NIL token: selector 0 is the nil
  pointer; selector 3 is a non-nil pointer whose pointee holds a nil
  interface; any other selector is a format error (WF-12). On the first
  encounter of the dynamic type the tag is a DESC literal instead of a
  REF; resolution is the same.
- **Backing join rule (guard).** A slice/blob position over memory already
  closed by a backing record joins that record — and emits a view over it —
  exactly when: (a) its whole extent-window [ptr, ptr+extent·es) lies
  inside the record's region [origin, origin+L·es); and (b) every element
  of its len-window at record index ≥ E (the record's implicit zero tail
  [E, L)) is bitwise zero in the live memory. The extent of a view is the
  width of its addressable window — the geometry field of WF-15, with
  len ≤ extent. A repeat that fails either condition is unrepresentable
  over the closed record and MUST open a fresh record — the sole
  body-duplication carve-out. Candidate records are considered in
  encounter order; the first that satisfies the rule wins.
- **First-encounter snapshot.** A record's body is a snapshot taken when
  its encoding begins: the dense prefix [0, E) is not re-read on subsequent
  encounters, mirroring pointer and map identity interning — mutations of
  already-encoded content between values are invisible, exactly as they
  are within one value.
- Zero-size reference identity is neither preserved nor observable: the
  format does not track it.

## 8. Canonical and Portable Profiles

### 8.1 Canonical Encoding (core) [WF-20]


Canonical mode is always on, and it is a decode-side contract: the
non-canonical byte classes defined normatively above — non-minimal view
forms (WF-15); non-minimal dense prefixes E — checked on materialization
for arrays and slices (WF-14) and on both paths for blobs (WF-11); a SLICE
of UINT-8 in a byte-slice position (WF-18); a nonzero ESC reserved nibble
(WF-19); and non-minimal arguments (WF-4) — are decoder rejects, not encoder
conventions.
A second implementation of this specification produces identical bytes or
fails — the claim extends over the whole integer domain (the BIGINT kind
and its ext argument, WF-18/WF-4) and over the decimal128 form (WF-8) —
with two scoped qualifications. (i) *Extent agreement:* the claim
holds between implementations that bind the same value to the view extent
(WF-13); two projections may differ on join boundaries only through their
extent binding, and that difference is a documented projection annotation,
not a core divergence. (ii) *±0 map keys:* the stored sign of a zero
float key is a projection concern (axiom E4 below; GO-2) and is excluded
from the cross-implementation claim. The byte sequence of a stream is a
deterministic function of the value sequence, including the memory-encounter
history across values: the backing join rule of WF-13 is normative — fully
determined by the closed geometry and the live bytes — so a second
implementation joins (or declines to join) identically. No timestamps,
addresses, or randomness enter the encoded bytes; intern tables are
deterministic in DFS order (WF-13); map order is fixed by the three-phase KO
scheme (KO-1, KO-2b, KO-2a below). The one place implementation-defined
identity participates is the E5 tie-break, which fixes
the ORDER of otherwise indistinguishable map pairs, never byte content.

**Key equality axioms (core).** The core owns the equality and order of
map keys through five axioms; the KO clauses below are their operational
contract.

- **E1 Key domain.** A map key is any encodable value whose kind admits
  equality in the value model. NaN and dynamically uncomparable kinds
  (slice/map/func at any depth) are outside the key domain: the encoder
  rejects them with a typed error naming the path to the offender. The
  exclusion is a property of the value model itself, not of any host
  language: a NaN slot is unreachable and undeletable through every
  observable operation (lookup, range, and deletion cannot name it), and
  two slots carrying identical raw bits could not be told apart, breaking
  injectivity (KO-2).
- **E2 Skeleton.** The skeleton of a key is its literal, non-interning
  encoding: repeated pointers are collapsed to the nil marker — equality
  of reference-kind components is decided by the identity layer (KO-2),
  never by dereferencing the pointee. Because skeletons never
  dereference, key encoding terminates on cyclic structures.
- **E3 Total order.** Map keys are totally ordered by bytewise
  lexicographic comparison of their skeletons.
- **E4 ±0 collapse.** At most one zero float key of a given float key
  type may occupy a map: +0 and −0 are one key of the order (E3 sees
  distinct raw bits, the domain sees one slot). Which sign is stored in
  the slot is not fixed by the core — it is the projection's
  key-overwrite semantics (GO-2) — and the encoder never normalizes ±0 in
  any position: the stored representation is observable and round-trips
  bit-for-bit (KO-3).
- **E5 Tie-break.** Pairs equal in (skeleton, value bytes) — legal when
  their keys occupy distinct identity slots (E2) — are ordered by a
  stable implementation-defined discriminator that never enters the
  encoded bytes. Within one encoding the discriminator is deterministic;
  between processes it is unspecified.

**KO-1 Base order.** The total order of map keys is bytewise lexicographic
over the key **skeleton** (axiom E2): the literal, non-interning canonical
encoding of the key value — strings as STRING literals (never REF tokens),
repeated pointer components collapsed to the nil marker, interfaces as
(type tag,
value), headers and tags included. The skeleton is a sort key, not a wire
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
deterministic, across processes or replays it is unspecified (E5). The
concrete instantiation — the identity form and the component tie rules —
is defined by the binding (Go: see GO-2).

**KO-3 Float keys.** Encoded as raw bits, big-endian, type width. −0.0 is
not normalized (axiom E4: ±0 cannot coexist in one map; the stored representation is
observable through range and is encoded as-is; round-trip equality for
float keys is bitwise). NaN keys are FORBIDDEN: the encoder rejects them
with a typed error carrying the path to the offender (axiom E1: NaN is
outside the key domain — unreachable and undeletable through observable
operations; identical raw bits across slots would
break injectivity, KO-2). NaN values outside key positions are legal.

**KO-4 Interface keys.** A key encoding of an interface is (concrete type
tag, canonical value) — the type tag is part of the key bytes: int64(1) and
int32(1) are different keys. nil-interface and typed-nil are distinct
tokens. A dynamically uncomparable kind (slice/map/func at any depth,
axiom E1) in a key position is an encoder reject.

**KO-5 Cyclic keys.** Supported by the object-id/backref mechanics:
skeletons never dereference pointers (axiom E2), so key encoding and
comparison terminate on cyclic structures; the uncomparable kinds are
excluded up front by KO-4. Self-references close inside the key
encoding.

**KO-6 Canonical forms.** Integers: minimal length — one line for the
whole integer domain, the minimal bare or ext argument of the zigzag image
(WF-4/WF-5/WF-18), so key order agrees with the argument-byte order over
the integers. Floats: raw bits BE at type width. Complex: the pair of raw-bit components, NaN components
forbidden in key position (same rationale as KO-3). Strings:
length-prefixed raw bytes, ordered bytewise. Structs: fields strictly in
descriptor order; blank fields neither encode nor compare. Arrays: by
ascending index. Interfaces: (type tag, value). Pointers: KO-2 identity
layer. Nil tokens per reference kind. Canonicalization never reorders
structure except maps.

**KO-7 Non-serializable categories.** chan is rejected in every position,
including keys (live resources are not data). Dynamically uncomparable
kinds in key positions are rejected per KO-4.

**KO-8 Duplicate keys.** Duplicate key slots — key encodings equal
including the identity layer — are a decoder reject. On materialized maps:
pointer-free keys reject equal skeleton bytes; pointer-carrying keys
collapse at value-model insertion (pair count ≠ final slot count →
reject). Byte-equal
skeletons in distinct slots are legal and are ordered by KO-2b/KO-2a —
that is the tie-break's raison d'être; on the skip path, byte-identical
key token sequences for pointer-free key types are a reject (WF-16). A
duplicate is always an attack or corruption.

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

Sharing and cycles are first-class core invariants (WF-13: the intern
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
WF-20 apply as written.

## 9. Limits and Budgeted Decode

### 9.1 Decoder Hygiene (core) [WF-22]


- Validate every {off, len, extent} triple against the backing L, every width,
  and every length before any type-introspection or allocation (WF-15).
- Budget the backing length L — not the view length — against the slice
  budget; exceeding it is a budget error (a crafted L of 2^50 must fail by
  budget, not by allocation).
- Charge derived backing allocations at their production point:
  a slice/blob backing is booked as L·elemsize — the implicit zero tail
  [E,L) included, the Binary adapter BLOB body included, the BIGINT value
  body booked by its advertised ext length — against the same MaxBytes
  counter as input bytes, before the allocation happens; a crafted
  L·es or ext length exceeding the budget fails by budget, never by
  allocation.
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
  sort: map positions take map records (WF-16), pointer positions take
  object records (WF-13); a REF to any other sort is a format error,
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
  lengths only (WF-3): truncation is a format error, never a hang;
  cyclic structures close through references (WF-13), so decoding
  terminates on them; a degenerate descriptor cycle is a format error
  (WF-22).
- **Silent data fabrication.** Unknown opcodes, unknown subclasses,
  and reserved selectors are format errors (WF-18, WF-19); no value is
  ever silently skipped, defaulted, or coerced into existence — the
  format never turns crafted bytes into a plausible wrong value
  (WF-23).
- **Error-channel hygiene.** Decoded values, keys, and stream names
  never enter the one-line error text (GO-5): the diagnostic channel
  is not a data-exfiltration or log-injection surface.
- **Stream identity.** The magic constant makes GBON bytes sniffable
  and collision-checked against known offset-0 signatures (WF-2).
  Content security — confidentiality, authenticity — is out of scope:
  the format carries no cryptography and composes with a wrapping
  secure channel.

## Appendix A. Examples

Worked micro-examples live with each construct (clauses 4–9); this
appendix collects the baseline illustrations. Every byte below follows
directly from the normative tables of this document.

**Stream header.** Every stream of this specification begins with the
same six bytes — the magic, major `00`, minor `00` (WF-2):

    67 62 6F 6E 00 00

**Inline arguments.** An ARG whose value is 0..11 is the selector
itself (WF-4): the value `5` in a bare argument position is the single
byte `05`; `12` needs the u8 form `0C 0C`; `255` is `0C FF`; `256`
crosses the u16 boundary and is `0D 01 00`.

**Zigzag.** INT carries `zz(n)` — 0→0, −1→1, 1→2, −2→3 (WF-5): the
argument of `−1` is the value `1`, the argument of `−2` the value `3`.

**Booleans.** The first byte of every token is `class << 4 |
arg-form` (WF-19): with class `0x1` and selectors 0/1, false is the
byte `10` and true the byte `11`.

**Conformance vectors (non-normative).** A machine-readable conformance
corpus lives in this repository: per-category vector files under
`vectors/` with a `manifest.json` index — vector identifiers `V-n`,
verdicts `ok`/`format`/`budget`, and per-vector derivation chains from
the normative tables of this document. The corpus is data for
implementations and their test readers; it is not normative prose, and
the tables and rules of this document remain the sole source of byte
prescriptions.

## Appendix B. Declared Origins

Declared-origin facts — where a wire artifact adopts a name of the
reference platform's standard library — are recorded at their
definition sites (WF-18) as projections, not as history of this
format. The consolidated external anchor map — sources, roles, and
verification statuses — is `docs/references.md`.

## Appendix C. References

The consolidated external anchor map — every cited source with its
support and verification status — is `docs/references.md`. This
document's normative citations: RFC 2119, RFC 8174 (clause 2.1), and
IEEE 754-2019 (clause 6.4).
