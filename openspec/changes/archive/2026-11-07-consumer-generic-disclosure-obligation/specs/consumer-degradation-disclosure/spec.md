## ADDED Requirements

### Requirement: Consumer reads the status header

A consumer of the programmatic calibration entry SHALL read the status header returned on the first line of the response. The published contract SHALL state this as an obligation in its own right, separate from the disclosure obligation, because a consumer that never reads the header cannot satisfy the disclosure obligation and would otherwise have no stated requirement it visibly fails.

#### Scenario: Consumer receives a calibrated response

- **WHEN** a consumer receives a response from the calibration entry
- **THEN** it reads the status header before using the returned draft

#### Scenario: Contract is read by a new consumer author

- **WHEN** someone implementing a new consumer reads the published contract
- **THEN** the contract states reading the status header as a requirement, not as an implication of another requirement

### Requirement: Consumer discloses a degraded outcome

When the returned status indicates that subject-specific rules were not applied, the consumer SHALL make that fact visible to its user. The contract SHALL express this with SHALL rather than SHOULD.

#### Scenario: Status indicates a generic register was used

- **WHEN** the returned status indicates the generic outcome
- **THEN** the consumer tells its user that subject-specific rules were not applied
- **AND** does not present the result as a fully calibrated one

#### Scenario: Draft reads well despite the generic outcome

- **WHEN** a generic-outcome draft is fluent and free of obvious defects
- **THEN** the disclosure is still made
- **AND** apparent quality is not accepted as evidence that calibration occurred

##### Example: Obligation strength before and after

| Clause | Before | After |
| ------ | ------ | ----- |
| read the status header | not stated | SHALL |
| disclose a degraded outcome | SHOULD | SHALL |

### Requirement: Contract enumerates the conditions producing a degraded outcome

The published consumer contract SHALL enumerate the conditions under which the degraded outcome occurs, so a consumer can turn its disclosure into an actionable message rather than a generic warning. The enumeration SHALL reference the resolution contract's outcome-status definition as the authority rather than restating the semantics, so the two cannot drift as the resolution order gains sources.

#### Scenario: Consumer author needs to write an actionable message

- **WHEN** a consumer author needs to tell the user why calibration degraded
- **THEN** the contract lists the conditions that produce the degraded outcome
- **AND** each condition is distinguishable enough to suggest a different user response

#### Scenario: Resolution order gains a new source

- **WHEN** the resolution order is extended with an additional rules source
- **THEN** the consumer contract's enumeration does not require a parallel edit to stay correct
- **AND** the enumeration continues to point at the resolution contract's definition

##### Example: Conditions producing the degraded outcome

| Condition | What the consumer can suggest |
| --------- | ----------------------------- |
| rules-location field absent from the request | the caller did not supply a location |
| supplied location resolves to nothing | the location may be stale or mistyped |
| no subject rules found at any source the resolution order consults | this subject has no rules on file yet |
