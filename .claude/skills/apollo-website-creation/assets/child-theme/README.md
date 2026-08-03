# {{SITE_NAME}} Custom Theme

WordPress child theme for the {{SITE_NAME}} website. Built by
[Mariart Design Studio](https://mariart.com.au).

- **Parent theme:** `apollo-care-base` (required — install it alongside this theme)
- **Companion plugin:** `mariart` (required — it enqueues the theme's stylesheets,
  autoloads fonts, and provides the shared site functionality)
- **Text domain:** `{{TEXT_DOMAIN}}`

The theme is currently an empty shell: it declares itself as a child of
`apollo-care-base` and adds nothing of its own yet.

## Structure

```
{{THEME_SLUG}}/
├── assets/
│   ├── css/default.css   Theme styles, enqueued after the parent's
│   ├── fonts/            Web fonts (auto-loaded by the Mariart plugin)
│   └── images/
├── blocks/               Genesis Custom Blocks templates
├── templates/            Template parts
├── functions.php         Namespace and base path/URL constants
└── style.css             Theme header only — the stylesheet WordPress requires
```

`index.php` files exist in each folder to prevent directory listing; leave them in
place.

## Installation

1. Clone into `wp-content/themes/` so the folder is named `{{THEME_SLUG}}`.
2. Make sure `apollo-care-base` and the `mariart` plugin are both present and the
   plugin is active.
3. Activate **{{SITE_NAME}} Custom Theme** in *Appearance → Themes*.

## Conventions

Follow the Mariart house style already used by `apollo-care-base` and the `mariart`
plugin — tab indentation, a space before the parenthesis in function calls and
declarations, and a trailing `// functionName ()` comment closing each function.
Escape all output with the WordPress escaping functions.
