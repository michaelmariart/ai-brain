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

**`[SET]` Always look for both a desktop and a mobile frame before building.** Decided by
Alison, 20 July 2026.

Do this **first**, before writing any markup — the answer changes how the CSS is written,
and retrofitting it is expensive.

**Finding them.** Call `get_metadata` without a `nodeId` to list the file's pages, then on
the page to list its frames. Match on the page name, not the exact separator: the usual
form is `Home - Desktop` / `Home - Mobile`, but separators vary (`-`, `–`, `•`, `/`, `|`)
and so do the labels (`Mobile`, `Mob`, `Phone`, `Small`; `Desktop`, `Web`, `Large`). Match
loosely and case-insensitively rather than assuming one convention.

**When both exist:** the mobile frame is authoritative for small screens. Build
mobile-first from it and match it breakpoint-for-breakpoint rather than guessing how the
desktop layout should collapse.

**When only one exists: stop and ask.** Never decide this silently. Offer exactly two
options:

1. **Interpolate** — infer the responsive behaviour from the desktop design, mobile-first.
   Reasonable, but every breakpoint is then an assumption nobody has approved.
2. **No responsive rules** — build the design as given, with no breakpoint behaviour at
   all.

Record the answer, because it is a per-project decision rather than a house default.

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

### Lists of other post types (blog, and the like)

**`[SET]` A section that lists another post type is a Query Loop, not repeated cards.**
Decided by Alison, 21 July 2026.

Some sections in a design are not really bespoke content — they are a *view of a post
type*. A "latest posts", "from the blog", "news" or "recent articles" strip is the
clearest case: the design draws two or three cards, but what it means is *show the newest
posts*. Recognise these and build them as a **Query Loop** (`core/query` +
`core/post-template` with `core/post-featured-image`, `core/post-terms`, `core/post-title`,
`core/post-excerpt`, `core/read-more`) that pulls the latest of that post type — never as
hardcoded card copy.

**How to recognise one.** The section is labelled as, or clearly is, a list of a known
post type (blog/news/articles → `post`); the cards are homogeneous — same fields repeated
(image, category, date, title, excerpt, a "read more"); and there is usually a "View all"
link to the archive. When it looks like a feed, it is one.

**Seed the posts when they don't exist yet.** A Query Loop on an empty site renders
nothing, so the design's own card content becomes the seed:

- **Create one real post per card shown**, taking the title and the excerpt verbatim from
  the design. The card's image becomes the post's **featured image**, sideloaded into the
  media library like any other (§7) — not a theme-file URL.
- **The body is placeholder.** The design only gives a title and a teaser, never the
  article, so fill `post_content` with clearly-dummy lorem ipsum. Never invent article
  copy in a client's voice and never pad the excerpt into a fake body — placeholder must
  read as placeholder so nobody ships it as finished writing.
- **Assign categories and tags exactly as the design shows them.** The card's category
  label (and any tags) are real taxonomy terms — create the terms if missing and attach
  them. If the design shows a category chip, the seeded post must carry that category, or
  the rendered card won't match the design.
- **Stagger the dates** so the newest post is the first card in the design's order — a
  Query Loop sorts by date, so equal timestamps make the order arbitrary.
- **Every seeded post ends with a featured image.** Use the card's image if it sideloads,
  and fall back to the site default (below) if it doesn't — a Query Loop card with an empty
  image well looks broken.

**`[SET]` Clear WordPress's default sample content at the start of an import.** Decided by
Alison, 21 July 2026. A fresh install ships a "Hello world!" post that is newer than
anything seeded, so it takes a slot in a latest-posts loop and shows sample copy on the
homepage. Trash it (reversible, not deleted) at the top of the importer, guarded to the
genuine default so a real post is never caught. The sample page and default comment are
worth clearing on the same principle.

**`[SET]` Provide a site-wide default featured image, so a post thumbnail is always
available.** Decided by Alison, 21 July 2026. Ship one raster as `default-featured.jpg`,
sideload it into the library at import and cache its id, then filter `post_thumbnail_id` on
the **front end only** to return it for any post that has none. The editor keeps showing
the true "no image set" state so an author still knows to choose one. Because it is one
swappable theme file, the client changes the default by replacing the file and re-importing
— no code change.

**Seeding is create-if-missing, keyed by slug.** These are throwaway posts a client will
replace with real writing, so once one exists the importer leaves it alone — it never
overwrites a post that may now hold real content. That is a lighter contract than the page
importer's edit-detection (which does track and protect edits): for seeds, mere existence
is enough to stop.

**Where the seeding lives.** In the same idempotent WP-CLI importer that builds the pages
(the "getting content into the database" rule above), and it must run **before** the pages
so the Query Loop has posts to show on the first pass.

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

