# File review — `wiki/vm-non-root.md`

- **File reviewed:** [`wiki/vm-non-root.md`](../../../wiki/vm-non-root.md)
- **Date:** 2026-03-15
- **Convention files used:**
  - `contributing/conventions/writing/common.md` (4.1–4.29)
  - `contributing/conventions/writing/wiki.md` (sections 1–3)

---

## Convention findings

### 4.1. Instructions wording

1. **[Low] Line 174** — "Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`)." — Compound instruction: "save" and "exit" are two distinct actions joined with "and". Convention: never write "Do A and do B" — split into two steps.

2. **[Low] Line 184** — "Find the `se-toolkit-vm` entry and change `User root` to `User <user>`." — Compound instruction: "find … and change …" joins two actions. Split into two steps: one to locate the entry, one to update the value.

### 4.8. Links and cross-references

1. **[Medium] Line 82** — "To copy the authorized keys from the user `root`," — First mention of the user `root` in section [Set up the `SSH` key authentication for the user `<user>` (REMOTE)](../../../wiki/vm-non-root.md#set-up-the-ssh-key-authentication-for-the-user-user-remote), but it is not linked. Per 4.8 and 4.29, link on first mention: `` [the user `root`](./linux.md#the-root-user) ``.

2. **[Low] Line 143** — `<user>` is linked again in the "Replace the placeholders:" list, but it was already linked in the Note at line 129 in the same section ([Connect to your VM by `SSH` as the user `<user>` (LOCAL)](../../../wiki/vm-non-root.md#connect-to-your-vm-by-ssh-as-the-user-user-local)). Convention: don't link on second mention. Use plain `` `<user>` ``.

3. **[Low] Line 184** — `<user>` is linked again in "Replace the placeholder `<user>`…", but it was already linked in the Note at line 179 in the same section ([Update the local `SSH` config (LOCAL)](../../../wiki/vm-non-root.md#update-the-local-ssh-config-local)). Convention: don't link on second mention. Use plain `` `<user>` ``.

### 4.24. Inline paths

1. **[Low] Line 74** — "To create the `.ssh` directory" — `.ssh` is a directory; convention requires a trailing `/`: `` `.ssh/` ``.

2. **[Low] Line 90** — "To set the correct ownership on the `.ssh` directory" — Same; use `` `.ssh/` ``.

3. **[Low] Line 102** — "To set the correct permissions on the `.ssh` directory" — Same; use `` `.ssh/` ``.

### 4.29. Referring to users of a machine

1. **[Medium] Line 16** — "to prevent direct `root` login" — Refers to the root user but does not use the required "the user `<username>`" pattern and is not linked. Suggested fix: rephrase to "to prevent login as the user `root`" and link `root` to `./linux.md#the-root-user`.

2. **[Medium] Line 53** — "To create a new user `<user>`," — Uses "a new user" instead of the required "the user" pattern. Fix: "To create the user `<user>`,"

3. **[Medium] Line 239** — "Confirm you are logged in as `<user>`, not `root`." — Neither `<user>` nor `root` follows the "the user `<username>`" pattern, and `root` is not linked. Fix: "Confirm you are logged in as the user `<user>`, not the user `root`." and link `root` to `./linux.md#the-root-user`.

### wiki.md — 1.3 / 1.4. About section structure

1. **[Low] Lines 22–34** — The [About setting up login as a non-root user](../../../wiki/vm-non-root.md#about-setting-up-login-as-a-non-root-user) section contains a `> [!NOTE]` block (lines 22–23) and a "Complete these steps:" mini-ToC (lines 25–34) beyond the 1–3 sentence definition + `Docs:` structure defined in wiki template 1.3. Consider moving the placeholder note and the steps list to immediately after the About section.

---

## TODOs

1. **Line 114** — `<!-- TODO why these permissions are correct? -->` (inside step 4 of [Set up the `SSH` key authentication…](../../../wiki/vm-non-root.md#set-up-the-ssh-key-authentication-for-the-user-user-remote))
2. **Line 124** — `<!-- TODO why these permissions are correct? -->` (inside step 5 of the same section)
3. **Line 150** — `<!-- TODO check there's this file at all with this content -->` (inside [Harden the `SSH` config (REMOTE)](../../../wiki/vm-non-root.md#harden-the-ssh-config-remote))

---

## Empty sections

No empty sections found.

---

## Summary

| Category | Count |
|---|---|
| Convention [High] | 0 |
| Convention [Medium] | 4 |
| Convention [Low] | 8 |
| TODOs | 3 |
| Empty sections | 0 |
| **Total** | **15** |

**Overall:** The file is well-structured and largely follows conventions — all terminal commands use the "To…" intention pattern with the required `VS Code Terminal` link, ordered lists are sequential, and GFM alerts are correctly placed or fallen back to blockquote style inside list items. The four medium-severity violations all relate to the "the user `<username>`" prose pattern (4.29): one unlinked first mention of `root` (line 82), two uses of the wrong prefix ("a new user" at line 53, bare backtick references at line 239), and one bare `root` reference in the About sentence (line 16). The eight low-severity issues cover repeated links on second mention (4.8 — lines 143, 184), missing trailing slashes on `.ssh` directory references (4.24 — lines 74, 90, 102), two compound instructions (4.1 — lines 174, 184), and extra content in the About section beyond the template (wiki 1.3). Three TODO comments flag unresolved content gaps (permission rationale ×2 and SSH config verification).
