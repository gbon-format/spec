# GBON specification

This repository holds the specification of the **GBON format**: the
normative wire format, the value-model foundations underneath it, and
its language bindings.

GBON is a language-independent binary format for serializing object
graphs under three hard contracts: bitwise-faithful round-trips,
always-canonical encoding, and decoding under explicit resource budgets.

GBON — Graph Binary Object Notation, pronounced GEE-bon.

The specification is developed together with the Go implementation
(`gbon-go`, module `github.com/gbon-format/gbon-go`) and the
[showcase repository](https://github.com/gbon-format/showcase), where
the format's measurable evidence is published as reproducible
artifacts; all three are published side by side. The conformance
corpus is derived from the specification, not from any
implementation's code, and a family of independent implementations is
expected — the language bindings are projections of the core, not its
source.

## Status

**Draft — format 0.0 (major 0, the draft era).** The format is under
active development and the documents describe work in progress. Draft
status is a statement of maturity, not a schedule and not a promise
about future versions.

## Documents

- [docs/wire-format.md](docs/wire-format.md) — the normative transfer
  syntax: stream header, value-stream grammar, value encodings, graph
  topology, the canonical profile, decode budgets and limits, version
  evolution, and security considerations.
- [docs/foundations.md](docs/foundations.md) — the value model: the
  neutral value-graph, its identity/sharing/cycles contract, equality
  and canonical-form semantics, requirements on the wire layer, and
  the academic anchor map of the model.
- [docs/bindings/go.md](docs/bindings/go.md) — the Go binding, an
  appendix non-normative with respect to the core: encodable
  categories, cross-version stability notes, the error model, and
  interop mappings.
- [docs/references.md](docs/references.md) — the consolidated external
  anchor map: source, support, role, and verification status for every
  external citation.

A machine-readable conformance corpus (non-normative data) lives in
[vectors/](vectors/) with its [manifest.json](manifest.json) index;
see the pointer in Appendix A of the wire format.

A schema-snapshot annex (`SA-n` identifiers, referenced from the Go
binding) publishes the schema-artifact verdict taxonomy as
specification surface. The schema-artifact engine — snapshotter and
checker — is a separate implementation surface, outside the day-one
perimeter of this repository.

## Repository gates

`scripts/gate.sh` runs the gates of this repository over the
tracked content: anchor and structure integrity, vocabulary hygiene,
residual-token and language scans, and — against a local checkout of
`gbon-go` — the factual-truth check of the error-class inventory
(`scripts/gate.sh --sb-e <gbon-go-dir>`).

## License

MIT — see [LICENSE](LICENSE).
