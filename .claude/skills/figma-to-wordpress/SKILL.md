---
name: figma-to-wordpress
description: >-
  Mariart's house method for turning a Figma design into a WordPress site. Use
  this for any Figma → WordPress build — e.g. "implement this Figma design in
  WordPress", "build the site from Figma", "import this design into the theme",
  "turn this Figma page into a template" — and whenever the company
  wordpress-development skill points at the figma-to-wordpress workflow. Reads
  structure.md to learn how the site, its pages and its templates should be
  structured, pulls the design through the Figma MCP tools, and builds to that
  structure. Asks rather than inventing when a rule is not defined.
---

# Figma → WordPress (house method)

This is the **local** skill that fills the `figma-to-wordpress` reference in the company
`wordpress-development` skill. It owns the *process*; the *structure rules* live in
[structure.md](structure.md) beside this file, so the conventions can change without
touching the workflow.

Load alongside it:

- **`coding`** and **`wordpress-development`** (company) — the standards that always apply.
- **`verbatim-transfer`** (company) — a design → code build **is** a transfer; the audit at
  the end is not optional.
- **`figma:figma-design-to-code`** (Figma plugin) — invoke it before calling
  `get_design_context`; it owns the mechanics of reading from Figma. **Do not** duplicate
  or override what it says about parameters and asset handling.

> **Scope:** design → code only. To push code *into* Figma, use the Figma plugin's
> `figma-generate-design` skill instead.

## The rule that matters most

**`structure.md` decides how the site is structured. This skill never guesses.**

If the design contains something `structure.md` doesn't cover — a page type with no
mapping, a section that could be a template or a pattern, content that could be hardcoded
or editable — **stop and ask.** Then offer to write the answer back into `structure.md` so
the decision is only made once.

Never invent a structural convention to keep moving. A wrong guess costs a rebuild.

## Workflow

### 1. Read the structure rules first

Read [structure.md](structure.md) **before** looking at the design. It tells you what
you're building into (theme or companion plugin), how Figma frames map to pages and
templates, where content lives, and how navigation and forms are handled.

If the project has its own `figma-structure.md` at its root, that **overrides**
`structure.md` for this project. Read both; the project file wins where they overlap.

### 2. Pull the design context

Invoke `figma:figma-design-to-code`, then call `get_design_context` on the target node.
Follow that skill for all parameter and asset mechanics.

**Then verify nothing was silently dropped.** A page-level call can exceed the response
limit and return truncated code — the tail is cut mid-element and whole sections can
vanish without an error.

- Call `get_metadata` on the same node to get the authoritative list of child sections.
- Compare it against the sections you actually received.
- Fetch any missing or truncated section with its **own** `get_design_context` call.

Do this every time on a full page. Treating a truncated response as complete silently
loses content and the audit in step 6 will fail.

Also call `get_variable_defs` on the node — the design tokens are what the theme's
`theme.json` should be built from, not values eyeballed from the screenshot.

### 3. Agree the structure before building

Map the design onto `structure.md` and state the plan back: which frames become pages,
which become templates, which become patterns, and what each is called. Get agreement
**before** writing files.

For a multi-page import, do this once for the whole site rather than per page — the
template set is a whole-site decision.

### 4. Build to the structure

Follow the standards in `coding` and `wordpress-development`, and the mapping in
`structure.md`. Beyond those:

- Build `theme.json` from the Figma **variables**, not from literal values in the markup.
- Bundle fonts locally (`woff2` in the theme) rather than hotlinking Google Fonts —
  clients are often in the EU.
- **Download every Figma asset into the theme.** The MCP asset URLs expire after ~7 days,
  so a committed reference to one is a broken image later. Note that some tooling is
  blocked by Figma's CDN — if a fetch returns empty, retry with `curl`.
- Never hand-draw an icon. If Figma reports an asset as `unknown` it cannot be exported —
  flag it and ask for the file rather than substituting something that looks close.

### 5. Verify it renders

Load the site and check each section at desktop and mobile, and check the console. If the
site can't be reached, say so plainly rather than reporting the build as verified — and
don't run the WordPress installer or create an admin account yourself.

### 6. Audit against the design

Run the `verbatim-transfer` audit: walk the design section by section and confirm every
heading, paragraph, label, button, nav item and list entry appears in the build.

Source placeholders stay placeholders — a button labelled "Button" stays "Button", lorem
ipsum stays lorem ipsum, and an empty frame stays empty. Never fill a gap in the design
with invented copy; list the gaps instead.

Report what the audit covered and anything deliberately not carried across.

### 7. Report the gaps

Finish with what the design could not supply and what still needs a decision — missing
assets, missing copy, unwired forms, and any alt text you wrote (the design rarely has
any, and yours is a guess about a photo you cannot see).
