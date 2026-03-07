# Review: `lab/tasks/required/task-1.md`

- **Date:** 2026-03-07
- **Convention files used:**
  - `instructors/context/conventions/tasks.md` — task structure, design principles, conceptual review dimensions (D1–D12)
  - `instructors/context/conventions/common.md` — writing conventions (4.1–4.26)

---

## Conceptual findings

### D1. Learning objective clarity

No issues found.

### D2. Step-by-step completeness

1. **[Medium]** Line 206 — "Start the `Qwen code` coding agent in the terminal inside the project directory." No instructions on how to start the agent, no link to a wiki page or setup guide. A student unfamiliar with Qwen code would not know what command to run or how to install/configure it.

   **Suggested fix:** Add a link to a wiki page explaining how to start Qwen code (e.g., `[Start the `Qwen code` coding agent](../../../wiki/qwen-code.md#start-the-agent)`), or inline the startup command.

### D3. Student navigation

1. **[High]** Lines 1–15 — Missing `<h4>Diagram</h4>` section between Context and Table of contents. The task involves actions across multiple actors and environments (local machine, VM, GitHub, Autochecker API). A Mermaid sequence diagram is required by the task template convention (Section 1.1) to show the overall task flow before students begin the steps.

   **Suggested fix:** Add a `<h4>Diagram</h4>` section with a Mermaid `sequenceDiagram` showing the flow: Developer explores API locally (Part A), implements pipeline locally, tests via Swagger, pushes to GitHub, pulls and tests on VM, creates PR.

### D4. Checkpoints and feedback loops

No issues found.

### D5. Acceptance criteria alignment

No issues found.

### D6. Difficulty and progression

No issues found.

### D7. Practical usability

1. **[Medium]** Line 206 — "Start the `Qwen code` coding agent" assumes the student has the agent installed and knows how to start it. No installation prerequisites, no link to documentation. A student on a fresh setup would be blocked at this step.

   **Suggested fix:** Either link to a wiki page with setup instructions or add a prerequisite note referencing where Qwen code is installed/configured (e.g., in `setup.md`).

### D8. LLM-independence

1. **[High]** Lines 206–211 — Step 1.4.2 requires using the `Qwen code` AI agent to implement the pipeline but does not provide a non-AI alternative path. Convention 4.16 (LLM-independence) requires tasks to be completable without LLMs unless the task explicitly states that students must use an AI. The step is not labeled as AI-required, and no fallback path exists for students who don't use the agent.

   **Suggested fix:** Either (a) provide an explicit non-AI path (e.g., "Implement the five functions by following the TODO comments in `etl.py` — use the existing models in `backend/app/models/` as reference"), or (b) clearly label the step as AI-required per convention 4.16 ("When a task explicitly requires AI use, mark it as a separate, clearly labeled part").

### D9. Git workflow coherence

No issues found.

### D10. Conceptual gaps and misconceptions

1. **[Low]** Line 74 — "The API has HTTP Basic Auth" is stated without explanation or a link to learn more. Students unfamiliar with HTTP Basic Auth may not understand what this means or how the `-u` flag in `curl` relates to it.

   **Suggested fix:** Add a brief inline explanation or a `> [!NOTE]` block explaining that HTTP Basic Auth sends credentials as `username:password` and that `curl -u` provides these credentials.

### D11. Controlled AI steps

1. **[Medium]** Lines 206–221 — The AI prompt is provided (line 209) and there is a review checklist (lines 215–221), but the task does not require AI curation annotations (`KEPT`/`FIXED`/`DISCARDED`) per convention 4.24. Students are asked to "review" the generated code but have no structured way to demonstrate critical evaluation of the AI output.

   **Suggested fix:** If AI-generated code curation is a learning objective, add the three annotation labels requirement and require at least one `DISCARDED` item. If not, consider adding a concrete checkpoint for the review step (e.g., "Confirm the code matches all six checklist items before proceeding").

2. **[Low]** Lines 206–221 — The step lacks a concrete verification checkpoint after the AI generates code. The review checklist (lines 215–221) tells students what to look for but does not provide a pass/fail check to confirm the implementation is correct before proceeding to run it.

   **Suggested fix:** Add a checkpoint such as: "After reviewing, confirm the code passes a quick syntax check or imports without errors."

### D12. Autochecker verifiability

No issues found.

---

## Convention findings

### Section 1. Task document template

1. **Lines 1–15:** Missing `<h4>Diagram</h4>` section. The task template (Section 1.1) requires a Mermaid sequence diagram when the task involves actions across multiple actors or environments. This task spans local machine, VM, GitHub, and the Autochecker API.

