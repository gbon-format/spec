# GBON Java Binding

Binding of the GBON wire-format core to the Java value model. The core
specification (docs/wire-format.md, format 0.2, minor 2) is
normative and language-independent; this document is the Java
projection — an appendix non-normative with respect to the core —
carrying the parts of the contract specific to the Java value model.
Sections of this binding carry stable IDs JV-1..JV-7; core rules are
cited by their WF-n section IDs (the ID scheme is defined by core
section WF-1). Resolvability of every ID reference across the
repository is enforced by the reference-lint gate (non-normative: see
the gbon-java repository).

**Contents**

- [1. Type Mapping](#1-type-mapping)
  - [1.1 Non-Encodable Categories [JV-1]](#11-non-encodable-categories-jv-1)
  - [1.2 Nil Model [JV-4]](#12-nil-model-jv-4)
  - [1.3 Interface Positions and Open Hierarchies](#13-interface-positions-and-open-hierarchies)
  - [1.4 Descriptor Names in Java](#14-descriptor-names-in-java)
- [2. Lifecycle and Behavioral Notes](#2-lifecycle-and-behavioral-notes)
  - [2.1 Cross-Version Stability Notes [JV-2]](#21-cross-version-stability-notes-jv-2)
  - [2.2 Known Limitations [JV-3]](#22-known-limitations-jv-3)
  - [2.3 Schema Snapshot Mechanics [JV-6]](#23-schema-snapshot-mechanics-jv-6)
  - [2.4 Evolution Intents [JV-7]](#24-evolution-intents-jv-7)
- [3. Error Conformance](#3-error-conformance)
  - [3.1 Error Classes [JV-5]](#31-error-classes-jv-5)
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

### 1.1 Non-Encodable Categories [JV-1]

Lambda expressions and method references — the function values — have
no opcodes in any class: the category has no wire image. The encoder
reports an unsupported-type error with the path to the offending
field. Runtime-live objects outside the value model — threads,
streams, open resources — carry no denotation either; the reject is
the same class. What crosses the wire is data (1.3).

**Key-domain restriction (from core WF-25).**

The core's key domain admits any encodable value as a map key (axiom
E1) and excludes exactly NaN and cycles reachable from a key position
(KO-5); identity keys are a binding-declared layer (KO-2). This
binding declares its identity layer per-type (2.1); map-in-key is
legal (Map content equality, 5.2); the rejects — NaN keys, cyclic
keys — are core contracts, restated as binding observables in the
denotation table (5.2).

### 1.2 Nil Model [JV-4]

The core's nil layer (WF-15) carries one nil state: selector 0,
absent. No selector encodes a nil sort — the sort of a nil is
derived, never read from the token: from the static type of the
position or, for a typed nil in an interface or reference position,
from the dynamic descriptor carried with the nil body (WF-15, WF-24).
Which nil sorts a projection distinguishes is binding content (WF-15);
Java distinguishes none beyond the static: every reference type is
nullable through one unnamed null type (jls:4.1), a null reference
carries no dynamic descriptor, and the sort of a null is always the
static type of its position — the typed-nil machinery of the core (a
nil riding an interface position under a dynamic descriptor, WF-24)
has no Java carrier:

| Java null position | How the sort reaches the decoder |
|---|---|
| any null reference | the static type of the position — no dynamic descriptor exists to carry |

null is never confused with empty (WF-15): an empty String is a
STRING with zero bytes (WF-13), an empty array an ARRAY with length 0
(WF-16), an empty map a MAP with count 0 (WF-18). Selectors 1..11 are
reserved by the core (WF-15); this projection exercises none beyond
selector 0.

### 1.3 Interface Positions and Open Hierarchies

The core's INTERFACE descriptor (WF-22, kind 6) is an opaque,
interface-like wrapper; method sets are a binding concern and are not
encodable. In this binding, an interface-typed position carries the
dynamic value's own descriptor and body — the wire image of a Java
interface value is its concrete dynamic value, never the static
interface type. Function values are outside the encodable categories
(JV-1), so no interface position carries behavior across the wire.
A null interface-typed position is the nil token (WF-15): the
position itself, no descriptor.

**Open hierarchies (from core WF-22; AM-2).**

An open class hierarchy — extensible, non-sealed or unsealed
(jls:8.1.1.2) — has no finite variant table: it rides interface
positions. The representation choice is keyed on closure, not on the
sealed keyword: a permits set containing a non-sealed (extensible)
member is not closed and rides interface positions even though the
hierarchy is declared sealed; a fully closed permits set is a VARIANT
(5.2).

**Enum singletons (from core WF-24).**

An enum constant is an interned singleton — "no instances other than
those defined by its enum constants" (jls:8.9) — and encodes as a
shared cell REF, never as a VARIANT value: the binding convention is
REF for enum singletons, so the singleton graph survives the
round-trip (G-1 of docs/foundations.md).

### 1.4 Descriptor Names in Java

The core's descriptor identity is structural (WF-22): descriptors
intern by canonical structure — kind, arguments, and child type-refs,
recursively — and nominal names do not participate in the structural
key: a nominal wrapper and its base intern independently. A nominal
name is qualified by the binding's namespace grammar (binding
content, WF-22), and instantiation is unified under the grammar
`Name[args]`: a type expression's wire name is the constructor name
followed by its bracketed argument list, the arguments being
canonical structural names. Generic instantiation is erased at run
time (jls:4.6) — the instantiation's identity is naming-only (5.2).

The namespace grammar of this projection is the binary name of the
Java binary-name grammar (jls:13.1): every defined type takes its
binary name; generic instantiations take `Name[args]`; unnamed
composites take their canonical structural string. The name mapping
is injective within one stream (WF-22): one binary name, one
descriptor — subject to the classloader caveat below.

Collisions follow the core's hybrid policy (WF-22): derived
qualified names stay clean — no renaming and no disambiguation
suffixes. Java's collision case is the defining-loader split: the
same binary name loaded by distinct classloaders denotes distinct
runtime classes (jls:13.1; jvms:5). If two such types reach one
stream, the encoder rejects at registry start with a
register-conflict error naming both origins (JV-5; the decode-side
counterpart is a format error at the colliding descriptor), and the
resolution is explicit name binding. The name-binding law is one
chain, one name: a binding attaches at the constructor's binary name
and covers the whole chain — every `Name[args]` instantiation of the
type rides it — so a second binding attaching a different name to a
chain already bound rejects with the register-conflict family
(JV-5), and re-binding the same name is a no-op. The reserved standard namespace
`std.` cannot collide with a language-derived name (WF-22).

The platform names carried in this projection:

| Platform name | Wire kind (WF-22) |
|---|---|
| byte, short, int, long | INT (10) — widths 8, 16, 32, 64 |
| char | UINT (11) — width 16 under the range rule 0..FFFF (2.1) |
| boolean | BOOL (9) |
| float, double | FLOAT (12) — binary32, binary64 |
| String | STRING (13) |
| byte[] | BLOB (14) |
| BigDecimal | std.decimal — the reserved interchange name (WF-11) |

BigDecimal maps onto the decimal interchange by default
name-binding (WF-11, WF-22) — the composition is lossless, and no
degradation row exists (2.1). BigInteger carries no platform name: it
rides the INT arbitrary-precision rung (WF-8) — INT is structural.

## 2. Lifecycle and Behavioral Notes

### 2.1 Cross-Version Stability Notes [JV-2]

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

**Identity layer (declaration, per-type).**

Java's identity layer is per-type: a class without a value-equals
override compares by reference identity — "for any non-null reference
values x and y, this method returns true if and only if x and y refer
to the same object" (api:Object.equals) — and such a type is an
identity key when used as a map key (axiom E5, KO-2). Every type
with value equals — records, String, the boxed primitives, the
collection classes — compares by value; no identity key exists for
it. The identity discriminator of an identity key is the referenced
object's allocation, stable within one JVM and unspecified across
processes (E5).

**Stability tier T2 declaration (identity-determinant instantiation
of WF-25).** determinant form — the LinkedHashMap insertion-order
sequence of the map's pairs: pairs tied in key skeleton and value
bytes across distinct identity slots are ordered by insertion
sequence. determinism scope — within one JVM with a deterministic
insertion history; HashMap is explicitly excluded (its iteration
order is unspecified), so the declaration covers only
insertion-ordered map types. verification hook — re-encode byte
identity over the insertion-ordered materialization. The determinant
fixes the ORDER of otherwise indistinguishable map pairs (axiom E5),
never byte content: the insertion sequence never enters the encoded
bytes. Outside this declaration Java's tier-2 coverage collapses to
stability tier T1 union T3.

**char range rule (from core WF-9).**

The core defines no character kind: a char-typed value is a UINT
under the binding's range rule — a UTF-16 code unit, 0..FFFF
(jls:4.2.1, jls:3.1). A UINT of any other width decoded into a char
target range-checks against 0..FFFF and rejects outside
(`overflow_value`, JV-5).

**Degradation table (per the core annotation WF-11).**

Degrades are declared with blame on receive, never as silent
widening:

| trigger | native? | behavior on receive | blame/class | escape hatch |
|---|---|---|---|---|
| FLOAT binary16 or binary128 into a Java value position | no — the language float types are float and double only (jls:4.2.3) | loud classified reject naming the form and the value path; a skipped field of that form consumes grammatically (WF-6) | `unsupported_kind` (JV-5) — the unsupported-form family | none — no native Java type exists |
| GBON UINT of a width with no same-width unsigned Java type | no — char is the only unsigned integral type (jls:4.2.1) | decode-side range check with blame: values within the target's representable range materialize in the next wider signed type; values outside reject loudly — never silent wraparound | `overflow_value` (JV-5) | widen to the next signed type, or BigInteger on the INT arb rung (WF-8) |
| a non-UTF-8 byte sequence in a STRING position against a String target | representational — String content is UTF-16 (jls:3.1); invalid UTF-8 has no String image | loud validity gate in both directions: encode-side the UTF-16-to-UTF-8 transcode failure rejects; decode-side an invalid sequence into a String target rejects | `invalid_string_encoding` (JV-5) | byte[] carries all bytes (WF-14) |

### 2.2 Known Limitations [JV-3]

- **transient/static exclusions.** Instance fields marked transient
  and static fields are skipped at encode — a declared encode-side
  skip policy, not an inferred one; the skipped positions produce no
  records and no references, and decode never materializes a value
  for them.
- **Extent binding (from core WF-24, WF-17, WF-25).** A Java array
  has a fixed length and no capacity notion — the length never
  changes (jls ch. 10) — so this projection binds extent = len, the
  documented projection annotation of WF-25 (i): two projections may
  diverge on join boundaries only through their extent binding, a
  qualification of the tier-1 claim attributed to the projection,
  never silently to the core.
- **Strings and blobs (from core WF-13, WF-14).** A Java String is a
  UTF-16 sequence (jls:3.1); the wire STRING is a byte sequence. The
  transcode is the binding's coder; the validity gates of the
  degradation table (2.1) own the non-UTF-8 cases, and byte[] carries
  arbitrary bytes as BLOB. The STRING/BLOB class split is the wire
  image of the projection's text-versus-binary distinction.
- **Field inheritance flattening.** Fields flatten across the class
  hierarchy into one sorted field list (WF-19): a field visible
  through inheritance encodes like a declared field (jls:8.2);
  shadowed field names — same name, distinct declaring classes —
  are a loud error at descriptor build.
- **Covariant array subtyping.** Arrays are covariant (jls:4.10.3)
  and the runtime enforces the element type on store
  (ArrayStoreException); the value model is unaffected — an array is
  an ARRAY of its element type, and no denotation rides the subtype
  relation.
- **Per-value budget scope (from core WF-26).** The MaxBytes counter
  scopes to the value being decoded — the grammar's top-level unit,
  one value per decode step: it opens at the value's start and resets
  when the next value begins, so cumulative consumption beyond
  MaxBytes across the values of one stream is conformant — no
  per-stream cumulative cap exists; within one value, input bytes and
  charged allocations share the counter.

### 2.3 Schema Snapshot Mechanics [JV-6]

A schema snapshot is taken from a declaration scope, never from a
value stream: the declarer accumulates declarations — types,
ready-made descriptors, coder declarations, name bindings — and
builds a schema snapshot. Encoding or decoding values in other scopes
never changes the built bytes; the snapshot is a pure function of the
declared set. The binding-side mechanics:

- The member set is the declaration list: declared Java types (record
  classes, sealed hierarchies, named composites), declared
  descriptors, and registry-only members — types declared but
  reachable from no other member still ride as top-level records.
- The artifact component is the frozen descriptor encoding (WF-22):
  the same bytes, the same canonical order, the same text twin
  discipline.
- A name binding (one wire name for one type) rides as a NAMED
  wrapper over the canonical descriptor — one graph per type, no
  structural duplicate (WF-22). The canonical record and the wrapper
  share the descriptor; a wrapper that would precede its canonical
  record in the canonical order is rejected at build time.
- Closure: every member is a top-level record. A member whose literal
  would surface inside a byte-wise earlier member is kept whole — the
  earlier record carries a structural unfolding of it under a
  canonical type-expression name, and the member keeps its own
  record. Sets that cannot close are rejected at build time.
- Coder declarations produce CODER records with canonical tags: each
  CODER record carries its ordinal among the CODER records of the
  canonical stream — an order derived from the sorted member set,
  not from the value-stream encounter order. Tags are stable across
  rebuilds and declaration permutations.
- Determinism: permuting the declarations and rebuilding the same
  scope produce identical artifact bytes.

### 2.4 Evolution Intents [JV-7]

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
- The artifact bytes are invariant to reserved-name declarations: the
  tombstone component is the only place a reserved name surfaces.
- The value codec enforces the removal on both sides: a scope holding
  a reserved name refuses to encode a value whose type carries that
  wire name (at the root or in any nested position) and refuses to
  decode a stream name landing in the reserved set — a
  registry-contract refusal in both directions. Re-declaring the same
  name is a no-op; a reserved name colliding with a live binding, a
  registered type, or a coder of the same scope is rejected at
  declaration time.
- A field alias intent declares that a struct field travels under a
  new name: the snapshot record carries the target field name, and
  the (source, target) pair survives as snapshot metadata — the
  rename is declared data, not a derived guess. Without a declaration
  the intent machinery leaves the bytes untouched; declaring against
  a missing field, or two targets for one source field, is rejected
  at declaration time.

## 3. Error Conformance

### 3.1 Error Classes [JV-5]

Codec errors are a contract of structure, not text: messages may
change between releases; the stable surface is the class ID, the
family attribution (a typed hierarchy root per family), and the
fields of the structured error type (class, input offset, value
path, got/want, cause). Six families carry the errors; the code and
contract families share one hierarchy root; the environment family
answers through its own root with the underlying read or write fault
reachable as the cause, and the internal family attributes a foreign
exception recovered by the decode tripwire — an internal defect, not
crafted input. The concrete exception types are implementation
identifiers and live outside this document (non-normative: see the
gbon-java repository). The one-line rendering interpolates no
untrusted input: decoded values, keys, and stream names surface only
through the structured fields; caller arguments (registry names,
Java types, configured limits) are trusted and stay in the text.
Value paths chain `$` (root), `.field`, `[i]`, and `["key"]`
segments as produced by the location tracking of the failing side.

Class IDs, snake_case, additive only (new classes may appear; IDs
are never renamed or reused). The table is the class inventory:
family and the hierarchy attribution (registry names are stream
data, coder faults are codec capability):

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
| `invalid_string_encoding` | data/format | format | STRING bytes invalid as UTF-8 for a String target |
| `budget_depth` | budget | budget | depth budget exhausted |
| `budget_nodes` | budget | budget | node budget exhausted |
| `budget_bytes` | budget | budget | byte budget exhausted |
| `budget_alloc` | budget | budget | allocation survived limits but failed |
| `unsupported_kind` | code | unsupported | value kind has no serialized form |
| `register_conflict` | code | unsupported | registry name or type conflict |
| `coder_error` | code | unsupported | custom coder failed |
| `coder_recursion` | code | unsupported | custom coder re-entered the codec |
| `contract_mismatch` | contract | unsupported | decode target breaks the evolution contract |
| `io_read` | env | io | underlying reader failed |
| `io_write` | env | io | underlying writer failed |
| `internal_error` | internal | internal | foreign exception recovered by the decode tripwire |
| `unstable_tie_break` | contract | unsupported | stable mode: map pairs tied in key skeleton and value bytes (identity tie-break order, E5) |
| `unstable_zero_float_key` | contract | unsupported | stable mode: zero float map key of ambiguous stored sign (E4) |

The core's evolution carve-out class `evolution_ref_unmaterialized`
(WF-6) projects onto `contract_mismatch` — a kept reference whose
target stayed unmaterialized under narrowing is a decode-target
setup problem, not a bytes problem.

**Cross-language slot preservation.** A stream carrying tied
identity-key pairs — encoded under this binding's identity layer —
read by a value-only consumer is a loud reject preserving the slot
count (`duplicate_key` in that consumer's inventory): a silent
slot collapse never substitutes for the reject. The mirror holds in
this direction too: a value-only stream decoded here never meets a
tied identity pair, and slot count is preserved in both directions.

### 3.2 Coder Error Contract

A custom coder throws and owns no location: the codec's coder seams
assign the path and the offset, attribute the class (coder_error, or
coder_recursion on re-entry), and keep the coder's original exception
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
| `internal_error` | 500 | Internal | `internal_error` |
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

Every claim this binding makes about the Java value model is grounded
in a four-rank source hierarchy, in normative order:

1. **Source rank 1 — the Java Language Specification, SE 27.** The
   language specification is the first source for every claim about
   the value model; a construct's semantics is stated here before
   the documentation of any implementation is consulted.
2. **Source rank 2 — the Java Virtual Machine Specification, SE
   27.** The JVM specification grounds the run-time structures the
   language delegates to — loading, linking, and run-time packages;
   it never overrides source rank 1.
3. **Source rank 3 — the Java SE API documentation.** The API
   documentation of the java.base classes grounds the contracts of
   the library types this binding maps (Object, String, the
   collections, BigDecimal).
4. **Source rank 4 — JDK behavior.** Runtime behavior grounds a claim
   only in zones the specifications themselves mark
   implementation-defined, and there only pinned by tests;
   everywhere else it is not a source.

A claim that needs a lower source rank where a higher rank speaks is
a defect (the falsification class of CLM-5 in docs/meta/claims.md).

**Version pins (source ranks 1-3).** The load-bearing pages are
pinned here in full; the family pin tables live in the consolidated
anchor map (docs/references.md, rows jls-se27, jvms-se27,
java-se27-api), which cites the fetch records of the grounding spike
(fetched 18 September 2026):

- JLS SE 27, chapter 4 (Types, Values, and Variables): 355701
  bytes, sha256
  3be1c820e9697e3a2b1d2e7ace1e202d187f8ef21fccc04b0da6ebb667f7876a.
- JLS SE 27, chapter 8 (Classes): 591935 bytes, sha256
  e62a30b838fb2ea60bf897d7778ca86fe68f8962997df42c8548d5c5ce50d154.
- JVM Specification SE 27, chapter 5 (Loading, Linking, and
  Initializing): 280082 bytes, sha256
  46ac90213223b3c3a1ca9a41edb1a3594c5b4aa61fe6459e6b17a49bf950b756.
- java.base API, java.lang.String: 281611 bytes, sha256
  67469dd65e9f7348832fbd995fba01a1ce5367cec7d0cef59b184c094661d731.
- java.base API, java.lang.Object: 56035 bytes, sha256
  7f06bc7e355dae3fda34c56c0f1cf246a01c24cb9ca9e13bfd4ac0c84a87fa23
  — the identity-layer re-pin (2.1), fetched 19 September 2026,
  grounding the identity-equals row (5.2) on the default equals
  contract.

A fetched page whose checksum differs from the pin is a re-pin event:
cited sections are re-resolved against the new page before any
further grounding claim.

**Citation form.** Table rows cite the pinned pages as `jls:`
followed by the chapter or section, `jvms:` by chapter, and `api:`
by class — for example `jls:4.2.1` ("signed two's-complement"),
`api:Object` ("this method returns true if and only if x and y refer
to the same object"). Quoted material is at most one sentence,
verbatim from the pinned page.

### 5.2 Denotation Table

The binding is a partial denotation from Java's serializable values
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
| byte, short, int, long | INT widths 8/16/32/64 (WF-8); signed two's-complement (jls:4.2.1) | value equality (≡_GBON value dimension); integer key order is the argument-byte order of the zigzag image (KO-6) | value; recorded width | none | EXACT | decoder range-checks the target width |
| char | UINT width 16 under the range rule 0..FFFF — a UTF-16 code unit (WF-9; jls:4.2.1, jls:3.1) | value equality | the code unit value | none | EXACT | a UINT of another width range-checks against 0..FFFF (2.1) |
| boolean | BOOL (WF-10); two values (jls:4.2.5) | value equality | value | none | EXACT | none beyond the stream |
| float, double | FLOAT binary32/binary64 (WF-11); "exactly correspond to" the IEEE 754 forms (jls:4.2.3) | bit equality: ±0, NaN payloads, subnormals are representation-level distinctions of ≡_GBON; float keys round-trip bitwise (KO-3) | raw bits | NaN is outside the key domain (E1) — a value-model limit, not a register cause | EXACT | binary16/binary128 materialization is a loud classified reject on receive with blame (the degradation table, 2.1); a skipped field of those forms consumes grammatically (WF-6) |
| String | STRING (WF-13); UTF-16-sourced — transcoding is the binding coder (jls:3.1; api:String) | content equality of the UTF-16 sequence; wire equality is bytewise over the UTF-8 image | valid text | invalid-UTF-8 byte sequences have no String image (register 5.3 utf16-transcode) | REPRESENTATIONAL | non-UTF-8 into a String target rejects loudly; byte[] carries all bytes (2.1, WF-14) |
| T[] (array) | ARRAY of T (WF-16); extent = length — the length never changes, no capacity (jls ch. 10) | reference comparison is identity (api:Object); the wire image is the element sequence | elements; fixed length | none | EXACT | extent binds to length (2.2) |
| record class | STRUCT under its qualified name; components as fields in canonical name-sorted order (WF-19, WF-22); header components with by-name accessors (jls:8.10) | components compared by value — the record's derived equality | the component set, by name | declaration-order positions are not a wire observable — access is by name (jls:8.10) | EXACT | reflect-materializable target components |
| enum class | interned shared cell REF (WF-24); "no instances other than those defined by its enum constants" (jls:8.9) | == identity maps onto cell identity | the singleton graph (sharing, G-1) | none | EXACT | REF resolution against interned cells |
| sealed hierarchy (closed permits) | VARIANT — closed sum; tags = the canonical sorted variant table (WF-21, WF-22; jls:8.1.1.2) | per-alternative | alternative identity | none | EXACT | permits-closure derivation |
| open hierarchy (extensible) | interface position — the dynamic value's own descriptor and body (WF-22; AM-2; jls:8.1.1.2) | the dynamic value's equality | dynamic type and value; null = the nil token | closure of the hierarchy is not a wire fact | EXACT | name resolution through the registry for dynamic types (`unknown_name` on miss) |
| null | the nil token — selector 0, absent (WF-15); one unnamed null type, every reference type nullable (jls:4.1) | one null value | nil-ness; sort derived from the static type | no typed nils — a null reference carries no dynamic descriptor (1.2) | EXACT | the sort materializes from the static type of the position |
| Map | MAP with count (WF-18); content-equality keys — "represent the same mappings" (api:Map); map-in-key legal | content-equality keys; a map in key position is a legal key | pair count; key distinction; deterministic pair order within one encoding | none | EXACT | key materialization per the KO scheme |
| cyclic collection from a key position | no wire image for the cycle-in-key — core encoder reject (KO-5, WF-25); recursive self-containment is spec-warned (api:Collection) | — | — | format limit, not a degeneracy cause | UNSUPPORTED | n/a — classified reject with the path |
| class without value equals, as key | identity key per the per-type identity layer (2.1; E5, KO-2) | reference identity — "true if and only if x and y refer to the same object" (api:Object) | key identity distinction; tied-pair order deterministic within the declared determinism scope (2.1) | allocation-identity across processes unspecified (E5) — register 5.3 identity-equals | EXACT | tie order per the declared determinant (2.1) |
| BigDecimal | std.decimal default name-binding (WF-11, WF-22); arbitrary-precision unscaled value + scale (api:BigDecimal) | value equality over the interchange image | the decimal value (unscaled value, scale) | none — the composition is lossless | EXACT | registered name binding (std.decimal, 1.4) |
| generics — C<T> | Name[args] (WF-22); erased at run time (jls:4.6) | instantiation identity is naming-only | the instantiation's wire name | run-time type identity of instantiations (register 5.3 erasure) | REPRESENTATIONAL | name resolution; decode materializes the erasure |
| inherited fields | flat flattening into the sorted field list (WF-19; jls:8.2) | fieldwise, over the flattened set | the flattened field set | shadowed field names — same name, distinct declaring classes — are a loud error at build (2.2) | REPRESENTATIONAL | shadow-name collision rejected |
| Optional<T> | library-level 2-variant sum — VARIANT (WF-21; the library-sum pattern) | empty is a variant, not the nil token | presence structure; nesting resolves naturally | none | EXACT | none beyond the stream |

UNSUPPORTED rows carry a format limit (no wire image for the
construct in that position), never a degeneracy cause; DEGRADED
rows, when one is declared, cite a register entry (5.3). The four
statuses are the CLM-5 vocabulary verbatim.

### 5.3 Degeneracy Register

Degeneracy causes are facts of the host language, stated against the
source hierarchy (5.1), never against codec behavior. The register is
the single source of degeneracy causes: the table (5.2) references
entries, prose elsewhere references the register.

| Cause | Degeneracy cause in the host language | Constructs | Declared treatment |
|---|---|---|---|
| identity-equals | a class without a value-equals override inherits the reference-identity default — "true if and only if x and y refer to the same object" (api:Object) — so its instances distinguish only by allocation, stable within one JVM and unspecified across processes (E5) | identity keys (2.1); identity-keyed map pairs | REPRESENTATIONAL |
| erasure | generic instantiations erase at run time (jls:4.6): distinct instantiations share one class — the instantiation's identity is carried by the wire name only | generics — Name[args] naming-only identity (5.2) | REPRESENTATIONAL |
| utf16-transcode | a String is a UTF-16 sequence internally (jls:3.1); the wire STRING is a byte sequence — the transcode is the binding's coder, and invalid UTF-8 has no String image | String (STRING); the validity gates of the degradation table (2.1); byte[] as the byte-carrying alternative | REPRESENTATIONAL |

The identity-equals entry carries the E5 qualification of the
canonical claim (WF-25): identity keys are stable within one JVM,
unspecified across processes — the tier-2 declaration (2.1) states
the determinism scope under which encodings agree.

### 5.4 Stable-class projection

The core's stable class — the class over which the stability tier T1
claim holds — and its guard contract (wire-format.md section 8.1,
WF-25) are normative there; this section is the binding's projection
of the class.

**Per-type identity keys and the stable class.** A Java map key sits
outside the stable class exactly when its key type is in the identity
layer (2.1 — a class without value equals) or holds a float
component: identity keys carry the E5 tie eligibility — ordered by
the declared determinant (2.1) — and float keys carry the E4
zero-sign ambiguity, excluded from the tier-1 claim (WF-25 (ii)).
Keys of value-equals types without float components — records of
such components, String, the boxed integral types, content compared
per api:Map ("represent the same mappings") — are in the stable
class by the static predicate.

**Guard contract.** The two guard classes of the inventory (JV-5)
project the core axioms: `unstable_tie_break` — pairs equal in key
skeleton and pair value bytes across distinct identity slots,
ordered by the declared determinant (axiom E5; the LinkedHashMap
insertion-order declaration, 2.1) — and `unstable_zero_float_key` —
a zero float key of either stored sign, as a scalar key or as a
component of a composite key (axiom E4). Both rejects name the value
path of the offender in sorted-index form; the classification is a
function of the offending rule alone, never of process state. An
application may restore membership by moving identity into value —
a declared discriminator inside the key (WF-25), without any format
change.
