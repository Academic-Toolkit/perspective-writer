## ADDED Requirements

### Requirement: Calibrate header names the additional disclosures

In calibrate mode, when resolving the subject's rules produced at least one additional disclosure, the status header SHALL carry ` disclosures=<kinds>` before ` -->`, listing each kind that occurred once, comma-separated without spaces, in the order of the resolution contract's *Additional disclosures* table. The attribute SHALL name kinds only and never a disclosure's target. With no disclosure the attribute SHALL be absent and the header SHALL be unchanged. The header token SHALL remain `v1`, and the status SHALL be the one resolution produced.

#### Scenario: An include names a plugin that is not installed

- **WHEN** the subject's core file is found and a genre file it uses includes a plugin that is not installed
- **THEN** the header is `<!-- pw:calibrate v1 status=person disclosures=include-unresolved -->`
- **AND** the header does not contain the include's target

#### Scenario: Two kinds occur

- **WHEN** an imported copy is stale and an include is unresolved
- **THEN** the attribute reads `disclosures=include-unresolved,import-stale`

#### Scenario: No disclosure

- **WHEN** every include and import resolves and no redirect is unresolved
- **THEN** the header is `<!-- pw:calibrate v1 status=person -->` exactly

### Requirement: Consumer ignores unrecognised header attributes

The published consumer contract SHALL state that consumers SHALL ignore header attributes they do not recognise.

#### Scenario: A consumer written before an attribute existed

- **WHEN** a consumer that reads only `status=` receives a header that also carries `disclosures=`
- **THEN** it reads the status as before and its handling of the draft is unaffected

### Requirement: Consumer discloses rules that were not applied as written

When the header carries `disclosures=`, the consumer SHALL tell its user that some of the subject's rules were not applied as written, naming the kinds and saying that running the skill directly on the same subject shows which files, whatever the status.

#### Scenario: Status person with an unresolved include

- **WHEN** the header is `<!-- pw:calibrate v1 status=person disclosures=include-unresolved -->`
- **THEN** the consumer tells its user that rules a rule file refers to were not loaded
- **AND** does not present the reply as calibrated with all of the subject's rules

### Requirement: Contract and skill agree on the disclosure kinds

The contract consistency check SHALL fail when the README consumer contract or the skill's Calibrate-draft entry does not specify the `disclosures=` attribute, when the README no longer states the ignore-unknown-attributes rule, or when the kinds the README lists differ from the resolution contract's table in membership or order.

#### Scenario: The contract gains a kind

- **WHEN** a fifth row is added to the resolution contract's *Additional disclosures* table and the README is not updated
- **THEN** the consistency check exits 1 and names the README's disclosure kinds