2. **Lines 42–63:** Step 1.2 combines issue creation (lines 44–48) and branch creation (lines 50–58) with an explanatory note (lines 60–63). The task template shows step 1.2 as only issue creation (`Title: [Task] <Task title>`). Branch creation is part of the Git workflow referenced in step 1.1.

3. **Lines 44–48:** Issue title is presented in a fenced code block without a language specifier. The task template uses inline code format: `Title: [Task] <Task title>`. If a code block is preferred, it should use `text` for consistency with the commit message format (convention 4.12).

4. **Lines 366–380:** "Finish the task" step inlines all PR creation instructions (7 numbered steps) instead of linking to the git-workflow wiki sections as specified in the template. Expected format:
   ```
   1. [Create a PR](../../../wiki/git-workflow.md#create-a-pr) with your changes.
   2. [Get a PR review](../../../wiki/git-workflow.md#get-a-pr-review) and complete the subsequent steps in the `Git workflow`.
   ```

### 4.1. Instructions wording

No issues found.

### 4.2. Terminal commands

No issues found.

### 4.3. Command Palette commands

Not applicable.

### 4.4. Options vs steps

Not applicable.

### 4.5. Ordered lists

No issues found.

### 4.6. Mini-ToC

No issues found.

### 4.7. Table of contents

No issues found.

### 4.8. Links and cross-references

1. **Lines 349–350:** `<task-branch>` placeholder is used in section 1.4.7 without being linked to its wiki definition in this section. It was first linked in section 1.4.6 (line 337), but convention 4.8 requires linking a concept the first time it is mentioned in a section.

### 4.9. Notes, tips, warnings

No issues found.

### 4.10. Images

Not applicable.

### 4.11. Collapsible hints and solutions

No issues found.

### 4.12. Commit message format

No issues found.

### 4.13. Diagrams

1. **Lines 1–15:** No diagram present. See Section 1 finding #1 above.

### 4.14. `<!-- TODO -->` comments

Not applicable.

### 4.15. `<!-- no toc -->` comments

No issues found.

### 4.16. Code snippets in explanations

Not applicable.

### 4.17. Heading levels in section titles

Not applicable.

### 4.18. Inline formatting of technical terms

1. **Lines 13, 72, 88, 258, 264:** Inconsistent capitalization of "Autochecker" / "autochecker" throughout the document. Line 13 uses "Autochecker API" (capitalized), while lines 72, 88, 258, 264 use "autochecker" (lowercase). Pick one form and use it consistently.

### 4.19. Steps with sub-steps

No issues found.

### 4.20. Placeholders in docs

1. **Lines 341–351:** `<task-branch>` placeholder appears in the terminal block of section 1.4.7 (lines 349–350) without a "Replace" instruction. Section 1.4.6 (line 337) properly includes `Replace [<task-branch>](../../../wiki/git-workflow.md#task-branch).` but section 1.4.7 does not.

### 4.21. `docker compose up` commands

No issues found.

### 4.22. Environment variable references

1. **Lines 264–265:** `AUTOCHECKER_EMAIL` and `AUTOCHECKER_PASSWORD` are referenced in prose (inside the troubleshooting block) without links to their wiki sections. Convention 4.22 requires linking environment variables to their wiki definitions.

2. **Line 280:** `AUTOCHECKER_API_URL` is referenced in prose without a link to its wiki section.

3. **Lines 357–358:** First mention of `CADDY_HOST_PORT` in section 1.4.7 lacks the `.env.docker.secret` file link. Convention 4.22 requires linking the file name to indicate the source, and per convention 4.8 the file link must appear at least once per section.

4. **Line 360:** `API_KEY` is linked to its wiki section but `.env.docker.secret` file link is missing in section 1.4.7 (no file link appears anywhere in this section's prose).

### 4.23. Horizontal rules

No issues found.

### 4.24. Inline paths

No issues found.

### 4.25. Branch-on-remote references

Not applicable.

### 4.26. Example IP address

Not applicable.

---

## TODOs

No `<!-- TODO ... -->` comments found.

---

## Empty sections

No empty sections found.

---

## Summary

| Category                | Count |
| ----------------------- | ----- |
| Conceptual — High       | 2     |
| Conceptual — Medium     | 3     |
| Conceptual — Low        | 2     |
| Convention violations   | 11    |
| TODOs                   | 0     |
| Empty sections          | 0     |
| **Total**               | **18** |

**Overall assessment:** The task is well-structured with clear steps, good checkpoints, proper troubleshooting blocks, and well-aligned acceptance criteria. The two high-severity issues are the missing Mermaid sequence diagram (required for multi-actor/multi-environment tasks) and the LLM-independence violation (step 1.4.2 requires an AI agent without providing a non-AI alternative or labeling the step as AI-required). The convention violations are mostly about environment variable linking and the "Finish the task" step deviating from the template by inlining PR instructions instead of linking to the wiki.
