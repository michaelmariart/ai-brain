# Import structure rules

**This file decides how a Figma design becomes a WordPress site.** The skill reads it and
follows it. Edit it freely — it is the point of the skill.

Each rule is marked:

- **`[SET]`** — decided. Follow it.
- **`[ASK]`** — not decided yet. The skill must **stop and ask**, then offer to write the
  answer back here as `[SET]`.

A project can override any of this with its own `figma-structure.md` at the project root.
The project file wins where the two overlap.

> Most `[SET]` rules below were derived from the Dama Charter build (July 2026) and are
> **provisional** — they are what was actually done once, not a considered house standard.
> Correct them.
>
> **§3 is different.** It is a deliberate ruling from Alison and is not provisional. Where
> anything else in this file conflicts with §3, §3 wins.

---

## 1. What gets built

**`[SET]` Output target — a stand-alone block theme**, at
`wp-content/themes/<project-slug>/`, unless the site already runs the Mariart plugin.

**`[ASK]` When does a site get a Mariart companion plugin instead of / as well as a theme?**
Zoom Car Wash and Poco Posy put site functionality in a companion plugin
(`Mariart\Plugin\<Name>`). Dama Charter did not, because it was a bare install and the job
was a design import. The dividing line is not defined — ask which applies.

*Partly narrowed:* §3 settles that **custom blocks** go in the theme, not a plugin. This
question is now only about other site functionality — post types, integrations, business
logic — not about blocks.

**`[SET]` Presentation lives in the theme.** Even where a companion plugin exists, the
Figma import produces theme markup and styles, not plugin output.

---

## 2. Figma → WordPress mapping

**`[SET]` One Figma top-level frame = one WordPress page.** The frame name is the page
title; its slug is the kebab-case of that name. `Home • Desktop` → front page.

**`[SET]` One Figma section instance = one block pattern**, in `patterns/<section>.php`,
registered under the `<project-slug>` pattern category. The pattern emits **block markup**
(§3) and exists to *seed* real page content — it is never the permanent home of copy. Keep
it in the inserter so a section can be added again later.

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

**`[SET]` Everything imported from Figma must be editable. No content in PHP, ever.**

Decided by Alison, 20 July 2026. This is absolute — it outranks build speed and pixel
convenience, and it applies to every section without exception:

- **No hardcoded content in PHP.** No copy, no arrays of cards, reviews, FAQs or tour
  options, no `esc_html('…')` wrapping a client's words. If a sentence exists only inside
  a `.php` file, the rule is broken.
- **Every content section is block markup**, in the WordPress Full Site Editing format.
- **Core blocks first.** Use a standard WordPress block wherever one fits the section.
- **Build a custom block** only where no core block covers what the design needs.
- **Content and settings for pages, posts and the like live in the database**, not in
  theme files.

### What this means in practice

Registering `patterns/*.php` is **not** enough. A pattern is theme code; it is not content.
The content of record is the database copy, so an import has to actually create the pages
and write block markup into `post_content`.

Patterns stay useful as the *seed* — the thing that stamps a section into a page — but once
stamped, the page in the database is what the client edits, and the pattern file stops
being the source of truth. Editing the pattern file afterwards will not change a live page.

This also rules out the convenient shortcut of looping a PHP array inside a pattern to
render repeated cards. Repeated items are either repeated blocks in the database, or a
custom block backed by post data — never a PHP array.

### Custom blocks

**`[SET]` Custom blocks live in the theme**, at `blocks/<block-name>/`. Decided by Alison,
20 July 2026.

> **Known trade-off, accepted deliberately.** Page content in the database will reference
> these blocks, so switching or removing the theme leaves that content rendering as block
> recovery errors. This was raised and chosen anyway — it keeps the site to a single
> artefact. Don't re-litigate it, but do keep block names stable, because renaming one
> breaks every page already saved against it.

**`[SET]` Build blocks with `block.json` and `@wordpress/scripts`.** Modern standard
tooling: JSX, a build step, asset versioning, proper editor previews. Not the hand-rolled
no-build style the Mariart plugin uses — that is existing code we match when editing it,
not a pattern for new work.

**`[SET]` Core blocks first.** A custom block is justified only when no core block, or
sensible combination of them, expresses the section. Record why in the block's README.

