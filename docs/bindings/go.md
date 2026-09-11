# GBON Go Binding

Binding of the GBON wire-format core to the Go value model. The core
specification (docs/wire-format.md, format 0.0 — the draft era) is
normative and language-independent; this document is the Go projection —
an appendix non-normative with respect to the core — carrying the parts
of the contract specific to the Go value model. Sections of this
binding carry stable IDs GO-1..GO-7; core
rules are cited by their WF-n section IDs (the ID scheme is defined by
core section WF-24). Resolvability of every ID reference across the
repository is enforced by the reference-lint gate (non-normative: see
the gbon-go repository).

**Contents**

- [1. Type Mapping](#1-type-mapping)
  - [1.1 Non-Encodable Categories [GO-1]](#11-non-encodable-categories-go-1)
  - [1.2 Nil Model [GO-4]](#12-nil-model-go-4)
  - [1.3 Interface Positions and Method Sets](#13-interface-positions-and-method-sets)
  - [1.4 Descriptor Names in Go](#14-descriptor-names-in-go)
- [2. Lifecycle and Behavioral Notes](#2-lifecycle-and-behavioral-notes)
  - [2.1 Cross-Version Stability Notes [GO-2]](#21-cross-version-stability-notes-go-2)
  - [2.2 Known Limitations [GO-3]](#22-known-limitations-go-3)
  - [2.3 Schema Snapshot Mechanics [GO-6]](#23-schema-snapshot-mechanics-go-6)
  - [2.4 Evolution Intents [GO-7]](#24-evolution-intents-go-7)
- [3. Error Conformance](#3-error-conformance)
  - [3.1 Error Classes [GO-5]](#31-error-classes-go-5)
  - [3.2 Coder Error Contract](#32-coder-error-contract)
- [4. Examples and Interop Notes](#4-examples-and-interop-notes)
  - [4.1 Consumption Mappings](#41-consumption-mappings)
  - [4.2 Worked Examples](#42-worked-examples)

## 1. Type Mapping

### 1.1 Non-Encodable Categories [GO-1]

chan, func, and unsafe.Pointer have no opcodes in any class — the category
has no wire image. The encoder reports an unsupported-type error with the
path to the offending field.

**Comparable restriction (from core WF-20, KO-4).**

The comparable/uncomparable split of the core's key-domain exclusion
mirrors Go's comparable restriction: the reject — an encoder error,
never a runtime panic — is the core's own contract.

**Statically uncomparable keys (from core WF-20, KO-7).**

Statically uncomparable key types are impossible at the Go type level,
so the encoder meets them only inside interface values — the reject is
the same either way.

### 1.2 Nil Model [GO-4]

The nil taxonomy of the core's nil tokens (WF-12) is a property of the
Go value model: class 0x0 selects one of four nil kinds.

| Selector | Meaning |
|---|---|
| 0 | nil pointer |
| 1 | nil slice |
| 2 | nil map |
| 3 | nil interface |

Selectors 4..11 are reserved (WF-12). nil is never confused with empty
(WF-12): an empty non-nil slice is a VIEW with len 0 (WF-15); an empty
non-nil map is a MAP with count 0 (WF-16).

**Bigint nil and zero (from core WF-3, WF-18).**

The BIGINT value body has one byte where the nil pointer token and the
inline zero argument coincide (WF-3): a nil `*big.Int` and a zero integer
encode to the same body. The projection reads the coincidence byte by its
own shape — pointer and interface positions materialize nil, value
positions zero — so a nil round-trips as nil and a zero as zero, and
either re-encodes to the same byte.

**Typed-nil distinctness (from core WF-20, KO-4).**

A typed-nil interface value is distinct from a nil interface and encodes
accordingly — nil-interface and typed-nil are distinct tokens (KO-4);
the nil kinds of the table above are the tokens a typed nil occupies.

### 1.3 Interface Positions and Method Sets

The core's INTERFACE descriptor (WF-18, kind 6) is an opaque,
interface-like wrapper; method sets are a binding concern and are not
encodable. In this binding, an interface position carries the dynamic
value's own descriptor and body — the wire image of a Go interface
value is its concrete dynamic value, never the static interface type's
method set. Function values are outside the encodable categories
(GO-1), so no interface position carries behavior across the wire:
what crosses is data.

**Decode targets and reference positions (from core WF-13).**

A stream's reference graph decodes into any target type whose
reference structure carries it. Pointer chains over an interface
point (`*any`, `**any`, …) are legal roots and legal slots at every
depth: references are type-erased handles, the types live on the
interned cells, and the decoder materializes one pointer level per
reserved id — a chain of any depth, and a cycle closing through any
slot, round-trips with exact slot types, pointer identity, and
byte-identical re-encoding. A nil pointer-chain root decodes as the
typed nil of the chain; a named or out-of-family root rejects with
`unknown_name` — the registry contract, not a format rule. The
distinctions survive the round-trip bit-exact: a self-referencing
chain re-encodes to its own bytes, and a nil-interface pointee never
merges with a typed-nil pointee.

**Unnamed chain derivation (registry miss).**

Unnamed pointer chains to an interface point (`*interface {}`,
`**interface {}`, …), with one slice or `map[string]` level over the
chain, derive from their descriptor name on a registry miss: the
canonical structural name alone fixes the type, so the stateless
`Unmarshal` decodes them without any registration. Explicit
`Register` bindings take precedence; every other shape — named types
above all — keeps its `unknown_name` rejection.

### 1.4 Descriptor Names in Go

The core's namespace-qualification rule (WF-18) projects onto Go as
the name derivation of the reference implementation: types from the
standard library and types defined in main packages take the short
form (`pkg.Type` — time.Time, big.Int); every other defined type takes
the import-path-qualified form (`import/path/pkg.Type`); unnamed
composites take their canonical structural string ("[]T", "[N]T",
"map[K]V", "*T"). This section is the Go projection of the core rule,
not an additional norm.

The platform names carried in the short form in this projection:

| Short-form name | Wire kind |
|---|---|
| bool, int, int8, int16, int32, int64, uint, uint8, uint16, uint32, uint64, float32, float64, complex64, complex128, string | primitive kinds 7..12 |
| `[]byte` | BLOB (13) |
| time.Time | CODER (14) |
| big.Int | BIGINT (15) — reserved |

## 2. Lifecycle and Behavioral Notes

### 2.1 Cross-Version Stability Notes [GO-2]

The stored representation of ±0 map keys is a property of the Go runtime
(key overwrite on update); signers over canonical bytes must pin the Go
version of the encoding side — the core excludes the stored sign from
the cross-implementation canonical claim (axiom E4 in WF-20). Zero-size
reference identity is
neither preserved nor observable (WF-13). *Core, restated here for the
signer:* the ESC reserved nibble is part of
the canonical surface: a nonzero low nibble is a decode reject (WF-19), so a
future subclass promotion never forks the spelling of existing tokens.

**E5 tie-break instantiation (from core WF-20).**

The core's E5 tie-break — the one place implementation-defined identity
participates in map-pair order — is instantiated by the KO-2a pointer
discriminator (the allocation-sequence discriminator). It fixes the
ORDER of otherwise indistinguishable map pairs, never byte content:
within one encoding the order is deterministic; across processes or
replays it is not specified. For each key, the discriminator is the
DFS-preorder sequence of runtime addresses of its reference-kind
components, compared lexicographically: a nil slot orders below every
address; a shorter prefix below its extension. Addresses never enter
the encoded bytes — the discriminator fixes only the order of the tied
pairs.

**Big integers (from core WF-5, WF-18).**

The whole integer domain is a built-in value class:
`math/big` integers ride the BIGINT descriptor kind under the reserved
wire name "big.Int". Both Go projections — `big.Int` and `*big.Int` —
encode to the same kind and name (pointer-ness is absorbed by the kind,
as `[]byte`'s is by BLOB), and both accept the stream on decode. The
encode ladder outranks the automatic text adapter: a big integer never
encodes as an adapter STRING. Streams carrying the kind-14 adapter form
under the same name decode as well; the re-encode of an adapter-read
value is the canonical kind-15 spelling (migration by rewrite, WF-23).

**Bigint map keys (from core WF-20).**

`*big.Int` map keys are pointer-identity keys, like every pointer key
category (E2/E5): two keys with equal values in distinct slots are
distinct keys — byte-equal skeletons ordered by the identity tie-break —
and no value-equality of keys is introduced. The canonical key order over
the integers is the argument-byte order of the zigzag image (KO-6).

**Platform-dependent integer widths (from core WF-22).**

The width recorded in INT and UINT descriptors for the
platform-dependent
types `int`, `uint`, and `uintptr` varies with the encoding platform's
pointer size (4 on 32-bit, 8 on 64-bit). Decoders accept both widths and
range-check against the target type's actual size.

### 2.2 Known Limitations [GO-3]

- **Decode atomicity leans on the sticky-error quarantine.** Target
  atomicity (WF-22) extends to the intern space only because the stream
  never resumes: after a failed decode the sticky error makes every
  subsequent call fail, so intern scratch state polluted by the failed
  record (partially filled backings, registered pointer targets,
  interned strings) stays unreachable. An in-place materialized root
  (GO-3 stream-lifetime bullet below) follows the same rule: after a
  failed decode the registered root cell points at the restored —
  pre-call — value of the caller's storage, and never-resume keeps that
  entry unreachable for the rest of the stream. Resumability would
  require an epoch/generation reset of the intern space at the failure
  point; the obligation is never-resume.
- **Skipped container records are not materialized.** When a struct field
  is skipped under the WF-23 evolution contract (absent on the target),
  its map, blob/array backing, and pointer-target records are consumed
  parse-only and never materialized (skipped string and descriptor
  literals do intern — the WF-13 mirror is exact, and subsequent REFs from kept
  positions resolve). A subsequent REF or view from a known position onto a
  skipped map, backing, or pointer target is a format error ("not
  materialized", "shared backing unavailable", "not a pointer target"):
  no silent partial object is created.
- **Stream-lifetime backing retention.** Materialized backings — and
  interned strings and descriptors — live for the whole stream on the
  decode side; each materialization is charged against the MaxBytes budget
  of its value at production (WF-22), so the retained total grows with the
  stream. An in-place materialized root cell — the caller's storage
  registered in the stream intern space when a pointer-target record root
  decodes directly into it — belongs to the same retention class: it lives
  for the whole stream, so subsequent values may legitimately REF the root, and
  the caller's memory is retained (readable, never freed by the codec)
  until the Decoder is discarded. On the encode side, grouping slots hold
  live references to the backing memory for the whole stream: the price of
  address stability without reuse (ABA) hazards. The memory is
  producer-owned; the codec never frees it.
- **Broad recover in Decode.** A decode-time panic of any origin
  surfaces as a budget-class error wrap instead of a process crash (WF-22). The
  expected class is reflect allocation panics that survive the budget
  gates under user-raised limits (a crafted backing length admitted by
  MaxBytes can still fail at the allocation itself); a non-allocation
  decoder bug is masked as a budget-class error — breadth is deliberate:
  never-panic on crafted input outranks bug signaling.
- **Linear-time slot grouping components.** Slot grouping uses an
  interval index: O(s·log s) to index s overlapping windows and O(1) per
  slot lookup. Dense-prefix scans and bridge removals remain linear in
  group size; pathological aliasing fans (thousands of windows over one
  backing) still dominate encode time through these linear components.
- **Pointer-to-map keys.** A pointer to a map (or to a struct containing
  maps) is a legal Go map key (compared by address), but the canonical key
  skeleton walks the pointee and has no map representation: such keys are
  rejected with an unsupported-type error naming the offending path.

**decimal128 degradation (from core WF-8).**

The Go projection has no decimal128 type: a materializing decode of the
form-2 FLOAT (width 16) is a loud unsupported-type error naming
decimal128 — the stream is valid, the projection is incomplete — while a
skipped field of that shape consumes grammatically (WF-23). There is no
encode path to the form from any built-in value.

**Extent binding (from core WF-1, WF-13, WF-15).**

The core's extent is the Go slice capacity — the backing join predicate
is the capacity-window rule, byte for byte. The core's view-extent field
(the reserved reach beyond the length) is therefore the slice capacity
in this binding. A projection without a capacity notion binds
extent = len: a documented degradation annotation (the shorter window
can decline a join the capacity-bearing projection takes, so two such
implementations may diverge on join boundaries), attributed to the
projection, never silently to the core (core §8.2).

**Strings and blobs (from core WF-10, WF-11).**

A Go string is not required to be UTF-8 — the core's "a string is a byte
sequence, not mandated text" carries the Go fact unchanged. The
STRING/BLOB class split is the wire image of the projection's
text-versus-binary distinction; the core itself carries two internable
byte-bearing record classes, and a projection with a single
byte-sequence kind maps both onto its own distinction.

**Descriptor field order (from core WF-18).**

Struct field order in descriptors is the owning type's source
declaration order (Go projection of the core's "deterministic
declaration order").

### 2.3 Schema Snapshot Mechanics [GO-6]

A schema snapshot is taken from a declaration scope, never from a value
stream: the declarer (a Snapshotter) accumulates declarations — types,
ready-made descriptors, coder declarations, name bindings — and builds a
SchemaSnapshot. Encoding or decoding values in other scopes never
changes the built bytes; the snapshot is a pure function of the declared
set. The binding-side mechanics:

- The member set is the declaration list: declared Go types, declared
  descriptors, and registry-only members — types declared but reachable
  from no other member still ride as top-level records (SA-4).
- The artifact component is the frozen descriptor encoding of SA-2: the
  same bytes, the same canonical order, the same text twin discipline.
- A name binding (one wire name for one type) rides as a NAMED wrapper
  over the canonical descriptor — one graph per type, no structural
  duplicate (SA-4). The canonical record and the wrapper share the
  descriptor; a wrapper that would precede its canonical record in the
  canonical order is rejected at build time.
- Closure: every member is a top-level record. A member whose literal
  would surface inside a byte-wise earlier member is kept whole — the
  earlier record carries a structural unfolding of it under a canonical
  type-expression name, and the member keeps its own record. Sets that
  cannot close are rejected at build time (SA-4).
- Coder declarations produce CODER records with canonical tags: each CODER
  record carries its ordinal among the CODER records of the canonical
  stream — an order derived from the sorted member set, not from the
  value-stream encounter order. Tags are stable across rebuilds and
  declaration permutations (SA-4).
- Determinism: permuting the declaration order and rebuilding the same
  scope produce identical artifact bytes.

### 2.4 Evolution Intents [GO-7]

Evolution facts are declared, not inferred: a removal is a reserved name,
a rename is a field alias intent. Both live with the declaration scope
and both reach the snapshot as data, not as wire grammar.

- A reserved-name declaration marks a wire name as removed from future
  use. The name must be well-formed under the tombstone namespace
  (SA-6) or be a single dot-free, slash-free type token. Reserved names
  never enter
  the descriptor stream: they form the tombstone component of the
  snapshot — a binary part carried beside the artifact (the value
  codec's own encoding of the name list) with a one-name-per-line text
  twin, and the pair regenerates only in lockstep under the same drift
  canon as the artifact twin (SA-3).
- The artifact bytes are invariant to reserved-name declarations: the
  tombstone component is the only place a reserved name surfaces.
- The value codec enforces the removal on both sides: a scope holding a
  reserved name refuses to encode a value whose type carries that wire
  name (at the root or in any nested position) and refuses to decode a
  stream name landing in the reserved set — a registry-contract refusal
  in both directions. The decode-side refusal covers the positions that
  resolve a stream name through the registry — interface payload
  lookups and coder lookups; concrete-target positions never resolve
  the stream name, so no gate applies there. Re-declaring the same name
  is a no-op; a reserved
  name colliding with a live binding, a registered type, or a coder of
  the same scope is rejected at declaration time.
- A field alias intent declares that a struct field travels under a new
  name: the snapshot record carries the target field name, and the
  (source, target) pair survives as snapshot metadata — the rename is
  declared data, not a derived guess. Without a declaration the intent
  machinery leaves the bytes untouched; declaring against a missing or
  unexported field, or two targets for one source field, is rejected at
  declaration time.

## 3. Error Conformance

### 3.1 Error Classes [GO-5]

Codec errors are a contract of structure, not text: messages may change
between releases; the stable surface is the class ID, the sentinel
family, and the fields of the structured error type (class, input
offset, value path, got/want, cause). Five package-level sentinels
carry the errors.Is attribution across the six families (the code and
contract families share one); the environment family answers through
its own sentinel with the underlying read or write fault reachable as the
cause (Unwrap), and the internal family attributes a foreign panic
recovered by the decode tripwire — an internal defect, not crafted
input. The concrete package-level sentinel variables are
implementation identifiers and live outside this document
(non-normative: see the gbon-go repository). The one-line rendering
interpolates no untrusted input: decoded values, keys, and stream
names surface only through the structured fields; caller arguments
(registry names, Go types, configured limits) are trusted and stay in
the text. Path key segments are bounded: printable keys of up to 16
runes render quoted, anything longer or non-printable renders as a
shape marker with the rune count — an address segment never carries a
full untrusted value. Value paths chain `$` (root), `.field`, `[i]`,
and `["key"]` segments as produced by the location tracking of the
failing side.

Class IDs, snake_case, additive only (new classes may appear; IDs are
never renamed or reused). The table is the class inventory: family and
the errors.Is attribution (registry names are stream data, coder
faults are codec capability):

| Class | Family | errors.Is | Meaning |
|---|---|---|---|---|
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

### 3.2 Coder Error Contract

A custom Coder returns a raw error and owns no location: the codec's
coder seams assign the path and the offset, attribute the class
(coder_error, or coder_recursion on re-entry), and keep the coder's
original error reachable through Unwrap — the structured wrap is the
codec's job, not the coder's.

## 4. Examples and Interop Notes

### 4.1 Consumption Mappings

For service boundaries that must answer HTTP or gRPC, every class maps
onto a problem-details identity and a status. The mapping derives from
the six families, with four exceptions where the family default
misstates the consumer's lever: `unknown_name` and `contract_mismatch`
are consumer-side setup problems (422 / FailedPrecondition — fix the
registry or the target, do not retry the bytes), and `io_read` and
`io_write` are environment faults worth a retry under policy
(503 / Unavailable). The
families themselves: data/format answers 400 / InvalidArgument, budget
classes answer 413 Payload Too Large / ResourceExhausted, code
classes answer 500 / Internal, and the internal family answers
500 / Internal. The ErrorInfo reason is the class ID
itself — machine-checkable shapes, no prose in the columns.

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

The table is the mapping contract and is kept in lockstep with the
class inventory in both directions.

### 4.2 Worked Examples

Worked examples live with the constructs they explain: byte-level
illustrations in the core document (its Appendix A), and the mechanics
of each binding concern in the sections above.
