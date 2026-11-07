## 1. Contract clauses

- [x] 1.1 Consumer reads the status header: the published consumer contract states reading the returned status header as an obligation in its own right, phrased with SHALL, and not merely implied by the disclosure clause. Verification: content review of the consumer-contract section confirms a standalone requirement exists and uses SHALL.
- [x] 1.2 Consumer discloses a degraded outcome: the clause that today says consumers SHOULD surface a degraded return is raised to SHALL, and states that apparent draft quality is not evidence that calibration occurred. Verification: searching the consumer-contract section for the disclosure clause shows SHALL and no remaining SHOULD on that obligation.
- [x] 1.3 Contract enumerates the conditions producing a degraded outcome: the section lists the conditions that yield the degraded outcome and points at the resolution contract's outcome-status definition as the authority rather than restating the semantics. Verification: content review confirms all three conditions from the spec example table are present and that the section links to the resolution contract instead of duplicating its definitions.

## 2. Release

- [x] 2.1 The changelog records the obligation change, naming the raised strength and the added enumeration, and states that no existing consumer breaks — a non-compliant one keeps working and is merely out of compliance. Verification: the changelog entry is present and says both things.
- [x] 2.2 The plugin manifest and the marketplace manifest carry a matching minor version increment reflecting an additive obligation rather than a breaking interface change. Verification: both manifests report the same new version and it is a minor bump from the current one.
