# GBON Go Binding

Binding of the GBON wire-format core to the Go value model. The core
specification (docs/wire-format.md, format 0.1, minor 1) is
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
- [5. Grounding](#5-grounding)
  - [5.1 Source Hierarchy](#51-source-hierarchy)
  - [5.2 Denotation Table](#52-denotation-table)
  - [5.3 Degeneracy Register](#53-degeneracy-register)
  - [5.4 Stable-class projection](#54-stable-class-projection)

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

The per-construct rows for these categories sit in the denotation
table (5.2, UNSUPPORTED): the exclusion is a format limit — no
opcodes — not a host-language degeneracy; the register (5.3) owns the
causes.

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

**Version state.** The binding tracks the core at format 0.1 (major 0,
minor 1); the stability notes of this section are stated against that
state. The per-construct grounding of the mapping sits in the
denotation table (5.2); the host-language degeneracy causes in the
register (5.3).

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

The denotation table (5.2) carries the per-construct rows subsuming
these notes — decimal128 under floats, pointer-to-map keys under
exotic map keys; the register (5.3) carries the host-language causes.

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
| `unstable_tie_break` | contract | unsupported | stable mode: map pairs tied in key skeleton and value bytes (pointer tie-break order, E5) |
| `unstable_zero_float_key` | contract | unsupported | stable mode: zero float map key of ambiguous stored sign (E4) |

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
| `unstable_tie_break` | 422 | FailedPrecondition | `unstable_tie_break` |
| `unstable_zero_float_key` | 422 | FailedPrecondition | `unstable_zero_float_key` |

The table is the mapping contract and is kept in lockstep with the
class inventory in both directions.

### 4.2 Worked Examples

Worked examples live with the constructs they explain: byte-level
illustrations in the core document (its Appendix A), and the mechanics
of each binding concern in the sections above.

## 5. Grounding

### 5.1 Source Hierarchy

Every claim this binding makes about the Go value model is grounded in
a four-tier source hierarchy, in normative order:

1. **Tier 1 — the Go Language Specification.** The language
   specification is the first source for every claim about the value
   model; a construct's semantics is stated here before the
   documentation of any implementation is consulted.
2. **Tier 2 — the reflect documentation.** The documentation of the
   reflect package grounds what reflection observes about values and
   types; it never overrides tier 1.
3. **Tier 3 — the unsafe documentation.** The documentation of the
   unsafe package grounds memory-layout observation — aliasing and
   pointer conversion — where this binding speaks of layout.
4. **Tier 4 — gc/runtime behavior.** Runtime behavior grounds a claim
   only in zones the language specification itself marks
   implementation-defined, and there only pinned by tests; everywhere
   else it is not a source.

A claim that needs a lower tier where a higher tier speaks is a defect
(the falsification class of CLM-5 in docs/meta/claims.md).

**Version pin (tier 1).** The Go Language Specification is pinned by
its fetch record: page https://go.dev/ref/spec/, fetched
17 September 2026, 341470 bytes, sha256
7a0e32461098566bd7f9ec16dfbef3e0e92ee2768c2106357d8b205395a36507.
Toolchain pin: gbon-go `go 1.27` and `toolchain go1.27.1`, gate image
`golang:1.27-bookworm`. A fetched page whose checksum differs from
the pin is a re-pin event: cited sections are re-resolved against the
new page before any further grounding claim.

**Citation form.** Table rows cite the pinned specification as
`gspec:` followed by the cited section's name, for example
`gspec:Slice types` ("A slice type denotes the set of all slices of
arrays of its element type."). Quoted material is at most one
sentence, verbatim from the pinned page.

### 5.2 Denotation Table

The binding is a partial denotation from Go's serializable values into
the GBON value model (CLM-5 in docs/meta/claims.md). Each row below
carries the construct, its GBON denotation, the projection of identity
and equality — against the value equivalence ≡_GBON and the grain
axioms G-1..G-6 of docs/foundations.md — the observables the
projection preserves, the losses it declares, one status, and the
environment a decode of the construct requires. Statuses: EXACT (host
semantics maps directly), REPRESENTATIONAL (host representation is
richer; declared portable observables survive), DEGRADED (host
semantics consciously excluded, with blame in the register), and
UNSUPPORTED (no correct denotation; a classified reject). Every
exclusion is justified either by a format limit or by a host-language
degeneracy recorded in the register (5.3).

| Construct | GBON denotation | Identity/equality | Preserved observables | Intentional loss | Status | Decode environment |
|---|---|---|---|---|---|---|
| bool | BOOL primitive (gspec:Boolean types) | value equality (≡_GBON value dimension); key order by bytewise skeleton (E3) | value | none | EXACT | none beyond the stream |
| integers | INT/UINT descriptors; math/big integers ride BIGINT under the reserved name big.Int (WF-18) (gspec:Numeric types) | value equality; bigint key order is the argument-byte order of the zigzag image (KO-6) | value; recorded width — 4 or 8 for int, uint, uintptr (WF-22) | none | EXACT | decoder accepts both widths and range-checks the target size (WF-22) |
| floats | FLOAT by width | bit equality: ±0, NaN payloads, subnormals are representation-level distinctions of ≡_GBON; float keys round-trip bitwise (KO-3) (gspec:Numeric types) | raw bits; stored ±0 sign of map keys (E4) | NaN is outside the key domain (E1) — a value-model limit, not a register cause | EXACT | decimal128 form-2 materialization is a loud unsupported-type reject (no Go type; a skipped field consumes grammatically, WF-23) |
| complex | a pair of FLOAT values (real and imaginary parts) (gspec:Numeric types) | "Complex types are comparable." (gspec:Comparison operators); wire equality is pairwise bit equality | raw bits of both parts | none | EXACT | none beyond the stream |
| strings | STRING (internable) (gspec:String types) | bytewise equality — "A string type represents the set of string values." | the byte sequence, not mandated UTF-8 | none | EXACT | none beyond the stream |
| arrays | ARRAY of fixed length | elementwise equality when comparable (gspec:Array types) | elements; length | none | EXACT | none beyond the stream |
| structs | STRUCT descriptor; field order is declaration order (WF-18) | fieldwise equality when comparable (gspec:Struct types) | fields in declaration order | identity of zero-size values neither preserved nor observable (G-6) — register 5.3 zero-size | EXACT | reflect-materializable target fields |
| slices | VIEW over a backing; extent is the slice capacity (WF-15) | slices are not host-comparable; identity of the backing is preserved (≡_GBON sharing; G-1) (gspec:Slice types) | len; capacity (extent); sharing; cycles | zero-tail degeneracy qualified by extent agreement (WF-20 (i)) — register 5.3 zero-tail | EXACT | backing join by the capacity window |
| maps | MAP with count | key domain and order per E1–E5 and KO-1, KO-2, KO-2b, KO-2a; slot keys materialize separately (KO-2); "The comparison operators == and != must be fully defined for operands of the key type; thus the key type must not be a function, map, or slice." (gspec:Map types) | pair count; key distinction; deterministic pair order within one encoding | none | EXACT | key materialization per the KO scheme |
| pointers | pointer-target record plus REF resolution (WF-13) | "Pointer types are comparable." (gspec:Comparison operators) — pointer identity, not pointee value; pointer keys are identity keys (E2, KO-2a) (gspec:Pointer types) | identity (sharing); nil-ness | address-identity across processes unspecified (E5) — register 5.3 address-weak | EXACT | REF resolution against pointer-target records |
| interfaces | the dynamic value's own descriptor and body (WF-18) | "Two interface values are equal if they have identical dynamic types and equal dynamic values or if both have value nil." (gspec:Comparison operators) (gspec:Interface types) | dynamic type and value; nil-interface vs typed-nil distinction (KO-4) | none | EXACT | name resolution through the registry for dynamic types (`unknown_name` on miss; unnamed chain derivation on a miss, 1.3) |
| typed nil | one nil class with a kind selector — pointer, slice, map, interface (WF-12) | nil-ness and nil kind round-trip; the representation is merged, the distinction is positional (gspec:Variables) | nil-ness; nil kind | *big.Int nil and inline zero share one body byte (WF-3) — register 5.3 nil-merge | REPRESENTATIONAL | position shape: pointer and interface positions materialize nil, value positions zero |
| time.Time | CODER kind 14 under the short-form name time.Time (1.4) | a struct type of the standard library (gspec:Struct types); wire equality is byte equality of the coder image | the coder's byte image round-trips | none declared beyond the coder contract | EXACT | registered coder (CODER 14) |
| Coder-backed types | CODER records with canonical tags (GO-6) | a defined type binds an identifier to a new type (gspec:Type declarations); wire equality is byte equality of the coded image | the coder's byte image; tag stability across rebuilds | none declared beyond the coder contract | EXACT | registered coder and name resolution (coder error contract, 3.2) |
| functions | no wire image — no opcodes in any class (GO-1) | "Slice, map, and function types are not comparable." (gspec:Comparison operators) (gspec:Function types) | — | format limit, not a degeneracy cause | UNSUPPORTED | n/a — classified reject `unsupported_kind` with the path |
| channels | no wire image — no opcodes in any class (GO-1) | comparable channels compare by identity — no denotation (gspec:Channel types) | — | format limit, not a degeneracy cause | UNSUPPORTED | n/a — classified reject `unsupported_kind` with the path |
| unsafe.Pointer | no wire image — no opcodes in any class (GO-1) | outside the value model (gspec:Package unsafe) | — | format limit, not a degeneracy cause | UNSUPPORTED | n/a — classified reject `unsupported_kind` with the path |
| exotic/composite map keys | map keys per the KO scheme; skeletons never dereference (E2) | identity keys for pointer components (KO-2a) — "Slice, map, and function types are not comparable." (gspec:Comparison operators) (gspec:Map types) | key identity distinction; tied-pair order deterministic within one encoding (E5) | pointer-to-map keys rejected unsupported-type (GO-3); dynamically uncomparable members outside the key domain (E1) | EXACT | per-key skeleton walk; the pointee-map reject names the path |

UNSUPPORTED rows carry a format limit (no opcodes), never a
degeneracy cause; DEGRADED rows, when one is declared, cite a register
entry (5.3). The four statuses are the CLM-5 vocabulary verbatim.

Named types receive the Go term of art `underlying type` (gspec:Types):
the type to which a defined type refers. The core names the concept
neutrally — the layout-normal form of G-5 of docs/foundations.md — and
docs/wire-format.md section 7.1 carries the neutral form only; this
binding is the term's corpus home.

### 5.3 Degeneracy Register

Degeneracy causes are facts of the host language, stated against the
source hierarchy (5.1), never against codec behavior. The register is
the single source of degeneracy causes: the table (5.2) references
entries, prose elsewhere references the register.

| Cause | Degeneracy cause in the host language | Constructs | Declared treatment |
|---|---|---|---|
| zero-size | distinct zero-size values carry no bytes and no address identity the language tier distinguishes; the runtime may place them at one shared base address (an implementation-defined zone, tier 4 of 5.1) | zero-size arrays, structs, and composites — nil-ness observable, identity neither preserved nor observable (G-6, WF-13) | REPRESENTATIONAL |
| nil-merge | the nil values of the reference kinds share one predeclared nil (gspec:Variables), and for `*big.Int` the nil token coincides with the inline zero argument byte (WF-3) | typed nil — the four nil kinds of one class with a selector (WF-12); the *big.Int nil/zero coincidence | REPRESENTATIONAL |
| zero-tail | a non-nil slice of length zero presents no elements: its observable shape degenerates to the extent window over its backing (WF-15) | zero-length non-nil slices (VIEW len 0) | REPRESENTATIONAL |
| address-weak | pointer identity is an address, an artifact of allocation — stable within one process, unspecified across processes (E5); pointer keys are identity keys (E2, KO-2a), and the stable-class predicate stays with the core (WF-20) | pointer map keys; identity-keyed map pairs | REPRESENTATIONAL |

The zero-tail entry carries the extent-agreement qualification of the
canonical claim (WF-20 (i)): two projections binding different extents
may diverge on join boundaries — a documented projection annotation,
not a core divergence.

### 5.4 Stable-class projection

The core's stable class and its guard contract (wire-format.md section
8.1, WF-20) are normative there; this section is the binding's
projection of the class, in two halves (CLM-2 Scope in
docs/meta/claims.md names both).

**Static conservative predicate over types.** The reference encoder's
per-type execution plan carries a verdict: a type is statically stable
when no interface appears anywhere in its graph and every map key type
in the graph is free of pointer, interface, float, complex, and
unsafe-pointer components, recursively through struct fields and array
elements. The condition is necessary, not sufficient: recursive type
graphs flag dynamic conservatively — the verdict is a bottom-up fold
that reads a self-referential component before its own verdict exists,
and the unset verdict counts as dynamic. The verdict is
one-directional by construction — it never
classifies an unstable-capable type as stable, while types flagged
dynamic may still hold only in-class values:

| Go map key category | Static verdict |
|---|---|
| bool, integer, string keys | statically stable — distinct slots carry distinct skeletons |
| struct/array keys of the above | statically stable |
| float32/float64, complex64/128 keys | dynamic — E4 zero-sign ambiguity |
| pointer keys (including `*big.Int`) | dynamic — E5 tie eligibility |
| interface keys | dynamic — the verdict is per dynamic key |
| keys with pointer/interface/float/complex components | dynamic |

Interfaces anywhere in a value graph force the dynamic path even under
safe keys: a slot can hold any dynamic value. Coder-covered types are
leaves of the verdict (GO-6): their byte image is the coder's contract,
outside the two rules. A statically stable type skips every dynamic
per-map check; the guard then runs only where value facts can violate
the class.

**Dynamic exact predicate at encode time.** Stable mode (the reference
implementation's `MarshalStable` and `Encoder.SetStable`) checks the
two rules exactly: the `unstable_tie_break` class when any map applies
the E5 tie-break — pairs equal in key skeleton and pair value bytes
across distinct identity slots, ordered by the KO-2a pointer
discriminator — and the `unstable_zero_float_key` class when any map
holds a zero float key of either sign, as a scalar key or as a component
of a composite key (axiom E4: the stored sign is the projection's
key-overwrite semantics, GO-2). Both rejects name the value path of the
offender in sorted-index form; the classification is a function of the
offending rule alone, never of process state. An application may
restore membership by moving identity into value — a declared
discriminator inside the key (WF-20), without any format change.