### Getting content into the database

**`[SET]` Ship a WP-CLI command** that creates or updates pages from the patterns.
Decided by Alison, 20 July 2026.

It must be:

- **Idempotent, keyed by page slug** — safe to run repeatedly; re-running updates rather
  than duplicating.
- **`--dry-run` capable**, so a re-import can be inspected before it touches live content.
- **Explicit about overwriting.** A client may have edited a page since the last import;
  never silently discard their edits. Report what would change and require confirmation.

Not a theme activation hook — that runs once, is awkward to re-run, and does nothing at all
on a site that already exists.

### Templates

**`[SET]` Templates and template parts ship as theme files** (`templates/*.html`,
`parts/*.html`). WordPress promotes one to a `wp_template` database record automatically the
first time it is edited in the site editor, which is the right moment for it to become
database state. Content still lives in the database under this rule, because content lives
in pages. Decided by Alison, 20 July 2026.

---

## 4. Navigation

**`[SET]` Nav markup comes from the design**, not from `wp_nav_menu()`, when the design's
navbar has custom structure (dropdowns, a CTA button in the bar).

**`[ASK]` Should the nav be wired to a real WordPress menu** so the client can edit it, and
if so how do the design's dropdowns and button map onto menu items? Dama Charter's nav
links are hardcoded anchors to on-page sections.

---

## 5. Forms

**`[SET]` Forms are Gravity Forms.** Decided by Alison, 20 July 2026. Never hand-rolled
HTML with no handler, and never a custom form block — WordPress has no core form block, and
GF is the house tool the company `wordpress-development` skill already names.

The contact section renders the `gravityforms/form` block, referencing the form by ID.

**`[ASK]` Does the import create the form definition, or expect one to exist?** A GF form is
database state, so creating it from the design's fields via `GFAPI::add_form()` fits the §3
ruling — but a form built in the GF UI is easier for a non-developer to adjust afterwards.
Not yet decided.

**`[ASK]` Where do submissions go?** GF notifications need a destination address, which the
design cannot supply. Always ask; never guess a client's email.

---

## 6. Spacing and fidelity

**`[SET]` Build `theme.json` from the Figma variables.** Colour schemes, text sizes, gap
and padding tokens and radii come from `get_variable_defs`, not from values read off the
markup.

**`[SET]` Gap, not margin.** Space between elements is `gap` on the flex/grid parent,
matching how Figma auto-layout expresses it. Avoid margins for layout spacing.

**`[SET]` Styling is hybrid: tokens native, layout in CSS.** Decided by Alison,
20 July 2026.

- **`theme.json` owns the tokens** — colour, type scale, spacing — built from the Figma
  variables. The site editor's controls then offer the real palette and sizes, so anything
  a client changes stays on-system.
- **The stylesheet owns section layout** — grids, card composition, bespoke positioning —
  attached to blocks with `className`.

The point is that editor controls must not lie. A client who opens a colour or spacing
control should see values that actually apply. Layout that no control exposes belongs in
CSS, where it cannot be half-changed into something broken.

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

**`[ASK]` Should imported images be sideloaded into the media library?** This is the one
place where §3's "content in the database" rule is not currently met. Images referenced by
theme-file URL are not attachments, so they get no `srcset`, no generated sizes, and no
media-library presence — WordPress serves the full-size original at every breakpoint.

The cost of leaving it: Dama Charter's homepage ships roughly 22 MB of images, including a
single 12.8 MB JPEG and a 9 MB one, at every viewport including phones.

Sideloading on import would fix all of that and make images properly editable, at the cost
of a more complex importer (dedupe by filename, rewrite `src` to attachment URLs, inject
attachment IDs into the block markup). Not yet decided, so the Dama Charter importer does
**not** sideload.

---

## 8. Worked example — Dama Charter

> ⚠️ **This build does not comply with §3 and must not be copied as a model.** It was built
> before the editability ruling: every section is hardcoded PHP, with the repeated items
> (tour cards, testimonials, FAQs, blog cards, tour radio options) as PHP arrays inside the
> pattern files, and no content in the database. None of it is client-editable. It is kept
> here only as a section-mapping reference and as the record of the truncation bug below.

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