**`[SET]` WordPress contributes no spacing. Every padding, gap and margin comes from the
Figma design.** Decided by Alison, 20 July 2026.

Core ships opinionated spacing on nearly every block, and none of it is in the design. It
is not a starting point to adjust — it is noise to remove. If a spacing value in the
rendered page cannot be traced back to a Figma variable or an auto-layout value, it should
not be there.

**Start by zeroing the block gap:** set `styles.spacing.blockGap` to `0` in `theme.json`.
WordPress defaults it to 24px and enforces it with
`:where(.is-layout-flow) > * { margin-block-start: … }`, which lands on every top-level
section inside `wp-block-post-content` and again on `.wp-site-blocks`. Figma sections butt
straight up against each other and carry their own padding, so that 24px is always wrong.

**Then strip the per-block defaults.** These are the ones that bit on Dama Charter — treat
it as a checklist, not an exhaustive list:

| Block | What core adds |
|---|---|
| `core/quote` | left border, text indent, bottom margin |
| `core/list`, `core/post-template` | `padding-inline-start`, list margins |
| `core/separator` | border-bottom, constrained width, vertical margins |
| `core/columns` | its own `gap`, plus `flex-basis`/`flex-grow` on columns |
| `core/social-links` | its own `gap` and icon sizing |
| `core/image` | `<figure>` user-agent margins |
| `core/button` | padding and border on the link |
| `core/navigation` | `gap` between items |

**Two separate sources, and removing one does not remove the other:**

- **`wp-block-styles`** — the *opinionated* layer, added by
  `add_theme_support('wp-block-styles')`. This is where the quote's left border and
  `1.75em` bottom margin come from. If the design supplies every value — and under this
  rule it should — **don't add the support at all** rather than overriding it block by
  block. Dropping it on Dama Charter removed the quote rules and about 2 KB, with no other
  change.
- **`wp-block-library`** — the *structural* layer, always loaded, needed for blocks to
  work. It still ships real spacing: `:where(.wp-block-columns){margin-bottom:1.75em}`
  survives the above and applies to any columns block. Override these in `theme.json` under
  `styles.blocks`, e.g. `core/columns` → `spacing.margin.bottom: "0"`. Both rules use
  `:where()` so specificity ties and source order decides — `theme.json` is emitted later
  and wins.

Overriding in the stylesheet instead works, but only for the one instance you thought of.
The next columns block anyone inserts gets the 1.75em back, and the editor shows it.

**Two conditions on doing this safely:**

1. **The theme must declare its own gaps first.** Zeroing the root gap only works because
   every flex and grid container sets one explicitly. Check before zeroing, or layouts
   relying on the inherited 24px will collapse.
2. **Fix it in `theme.json`, not with a CSS override**, wherever `theme.json` can express
   it. A CSS-only fix leaves the site editor showing spacing the front end doesn't have,
   which is exactly the editor-lying problem the hybrid rule exists to prevent.

**How to check:** search the rendered HTML for core's generated spacing rules
(`margin-block-start`, `--wp--style--block-gap`, `wp-container-`) and confirm every
surviving value is one you can point at in Figma.

**`[SET]` Build mobile-first.** Decided by Alison, 20 July 2026.

**The base styles are the mobile design.** Not the desktop design shrunk, and not a guess
about how the desktop collapses — the actual values from the mobile frame (see §2, which
requires you to find it before building). Everything outside a media query should render
the mobile layout correctly on its own.

**Layer larger layouts on with `min-width` only.** A `max-width` query is a signal that
something was built desktop-first and is being walked back; treat each one as a defect to
justify or remove. The concrete failure on Dama Charter: the navbar was built from the
desktop frame, so core's navigation overlay had to be *forced* back on with
`@media (max-width: 61.999rem)` — patching over a base state that should have been the
overlay to begin with.

In practice that means:

- **Single column is the default.** Multi-column grids and flex rows are added at a
  breakpoint, never removed at one.
- **Stacked is the default.** Splits, cards and columns stack in the base styles.
- **Type scales up.** Base font sizes come from the mobile frame; larger sizes are added at
  breakpoints. `clamp()` is fine, but its lower bound must be the mobile design's value
  rather than an invented floor.
- **Breakpoints come from where the design actually changes**, not from a standard set of
  device widths carried in from another project.

**Where only a desktop frame exists,** this rule does not license inventing mobile values —
§2 still applies: stop and ask whether to interpolate or ship no responsive rules at all.
Mobile-first describes how the CSS is written, not permission to guess what it contains.

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

**`[SET]` Never author an icon by hand.** Use the exported asset.

