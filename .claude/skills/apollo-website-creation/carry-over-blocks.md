# Carrying blocks over from a donor child theme

A cloned Apollo site arrives with the previous client's child theme still present and
still active. Its `blocks/` folder is usually worth reusing — but the donor's name is
baked into **four separate places**, and each one fails differently.

## Copy verbatim first

Copy the files across untouched, then prove the copy is complete before changing
anything — compare file counts and hashes, don't eyeball the list. De-branding a file
you retyped from memory is how content goes missing.

```powershell
Copy-Item -Path "$donor\blocks\*" -Destination "$new\blocks" -Recurse -Force
```

The scaffold's `blocks/index.php` is overwritten by the donor's identical copy — no
issue.

## The four places the donor's name hides

### 1. Theme constants (breaks the page)

Block templates reference the child theme's own base-URL constant:

```php
<img src="<?php echo MARIART_THEME_<DONOR>_BASE_URL; ?>/blocks/spacer-line/icon.png" ...
```

The new theme defines `MARIART_THEME_<CLIENT>_BASE_URL`, so the copied line references
a constant that doesn't exist. **On PHP 8 an undefined constant is a fatal `Error`** —
every page using that block dies. This is the most severe of the four and the least
visible, because nothing complains until the block is actually rendered.

**Leave `MARIART_THEME_APOLLO_*` alone.** That's the *parent* theme's constant, pointing
at shared assets in `apollo-care-base`, and it is correct in the new theme. Rewriting it
breaks the block. Grep for `MARIART_` and change only the child-theme ones.

### 2. Block titles in the database (not in the files)

Genesis Custom Blocks stores each block as a `genesis_custom_block` post. The editor
label lives in **two** fields that must stay in sync:

- `post_title` — e.g. `Tenterfield - Spacer Line`
- the `title` key inside the JSON block config in `post_content`

Update both. Retitling to `<Client> - <Block>` matches the `Apollo - <Block>` convention
already used by the shared blocks.

> **Never change the block `name`/slug** (`post_name`, the `name` key, and the
> `genesis-custom-blocks/<slug>` config key). Page content references blocks by that
> slug and the theme finds templates by the matching `blocks/<slug>/` folder — renaming
> it orphans every existing use of the block. Titles are display-only and safe.

Validate the JSON after replacing and skip any row that fails, rather than writing a
corrupt block config. Restrict the search-and-replace to the title separator
(`'<Donor> - '`) so it can't touch field labels or default values that happen to mention
the donor.

Two things to know before running it:

- The donor theme is usually **still active**, so the new titles appear in the live
  site's editor straight away. On a site being repurposed that's intended — confirm it
  is.
- Check for **orphaned templates**: a `blocks/<slug>/block.php` with no matching
  `genesis_custom_block` post. The block can't be inserted and the file is dead weight.
  Report it; don't silently carry it over.

### 3. Text domain

`__ ()` / `_e ()` calls carry the donor's domain (`'tenterfield'`). Change them to the
new theme's. Harmless today — nothing is translated — but it silently breaks any future
translation of these strings.

### 4. CSS class names

Class prefixes like `.donor-spacer-line` appear in **both** the markup and the block's
`block.css`. They're internally consistent, so they work; they're just wrong-branded.
Rename markup and stylesheet **together**, or the block loses its styling.

Leave shared classes alone — `apollo-*`, `mariart-*` and generic ones like
`news-list-read-more` come from the parent theme and the plugin.

## What not to fix silently

- **Donor CSS custom properties** — `var(--donor-colour-orange)` and friends are defined
  in the donor's `assets/css/default.css`, which is *not* copied. Renaming the variable
  makes it look resolved while it still resolves to nothing. Flag it and get the client's
  actual palette value; that's a design decision, not a rename.
- **Classes with no styles in the new theme** — same cause. Say which ones.
- **Hardcoded donor content** — e.g. a types-of-care block listing the donor's three care
  types. Copy it, then ask; it's content, not code.

## Verify

- `php -l` every copied `.php` file.
- Grep the whole new theme for the donor's name, case-insensitively. What's left should
  be only the items you consciously chose to leave — be able to name each one.
- Re-query the block posts: titles changed, slugs unchanged, JSON still valid.
- Load the front end and confirm HTTP 200.
