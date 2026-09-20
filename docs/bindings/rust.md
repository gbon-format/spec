# GBON Rust Binding

Binding of the GBON wire-format core to the Rust value model. The core
specification (docs/wire-format.md, format 0.2, minor 2) is
normative and language-independent; this document is the Rust
projection — an appendix non-normative with respect to the core —
carrying the parts of the contract specific to the Rust value model.
Sections of this binding carry stable IDs RS-1..RS-7; core rules are
cited by their WF-n section IDs (the ID scheme is defined by core
section WF-1). Resolvability of every ID reference across the
repository is enforced by the reference-lint gate (non-normative: see
the gbon-rust repository).

**Contents**

- [1. Type Mapping](#1-type-mapping)
  - [1.1 Non-Encodable Categories [RS-1]](#11-non-encodable-categories-rs-1)
  - [1.2 Nil Model [RS-4]](#12-nil-model-rs-4)
  - [1.3 Interface Positions and Trait Objects](#13-interface-positions-and-trait-objects)
  - [1.4 Descriptor Names in Rust](#14-descriptor-names-in-rust)
- [2. Lifecycle and Behavioral Notes](#2-lifecycle-and-behavioral-notes)
  - [2.1 Cross-Version Stability Notes [RS-2]](#21-cross-version-stability-notes-rs-2)
  - [2.2 Known Limitations [RS-3]](#22-known-limitations-rs-3)
  - [2.3 Schema Snapshot Mechanics [RS-6]](#23-schema-snapshot-mechanics-rs-6)
  - [2.4 Evolution Intents [RS-7]](#24-evolution-intents-rs-7)
- [3. Error Conformance](#3-error-conformance)
  - [3.1 Error Classes [RS-5]](#31-error-classes-rs-5)
  - [3.2 Coder Error Contract](#32-coder-error-contract)
- [4. Examples and Interop Notes](#4-examples-and-interop-notes)
  - [4.1 Consumption Mappings](#41-consumption-mappings)
  - [4.2 Worked Examples](#42-worked-examples)
- [5. Grounding](#5-grounding)
  - [5.1 Source Hierarchy](#51-source-hierarchy)
  - [5.2 Denotation Table](#52-denotation-table)
  - [5.3 Degeneracy Register](#53-degeneracy-register)
  - [5.4 Stable-class projection](#54-stable-class-projection)

## 1. Type Mapping

### 1.1 Non-Encodable Categories [RS-1]

Raw pointers (`*const T`, `*mut T`), function values (fn pointers,
closures, the fn traits), and mutable borrows have no opcodes in any
class — the categories have no wire image. The encoder reports an
unsupported-type error with the path to the offending field.
PhantomData is a marker type that carries no values: it is excluded
from encoding — a field of PhantomData type appears in no descriptor
(blank fields, WF-19) and produces no records, no references, and no
rejects. Live runtime objects outside the value model — sockets,
locks, file handles — carry no denotation either; the reject is the
same class. What crosses the wire is data (1.3).

**Key-domain restriction (from core WF-25).**

The core's key domain admits any encodable value as a map key (axiom
E1) and excludes exactly NaN and cycles reachable from a key position
(KO-5); identity keys are a binding-declared layer (KO-2). This
binding declares no identity layer (2.1): every Rust key compares by
value. Map-in-key is legal (value equality, 5.2); float keys are
impossible at the type level — floats implement PartialEq but not Eq
(std:Eq) — so the zero-sign determinant of axiom E4 has no Rust
carrier. The cyclic-key reject is a core contract restated as a
binding observable in the degradation table (2.1).

### 1.2 Nil Model [RS-4]

The core's nil layer (WF-15) carries one nil state: selector 0,
absent. No selector encodes a nil sort — the sort of a nil is
derived, never read from the token: from the static type of the
position or, for a typed nil in an interface or reference position,
from the dynamic descriptor carried with the nil body (WF-15, WF-24).
Which nil sorts a projection distinguishes is binding content
(WF-15); Rust distinguishes none: the language has no null type
(ref:references; std:Option), absence is Option's None variant — a
VARIANT value (WF-21) — and the nil token has no Rust carrier:

| Rust absence position | How the decoder sees it |
|---|---|
| absence — no null exists | Option's None variant, a VARIANT value; never the nil token |

The nil selectors 0..3 are exercised by no Rust value; selector 4 —
the zero-size marker (WF-24) — is. Absence is never confused with
empty (WF-15): an empty String is a STRING with zero bytes (WF-13),
an empty Vec an ARRAY with length 0 (WF-16), an empty map a MAP with
count 0 (WF-18).

### 1.3 Interface Positions and Trait Objects

The core's INTERFACE descriptor (WF-22, kind 6) is an opaque,
interface-like wrapper; method sets are a binding concern and are not
encodable. In this binding, a trait-object position (dyn Trait)
carries the dynamic value's own descriptor and body — the wire image
of a dyn Trait value is its concrete dynamic value, never the
trait's method set. Function values are outside the encodable
categories (RS-1), so no trait-object position carries behavior
across the wire: what crosses is data.

**Open existentials (from core WF-22; AM-2).**

The Reference's trait system states constraints, not data
inheritance (ref:trait-objects; ref:supertraits): the implementor set
of a trait is open — no finite variant table exists — so a dyn Trait
position rides interface positions. The closure of an implementor set
is never a wire fact. Supertraits are constraints on implementors,
not data inheritance: a supertrait bound adds nothing to the value
graph of a type.

### 1.4 Descriptor Names in Rust

The core's descriptor identity is structural (WF-22): descriptors
intern by canonical structure — kind, arguments, and child type-refs,
recursively — and nominal names do not participate in the structural
key: a nominal wrapper and its base intern independently. A nominal
name is qualified by the binding's namespace grammar (binding
content, WF-22), and instantiation is unified under the grammar
`Name[args]`: a type expression's wire name is the constructor name
followed by its bracketed argument list, the arguments being
canonical structural names. Generic instantiation is compile-time
monomorphization (ref:generics) — the instantiation's identity is
naming-only (5.2).

The namespace grammar of this projection is the crate path: every
defined type takes its crate-qualified name (`crate::path::Type`);
unnamed composites take their canonical structural string. The name
mapping is injective within one stream (WF-22): one qualified name,
one descriptor.

Collisions follow the core's hybrid policy (WF-22): derived qualified
names stay clean — no renaming and no disambiguation suffixes. Rust's
collision case is the versioned-crate split: "When multiple versions
of a crate appear in the resolve graph" (cargo:resolver), distinct
compile units of one library whose types would derive one qualified
name within one stream. If two such types reach one stream, the
encoder rejects at registry start with an unsupported-type error
naming both origins (the decode-side counterpart is a format error at
the colliding descriptor), and the resolution is explicit name
binding. The name-binding law is one chain, one name: a binding
attaches at the crate path and covers the whole chain — every
generic instantiation of the type rides it — so a second binding
attaching a different name to a chain already bound rejects with the
register-conflict family (RS-5), and re-binding the same name is a
no-op. The reserved standard namespace `std.` cannot collide with a
language-derived name (WF-22).

The platform names carried in this projection:

| Platform name | Wire kind (WF-22) |
|---|---|
| bool | BOOL (9) |
| i8, i16, i32, i64, i128 | INT (10) — widths 8, 16, 32, 64, 128 |
| u8, u16, u32, u64, u128 | UINT (11) — widths 8, 16, 32, 64, 128 |
| char | UINT (11) — under the range rule 0..=0x10FFFF (2.1) |
| f16, f32, f64, f128 | FLOAT (12) — binary16, binary32, binary64, binary128 |
| str, String | STRING (13) |
| `[u8]`, Vec<u8> | BLOB (14) |
| Option<T> | VARIANT (1) — wire name `core::option::Option[<T>]` (defining crate; 5.2) |

Every integer width is fixed by its type: the platform-dependent
width class of other bindings has no Rust carrier.

## 2. Lifecycle and Behavioral Notes

### 2.1 Cross-Version Stability Notes [RS-2]

**Version state.** The binding tracks the core at format 0.2 (major 0,
minor 2); the stability notes of this section are stated against that
state. Unknown minors are rejected while the major is 0 — the draft
era carries no cross-minor compatibility promises; the freeze
discipline starts at major 1. The per-construct grounding of the
mapping sits in the denotation table (5.2); the host-language
degeneracy causes in the register (5.3).

**Evolution narrowing (from core WF-6).** The core's evolution
compatibility carries one carve-out, restated here as this binding's
observable: a kept field's reference — a REF or a view token — whose
target stayed unmaterialized because a skipped field owned it rejects
loudly on decode (the core class `evolution_ref_unmaterialized`; the
projection sits in 3.1) — never a silently dangling reference; the
affected shapes are the aliased ones — a REF naming an aliased map
record, a view over a shared backing, a reference into the skipped
region (a cut pointer cycle). Non-aliased narrowing stays
compatible: added fields skip on decode and default on the missing
side.

**Identity layer (declaration).**

NONE DECLARED — no identity keys exist. Every Rust Eq is value
equality: Box, Rc, and Arc compare by deref — "Two Rcs are equal if
their inner values are equal" (std:Rc) — and pointer identity
(Rc::ptr_eq, "point to the same allocation", std:Rc) sits outside Eq.
Sharing survives the wire as shared cells (REF, WF-24; G-1 of
docs/foundations.md) but never participates in key equality.

**Stability tier T2 declaration (identity-determinant instantiation
of WF-25).** NONE DECLARED — the Rust-denotable domain holds no
identity keys and no float keys, so the stable class covers it:
T1 by construction. A declaration would become necessary only if a
future determinant — order-sensitive, decoder-unverifiable — entered
the language. The conditions that would have required a declaration:
identity keys (no Eq type compares by allocation) or float map keys
(floats do not implement Eq, std:Eq) — neither is writable at the
type level.

**char range rule (from core WF-9).**

The core defines no character kind: a char-typed value is a UINT
under the binding's range rule — a Unicode scalar value, 0 to
0x10FFFF inclusive (std:char). A UINT of any other width decoded
into a char target range-checks against that range and rejects
outside (`overflow_value`, RS-5).

**Degradation table (per the core annotation WF-11).**

Degrades are declared with blame on receive, never as silent
widening:

| trigger | native? | behavior on receive | blame/class | escape hatch |
|---|---|---|---|---|
| a non-UTF-8 byte sequence in a STRING position against a String or str target | representational — String and str are always valid UTF-8 (std:str) | loud validity gate in both directions: encode-side the type invariant is the gate — a non-UTF-8 byte sequence cannot inhabit a String or str; decode-side an invalid sequence into a String or str target rejects | `invalid_string_encoding` (RS-5) | Vec<u8> carries all bytes (WF-14) |
| a cycle reachable from a map key position | — a value-model limit, not a host form | n/a on receive — the guard is encode-side: a loud classified encoder reject naming the path, the core's termination guard restated as this binding's observable | core classified termination error (KO-5, WF-25) | none — cycles are outside the key domain (E1) |

binary16 and binary128 carry no degradation rows: f16 and f128 are
native — a "binary16 type defined in IEEE 754-2008" (std:f16), with
the f128 page on the same pinned docset — and materialize natively in
both directions (5.2); the core annotation binds only projections
without the native form.

### 2.2 Known Limitations [RS-3]

- **Decode-target materialization: Default plus record-then-fill.**
  A decode materializes its target through the target's Default
  value, then fills it under the core's record-then-fill discipline
  (WF-24, WF-18): a record registers in the intern space before its
  children, so a value position inside the children may close a
  cycle through a REF to the mid-fill record. Shared and aliased
  decode targets materialize through the indirection contract: Box,
  Rc, and Arc targets are the shared cells of WF-24 — one cell per
  intern id, every clone a view of that cell.
- **Derive-based codec machinery is out of scope.** This document is
  a binding, not an implementation: derive macros, trait
  scaffolding, and registration APIs belong to the codec crate and
  carry no contract here.
- **Per-value budget scope (from core WF-26).** The MaxBytes counter
  scopes to the value being decoded — the grammar's top-level unit,
  one value per decode step: it opens at the value's start and resets
  when the next value begins, so cumulative consumption beyond
  MaxBytes across the values of one stream is conformant — no
  per-stream cumulative cap exists; within one value, input bytes and
  charged allocations share the counter.
- **PhantomData and zero-sized handling on decode.** Zero-sized
  positions decode as the zero-size marker, selector 4 (WF-24);
  PhantomData positions never appear in descriptors (1.1), so no
  record, no reference, and no reject ever names them.
- **Extent binding (from core WF-24, WF-17, WF-25).** A slice
  carries its length and no capacity notion — "slices store the
  length of the sequence they refer to" (std:slice) — so this
  projection binds extent = len, the documented projection
  annotation of WF-25 (i): two projections may diverge on join
  boundaries only through their extent binding, a qualification of
  the tier-1 claim attributed to the projection, never silently to
  the core. A Vec's capacity is an instantiation detail (std:Vec —
  capacity and reallocation are observable) that never enters any
  record: arrays and views encode len only.
- **Strings and blobs (from core WF-13, WF-14).** A Rust String or
  str is always valid UTF-8 (std:str); the wire STRING is a byte
  sequence with no validity gate. The decode-side gate of the
  degradation table (2.1) owns the non-UTF-8 cases, and Vec<u8>
  carries arbitrary bytes. The STRING/BLOB class split is the wire
  image of the projection's text-versus-binary distinction.
- **Struct field order (from core WF-22).** Struct field order in
  descriptors and in value bodies is the canonical name-sorted
  order — the bytewise-lexicographic ascending order of the
  field-name byte sequences, case-sensitive — as fixed by the
  descriptor's field table (WF-22, WF-19). The order in which
  fields are written in the Rust source does not participate.

### 2.3 Schema Snapshot Mechanics [RS-6]

A schema snapshot is taken from a declaration scope, never from a
value stream: the declarer accumulates declarations — types,
ready-made descriptors, coder declarations, name bindings — and
builds a schema snapshot. Encoding or decoding values in other
scopes never changes the built bytes; the snapshot is a pure
function of the declared set. The binding-side mechanics:

- The member set is the declaration list: declared Rust types
  (structs, enums, newtype and tuple structs), declared descriptors,
  and registry-only members — types declared but reachable from no
  other member still ride as top-level records.
- The artifact component is the frozen descriptor encoding (WF-22):
  the same bytes, the same canonical order, the same text twin
  discipline.
- A name binding (one wire name for one type) rides as a NAMED
  wrapper over the canonical descriptor — one graph per type, no
  structural duplicate (WF-22). The canonical record and the wrapper
  share the descriptor; a wrapper that would precede its canonical
  record in the canonical order is rejected at build time.
- Closure: every member is a top-level record. A member whose
  literal would surface inside a byte-wise earlier member is kept
  whole — the earlier record carries a structural unfolding of it
  under a canonical type-expression name, and the member keeps its
  own record. Sets that cannot close are rejected at build time.
- Coder declarations produce CODER records with canonical tags: each
  CODER record carries its ordinal among the CODER records of the
  canonical stream — an order derived from the sorted member set,
  not from the value-stream encounter order. Tags are stable across
  rebuilds and declaration permutations.
- Determinism: permuting the declarations and rebuilding the same
  scope produce identical artifact bytes.

### 2.4 Evolution Intents [RS-7]

Evolution facts are declared, not inferred: a removal is a reserved
name, a rename is a field alias intent. Both live with the
declaration scope and both reach the snapshot as data, not as wire
grammar (the decoder evolution contract, WF-6).

- A reserved-name declaration marks a wire name as removed from
  future use. Reserved names never enter the descriptor stream: they
  form the tombstone component of the snapshot — a binary part
  carried beside the artifact with a one-name-per-line text twin,
  and the pair regenerates only in lockstep under the same drift
  canon as the artifact twin.
- The artifact bytes are invariant to reserved-name declarations:
  the tombstone component is the only place a reserved name
  surfaces.
- The value codec enforces the removal on both sides: a scope
  holding a reserved name refuses to encode a value whose type
  carries that wire name (at the root or in any nested position) and
  refuses to decode a stream name landing in the reserved set — a
  registry-contract refusal in both directions. Re-declaring the
  same name is a no-op; a reserved name colliding with a live
  binding, a registered type, or a coder of the same scope is
  rejected at declaration time.
- A field alias intent declares that a struct field travels under a
  new name: the snapshot record carries the target field name, and
  the (source, target) pair survives as snapshot metadata — the
  rename is declared data, not a derived guess. Without a
  declaration the intent machinery leaves the bytes untouched;
  declaring against a missing field, or two targets for one source
  field, is rejected at declaration time.

## 3. Error Conformance

### 3.1 Error Classes [RS-5]

Codec errors are a contract of structure, not text: messages may
change between releases; the stable surface is the class ID, the
family attribution (a kind discriminant per family), and the fields
of the structured error type (class, input offset, value path,
got/want, cause). Six families carry the errors; the code and
contract families share one discriminant; the environment family
answers through its own kind with the underlying read or write fault
reachable as the cause, and the internal family attributes a foreign
panic recovered by the decode tripwire — an internal defect, not
crafted input. The concrete error types are implementation
identifiers and live outside this document (non-normative: see the
gbon-rust repository). The one-line rendering interpolates no
untrusted input: decoded values, keys, and stream names surface only
through the structured fields; caller arguments (registry names,
Rust types, configured limits) are trusted and stay in the text.
Value paths chain `$` (root), `.field`, `[i]`, and `["key"]`
segments as produced by the location tracking of the failing side.

Class IDs, snake_case, additive only (new classes may appear; IDs
are never renamed or reused). The table is the class inventory:
family and the kind attribution (registry names are stream data,
coder faults are codec capability):

| Class | Family | Attribution | Meaning |
|---|---|---|---|
| `bad_magic` | data/format | format | wrong stream magic |
| `truncated` | data/format | format | input ended mid-value |
| `malformed_op` | data/format | format | unknown or misplaced op byte |
| `malformed_arg` | data/format | format | malformed op argument |
| `overflow_value` | data/format | format | value out of the target range |
| `duplicate_key` | data/format | format | duplicate map key |
| `bad_ref` | data/format | format | unresolvable or misused reference |
| `bad_view` | data/format | format | malformed view record |
| `type_mismatch` | data/format | format | stream kind does not fit the target |
| `unknown_name` | data/format | format | unregistered wire name |
| `invalid_string_encoding` | data/format | format | STRING bytes invalid as UTF-8 for a String or str target |
| `budget_depth` | budget | budget | depth budget exhausted |
| `budget_nodes` | budget | budget | node budget exhausted |
| `budget_bytes` | budget | budget | byte budget exhausted |
| `budget_alloc` | budget | budget | allocation survived limits but panicked |
| `unsupported_kind` | code | unsupported | value kind has no serialized form |
| `register_conflict` | code | unsupported | registry name or type conflict |
| `coder_error` | code | unsupported | custom coder failed |
| `coder_recursion` | code | unsupported | custom coder re-entered the codec |
| `contract_mismatch` | contract | unsupported | decode target breaks the evolution contract |
| `io_read` | env | io | underlying reader failed |
| `io_write` | env | io | underlying writer failed |
| `internal_panic` | internal | internal | foreign panic recovered by the decode tripwire |
| `unstable_tie_break` | contract | unsupported | stable mode: map pairs tied in key skeleton and value bytes (E5 — no Rust carrier, 5.4) |
| `unstable_zero_float_key` | contract | unsupported | stable mode: zero float map key of ambiguous stored sign (E4 — no Rust carrier, 5.4) |

The core's evolution carve-out class `evolution_ref_unmaterialized`
(WF-6) projects onto `contract_mismatch` — a kept reference whose
target stayed unmaterialized under narrowing is a decode-target
setup problem, not a bytes problem.

**Cross-language slot preservation.** A stream carrying tied
identity-key pairs — encoded under another binding's identity layer
— read by this value-only consumer is a loud reject preserving the
slot count (`duplicate_key`): a silent slot collapse never
substitutes for the reject. The mirror holds in this direction too:
a stream encoded here never carries a tied identity pair — no
identity keys exist (2.1) — and slot count is preserved in both
directions.

### 3.2 Coder Error Contract

A custom coder fails and owns no location: the codec's coder seams
assign the path and the offset, attribute the class (coder_error, or
coder_recursion on re-entry), and keep the coder's original error
reachable as the cause — the structured wrap is the codec's job, not
the coder's.

## 4. Examples and Interop Notes

### 4.1 Consumption Mappings

For service boundaries that must answer HTTP or gRPC, every class
maps onto a problem-details identity and a status. The mapping
derives from the six families, with four exceptions where the family
default misstates the consumer's lever: `unknown_name` and
`contract_mismatch` are consumer-side setup problems (422 /
FailedPrecondition — fix the registry or the target, do not retry
the bytes), and `io_read` and `io_write` are environment faults
worth a retry under policy (503 / Unavailable). The families
themselves: data/format answers 400 / InvalidArgument, budget
classes answer 413 Payload Too Large / ResourceExhausted, code
classes answer 500 / Internal, and the internal family answers
500 / Internal. The ErrorInfo reason is the class ID itself —
machine-checkable shapes, no prose in the columns.

| Class | HTTP status | gRPC code | ErrorInfo reason |
|---|---|---|---|
| `bad_magic` | 400 | InvalidArgument | `bad_magic` |
| `truncated` | 400 | InvalidArgument | `truncated` |
| `malformed_op` | 400 | InvalidArgument | `malformed_op` |
| `malformed_arg` | 400 | InvalidArgument | `malformed_arg` |
| `overflow_value` | 400 | InvalidArgument | `overflow_value` |
| `duplicate_key` | 400 | InvalidArgument | `duplicate_key` |
| `bad_ref` | 400 | InvalidArgument | `bad_ref` |
| `bad_view` | 400 | InvalidArgument | `bad_view` |
| `type_mismatch` | 400 | InvalidArgument | `type_mismatch` |
| `unknown_name` | 422 | FailedPrecondition | `unknown_name` |
| `invalid_string_encoding` | 400 | InvalidArgument | `invalid_string_encoding` |
| `budget_depth` | 413 | ResourceExhausted | `budget_depth` |
| `budget_nodes` | 413 | ResourceExhausted | `budget_nodes` |
| `budget_bytes` | 413 | ResourceExhausted | `budget_bytes` |
| `budget_alloc` | 413 | ResourceExhausted | `budget_alloc` |
| `unsupported_kind` | 500 | Internal | `unsupported_kind` |
| `register_conflict` | 500 | Internal | `register_conflict` |
| `coder_error` | 500 | Internal | `coder_error` |
| `coder_recursion` | 500 | Internal | `coder_recursion` |
| `contract_mismatch` | 422 | FailedPrecondition | `contract_mismatch` |
| `io_read` | 503 | Unavailable | `io_read` |
| `io_write` | 503 | Unavailable | `io_write` |
| `internal_panic` | 500 | Internal | `internal_panic` |
| `unstable_tie_break` | 422 | FailedPrecondition | `unstable_tie_break` |
| `unstable_zero_float_key` | 422 | FailedPrecondition | `unstable_zero_float_key` |

The table is the mapping contract and is kept in lockstep with the
class inventory in both directions.

### 4.2 Worked Examples

Worked examples live with the constructs they explain: byte-level
illustrations in the core document (its Appendix A), and the
mechanics of each binding concern in the sections above.

## 5. Grounding

The grounding apparatus is shared across the binding series; the
terminology block below is its verbatim carrier (edits land in all
three bindings).

<!-- BEGIN shared terminology (verbatim; edits land in all three bindings) -->
Stability tiers are named with the qualified vocabulary only (stability
tier T1/T2/T3). A tier-2 instantiation fills the core slot: determinant
form, determinism scope, verification hook. Status vocabulary: EXACT,
REPRESENTATIONAL, DEGRADED, UNSUPPORTED. Doc-source hierarchy ranks are
named source rank 1..4.
<!-- END shared terminology -->

### 5.1 Source Hierarchy

Every claim this binding makes about the Rust value model is grounded
in a four-rank source hierarchy, in normative order:

1. **Source rank 1 — the Rust Reference.** The reference is the first
   source for every claim about the value model; a construct's
   semantics is stated here before the documentation of any
   implementation is consulted. The Reference self-declares
   incompleteness — known bugs and omissions (ref:intro) — and where
   it declares a gap, the affected claim is grounded at source rank 2
   and the caveat is stated at the claim.
2. **Source rank 2 — the standard library and alloc documentation.**
   The API documentation of the rustc 1.98.1 docset grounds the
   contracts of the library types this binding maps (Eq, Option, the
   collections, Box, Rc); it never overrides source rank 1, and the
   Reference's incompleteness caveat weights it up exactly where
   rank 1 self-declares gaps.
3. **Source rank 3 — the toolchain references.** The Cargo resolver
   reference and the Edition Guide ground toolchain-level facts —
   crate-version resolution and edition rules; they never override
   the ranks above.
4. **Source rank 4 — rustc 1.98.1 behavior.** Compiler behavior
   grounds a claim only in zones the documents themselves mark
   implementation-defined, and there only pinned by tests;
   everywhere else it is not a source.

A claim that needs a lower source rank where a higher rank speaks is a
defect (the falsification class of CLM-5 in docs/meta/claims.md).

**Version pins (source ranks 1-3).** The load-bearing pages are
pinned here in full; the family pin tables live in the consolidated
anchor map (docs/references.md, rows rust-reference, rust-std-1981,
cargo-resolver, rust-channel, rust-edition-guide), which cites the
fetch records of the grounding spike (fetched 18 September 2026):

- Rust Reference, print.html (single page): 4442206 bytes, sha256
  f9c51c87081c9f572d8dcbdfec3fed2ff45208d1a6c3d71b28cde02f256bf2be.
- std documentation, str primitive: 681363 bytes, sha256
  f5d772e6b44a2af511cabb0779822455bf429e7a93f938fb6bf25c514c15b3a1.
- std documentation, f16 primitive: 350153 bytes, sha256
  788da1f85efe82adde9c6a249751a1e40e0a671de32ed2c58386a3c0e0403114.
- Cargo resolver reference: 60651 bytes, sha256
  f2e130d53baeaaa73d4ea3659567cdcea70b5cab0515d237912acb89071aa1bc.
- Release channel manifest, channel-rust-stable.toml — the rustc
  1.98.1 version determination: 898637 bytes, sha256
  a7c8774a5fd8441c997d94c029776cbc5eb111e9d72ab5d256fa69866644347e.

A fetched page whose checksum differs from the pin is a re-pin event:
cited sections are re-resolved against the new page before any
further grounding claim.

**Citation form.** Table rows cite the pinned pages as `ref:`
followed by the Reference chapter, `std:` by item, and `cargo:` by
document — for example `std:str` ("string slices are always valid
UTF-8"), `ref:items.enum` (discriminants "logically associated" with
their variants). Quoted material is at most one sentence, verbatim
from the pinned page.

### 5.2 Denotation Table

The binding is a partial denotation from Rust's serializable values
into the GBON value model (CLM-5 in docs/meta/claims.md). Each row
below carries the construct, its GBON denotation, the projection of
identity and equality — against the value equivalence ≡_GBON and the
grain axioms G-1..G-6 of docs/foundations.md — the observables the
projection preserves, the losses it declares, one status, and the
environment a decode of the construct requires. Statuses: EXACT
(host semantics maps directly), REPRESENTATIONAL (host
representation is richer; declared portable observables survive),
DEGRADED (host semantics consciously excluded, with blame in the
register), and UNSUPPORTED (no correct denotation; a classified
reject). Every exclusion is justified either by a format limit or by
a host-language degeneracy recorded in the register (5.3).

| Construct | GBON denotation | Identity/equality | Preserved observables | Intentional loss | Status | Decode environment |
|---|---|---|---|---|---|---|
| i8..i128 / u8..u128 | INT/UINT descriptors, widths 8..=128 — width 16 is the 128-bit section (WF-8, WF-9, WF-22); the primitive list names them all (ref:types) | value equality (≡_GBON value dimension); integer key order is the argument-byte order of the zigzag image (KO-6) | value; recorded width — fixed per type, no platform dependence | none | EXACT | decoder range-checks the target width |
| f32, f64 | FLOAT binary32/binary64 (WF-11); the IEEE 754 forms (ref:types) | bit equality: ±0, NaN payloads, subnormals are representation-level distinctions of ≡_GBON; float keys round-trip bitwise (KO-3) | raw bits | NaN values are outside the key domain (E1) — a value-model limit, not a register cause | EXACT | none beyond the stream |
| f16, f128 | FLOAT binary16/binary128 — native (WF-11); "a binary16 type defined in IEEE 754-2008" (std:f16; std:f128 on the pinned docset) | bit equality (KO-3) | raw bits | none | EXACT | materializes natively in both directions — no degradation row exists (2.1) |
| char | UINT under the range rule — a Unicode scalar value, 0 to 0x10FFFF inclusive (WF-9; std:char) | value equality | the scalar value | none | EXACT | a UINT of another width range-checks against the range rule (2.1) |
| String, &str | STRING (WF-13); the str view rides VIEW/extent mechanics (WF-17); "string slices are always valid UTF-8" (std:str) | content equality of the UTF-8 sequence; wire equality is bytewise over the same bytes — no transcode exists | valid text; the byte sequence | non-UTF-8 byte sequences have no String image — Vec<u8> carries them (2.1) | EXACT | a non-UTF-8 sequence into a String or str target rejects loudly (2.1) |
| bool | BOOL (WF-10); the primitive bool (ref:types) | value equality; key order by bytewise skeleton (E3) | value | none | EXACT | none beyond the stream |
| (), zero-sized types, PhantomData | zero-size marker, selector 4 (WF-24); PhantomData is excluded from encoding — no descriptor position (ref:layout; 1.1) | zero-size identity is neither preserved nor observable (G-6) — zero-sized types may share one address, an implementation-defined zone (ref:layout) | presence of the marker vs its absence | address identity of zero-size values | REPRESENTATIONAL | zero-sized positions decode as selector 4; PhantomData never names a record |
| tuple (A, B, ...) | TUPLE — positional, arity structural (WF-20, WF-22); the tuples of the types chapter (ref:types) | elementwise value equality when all components are Eq | elements in positional order; arity | none | EXACT | none beyond the stream |
| tuple struct / newtype | NAMED wrapper over a TUPLE payload (WF-22); tuple structs (ref:types) | value equality through the payload | the payload in positional order, under the nominal name | none | EXACT | name resolution |
| struct | STRUCT; fields in canonical name-sorted order (WF-19, WF-22); structs (ref:types) | fieldwise value equality when all fields are Eq | fields in canonical order, by name | source-order field positions are not a wire observable — access is by name | EXACT | Default-constructible target with fillable fields (2.2) |
| enum | VARIANT — closed sum (WF-21); the tag is the index into the sorted variant table; named-field variants are anonymous STRUCT payloads, tuple variants are TUPLE (ref:items.enum) | per-alternative value equality | alternative identity; payloads | none | EXACT | by-name alternative matching (WF-21) |
| explicit enum discriminants | no denotation — the integers are "logically associated" with the variants to "determine which variant" a value holds (ref:items.enum) | value equality is unaffected — the variant name is the wire identity | alternative identity | discriminant integers are not carried — matching is by variant name (WF-21) | REPRESENTATIONAL | none beyond the stream |
| Option<T> | library-level 2-variant sum — VARIANT (WF-21); the pinned doctest nests Option<Option<u32>> = Some(None) (std:Option) | value equality; None is a variant, not the nil token | presence structure; nesting resolves naturally — Some(None) is two levels | none | EXACT | none beyond the stream |
| Result<T, E> | library-level 2-variant sum — VARIANT, the twin of Option under the same library-sum rule (WF-21; std:Option) | value equality | success/error structure; nesting resolves naturally | none | EXACT | none beyond the stream |
| dyn Trait | interface position — the dynamic value's own descriptor and body (WF-22; AM-2); trait objects (ref:trait-objects) | the dynamic value's equality | dynamic type and value | closure of the implementor set is not a wire fact | EXACT | name resolution through the registry for dynamic types (`unknown_name` on miss) |
| Vec<T> | ARRAY of T (WF-16); capacity is not encoded — len only (std:Vec) | elementwise value equality | elements; length | capacity — an instantiation detail that never enters any record | EXACT | extent binds to len (2.2) |
| &[T] | VIEW over a backing (WF-17); "slices store the length of the sequence they refer to" (std:slice) | elementwise value equality when T is Eq; identity of the backing is preserved (≡_GBON sharing; G-1) | len; extent; sharing | zero-tail degeneracy qualified by extent agreement (WF-25 (i), 2.2) | EXACT | backing join by the extent window |
| HashMap<K, V> | MAP with count (WF-18); iteration is an "unsorted (and unspecified) order" over a "randomly seeded" hasher (std:HashMap) — canonical bytes never derive from iteration (KO-2: the pair sort precedes emission) | content-equality keys (K: Eq + Hash) | pair count; key distinction; deterministic pair order within one encoding — value-derived | none | EXACT | key materialization per the KO scheme |
| BTreeMap<K, V> | MAP with count (WF-18); the sorted map (std:BTreeMap) | content-equality keys (K: Ord) | pair count; key distinction; deterministic pair order | none | EXACT | key materialization per the KO scheme |
| map in key position — HashMap as K | legal — the Eq implementors include HashMap (std:Eq): value equality | content-equality keys; a map in key position is a legal key | the key's value structure | none | EXACT | per the KO scheme |
| f32/f64 as map key | no denotation is needed — impossible at the type level: floats "implement only PartialEq but not Eq" (std:Eq) and std map keys require Eq | — | — | the zero-sign determinant (E4) has no Rust carrier — no float key type can be written | EXACT | n/a — the compiler rejects the key type before the codec is reached |
| Box/Rc/Arc<T> | VALUE denotation — the pointer is encoding-invisible; REF is an optional sharing optimization, never an identity key (WF-24; std:Rc) | "Two Rcs are equal if their inner values are equal" (std:Rc); Rc::ptr_eq — "point to the same allocation" — is outside Eq | sharing (G-1); the pointee value | pointer identity as a key discriminator — no identity keys exist (register 5.3 value-eq) | EXACT | shared cells materialize through the indirection contract (2.2) |
| &mut T / borrows | no denotation — an access path, not a value; exclusivity is a compile-time rule (ref:references) | — | — | format limit, not a degeneracy cause | UNSUPPORTED | n/a — classified reject `unsupported_kind` with the path |
| absence | Option's None variant only — a VARIANT value (WF-21); the nil selectors 0..3 are unused by this binding, selector 4 in use (WF-15, WF-24; ref:references; std:Option) | no null value exists to compare | presence structure | the core's nil token has no Rust carrier (register 5.3 no-null) | EXACT | absence materializes as None |
| crate-path type names | Name[args] over crate-qualified names (WF-22); the hybrid collision policy applies to crate-version duplicates (1.4; cargo:resolver) | structural identity; names are the nominal overlay | the qualified name; instantiation args | none | EXACT | name resolution; collisions reject at registry start (1.4) |
| generics — C<T> | Name[args] (WF-22); generics are compile-time monomorphization (ref:generics) | instantiation identity is naming-only | the instantiation's wire name | run-time type identity of instantiations — distinct monomorphizations share no run-time link; the identity rides the wire name | REPRESENTATIONAL | name resolution; decode materializes the erasure |
| unsafe supertraits | no data-model effect — supertraits are constraints on implementors, not data inheritance (ref:supertraits) | per the underlying value | the underlying value's observables | none | EXACT | none beyond the stream |

Raw pointers and function values carry no rows above: the categories
have no wire image at all (RS-1) — the exclusion is a format limit,
not a host-language degeneracy. UNSUPPORTED rows carry a format
limit, never a degeneracy cause; DEGRADED rows, when one is declared,
cite a register entry (5.3). The four statuses are the CLM-5
vocabulary verbatim.

### 5.3 Degeneracy Register

Degeneracy causes are facts of the host language, stated against the
source hierarchy (5.1), never against codec behavior. The register is
the single source of degeneracy causes: the table (5.2) references
entries, prose elsewhere references the register.

| Cause | Degeneracy cause in the host language | Constructs | Declared treatment |
|---|---|---|---|
| no-null | the language has no null type — absence is Option's None variant, a VARIANT value; the core's nil token and its derived-sort machinery have no Rust carrier (ref:references; std:Option) | absence — selectors 0..3 unused, selector 4 in use (WF-15, WF-24) | REPRESENTATIONAL |
| RandomState | std HashMap iterates an unspecified order over a randomly seeded hasher (std:HashMap) — no insertion-ordered determinant is declarable over std maps, and the canonical pair order never derives from iteration (KO-2) | HashMap — MAP with value-derived pair order; the tier-2 none-declaration (2.1) | REPRESENTATIONAL |
| value-eq | every Eq is value equality — Box/Rc/Arc compare by deref and pointer identity sits outside Eq (std:Rc) — so no identity keys exist and sharing never orders keys | Box/Rc/Arc — VALUE denotation, REF optional (5.2); the identity-layer none-declaration (2.1) | REPRESENTATIONAL |

The value-eq entry carries the tie-break eligibility of axiom E5 to
its Rust conclusion: with no identity slots, byte-equal skeletons in
distinct slots cannot arise — byte-equal value-equal keys are true
duplicates (KO-8) — and the tie-break has no carrier.

### 5.4 Stable-class projection

The core's stable class — the class over which the stability tier T1
claim holds — and its guard contract (wire-format.md section 8.1,
WF-25) are normative there; this section is the binding's projection
of the class.

**T1 by construction.** A Rust value graph sits in the stable class
unconditionally. No map in it can apply the tie-break of axiom E5:
byte-equal key skeletons across distinct identity slots require
identity slots, no identity keys exist (2.1), and byte-equal
value-equal keys are duplicates — rejected by KO-8, never tied. No
map in it can hold a zero float key (axiom E4): no float key type is
writable (std:Eq). The static predicate over types is therefore
trivially true for every encodable Rust key type — the key's Eq is
value equality.

**Guard contract.** The two guard classes of the inventory (RS-5)
project the core axioms — `unstable_tie_break` (axiom E5) and
`unstable_zero_float_key` (axiom E4) — and cannot fire for a
Rust-typed value graph: their premises (identity slots, float keys)
are unwritable at the type level. The classes stay in the inventory
as the projection of the core guard contract (WF-25); the
completeness declaration H-1 — exactly the declared identity
determinants exhaust the sources of process-dependence — holds for
this binding with an empty determinant set: none is declared because
none is needed.
