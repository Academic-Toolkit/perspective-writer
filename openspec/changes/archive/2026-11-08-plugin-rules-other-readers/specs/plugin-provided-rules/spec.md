## ADDED Requirements

### Requirement: A plugin's published rule files are not reserved for this plugin

The resolution contract SHALL state that a file a plugin publishes under `perspective-writer/` may also be read directly by that plugin's own skills, so that one copy serves both readers. It SHALL state that perspective-writer expands nothing and discloses nothing for those other readers, that `plugin-rules.sh` is not an interface for other plugins, and that a file meant for both kinds of reader contains no include line.

#### Scenario: A plugin's own skill reads its published genre file

- **WHEN** a plugin publishes `perspective-writer/genres/<slug>.md` and one of its own skills reads that file directly
- **THEN** the contract permits it, and the plugin keeps no second copy for its own skills

#### Scenario: A shared file contains an include line

- **WHEN** a maintainer reads the contract to decide whether a file read by both the plugin's skills and perspective-writer may contain an include line
- **THEN** the contract states that such a file contains no include line, because a direct reader sees the line as a comment and perspective-writer does not expand an include line inside an included file

#### Scenario: Another plugin's skill wants expanded rules

- **WHEN** a maintainer reads the contract to learn whether another plugin's skill may call `plugin-rules.sh expand`
- **THEN** the contract says the script is not an interface for other plugins and perspective-writer makes no disclosure on their behalf
