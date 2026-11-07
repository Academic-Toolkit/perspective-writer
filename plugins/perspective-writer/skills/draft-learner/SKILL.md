---
name: draft-learner
description: >
  Auto-learn from user edits to draft files. When a system-reminder shows a draft was modified,
  diff the changes, extract concrete rules, and persist them to the right rules location. Trigger when you
  detect a file modification system-reminder on a file you recently wrote or edited.
argument-hint: (auto-triggered from file modification)
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/plugin-rules.sh *), Read, Edit, Write, Grep, Glob, TaskCreate, TaskUpdate, TaskList
---

# Draft Learner

You have been triggered because a file you recently wrote or edited in this conversation was modified by the user. Your job is to learn from their edits and persist those preferences as reusable rules.

## Step 0: Bootstrap Stage Task List（強制）

**在動任何事之前**先用 `TaskCreate` 為這個 stage 建 todo list：

```
TaskCreate(name="step1_detect_and_diff",     description="Step 1: 讀修改後的檔案，對照原版，把每個改動分類")
TaskCreate(name="step2_extract_rules",       description="Step 2: 把每個改動轉成具體、可重用的 rule（一改動一 rule）")
TaskCreate(name="step3_locate_rules_file",   description="Step 3: 依 Split criterion by reader 決定去向；本 plugin 讀的走 persist，其餘留 injected rules 目錄")
TaskCreate(name="step4_update_rules",        description="Step 4: Edit 現有檔案（不覆寫、不重複、矛盾就取代）或 Write 新檔")
TaskCreate(name="step5_confirm_with_user",   description="Step 5: 給 user 簡短摘要說學到什麼、存到哪")
```

完成每一步立即 `TaskUpdate → completed`。**靜默完成 = 違規**。

**為什麼強制**：draft-learner 最大風險是 step 2 偷懶寫出「be more formal」這種沒用的模糊 rule 就交差。TaskList 讓 step 2 的「extract_rules」必須被看到完成，不能靜默跳過。

---

## Step 1: Detect and Diff

1. Read the modified file using the `Read` tool (the path comes from the system-reminder or conversation context).
2. Compare it against the original version you wrote — use the conversation history to recall exactly what you produced.
3. Categorize every change into one or more of these types:

| Category | Examples |
|----------|----------|
| **Tone shift** | Formality level, honorifics (你→您), pronoun changes, register |
| **Content cut** | Removed sentences, paragraphs, compliments, filler |
| **Content add** | Added greetings, closings, disclaimers, details |
| **Structure change** | Merged/split paragraphs, reordered sections, changed formatting |
| **Wording swap** | Specific word or phrase replacements (e.g., "希望"→"期盼") |

## Step 2: Extract Concrete Rules

Turn each change into a **concrete, reusable rule**. Specificity is critical.

### BAD (too vague — never write rules like these):
- "be more formal"
- "shorter emails"
- "adjust tone"

### GOOD (specific and actionable):
- "用「您」不是「你」when writing to professors or seniors"
- "刪掉評價對方研究設計的句子 — 只描述自己的需求"
- "結尾固定加「祝 研安」for academic correspondence"
- "每段不超過3句，避免長段落"
- "不用驚嘆號，句號結尾即可"
- "Use bullet points instead of prose for listing action items"

### Inferring WHY
If the reason behind a change is inferable, include it parenthetically:
- "不稱呼「親愛的」（對資深學者太隨意）"
- "Remove self-deprecating phrases like '不好意思打擾'（user prefers direct tone）"

**One rule per change.** Do not merge multiple distinct edits into a single vague rule.

## Step 3: Find or Create Rules File

Where a rule goes depends on **who reads it** — see the *Split criterion by reader*
section of [`references/rules-resolution.md`](../../references/rules-resolution.md).
A rule this plugin reads goes through the **persist** operation. A rule no skill
reads stays in the injected project rules directory, because injection is its only
delivery mechanism.

### Routing by draft type:
| Draft type | Read by a skill in this plugin | Where it goes |
|------------|:---:|---------------|
| Correspondence to a person | yes | **persist** — subject's core or facet |
| Reports / documents | yes | **persist** — genre convention, or the subject's facet if party-specific |
| Code comments / docs | no | `.claude/rules/code-writing-style.md` (unchanged) |
| General writing | no | `.claude/rules/writing-style.md` (unchanged) |

