# GBON External References

Consolidated anchor map of the external sources cited by the GBON
specification corpus. One row per external anchor: the anchor key, the
bibliographic source, what the anchor supports, its role, and its
verification status. The per-document reference surfaces point here;
this file is the single source of external anchors.

**Anchor keys.** Canonical, human-readable identifiers derived from the
primary source: document numbers for standards (`rfc-8949`,
`ieee-754-2019`, `iso-8824-1`) and author-year forms for papers
(`kraft-1949`, `goguen-et-al-1977`). Gate phase (e) extracts and
normalizes anchor citations from the citing documents and cross-checks
them against this map; the keys themselves need not appear verbatim in
the text.

**Roles.** `normative anchor` — the source grounds a normative clause;
`family-note` — a related format or mechanism, cited non-normatively;
`precedent-note` — an engineering precedent or practice.

**Status.** `verified` — the bibliographic data was checked against the
primary source; `verified-bib` — checked against secondary bibliographic
records (DBLP and similar); `verify-on-write` — carried in canonical
form, re-checked before the entry enters a normative document.

| Anchor key | Source | Support | Role | Status |
|---|---|---|---|---|
| rfc-2119 | S. Bradner. Key words for use in RFCs to Indicate Requirement Levels. RFC 2119, BCP 14, IETF, March 1997. | Requirements-language interpretation in wire-format.md clause 2.1 and spec-conventions.md SC-4 | normative anchor | verified |
| rfc-8174 | B. Leiba. Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words. RFC 8174, BCP 14, IETF, May 2017. | Requirements-language interpretation; uppercase-only force of the keywords | normative anchor | verified |
| rfc-8949 | C. Bormann, P. Hoffman. Concise Binary Object Representation (CBOR). RFC 8949, STD 94, IETF, December 2020. | WF-21 versioning-governance fallback; the CBOR no-offset-0-magic fact of wire-format.md clause 4.2; SC-10 | precedent-note | verified |
| ieee-754-2019 | IEEE 754-2019. IEEE Standard for Floating-Point Arithmetic (IEEE Std 754-2019; identical to ISO/IEC 60559:2020), the binary32/64 and decimal128 formats. | WF-8 float formats; bitwise preservation of NaN, ±0, subnormals | normative anchor | verify-on-write |
| iso-60559-2020 | ISO/IEC 60559:2020, Floating-point arithmetic; identical to IEEE Std 754-2019. | WF-8: the ISO/IEC edition of IEEE Std 754-2019 | normative anchor | verify-on-write |
| iso-8824-1 | ISO/IEC 8824-1, Information technology — Abstract Syntax Notation One (ASN.1): Specification of basic notation; ITU-T X.680. | Language-mapping pattern terminology of wire-format.md; SC-10 | family-note | verify-on-write |
| iso-8825-1 | ISO/IEC 8825-1, Information technology — ASN.1 encoding rules; ITU-T X.690. | Language-mapping pattern terminology of wire-format.md; SC-10 | family-note | verify-on-write |
| protobuf-encoding | Protocol Buffers — encoding: varint, ZigZag. The project's official documentation (protobuf.dev). | WF-4 varint family note; WF-5 ZigZag precedent; SC-10 | precedent-note | verify-on-write |
| ion-spec | Amazon Ion specification. | SC-10 further reading | family-note | verify-on-write |
| bson-spec | BSON specification. | SC-10 further reading | family-note | verify-on-write |
| avro | Apache Avro — Schema Resolution; Protocol Buffers — type updates (field evolution). The projects' official documentation. | WF-23 evolution practice note | precedent-note | verify-on-write |
| dwarf | DWARF Debugging Information Format, Version 5. DWARF Standards Committee. | WF-4 family note: LEB128 | family-note | verify-on-write |
| gob | Go standard library, encoding/gob package documentation. | The gob no-offset-0-magic fact of wire-format.md clause 4.2 | family-note | verify-on-write |
| stable-rfc-std-numbering | IETF — the practice of stable RFC/STD numbering (RFC Index, STD 1). | WF-24 precedent note: stable section-ID numbering | precedent-note | verify-on-write |
| barendregt-et-al-1987 | H. P. Barendregt, M. C. J. D. van Eekelen, J. R. W. Glauert, R. Kennaway, M. J. Plasmeijer, M. R. Sleep. Term Graph Rewriting. PARLE (2) 1987: 141-158. | WF-13: cycles as rational trees; term graphs make sharing an object of the theory | normative anchor | verified-bib |
| backhouse-et-al-1998 | R. C. Backhouse, P. Jansson, J. Jeuring, L. Meertens. Generic Programming: An Introduction. Advanced Functional Programming 1998: 28-115. | The neutral value model (element series 3) | normative anchor | verified-bib |
| hoare-1975 | C. A. R. Hoare. Recursive Data Structures. Int. J. Parallel Program. 4(2): 105-132, 1975. | WF-10, WF-17: the sequence sort and labeled products | normative anchor | verified-bib |
| goguen-et-al-1977 | J. A. Goguen, J. W. Thatcher, E. G. Wagner, J. B. Wright. Initial Algebra Semantics and Continuous Algebras. J. ACM 24(1): 68-95, 1977. | WF-6, WF-7, WF-9, WF-16, WF-18: the sorts of the neutral model's signature | normative anchor | verified-bib |
| babai-luks-1983 | L. Babai, E. M. Luks. Canonical Labeling of Graphs. STOC 1983: 171-183. | WF-20 canonicalization complexity | normative anchor | verified-bib |
| babai-kucera-1979 | L. Babai, L. Kucera. Canonical Labelling of Graphs in Linear Average Time. FOCS 1979: 39-46. | WF-20 canonicalization complexity | normative anchor | verified-bib |
| elias-1975 | P. Elias. Universal Codeword Sets and Representations of the Integers. IEEE Trans. Inf. Theory 21(2): 194-203, 1975. | WF-3, WF-4, WF-18: prefix-free codes, the ARG width ladder, the ext body | normative anchor | verified-bib |
| strong-et-al-1958 | J. Strong, J. Wegstein, A. Tritter, J. Olsztyn, O. Mock, T. Steel. The Problem of Programming Communication with Changing Machines: A Proposed Solution. Commun. ACM 1(8): 12-18, 1958. | WF-1 (supporting): spec-first federation (element series 8) | normative anchor | verified-bib |
| conway-1958 | M. E. Conway. Proposal for an UNCOL. Commun. ACM 1(10): 5-8, 1958. | Spec-first federation (element series 8) | normative anchor | verified-bib |
| steel-1961 | T. B. Steel Jr. UNCOL: The Myth and the Fact. Annual Review in Automatic Programming 2: 325, 1961. | Spec-first federation (element series 8) | normative anchor | verified-bib |
| macrakis-1992 | S. Macrakis. From UNCOL to ANDF: Progress in Standard Intermediate Languages. OSF Research Institute RI-ANDF-TP2-1, 1992. | Spec-first federation (element series 8) | normative anchor | verified-bib |
| courcelle-1983 | B. Courcelle. Fundamental Properties of Infinite Trees. Theor. Comput. Sci. 25, 1983. | WF-13: cycles as rational trees | normative anchor | verify-on-write |
| milner-1977 | R. Milner. Fully Abstract Models of Typed λ-Calculi. Theor. Comput. Sci. 4, 1977. | WF-1, WF-12, WF-15: full abstraction of the embedding; the degradation ladder | normative anchor | verify-on-write |
| plotkin-1977 | G. Plotkin. LCF Considered as a Programming Language. Theor. Comput. Sci. 5, 1977. | WF-12, WF-15: the degradation ladder | normative anchor | verify-on-write |
| reynolds-1978 | J. C. Reynolds. Syntactic Control of Interference. POPL 1978. | WF-13, WF-20: the identity layer is observable | normative anchor | verify-on-write |
| reynolds-2002 | J. C. Reynolds. Separation Logic: A Logic for Shared, Mutable Data Structures. LICS 2002. | WF-13, WF-20: identity and sharing (element series 2) | normative anchor | verify-on-write |
| burstall-1969 | R. M. Burstall. Proving Properties of Programs by Structural Induction. Computer Journal 12(1), 1969. | WF-10, WF-17: the sequence sort, labeled products | normative anchor | verify-on-write |
| kraft-1949 | L. G. Kraft. A Device for Quantizing, Grouping, and Coding Amplitude-Modulated Pulses. MIT Master's thesis, 1949. | WF-1, WF-3, WF-14, WF-20: prefix-freeness, minimal length | normative anchor | verify-on-write |
| mcmillan-1956 | B. McMillan. Two Inequalities Imposed by the Decodability Requirement. IRE Trans. Inf. Theory 2(4), 1956. | WF-1, WF-3, WF-14, WF-20: unique decodability | normative anchor | verify-on-write |
| mckay-1981 | B. D. McKay. Practical Graph Isomorphism. Congressus Numerantium 30: 45-87, 1981. | WF-20 canonicalization complexity | normative anchor | verify-on-write |
| luks-1982 | E. M. Luks. Isomorphism of Graphs of Bounded Valence Can Be Decided in Polynomial Time. J. Comput. Syst. Sci. 25(1), 1982. | WF-20 canonicalization complexity | normative anchor | verify-on-write |
| babai-2016 | L. Babai. Graph Isomorphism in Quasipolynomial Time. STOC 2016. | WF-20 canonicalization complexity | normative anchor | verify-on-write |
| schorr-waite-1967 | H. Schorr, W. M. Waite. An Economical Marking Algorithm. Commun. ACM 10(10), 1967. | WF-13: traversal with bounded memory | normative anchor | verify-on-write |
| ershov-1958 | A. P. Ershov. On Programming Arithmetic Operations. Commun. ACM 1(8), 1958. | WF-11, WF-13, WF-16, WF-18: value numbering, hash-consing | normative anchor | verify-on-write |
| crosby-wallach-2003 | S. A. Crosby, D. S. Wallach. Denial of Service via Algorithmic Complexity Attacks. USENIX Security 2003. | WF-22: the budget dimensions cover the classes of complexity attacks | normative anchor | verify-on-write |
| tarjan-1985 | R. E. Tarjan. Amortized Computational Complexity. SIAM J. Algebraic Discrete Methods 6(2), 1985. | WF-22: charge-before-allocation is the potential method | normative anchor | verify-on-write |
| miller-et-al-1990 | B. P. Miller, L. Fredriksen, B. So. An Empirical Study of the Reliability of UNIX Utilities. Commun. ACM 33(12), 1990. | WF-22: fuzzing empirics | normative anchor | verify-on-write |
| cardelli-mitchell-1991 | L. Cardelli, J. C. Mitchell. Operations on Records. Math. Struct. Comput. Sci. 1(1), 1991. | WF-17, WF-21, WF-23: width subtyping; bidirectional wire compatibility | normative anchor | verify-on-write |
| findler-felleisen-2002 | R. B. Findler, M. Felleisen. Contracts for Higher-Order Functions. ICFP 2002. | WF-15: extent as a capacity-like annotation with blame | normative anchor | verify-on-write |
| siek-taha-2006 | J. G. Siek, W. Taha. Gradual Typing for Functional Languages. Workshop on Scheme and Functional Programming 2006. | WF-15: the degradation ladder | normative anchor | verify-on-write |
| goguen-burstall-1992 | J. A. Goguen, R. M. Burstall. Institutions: Abstract Model Theory for Specification and Programming. J. ACM 39(1), 1992. | Spec-first federation (element series 8) | normative anchor | verify-on-write |
| sleep-plasmeijer-1993 | M. R. Sleep, M. J. Plasmeijer (eds.). Term Graph Rewriting: Theory and Practice. Wiley, 1993. | WF-13: term graphs (element series 1) | normative anchor | verify-on-write |
| fraenkel-klein | A. S. Fraenkel, S. T. Klein. Robust Universal Complete Codes for Transmission and Compression. Discrete Appl. Math. 64, 1995. | WF-4 family note: start-step-stop codes | family-note | verify-on-write |
