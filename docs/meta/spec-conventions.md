# GBON Specification Conventions

Binding rules for writing and editing the GBON specification corpus:
`docs/`, the repository `README.md`, and the conformance corpus surface.
The mechanical subset is enforced by the repository gates
(`scripts/gate.sh`). Rule identifiers (SC-n) are stable: rules are
extended, never renumbered or reused.

## SC-1. Document roles and layering

The corpus is three sibling documents with fixed roles:

- `docs/foundations.md` — the core value-graph model. Owns the model:
  values, identity, sharing, cycles, equality and canonical-form
  semantics, and the extensibility requirements imposed on the wire
  layer. Do not add a conformance clause here; conformance lives in the
  transfer-syntax document.
- `docs/wire-format.md` — the transfer syntax. Owns the token grammar,
  stream structure, graph machinery, canonical profile, decode limits,
  and the conformance clause.
- `docs/bindings/<host>.md` — host-binding appendices. Own the
  projection of the neutral model onto one host language: type
  mappings, nil taxonomies, name inventories, lifecycle notes, and
  error conformance.

Layering direction: the model document states requirements for the wire
layer; the wire document references the model; bindings reference both.
Do not invert these directions.

## SC-2. Section structure

Use flat section spines. Do not introduce an internal "Part" level: in
standards usage a Part is a separate document, and the GBON files
already are the parts.

- `wire-format.md` spine, in order: 1 Scope and layering; 2 Conventions
  and requirements language; 3 Conformance (dedicated, early:
  well-formed vs valid, budget duties, refusal scope); 4 Stream
  structure and version marker; 5 Primitive field formats; 6 Value
  encodings by kind; 7 Graph encodings; 8 Canonical and portable
  profiles (restriction clauses over the base encoding); 9 Limits and
  budgeted decode; 10 Security considerations; Appendix A Examples;
  Appendix B Declared Origins.
- `foundations.md` spine: unnumbered Introduction (layering overview,
  annex status list); 1 Scope with the layering statement; 2
  Definitions; 3 Model overview; constructive mechanisms; equality and
  canonical semantics; extensibility requirements; informative annexes
  (examples, guidance, the preliminary bibliography with its status
  marker).
- `bindings/<host>.md` spine: status declaration; type mapping;
  lifecycle; error conformance; examples.

Numbering depth is at most two levels (a third only inside one
"general" subsection). Appendices are lettered. Every document carries
a manual table of contents; TOC entries and introductory claims must
match the actual section set.

## SC-3. Identifier stability

Section identifiers — `WF-n` (transfer syntax), `E-n` (axioms), `KO-n`
(key ordering and canonical rules), `SA-n` (schema-snapshot annex),
`GO-n` (host binding) — are stable anchors, orthogonal to section
numbers. Define each identifier once in its home document; reference it
elsewhere by identifier. Extend only; never renumber; never reuse a
freed identifier. Corpus vector ids (`V-n` in `manifest.json`) follow
the same law.

## SC-4. Normative language

Use the requirements keywords of RFC 2119 / RFC 8174, introduced in
the Conventions section of `wire-format.md`. Split normative and
informative material explicitly: informative content lives in
appendices or annexes with their status declared. Do not let the force
of a statement (MUST/SHOULD/MAY) drift between revisions; changing it
is a substantive change and requires a changelog entry.

## SC-5. Neutrality and origin honesty

Keep the core documents neutral; host-shaped content belongs to
bindings.

- Every core rule must be decidable without host-language concepts: a
  second implementation in any language reads the rule and produces
  identical bytes. Where a rule needs a vocabulary originating in one
  ecosystem (a reserved-name table, a type-name form), state the
  neutral rule plus a declared origin in the core, and carry the
  inventory in the binding (the WF-18 namespace pattern).
- Frozen artifacts inherited from history (the reserved `big.Int` wire
  name) are presented as origin facts, not as neutral norms.
- Repository positioning: the `gbon-go` README states that it is the
  reference implementation of the GBON specification, developed by the
  specification's author; the specification README states that the
  conformance corpus is derived from the specification, not from the
  code, and names the reference implementation.

## SC-6. Language

Write in English, outside fenced code blocks and byte dumps. Rewrites
are authored, not machine-translated. Tracked content is free of
contributing-process vocabulary, cycle labels, and datestamped
verification labels; the repository scan enforces this.

## SC-7. Numbers and single-source counting

Format constants (widths, budgets, opcodes, magic bytes) are
specification material and live in the core documents. Measurable
performance claims live in the showcase only — the specification never
carries them. Declare each count once and reference it: vector counts
in `manifest.json`, section counts in the gate constants; prose does
not restate them.

## SC-8. Examples and rationale

Place worked examples inline at each construct and consolidated in
Appendix A. Place rationale, comparisons, and history in informative
appendices (`Appendix B Declared Origins`) or the bibliography annex.
Declared-origin notes (SC-5) are the one admissible form of history
inside normative clauses.

## SC-9. Editing rules

- The gates (`scripts/gate.sh`, including `--sb-e` against the
  reference implementation) must pass before any change is committed or
  merged; they check anchors and TOC, the vocabulary scan, residual
  tokens and cycle labels against the frozen-origin whitelist,
  English outside fenced blocks, error-class factual truth, and
  corpus/manifest integrity.
- Change corpus files and the manifest only together with the
  specification text that derives them; each vector carries its
  derivation chain. Extracting expected bytes from implementation
  behavior is not a valid source.
- Wire-format bytes are frozen: no edit may change any byte of a
  legitimate stream. A disagreement between the text and the reference
  implementation is a defect report against one of them — never a
  silent adaptation of either side.
- Never edit `LICENSE` or identity files.

## SC-10. References

RFC 8949 (STD 94); ISO/IEC 8824-1 (ITU-T X.680); ISO/IEC 8825-1
(ITU-T X.690); the Protobuf encoding specification; the Amazon Ion
specification; the BSON specification. The consolidated anchor map —
sources, roles, and verification statuses — is `docs/references.md`.
