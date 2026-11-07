## 1. Contract

- [x] 1.1 A plugin's published rule files are not reserved for this plugin: the resolution contract's section on rules published by other plugins has an **Other readers** paragraph stating that a published file is not reserved for perspective-writer, that the publishing plugin's skills may read it directly, that perspective-writer expands and discloses nothing for them and `plugin-rules.sh` is not an interface for other plugins, and that a file meant for both readers contains no include line. Verification: content review of `references/rules-resolution.md`; `check-contract-consistency.sh` passes.
- [x] 1.2 The README section on rules from other plugins says the same in one sentence. Verification: content review of `README.md`.

## 2. Release

- [x] 2.1 The changelog records the clarification under 4.12.4, and the plugin and marketplace manifests both carry 4.12.4. Verification: the changelog entry is present and both manifests report 4.12.4.
- [x] 2.2 The plugin-rules test suite still passes. Verification: `bash tests/plugin-rules.test.sh` exits 0.
