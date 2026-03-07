# File review: `wiki/vm-hardening.md`

- **Date:** 2026-03-07
- **Convention files used:**
  - `instructors/context/conventions/common.md` (4.1–4.26)
  - `instructors/context/conventions/wiki.md` (Sections 1–3)

---

## Conceptual findings

Not applicable (wiki file, not a task file).

---

## Convention findings

### 4.1. Instructions wording

No issues found.

### 4.2. Terminal commands

No issues found. All terminal commands use the "To…" intention pattern with a `[run in the VS Code Terminal]` link.

### 4.3. Command Palette commands

Not applicable.

### 4.4. Options vs steps

No issues found.

### 4.5. Ordered lists

No issues found.

### 4.6. Mini-ToC

No issues found.

### 4.7. Table of contents

No issues found. Uses `<h2>Table of contents</h2>` and entries match headings.

### 4.8. Links and cross-references

1. ~~**Line 120:** `SSH` is mentioned for the first time in the "Configure `fail2ban`" section ("it rate-limits repeated `SSH` connection attempts") but is not linked to `./ssh.md#what-is-ssh`. Per convention, link on first mention per section.~~

### 4.9. Notes, tips, warnings

1. ~~**Lines 91–92:** The `> [!IMPORTANT]` alert is indented inside a list item (step 2). Convention 4.9 states: "Do not indent alerts. GitHub-flavored Markdown alerts do not render correctly when indented (e.g., inside a list item)." Move the alert outside the list or use bold text (e.g., **Important:**) as a fallback.~~

### 4.10. Images

Not applicable.

### 4.11. Collapsible hints and solutions

Not applicable.

### 4.12. Commit message format

Not applicable.

### 4.13. Diagrams

Not applicable.

### 4.14. `<!-- TODO -->` comments

Not applicable (none present).

### 4.15. `<!-- no toc -->` comments

Not applicable.

### 4.16. Code snippets in explanations

Not applicable.

### 4.17. Heading levels in section titles

Not applicable.

### 4.18. Inline formatting of technical terms

1. ~~**Line 79:** `Uncomplicated Firewall` is wrapped in backticks (`` `Uncomplicated Firewall` ``). It is not a tool, language, format, or protocol name — it is the plain-English expansion of the acronym. Remove backticks: `ufw` (Uncomplicated Firewall).~~

### 4.19. Steps with sub-steps

No issues found.

### 4.20. Placeholders in docs

1. ~~**Line 40:** `<username>` placeholder is used without a "Replace" instruction. Convention requires either a linked replacement note or an inline explanation (e.g., "Replace `<username>` with your chosen username."). The same placeholder reappears on lines 48, 56–60, 68, 219 without prior explanation.~~

### 4.21. `docker compose up` commands

Not applicable.

### 4.22. Environment variable references

Not applicable.

### 4.23. Horizontal rules

No issues found.

### 4.24. Inline paths

No issues found.

### 4.25. Branch-on-remote references

Not applicable.

### 4.26. Example IP address

Not applicable (the file uses `<your-vm-ip-address>` placeholder, not a hardcoded IP).

### Wiki 1.3. Structure of a wiki file

1. ~~**Line 21:** `## Hardening steps` section has no content between the heading and the first subsection `### Create a non-root user` (line 23). Convention 1.3 expects sections to have explanation and/or instructions, not just subsections. Consider adding a brief introductory sentence.~~

### Wiki 1.4. Key rules

No issues found.

---

## TODOs

No TODOs found.

---

## Empty sections

1. ~~**Line 21:** `## Hardening steps` — heading is followed only by a blank line and then another heading (`### Create a non-root user` on line 23), with no content in between.~~

---

## Summary

| Category | Count |
|---|---|
| Convention violations | 5 |
| TODOs | 0 |
| Empty sections | 1 |
| **Total** | **6** |

Overall: The file is well-structured and follows most conventions consistently. The main issues are: an indented alert inside a list item (4.9), a missing first-mention link for `SSH` in the `fail2ban` section (4.8), an incorrectly backticked plain-English phrase (4.18), a missing placeholder replacement instruction for `<username>` (4.20), and an empty parent section (Wiki 1.3).
