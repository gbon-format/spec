# GBON Claim Registry

Informative meta-document, non-normative with respect to the core. The
registry of the format's public claims and invariants: formulations,
scopes, falsification criteria, and verification ownership. Normative
force lives exclusively in `docs/foundations.md`,
`docs/wire-format.md`, and `docs/bindings/go.md`, per the layering of
`docs/meta/spec-conventions.md` (SC-1). Registry identifiers `CLM-n`
and `H-n` follow the SC-3 stability law: extend only, never renumber,
never reuse. Named sub-properties (`S1`–`S3`) are defined once in
their owning claim and referenced elsewhere by identifier; the grain
axioms (`G-1`–`G-6`) are defined once in `docs/foundations.md`
(clause 4.1) and referenced here by identifier.

**Contents**

- [1. Purpose and Method](#1-purpose-and-method)
- [2. Format Claims](#2-format-claims)
  - [CLM-1 Value Domain and Equivalence](#clm-1-value-domain-and-equivalence)
  - [CLM-2 Canonicality: the Signature Contract](#clm-2-canonicality-the-signature-contract)
  - [CLM-3 Observables and the Round Trip](#clm-3-observables-and-the-round-trip)
  - [CLM-4 Grain Invariants](#clm-4-grain-invariants)
  - [CLM-5 Binding Projection and Expressibility](#clm-5-binding-projection-and-expressibility)
  - [CLM-6 Negative Completeness](#clm-6-negative-completeness)
  - [CLM-7 Conformance Architecture](#clm-7-conformance-architecture)
- [3. Hypotheses](#3-hypotheses)
  - [H-1 Exhaustiveness of Re-derivation Exceptions](#h-1-exhaustiveness-of-re-derivation-exceptions)
- [4. Verification Ledger Schema](#4-verification-ledger-schema)

## 1. Purpose and Method

A claim is a falsifiable public commitment of the format, of a
binding, or of the verification architecture. The registry is the
single source the conformance corpus and the test pyramid are built
against: every test cites exactly one owning claim; every claim cites
its verification instrument.

Each entry carries five fields:

- **Formulation** — the commitment, stated declaratively.
- **Scope** — qualifications that bound the claim; an unqualified
  reading of the formulation is a misreading.
- **Falsification** — the observation that kills the claim. A claim
  without a concrete falsifier is not admitted to the registry.
- **Verification** — the owning level: `F` (format conformance,
  implementation-independent) or `I` (binding and implementation).
- **Status** — `codified`: the normative home carries the text;
  `derived`: the reference implementation carries the behavior and the
  normative home is assigned; `formulated`: this registry is the home
  until the placement edit lands in the corpus.

Statuses record placement, not history: they say where the text lives,
never why it looks the way it does.

## 2. Format Claims

### CLM-1 Value Domain and Equivalence

**Formulation.** GBON defines a language-independent value-graph
domain: values with explicit identity, sharing, cycles, ordering, and
representation-level observables. The domain carries an equivalence
`≡_GBON` — identity-structure-preserving isomorphism with equal
declared observables — and every value of the domain has a decidable
equivalence to every other value.

**Scope.** `≡_GBON` is not arbitrary graph isomorphism: it preserves
the identity layer (which nodes are shared, where cycles close) and
the declared representation observables. Canonical labeling of graphs
up to isomorphism is outside the format's computational commitment
(foundations clause 5); no claim of the shape "isomorphic graphs imply
equal bytes" is made or implied.

**Falsification.** Two values equal under `≡_GBON` whose encodings
differ without a declared exception (CLM-2); two values distinct under
`≡_GBON` whose encodings coincide; a domain construct for which
`≡_GBON` is undecidable.

**Verification.** F: equivalence fixtures (equal and distinct pairs
with expected bytes).

**Status.** codified — foundations clauses 2–5 (the equivalence
`≡_GBON`: clause 5.1); WF-13. The grain fragment of the domain is
codified at the model level (foundations 4.1; CLM-4).

### CLM-2 Canonicality: the Signature Contract

**Formulation.** Canonical bytes are sufficient material for a
signature over value content and topology. The contract is three
properties:

- **S2 (soundness).** `E(v1) = E(v2)` implies `v1 ≡ v2`, and
  `D(E(v)) ≡ v`: equal bytes denote one value; the round trip lands on
  an equivalent value.
- **S3 (exclusivity).** A non-canonical spelling of a value is an
  invalid stream: canonicality is a decode-side contract, so any
  alternative byte sequence for the same value is rejected, never
  merely different.
- **S1 (stability).** On the stable class — a decidable predicate on
  the value domain — the encoding is a function of the value alone:
  any process, any construction order, any conforming implementation
  (with the extent agreement of WF-20) produces the same bytes.
  Outside the stable class, S1 makes no claim; S2 and S3 hold
  unconditionally.

**Scope.** The stable class excludes exactly the declared
re-derivation exceptions (H-1): the E5 tie-break (pairs equal in
skeleton and value bytes occupying distinct identity slots) and the
E4 zero-sign freedom (float keys holding a zero whose stored sign the
projection leaves to key-overwrite semantics). A value leaves the
class the moment any map in its graph triggers either rule. Encoder
side: a stable mode MUST reject a value outside the class with a
deterministic classified error; the guard's completeness is
conditional on H-1. Bindings declare the projection of the class — a
static conservative predicate over types and a dynamic exact
predicate at encode time. An application MAY restore membership by
moving identity into value (a declared discriminator inside the key),
without any format change.

**Falsification.** A decoder accepting a non-canonical spelling (S3);
a byte collision between `≡_GBON`-distinct values (S2);
isomorphic-pair divergence on a value inside the declared stable
class (S1 or H-1); a guard pass on a value whose encodings differ
across processes.

**Verification.** F: canonicality fixtures; reject vectors per
non-canonical class; the isomorphic-pair differential (two
independently constructed `≡_GBON` instances, byte equality). I: guard
determinism and error classification; the binding's class projection.

**Status.** codified for S3 and the WF-20 determinism core (WF-20,
KO-1..KO-8, E1–E5); derived for S2 (reference implementation;
axiom-set audit assigned); codified for the stable-class predicate
and the guard return-contract (wire-format 8.1); the guard
implementation is derived in the Go binding (stable mode) and
instrumented by the isomorphic-pair differential.

### CLM-3 Observables and the Round Trip

**Formulation.** The round trip preserves every declared observable
bitwise: value contents, identity and sharing, cycle topology,
reference topology, map-key semantics, nil versus empty, slice
extent, NaN payloads, ±0, subnormals, non-UTF-8 byte sequences, exact
numeric representations, typed nils. Each observable carries one of
three classifications: MUST preserve; MAY degrade with declared blame
(the degradation ladder of foundations 6.5); OUTSIDE GBON. No path
exists from a value to its round-trip image that loses an observable
without a declared, attributed classification.

**Scope.** The classification table is per observable and per
position; "preserved" means bit-exact where the observable is
representation-level. Degradation blames the boundary (the
projection), never the core silently.

**Falsification.** A round trip losing a MUST-preserve observable; a
degradation without a ladder classification; blame landing on the
core where the projection owns the loss.

**Verification.** F: observable fixtures with expected bytes and
expected observables, both directions. I: materialization fidelity of
the binding for each observable.

**Status.** codified — foundations 6.2 (the consolidated
classification table), 6.5; WF-8, WF-11, WF-12, WF-14, WF-15, WF-16.

### CLM-4 Grain Invariants

**Formulation.** The domain admits typed views over one identity
(grains): a single identity observed at distinct types. The grain
layer obeys the six model axioms G-1..G-6 — single record, spine
compatibility, order independence, uniform resolution, layout-normal
normalization, contentless views — defined in `docs/foundations.md`
(clause 4.1) and referenced here by identifier.

**Scope.** Descent from a record's canonical grain to a position's
view is derivable, carries no bytes, and is fixed by the record's
content tag and the view structure. The grain layer is a domain-level
construct with wire-level operational rules; host vocabulary
(pointer, field offset, underlying type) belongs to bindings.

**Falsification.** Two records for one identity; a canonical grain
that varies across runs or implementations for one tracked-view set
(G-3, and a breach of S1); a resolution that depends on the asking
position; a layout-normal divergence between the intern key and the
record grain; a contentless view carrying a record.

**Verification.** F: grain fixtures (view sets with expected canonical
grains and bytes); the bounded-exhaustive grammar corpus. I: the
reference implementation against the grammar generator.

**Status.** codified at the model level — foundations 4.1 (G-1..G-6);
codified operationally — WF-13 (the grain rules of the wire graph
section); derived in the reference implementation.

### CLM-5 Binding Projection and Expressibility

**Formulation.** A binding defines a partial denotation from a host
language's serializable values into the value domain. Every covered
construct carries one of four statuses: EXACT (the host semantics
maps directly), REPRESENTATIONAL (the host representation is richer;
declared portable observables survive), DEGRADED (host semantics is
consciously excluded, with blame), UNSUPPORTED (no correct denotation
exists; a classified reject). The expressibility thesis: every host
construct whose topology does not degenerate within the host language
itself has an exact denotation; every exclusion is justified either
by a format limit or by host-language degeneracy, recorded in the
degeneracy register (construct, degeneracy cause, declared
treatment).

**Scope.** The Go binding is grounded in the Go Language Specification
through the source hierarchy: the language specification; the
`reflect` documentation; the `unsafe` documentation; runtime behavior
only where the specification itself marks the behavior
implementation-defined, and there pinned by tests. The binding pins
the specification version. The stable-class projection of CLM-2
(static and dynamic predicates) is a binding-declared section. The
denotation table cites, per construct: the specification anchor, the
denotation, the identity and equality semantics, the preserved
observables, the intentional losses, the status.

**Falsification.** A host construct without a table row and without a
register entry; a DEGRADED status without a register cause; a silent
loss; a denotation contradicting its cited specification anchor; an
unpinned implementation-defined zone influencing bytes.

**Verification.** I: the binding table against the reference
implementation, construct by construct. F: the promoted subset —
every construct whose denotation is expressible as an abstract
fixture.

**Status.** codified — the grounding sections of
`docs/bindings/go.md` (5.1 source hierarchy, 5.2 denotation table,
5.3 degeneracy register) are the home of the binding projection and
its expressibility thesis; GO-1..GO-7 carry the type mapping, nil
model, lifecycle, and error conformance.

### CLM-6 Negative Completeness

**Formulation.** Every value outside the encodable domain meets an
explicit, deterministic, classified error — never a panic, never a
silent degradation, never a wrong encoding. Hostile input is the
default decode posture: budgets bound depth, nodes, bytes, and
allocations; validation precedes allocation; error classes are stable
and additive.

**Scope.** Deterministic means: the same input and environment yield
the same error class on every run. The class inventory is the binding
error table (GO-5); the core owns the reject classes of the wire
grammar.

**Falsification.** A panic on any input; a nondeterministic error
class; an out-of-domain value encoding to plausible bytes; a
degradation path without an error.

**Verification.** F: reject vectors per class. I: the error taxonomy
of the implementation, tripwires, budget gates.

**Status.** codified — WF-22; GO-1, GO-5; derived in the reference
implementation; the completeness audit over the construct inventory
is assigned under CLM-5.

### CLM-7 Conformance Architecture

**Formulation.** Verification is a two-level pyramid with claim
ownership:

- **Level F — format conformance.** Fixtures are data: abstract value
  graphs with expected canonical bytes, expected observables, and
  reject classes. Portability holds by the differential criterion:
  two independent implementations byte-agree on every fixture. Each
  implementation binds through an adapter of exactly three
  operations — materialize a fixture, encode, decode to an
  observables report. Expected bytes derive from the specification,
  never from extraction of a single implementation's output (SC-9).
- **Level I — binding and implementation.** Projection fidelity
  against the binding tables, registry semantics, coder contracts,
  error taxonomy, budgets, tripwires, performance guards. Not
  portable across implementations by construction.

Non-delegation: a test asserts exactly one owning claim at its own
level, without reliance on another level's coverage. Reuse of fixture
data across levels is not duplication when the asserted claims
differ. An implementation-language test of a format-level claim is a
promotion candidate: the claim citation is the promotion trigger, the
fixture is the promotion product.

**Scope.** The adapter surface is itself an audit object: an adapter
exceeding three operations smuggles implementation behavior into
Level F. Bounded-exhaustive generation belongs to F when driven from
the abstract grammar; the host-value generator harness is I.

**Falsification.** An orphan claim (no owning test); an orphan test
(no cited claim); two tests asserting one claim at one level; a
fixture whose expected bytes come from one implementation's output
without an independent derivation; a fat adapter.

**Verification.** The ledger of section 4 — the registry checks
itself: every CLM row resolves to ledger entries; every ledger entry
cites a CLM row.

**Status.** codified — the ledger ships with the corpus
(manifest.json); the registry checks itself (lint gate stage).

## 3. Hypotheses

### H-1 Exhaustiveness of Re-derivation Exceptions

**Statement.** The stable class of CLM-2 excludes exactly two rules,
and no others:

1. The E5 tie-break (KO-2a): map pairs equal in skeleton bytes and
   pair-value bytes occupying distinct identity slots, ordered by a
   process-local discriminator.
2. The E4 zero-sign freedom: a float key holding a zero whose stored
   sign the projection leaves to key-overwrite semantics.

Every other byte-determining component — intern numbering in DFS
order, descriptor first-encounter order, the KO-2b value-bytes phase
and its nested recursion, grain selection (G-3), derivable descent,
layout normalization, the backing join over closed geometry — is a
function of the value alone. Platform-dependent type widths are
denotation variance (distinct domain values), not re-derivation
exceptions; extent binding is a projection annotation (WF-20 (i)).

**Falsification.** A value inside the declared stable class whose
encodings differ between processes, construction orders, or
implementations; an audit finding a third order-sensitive component.

**Verification.** Specification audit over every order- and
representation-decision point of the wire grammar; the
isomorphic-pair differential bounded-exhaustively over the grammar
corpus.

**Status.** verified — the audit held (the exhaustiveness spike
closed the question to the two declared rules); the differential
instrument landed green.

## 4. Verification Ledger Schema

The ledger binds claims to tests. One row per test:

```text
test-id | level (F|I) | owning CLM (and sub-property) | instrument
```

Laws:

- Every CLM entry (and every named sub-property asserting something
  testable) resolves to at least one `F` or `I` row; H-n rows carry
  their verification instrument the same way.
- Every row cites exactly one owning claim; a test asserting two
  claims is two tests.
- No two rows share (level, claim): one claim, one level, one
  instrument; additions replace, they do not accumulate.
- The ledger ships with the conformance corpus and moves only in
  lockstep with it (SC-9).

Materialization: the ledger is the `ledger` block of `manifest.json`,
and the manifest's `version` is the schema version of the block and the
fixture classes (the block, the classes, and the number move in one
cross-repo land unit; the wire version of the streams is a separate
axis). A row is a JSON object with exactly the fields

```text
test | level | claim | sub | instrument
```

- `test` — the bound artifact: at level F the `vectors[].id` of a
  manifest fixture (a fixed-byte vector or a fixture class declared in
  `vectors/`); at level I a `Test` function of the reference binding.
- `level` — `F` or `I`.
- `claim` — the owning registry identifier (`CLM-n`, `H-n`).
- `sub` — the sub-property cell beneath the claim where the row binds
  (`S1`–`S3`, an instrument zone such as `guard`), empty when the row
  binds the claim itself. The uniqueness law reads the composite
  `claim[/sub]` as the claim.
- `instrument` — the live instrument executing the row: the corpus
  consumer, the differential runner, the lint stage of the spec gate.

The registry checks itself: the ledger laws above are a gate stage of
the spec repository — row-to-def and def-to-row resolution, the
uniqueness cell, and test-to-artifact resolution, each direction, over
the def set derived from this document's own headings.

The ledger for the current registry state is the work product of the
conformance corpus; its materialization accompanies the first
fixture set promoted under CLM-7.
