---
name: apollo-website-creation
description: >-
  Mariart's house method for standing up a new Apollo aged-care website — a
  WordPress site built on the apollo-care-base parent theme plus the mariart
  companion plugin. Use this whenever a new Apollo site is being created or an
  existing Apollo site is cloned and repurposed for a new client — e.g. "set up
  the new Apollo site", "create the site for <client>", "clone <site> for
  <client>", "new aged-care site". Links the Local site into the workspace,
  forces the WordPress database prefix to wp_ in both wp-config.php and the
  database, and scaffolds an empty child theme wired to its own GitHub repo.
---

# Apollo website creation

Every Apollo site is the same three parts:

| Part | What it is |
|---|---|
| `apollo-care-base` | The parent theme. Shared across every Apollo site — **never edit it per-client.** |
| `mariart` plugin | The companion plugin. Enqueues the child theme's stylesheets, auto-loads its fonts, and provides the shared post types and shortcodes. |
| `<client>` child theme | The only per-client code. Its own folder, its own GitHub repo. |

New sites are usually **cloned from an existing Apollo site** in Local, so they arrive
carrying the previous client's database, theme and content. This skill covers getting
that clone into a clean, known state. It does **not** cover building the design — once
the steps below pass, hand over to **`figma-to-wordpress`**.

Load alongside: **`coding`** and **`wordpress-development`** (company standards, always),
and **`new-project`** for step 1.

## The two things that are never optional

1. **The database prefix is `wp_`** — in `wp-config.php` *and* on every table, option
   name and usermeta key. No exceptions, on every Apollo site.
2. **The client gets a fresh, empty child theme** in its own repo. Never rename or edit
   the previous client's child theme into the new one; its content and styles are
   reference material, not a starting point.

## Workflow

### 1. Link the site into the workspace

Follow the **`new-project`** skill. The path is the Local site's `app` folder:

```
C:\Users\michael\Local Sites\<site>\app
```

It is an existing WordPress install, so it gets **linked as-is and nothing is
scaffolded** — the starter files in `new-project` are for blank projects only.

### 2. Force the database prefix to `wp_`

Do this **before** any other work — a mismatched prefix makes WordPress report itself as
"not installed", and every later verification step becomes meaningless.

The full procedure, including the traps that will bite you, is in
[db-prefix.md](db-prefix.md). The short version:

1. Back up the database first (`mysqldump`).
2. Rename every `<old>_*` table to `wp_*`.
3. Rename the option names and usermeta keys that embed the prefix.
4. Set `$table_prefix = 'wp_';` in `wp-config.php`.
5. Verify through WordPress, not just the database.

`assets/change-db-prefix.php` does steps 2–4 and has a `--dry-run` mode. **Read
[db-prefix.md](db-prefix.md) before running it** — the collision rule it applies is a
judgement call you need to understand, not a black box.

### 3. Scaffold the child theme

Lay the scaffold in `assets/child-theme/` out into
`wp-content/themes/{{THEME_SLUG}}/` like this:

```
style.css              ->  style.css
functions.php          ->  functions.php
README.md              ->  README.md
default.css            ->  assets/css/default.css
index.php              ->  assets/index.php, assets/css/index.php,
                           assets/fonts/index.php, assets/images/index.php,
                           blocks/index.php, templates/index.php
dot-gitignore          ->  .gitignore
dot-gitattributes      ->  .gitattributes
```

The two `dot-` files are stored without their leading dot so they don't take effect
inside the AI Brain repo itself — rename them on copy.

Then fill in the placeholders:

| Placeholder | Meaning | Example |
|---|---|---|
| `{{SITE_NAME}}` | Human-readable client name | `Vincent Court` |
| `{{THEME_SLUG}}` | Folder name — **must match the GitHub repo name** | `theme-vincent-court` |
| `{{TEXT_DOMAIN}}` | Text domain | `vincent-court` |
| `{{NAMESPACE}}` | StudlyCaps namespace segment | `VincentCourt` |
| `{{CONST_PREFIX}}` | SCREAMING_SNAKE constant segment | `VINCENTCOURT` |

The theme ships **empty on purpose** — a theme header, a namespaced `functions.php`
holding the base path/URL constants, and the standard folders with their
directory-listing guards. No styles, blocks or templates until the design work starts.

Three things that are easy to get wrong:

- **The child theme needs no enqueue code.** The `mariart` plugin already enqueues the
  child's `style.css` and `assets/css/default.css` when they exist, and auto-loads
  `assets/fonts/`. Adding your own `wp_enqueue_style` double-loads them.
- **Match the Mariart house style**, not PSR-12 — tab indentation, a space before the
  parenthesis in calls and declarations, `// functionName ()` closing each function. The
  parent theme and the plugin are existing code and set the convention the child theme
  sits inside.
- **Do not activate it yet.** The outgoing child theme is usually the reference for the
  build. Ask before switching themes.

### 4. Give the child theme its own repo

One repo per child theme, named to match the folder:
`github.com/mariartau/theme-<client>`.

```bash
git init -b main
git remote add origin https://github.com/mariartau/theme-<client>.git
```

The scaffold includes a `.gitattributes` that normalises to LF (`core.autocrlf` is on
globally on this machine and will otherwise commit CRLF) and marks fonts and images as
binary. Update the `README.md` in the same commit as any later code change — the
workspace rule applies to this repo too.

Confirm the remote exists and is empty before pushing:

```bash
git ls-remote https://github.com/mariartau/theme-<client>.git
```

Exit 0 with no refs means the repo exists and is empty — safe to push. A failure means
it doesn't exist: **ask the user to create it**, don't try to create it yourself.

### 5. Verify before declaring done

All four, through WordPress rather than by eyeballing the database:

```
wp core is-installed          # exit 0
wp theme list                 # the new theme appears, version parsed, not "broken"
wp user list                  # users still resolve to their roles
```

...plus the front end actually returning HTTP 200. Roles are the sharpest test of a
prefix change: if `wp_user_roles` or `wp_capabilities` were missed, every user silently
loses their role while the site otherwise looks fine.

Running WP-CLI against a Local site on this machine needs three separate overrides —
see [local-wp-cli.md](local-wp-cli.md).

## What this skill does not do

Building pages, templates and blocks from the design is **`figma-to-wordpress`**. Start
it only once step 5 passes; building on a broken prefix wastes the whole build.
