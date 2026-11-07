## 1. Core

- [x] 1.1 Core is the entry point and retains its name: the main skill keeps its current identifier, stays the target of the downstream invocation and presence probe, and its description narrows to genre-independent scope without claiming correspondence conventions it no longer holds. Verification: the invocation string used downstream still resolves, and reading the description shows it no longer promises letter-specific conventions.
- [x] 1.2 Core loads the facet from its body, not by trigger: the bootstrap phase determines the genre, states the determination, instructs loading the matching facet, and states explicitly when no facet exists for that genre rather than defaulting to correspondence. Verification: reading the bootstrap phase shows all three behaviors, and the instruction sits before any drafting step.
- [x] 1.3 Section allocation between core and facet, core side: the core retains the referent discipline, fabrication traps, compose-versus-revise, bootstrap, rules resolution and load gate, understanding the writer, simulation, presenting and iterating, learning from edits, persistence, and the calibration entry. Verification: searching the core for greeting conventions, pressure calibration, and recipient ordering returns nothing.

## 2. Facet

- [x] 2.1 Facet declares inheritance and adds only increments: a correspondence facet exists whose header states that the core is required and expresses the override precedence in the same wording as the rules contract's composition section, and whose body restates none of the core's genre-independent content. Verification: reading the facet header shows both statements, and the facet contains no copy of the referent discipline or fabrication traps.
- [x] 2.2 Section allocation between core and facet, facet side: the facet holds understanding the recipient, opening priority, address conventions, cultural calibration, pressure calibration, recipient ordering, and draft output format. Verification: each of those seven concerns is present in the facet and absent from the core.
- [x] 2.3 The facet's description identifies it as a genre facet loaded by the core rather than as a general answer to a request to write a letter, while remaining directly invocable by name. Verification: reading the description shows it does not compete with the core's trigger phrasing.

## 3. Anti-pattern checklist

- [x] 3.1 Anti-pattern checklist splits row by row: every row present before the split appears in exactly one of the two files, with genre-independent tells in the core and correspondence or draft-presentation rows in the facet. Verification: count rows in both files and confirm the total equals the pre-split count with no row appearing twice.

## 4. Published contract and docs

- [x] 4.1 Published contract names sections rather than phase numbers: the calibration contract's list of non-applicable sections is restated by section name, and every named section is present in the core. Verification: look up each named section in the core and confirm it exists; confirm no phase numbers remain in that mapping.
- [x] 4.2 The README skills table lists the facet and explains that a genre facet is loaded by the core rather than triggered independently, so a reader knows the core is the entry point. Verification: the table includes the facet and the surrounding prose states the load path.
- [x] 4.3 The rules-resolution reference's wording for skill-packaged rules aligns with the genre-facet concept introduced here, so the same word does not mean two different things across the two documents. Verification: read both and confirm the facet terminology is consistent.

## 5. Release

- [x] 5.1 The changelog records the split, naming the two constraints that shaped it — the downstream hardcoded name and the absence of a skill inheritance mechanism — and states the accepted trade-off that completeness is now compositional. Verification: the entry is present and says all three things.
- [x] 5.2 The plugin manifest and the marketplace manifest carry a matching major version increment reflecting the changed skill surface and narrowed core description. Verification: both manifests report the same new version.
