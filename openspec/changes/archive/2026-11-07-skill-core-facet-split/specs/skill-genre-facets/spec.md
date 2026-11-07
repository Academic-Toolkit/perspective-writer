## ADDED Requirements

### Requirement: Core is the entry point and retains its name

The main writing skill SHALL retain its current name and remain the entry point for writing tasks, including the programmatic calibration mode. Genre facets SHALL be additive skills beside it. The core SHALL NOT be renamed to a core-suffixed identifier.

#### Scenario: Downstream consumer invokes the skill

- **WHEN** a downstream consumer invokes the writing skill by the name it currently hardcodes
- **THEN** the invocation resolves to the core
- **AND** the calibration mode behaves as before

#### Scenario: A new genre facet is added

- **WHEN** a facet for a new genre is introduced
- **THEN** it is a new skill beside the core
- **AND** the core's name is unaffected

### Requirement: Core loads the facet from its body, not by trigger

The core SHALL determine the genre of the document during its bootstrap phase, SHALL state that determination, and SHALL instruct loading the matching genre facet. Facet loading SHALL NOT depend on the facet's own trigger surface.

#### Scenario: Writing a document in a genre that has a facet

- **WHEN** the core is invoked and determines the genre is one that has a facet
- **THEN** the core states the determined genre
- **AND** instructs loading that genre's facet before drafting

#### Scenario: Writing a document in a genre with no facet

- **WHEN** the core determines a genre for which no facet exists
- **THEN** the core states that no facet exists for that genre
- **AND** proceeds with genre-independent discipline alone
- **AND** does not silently apply correspondence conventions

##### Example: Load path determinism

| Step | Mechanism | Deterministic |
| ---- | --------- | ------------- |
| core is invoked | semantic trigger on the core's description | no |
| facet is loaded | instruction in the core's bootstrap phase | yes |

### Requirement: Facet declares inheritance and adds only increments

A genre facet SHALL state in its header that it inherits the core and that the core must be loaded. A facet SHALL NOT restate the core's genre-independent content. A facet MAY override the core's general conventions and MUST NOT override the core's honesty boundaries; the facet SHALL express this precedence using the same wording as the rules contract's composition section.

#### Scenario: Reading a facet in isolation

- **WHEN** a facet file is read on its own
- **THEN** its header states that the core is required
- **AND** states the override precedence

#### Scenario: Facet would contradict a core honesty boundary

- **WHEN** a facet convention would relax a claim boundary the core marks as a limit
- **THEN** the core's boundary applies

#### Scenario: Facet content duplicates core content

- **WHEN** a facet is reviewed for duplication
- **THEN** it contains no restatement of the core's referent discipline or fabrication traps

### Requirement: Section allocation between core and facet

The core SHALL retain the sections that do not vary with genre: the referent discipline, the fabrication traps, the compose-versus-revise distinction, bootstrap, rules resolution and its load gate, understanding the writer, simulation, presenting and iterating, learning from edits, persistence, and the calibration entry. A correspondence facet SHALL receive the sections specific to correspondence: understanding the recipient, opening priority, address conventions, cultural calibration, pressure calibration, recipient ordering, and draft output format.

#### Scenario: Core is inspected for correspondence-specific content

- **WHEN** the core is searched for greeting conventions, pressure calibration, or recipient ordering
- **THEN** no such content is found

#### Scenario: Another genre uses the core

- **WHEN** the core is used for a genre other than correspondence
- **THEN** the genre-independent discipline applies
- **AND** no correspondence convention is inherited

### Requirement: Anti-pattern checklist splits row by row

The anti-pattern checklist SHALL be divided per row, not moved as a block. Rows describing generated-text tells that hold for any genre SHALL remain in the core. Rows bound to correspondence or to draft presentation SHALL move to the correspondence facet. Every row present before the split SHALL appear in exactly one of the two files.

#### Scenario: Counting rows after the split

- **WHEN** the rows in the core and the facet are counted together
- **THEN** the total equals the number of rows before the split
- **AND** no row appears in both files

#### Scenario: A genre without a facet drafts a document

- **WHEN** a genre with no facet is drafted using the core alone
- **THEN** the genre-independent anti-pattern rows still apply

### Requirement: Published contract names sections rather than phase numbers

The published calibration contract SHALL identify the skill sections that do not apply to its mode by section name rather than by phase number, so the mapping survives reordering. Every section named in the contract SHALL exist in the core.

#### Scenario: Skill sections are reordered

- **WHEN** the core's sections are renumbered or reordered
- **THEN** the published contract's mapping remains correct without edits

#### Scenario: Contract is checked against the core

- **WHEN** each section named in the contract's mapping is looked up in the core
- **THEN** every one is found
