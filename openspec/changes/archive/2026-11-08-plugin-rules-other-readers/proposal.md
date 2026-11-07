## Summary

State in the resolution contract that a rule file a plugin publishes for perspective-writer is not reserved for perspective-writer: the publishing plugin's own skills may read the same file. perspective-writer does not take on general rule sharing.

## Motivation

The plugin-provided-rules change defined where a plugin puts rules for perspective-writer (`<plugin-root>/perspective-writer/genres/`, `subjects/`) and how perspective-writer reads them. It said nothing about other readers. A plugin that also needs the rules in its own skills already reads the same file directly. Because the contract is silent, a later maintainer can read the location as perspective-writer's alone and keep a second copy for the plugin's own skills; the two copies then drift.

## Proposed Solution

Add an **Other readers** paragraph to the contract's section on rules published by other plugins, after the layout and path rules:

- the published file is not reserved for perspective-writer, and the publishing plugin's skills may read it directly, so one copy serves both;
- perspective-writer takes no part in that other reading: it expands nothing for those readers, makes no disclosure on their behalf, and `scripts/plugin-rules.sh` is not an interface for other plugins;
- a reader that opens the file directly sees an include line as a comment, and perspective-writer does not expand an include line inside an included file, so a file meant for both kinds of reader contains no include line.

Add one sentence to the README section on rules from other plugins saying the same.

## Non-Goals

- A cross-plugin sharing mechanism, such as letting other skills call `plugin-rules.sh expand`. Nothing needs it now, and it would make a writing plugin infrastructure for other plugins.
- A mechanical check that shared files contain no include line. The files live in other plugins' repositories, outside this plugin's checks.

## Alternatives Considered

**Let other skills call `plugin-rules.sh expand`.** Rejected: those skills would then depend on perspective-writer's script, its exit codes and its disclosure format, and perspective-writer would have to decide who reports a disclosure raised for another plugin's skill. No plugin needs expansion today; the one known case reads a file with no include line.

**Say nothing.** Rejected: the silence is what invites the second copy.

## Impact

- Affected specs: plugin-provided-rules
- Affected files: `plugins/perspective-writer/references/rules-resolution.md`, `README.md`, the changelog and both version fields
