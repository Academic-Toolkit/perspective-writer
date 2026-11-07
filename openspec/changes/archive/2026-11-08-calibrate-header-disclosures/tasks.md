## 1. Contract and skill

- [x] 1.1 Calibrate header names the additional disclosures: the README return shape (promise 7) specifies `disclosures=<kinds>` with the kinds line, kinds only, `v1` unchanged, and states that writing it is a prose-model obligation; the skill's Calibrate-draft entry collects the disclosures and writes the attribute; the resolution contract's *Additional disclosures* section points to it. Verification: content review of the three files.
- [x] 1.2 Consumer ignores unrecognised header attributes, and Consumer discloses rules that were not applied as written: promise 7 and promise 5 state both obligations with SHALL; the version-floor paragraph names 4.13.0 for consumers that read the attribute; promise 1 says the disclosures travel back in the header. Verification: content review of the README contract section.

## 2. Checks

- [x] 2.1 Contract and skill agree on the disclosure kinds: `check-contract-consistency.sh` gains the assertion, and `tests/plugin-rules.test.sh` gains cases for drifted kinds, reordered kinds, a new contract kind, a skill entry without the attribute, and a README without the ignore rule. Verification: the five cases fail before the assertion exists and pass after; `bash tests/plugin-rules.test.sh` and `PW_TEST_BASH=/bin/bash /bin/bash tests/plugin-rules.test.sh` both exit 0.

## 3. Release

- [x] 3.1 The changelog records 4.13.0 (minor: an additive contract change) and states that existing consumers keep working; the plugin and marketplace manifests both carry 4.13.0. Verification: the entry is present and both manifests report 4.13.0.
