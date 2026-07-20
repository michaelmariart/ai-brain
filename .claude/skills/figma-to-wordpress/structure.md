# Import structure rules

**This file decides how a Figma design becomes a WordPress site.** The skill reads it and
follows it. Edit it freely — it is the point of the skill.

Each rule is marked:

- **`[SET]`** — decided. Follow it.
- **`[ASK]`** — not decided yet. The skill must **stop and ask**, then offer to write the
  answer back here as `[SET]`.

A project can override any of this with its own `figma-structure.md` at the project root.
The project file wins where the two overlap.

> The `[SET]` rules below were derived from the Dama Charter build (July 2026) and are
> **provisional** — they are what was actually done once, not a considered house standard.
> Correct them.

---

## 1. What gets built

**`[SET]` Output target — a stand-alone block theme**, at
`wp-content/themes/<project-slug>/`, unless the site already runs the Mariart plugin.

**`[ASK]` When does a site get a Mariart companion plugin instead of / as well as a theme?**
Zoom Car Wash and Poco Posy put site functionality in a companion plugin
(`Mariart\Plugin\<Name>`). Dama Charter did not, because it was a bare install and the job
was a design import. The dividing line is not defined — ask which applies.

**`[SET]` Presentation lives in the theme.** Even where a companion plugin exists, the
Figma import produces theme markup and styles, not plugin output.

---

## 2. Figma → WordPress mapping

**`[SET]` One Figma top-level frame = one WordPress page.** The frame name is the page
title; its slug is the kebab-case of that name. `Home • Desktop` → front page.

**`[SET]` One Figma section instance = one block pattern**, in `patterns/<section>.php`,
registered under the `<project-slug>` pattern category with `Inserter: no`.

**`[SET]` Pages are assembled by templates, not by pasted markup.** A template composes
patterns via `<!-- wp:pattern {"slug":"…"} /-->` — never duplicate section markup between
templates.

**`[SET]` Header and footer are template parts** (`parts/header.html`, `parts/footer.html`),
each of which just references its pattern.

**`[ASK]` Responsive variants.** Figma files carry `• Desktop` / `• Mobile` frames of the
same page. Dama Charter only had Desktop, so mobile was inferred from the desktop design
mobile-first. Should a Mobile frame, when present, be treated as authoritative and matched
breakpoint-for-breakpoint?

**`[ASK]` Which templates should a site always ship?** Dama Charter has only
`front-page.html` and `index.html`. Is there a standard set — `page`, `single`, `archive`,
`404`, `search` — that every build should include even when the design doesn't show them?

### Naming

**`[SET]` Pattern slug:** `<project-slug>/<section-name>`, section name kebab-cased and
**stripped of the Figma component code** — `Layout / MA02 /` becomes what the section *is*
(`tours`), not `layout-ma-02`. The MA codes are Figma-side component identifiers and mean
nothing in the codebase.

**`[SET]` CSS classes:** BEM-ish, kebab-case, named for the thing not the design system —
`.tour-card__body`, not `.ma02-card-body`.

---

## 3. Where content lives

**`[ASK]` This is the most important undecided rule.**

Dama Charter hardcoded all copy into the patterns, with repeated items (tour cards,
testimonials, FAQs, blog cards) as PHP arrays at the top of each pattern file. That is fast
to build and pixel-exact, but **the client cannot edit any of it** without touching code.

The options, roughly in order of editing freedom:

1. **Hardcoded in patterns** — what Dama Charter did. No client editing.
2. **Editable block content** — patterns emit core blocks so the page can be edited in the
   site editor. Client edits freely; layout can drift from the design.
3. **Custom post types + fields** — repeated items (tours, testimonials, FAQs) become CPTs
   rendered by the pattern. Client edits safely; most build effort.

Ask which applies, per content type — the answer is often different for a hero (1) and a
testimonials list (3).

---

## 4. Navigation

**`[SET]` Nav markup comes from the design**, not from `wp_nav_menu()`, when the design's
navbar has custom structure (dropdowns, a CTA button in the bar).

**`[ASK]` Should the nav be wired to a real WordPress menu** so the client can edit it, and
if so how do the design's dropdowns and button map onto menu items? Dama Charter's nav
links are hardcoded anchors to on-page sections.

---

## 5. Forms

**`[ASK]` The company `wordpress-development` skill names Gravity Forms.** Dama Charter's
enquiry form was built as accessible HTML with no handler, because Gravity Forms was not
installed.

Define: is Gravity Forms always the target? Should the import build the GF form definition
itself, or emit a placeholder and a note for someone to build the form in the GF UI? Where
do submissions go?

---

## 6. Spacing and fidelity

**`[SET]` Build `theme.json` from the Figma variables.** Colour schemes, text sizes, gap
and padding tokens and radii come from `get_variable_defs`, not from values read off the
markup.

**`[SET]` Gap, not margin.** Space between elements is `gap` on the flex/grid parent,
matching how Figma auto-layout expresses it. Avoid margins for layout spacing.

**`[ASK]` How literally should the desktop design be reproduced?** The company skill says
"pixel-faithful". Dama Charter interpreted that as: exact tokens and structure, but fluid
type (`clamp()`) and mobile-first breakpoints rather than the design's fixed 1440px canvas.
Confirm that reading, or define the breakpoints.

**`[ASK]` Editor-experience rules.** The company skill lists these as part of the method but
they were never written down. What should the client see in the site editor — locked
patterns? Restricted blocks? A curated inserter?

---

## 7. Assets

**`[SET]` Download every Figma asset into the theme** at `assets/images/`. MCP asset URLs
expire after about 7 days.

**`[SET]` Bundle fonts locally** as `woff2` under `assets/fonts/`, registered through
`theme.json` `fontFace`. Do not hotlink Google Fonts — clients are often in the EU.

**`[SET]` Never author an icon by hand.** Use the exported asset. If Figma reports an asset
as `unknown` it cannot be exported — flag it and ask for the file.

**`[ASK]` Alt text.** Figma images almost always have empty `alt`. Dama Charter wrote
descriptive alt text and flagged it for review, since accessibility is required. Confirm
that, or define a different handling (leave empty, ask the client, use a caption field).

---

## 8. Worked example — Dama Charter

Homepage, 12 sections, built July 2026. `Home • Desktop` → `templates/front-page.html`,
composing twelve patterns:

| Figma section | Pattern slug | Notes |
|---|---|---|
| `Navbar / MA01 /` | `dama-charter/navbar` | via `parts/header.html` |
| `Hero / MA01 /` | `dama-charter/hero` | carries the page's single `<h1>` |
| `Layout / MA01 /` | `dama-charter/intro` | |
| `Layout / MA02 /` | `dama-charter/tours` | 3 cards from a PHP array |
| `Layout / MA03 /` | `dama-charter/captain` | media-first split |
| `Layout / MA04 /` | `dama-charter/boat` | full-bleed image below |
| `Testimonial / MA01 /` | `dama-charter/testimonials` | 6 reviews, 2 columns |
| `Contact / MA01/` | `dama-charter/contact` | form has no handler |
| `Gallery / MA01 /` | `dama-charter/gallery` | |
| `FAQ / MA01 /` | `dama-charter/faq` | 9 of 10 answers absent from the design |
| `Blog / MA01 /` | `dama-charter/blog` | static cards, not a real query |
| `Footer / MA01 /` | `dama-charter/site-footer` | via `parts/footer.html` |

Two sections — `Blog` and `Footer` — were **silently lost to response truncation** on the
page-level `get_design_context` call and had to be fetched individually. This is why the
skill requires a `get_metadata` cross-check.