**`[SET]` Social icons come from the design, never a brand style guide.** Decided by
Alison, 21 July 2026. Core's Social Icons block (`core/social-links`) ships each platform's
official glyph and brand colour — the wrong shape and the wrong colour when the design has
drawn its own (monochrome, a single scheme colour, a particular weight). Keep the block, so
the links stay editable in the database (§3), but neutralise its appearance and paint the
design's glyph instead:

- Apply the **`is-style-logos-only`** variation to drop core's coloured pills.
- **Strip core's `<svg>` from the output**, not just hide it — a `render_block_core/social-link`
  filter that removes the `<svg>…</svg>` (keep core's screen-reader label). A WordPress
  glyph must never appear in the HTML, only be `display:none`'d.
- **`mask` each anchor** with the design's exported SVG (`assets/images/…svg`, a theme
  asset per the raster/vector split above), coloured with a `background-color` token from
  `theme.json`.
- **The `<a>` is the fixed container.** Give every link the *same* box, sized to the
  largest icon in each axis (largest width across all icons × largest height across all
  icons), so the click targets are identical.
- **Centre each glyph at its own intrinsic size inside that box** — `mask-size` set to the
  SVG's own dimensions (never `contain`, which would scale it to fill) and `mask-position:
  center`. The design's icons differ in aspect (a wide play button beside a square camera);
  a uniform box with centred, intrinsically-sized glyphs keeps every shape true.

The same reasoning applies to any core block that substitutes its own house iconography for
the design's.

**`[SET]` Always run `download_assets` as well as `get_design_context`.** They return
different things, and the difference matters:

- `get_design_context` gives **rendered exports** of nodes, at scale 1 by default — the size
  the asset appears in the design.
- `download_assets` also returns **`rawImages`**: the original uploaded source files behind
  the fills, anywhere in the node subtree.

On Dama Charter this recovered five source images `get_design_context` never surfaced —
including the **company logo**, which `get_design_context` had reported as `unknown` and
therefore unexportable, and two genuine client photographs that had simply been missed.

So an asset reported as `unknown` is **not** necessarily unavailable. Check `rawImages`
before telling anyone a file is missing.

**`[SET]` Check whether the raw sources are actually larger before re-exporting.** Compare
the raw images against what you already have — hash them, and measure the pixel dimensions.
If the raw source *is* the low-resolution file, exporting at a higher `defaultScale` only
upscales it and produces a softer image, not a sharper one. On Dama Charter every raw source
was byte-identical to the existing asset: 14 of 17 rasters are genuinely low-resolution in
the design file, the hero included at 500×334. That is a problem to raise with the designer,
not something export settings can fix.

**`[ASK]` Alt text.** Figma images almost always have empty `alt`. Dama Charter wrote
descriptive alt text and flagged it for review, since accessibility is required. Confirm
that, or define a different handling (leave empty, ask the client, use a caption field).

**`[SET]` Every image and media file is served from the media library.** Decided by Alison,
20 July 2026. Not from theme-file URLs.

The importer sideloads each asset into the uploads directory, creates the attachment, and
rewrites the block markup to reference it by ID. That is what earns `srcset`, generated
sizes and a media-library presence — a theme-file URL earns none of them, so WordPress
serves the full-size original at every breakpoint.

The cost of getting this wrong is not theoretical: before the change, Dama Charter's
homepage shipped roughly 22 MB of images, including a 12.8 MB JPEG and a 9 MB one, to
phones as well as desktops.

Rules for the importer:

- **Dedupe by source filename**, recorded in attachment meta, so re-running never creates
  a second copy of the same asset.
- **Set the block's `id` attribute and the `wp-image-<id>` class**, not just the `src`.
  Without both, WordPress will not generate `srcset` and the exercise is wasted.
- **The site logo becomes an attachment too**, set via the `site_logo` option, so
  `wp:site-logo` resolves.

**`[SET]` Raster images go to the library; vectors and decorative assets stay in the theme.**
Decided by Alison, 20 July 2026.

WordPress blocks SVG uploads because an SVG is XML and can carry `<script>`, which makes it
a stored XSS vector. Enabling them was considered and rejected: icons, logos, textures and
list bullets stay as theme assets, and only raster content images are sideloaded. This also
settles CSS-referenced decorative images, which stay in the theme by the same reasoning.

**`[SET]` Generate attachment sizes, and check that you did.** Sideloading alone is not
enough — `wp_generate_attachment_metadata()` silently produces no sizes when PHP has no
image editor available, and `srcset` then never appears even though the markup looks
correct. This happened on the Dama Charter import, which ran through a CLI PHP without GD
loaded. Always confirm `srcset` is present in the rendered HTML afterwards; the attachment
IDs and `wp-image-<id>` classes look perfectly fine while achieving nothing.

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