**Do not move the bottom two rows into the plugin namespace.** No skill here reads
them; they work by being injected into general session context. Moving them removes
their only reader — silently, with no error and no attributable change in output.
When you are unsure which side a new rule category falls on, leave it in the
injected directory: that failure mode is the visible one.

For the top two rows, do not assemble a path. Name the **persist** operation and
cite the contract's *Named resolution contract* and *Storage layout* sections.
A rule that holds across genres for that subject belongs in the subject's core;
a rule specific to this draft's genre belongs in that genre's facet.

### Read the target's existing rules expanded

Before adding a rule, read what the target file already says, expanded: run

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/plugin-rules.sh" expand <file> 2><disclosures-file>
```

on it and read its stdout (*Resolution order* in the contract). A workspace file that is mostly a
`pw:include` line shows only that comment when read raw, so a rule the included plugin already states, or
contradicts, would go unnoticed. Compare the new rule with the expansion; tell the user every
`pw:disclosure` line. Write into the raw workspace file, as the next section says. A target that does not
exist yet has no rules to compare: skip the expansion (`expand` exits 2 on a missing file).

### Persist writes only workspace files

The contract's *Named resolution contract* and *Composition precedence* sections set
three limits on where the rule is written:

1. **Only files in this workspace's rules namespace.** Never edit a file inside
   another plugin, even when the rule the user corrected came from one (it appears
   between `pw:source` markers in the expanded text). The correction goes into the
   workspace file and overrides the plugin's rule from there.
2. **After any include line.** When the target file contains a
   `<!-- pw:include plugin:... -->` line, write the new rule after it, so the new
   rule takes precedence over the included rules. Leave the include line unchanged.
3. **An imported copy may be edited directly.** A file whose first line is
   `<!-- pw:imported ... -->` is the workspace's own copy; add the rule to it and keep
   that header as the first line.

### If the file exists:
1. **Read it first** using the `Read` tool, to edit it. Judge duplicates and contradictions against the
   expansion from *Read the target's existing rules expanded* above, not against this raw text.
2. Proceed to Step 4 (update).

### If the file does NOT exist:
1. Ask the user: "我偵測到你對草稿做了修改。要不要把這些偏好記下來？"（一併說出 routing 決定的目標位置）
2. If the user agrees, create it with a header and the extracted rules.
3. If the user declines, still show the summary (Step 5) but do not persist.

## Step 4: Update Rules File

When updating an existing rules file:

1. **Do not duplicate.** If a rule already exists that covers the same point, skip it.
2. **Replace contradictions.** If a new rule contradicts an existing one, replace the old rule with the new one. Add a comment like `<!-- updated YYYY-MM-DD -->` next to the replacement.
3. **Organize by section.** Keep rules grouped under relevant headings (e.g., `## Tone`, `## Structure`, `## Vocabulary`, `## Opening/Closing`). Create new sections as needed.
4. **Append new rules** at the end of the appropriate section.

Use the `Edit` tool for surgical updates. Only use `Write` if creating a new file.

## Step 5: Confirm with User

After updating (or deciding not to), show a short summary:

```
從你的修改我學到了：
1. [concrete change 1]
2. [concrete change 2]
3. [concrete change 3]

已更新 [實際寫入的路徑]，你隨時可以打開修改。
```

If the user declined to create a rules file:
```
從你的修改我觀察到：
1. [concrete change 1]
2. [concrete change 2]

如果之後想儲存這些偏好，跟我說一聲就好。
```

## Important Guardrails

- **Always trigger on draft edits.** User edits to your drafts are the highest-signal feedback. Do not skip or ignore them.
- **Only trigger on YOUR drafts.** Only activate when the modified file is one you wrote or edited in the current conversation. Do not trigger on files the user is editing independently.
- **Stay concrete.** Every rule must be specific enough that a different AI session could follow it without ambiguity.
- **One rule per change.** Never merge multiple distinct edits into one vague rule.
- **Respect existing rules files.** Always read before writing. Never overwrite the entire file.
- **Language matching.** Write rules in the same language as the draft. If the draft is in Chinese, rules should be in Chinese. If mixed, match the dominant language.
