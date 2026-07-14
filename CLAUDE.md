# AI Brain — Coding Standards & Working Conventions

This file is read automatically by Claude Code. It applies to **all work done in this
workspace**, including every project under `projects/`. When building or editing code
here, follow these standards. When a project already has its own established style,
match that project first and use these as the baseline.

Primary stack: **HTML, CSS, JavaScript, PHP** (mostly small websites and holding pages).

---

## 1. Workspace layout

- All hands-on work lives in **`projects/`** (one entry per project). This folder is
  Git-ignored — see [PROJECTS.md](PROJECTS.md).
- A project under `projects/` may be a real subfolder **or a link** (a Windows junction, or
  a symlink on macOS) to a folder elsewhere on the machine — managed by `Set-Project.ps1`
  (Windows) or `set-project.sh` (macOS/Linux). When a project is linked in (e.g. the Mariart
  plugin), treat it as living at its real location — match that codebase's existing
  conventions and preserve its line endings.
- Each project is **self-contained**: its own `index` entry point, `assets/` for
  images/fonts/SVG, and a short `README.md`.
- Use **relative paths** inside a project (`assets/logo.svg`), never absolute local paths
  (`C:\Users\...`).
- Never commit secrets, `node_modules/`, `vendor/`, or build output.

## 2. How to work

- Prefer the **simplest thing that works**. Clarity beats cleverness.
- Keep changes **small and focused**; don't reformat or refactor unrelated code.
- **Verify before declaring done** — open the page/app and check it actually works.
- Ask before anything hard to undo (deleting files, publishing, sending).
- Explain trade-offs briefly; don't over-explain routine work.

## 3. Formatting (enforced by the tool configs in this folder)

Handled by `.editorconfig`, `.prettierrc.json`, and `.php-cs-fixer.dist.php` (PSR-12 for
PHP — see §8):

| | Setting |
|---|---|
| Indentation | **2 spaces** (HTML/CSS/JS/JSON) · **4 spaces** (PHP, PSR-12) |
| Encoding | UTF-8 |
| Line endings | LF (CRLF only for `.ps1` / `.bat` / `.cmd`) |
| Line length | aim for ≤ 100 characters |
| Whitespace | trim trailing (except Markdown), end files with a newline |
| Quotes | double in HTML attributes; JS double (Prettier default); PHP single unless interpolating |
| Semicolons (JS) | yes |

## 4. General principles (all languages)

- **Names say what they mean.** `submitButton`, not `btn2`. Booleans read as questions
  (`isValid`, `hasError`).
- **Small, single-purpose** files and functions.
- **Comment the _why_,** not the _what_. Good names remove the need for most comments.
- **Don't repeat yourself** — but don't over-abstract before there's a real second use.
- **No secrets in code.** Keep credentials/API keys in a separate, Git-ignored config file
  (e.g. `config.local.php`, `.env`).
- **Handle errors** deliberately; never swallow them silently.

## 5. HTML

- HTML5: `<!DOCTYPE html>`, `<html lang="…">`, `<meta name="viewport" …>`, UTF-8.
- Use **semantic elements** — `header`, `nav`, `main`, `section`, `article`, `footer` —
  over `div` soup.
- **Exactly one `<h1>`** per page; don't skip heading levels.
- **Accessibility is required, not optional:**
  - Meaningful `alt` text on images (empty `alt=""` for purely decorative ones).
  - Label every form control (`<label for>` or `aria-label`).
  - Keep a visible keyboard **focus state**.
  - Ensure text contrast meets **WCAG AA** (4.5:1 body, 3:1 large text).
- Keep structure (HTML), presentation (CSS), and behaviour (JS) separated — no inline
  styles or inline `onclick` for anything non-trivial.

## 6. CSS

- **Mobile-first**: base styles for small screens, then `@media (min-width: …)` to scale up.
- Define reusable tokens as **custom properties** in `:root` (colours, spacing, fonts):
  ```css
  :root { --navy: #002742; --orange: #f37021; --font: "Noto Sans", sans-serif; }
  ```
- **Class-based, low-specificity** selectors; use `kebab-case`. Avoid IDs for styling and
  avoid `!important`.
- Relative units for type/spacing (`rem`, `em`); `max-width: 100%` on media.
- Support **light and dark** where it makes sense (`prefers-color-scheme`).
- Prefer CSS grid/flexbox over floats and absolute positioning for layout.

## 7. JavaScript

- Modern syntax: `const`/`let` (never `var`), arrow functions, template literals, modules.
- **Vanilla-first.** Add a library only when it clearly earns its weight; note why.
- **Progressive enhancement** — the page should still make sense if JS fails to load.
- Avoid globals; keep scope tight. Prefer pure functions.
- No leftover `console.log` in delivered code. Handle promise rejections/errors.
- Keep interactions **accessible**: keyboard-operable, correct ARIA, respect
  `prefers-reduced-motion`.

## 8. PHP

New PHP that Claude writes follows **PSR-12**, with the modern defaults below. Code Claude
did **not** generate is exempt — see "Existing / third-party code" at the end.

**Style**
- **4-space indentation**, no tabs. Files start with `<?php`; pure-PHP files omit the
  closing `?>`.
- One class per file. `StudlyCaps` class names, `camelCase` methods and variables,
  `SCREAMING_SNAKE_CASE` constants. `namespace` then `use` declarations at the top.
- Braces: on their **own line** for classes and functions/methods; on the **same line** for
  control structures (`if (…) {`). Always use braces, even for a single statement.
- **Short array syntax** `[…]`; **single quotes** unless interpolating.
- Declare visibility on every property and method; add parameter and return **type
  declarations** where practical. One blank line between methods.

**Security — non-negotiable**
- **Escape all output** before printing: `htmlspecialchars($v, ENT_QUOTES, 'UTF-8')`, or in
  WordPress `esc_html()` / `esc_attr()` / `esc_url()` / `wp_kses_post()`.
- **Never concatenate SQL** — use prepared statements (PDO / mysqli bound parameters, or
  `$wpdb->prepare()`).
- **Validate and sanitise all input** (`$_GET` / `$_POST` / `$_FILES`); use nonces on forms.
- Keep credentials/keys in a **Git-ignored** config file; in production, log errors rather
  than displaying them.

**WordPress**
- Use WordPress APIs (`add_action`, `register_post_type`, `wp_enqueue_script`, `__()`, …)
  together with the escaping/sanitising rules above.

**Existing / third-party code (not written by Claude)**
- Code Claude did not generate — e.g. the linked **Mariart plugin**, which uses its own
  bespoke style — is **exempt from PSR-12**. When editing such a file, **match the style
  already in that file** (indentation, spacing, naming, brace placement) and preserve its
  line endings. Do **not** reformat it as a side effect of an edit.
- Convert existing code to PSR-12 **only when explicitly asked**. On request it can be
  reformatted with `php-cs-fixer` pointed at that path (see §10), or by hand.

**Example (PSR-12)**

```php
<?php

namespace App\Contact;

class Example
{
    private string $slug;

    public function register(): void
    {
        if ($this->slug === '') {
            return;
        }

        add_action('init', [$this, 'load']);
    }
}
```

## 9. Git

- Commit only when asked. Make **small, logical commits** with clear, imperative messages
  ("Add contact form validation", not "stuff").
- Never commit secrets, dependencies (`vendor/`, `node_modules/`), or build artefacts.
- `projects/` is intentionally ignored — see [PROJECTS.md](PROJECTS.md).

## 10. Using the tools (optional)

The config files work automatically in editors that support them (e.g. VS Code with the
EditorConfig and Prettier extensions). To run the formatters manually:

```powershell
# HTML / CSS / JS / JSON / Markdown  (needs Node.js)
npx prettier --write .

# PHP — PSR-12  (needs PHP + Composer + PHP CS Fixer)
vendor/bin/php-cs-fixer fix                     # Claude-generated projects (safe default)
vendor/bin/php-cs-fixer fix projects/mariart    # existing code: only on request, by path
```

`.php-cs-fixer.dist.php` deliberately **skips linked-in / third-party code** (e.g. the
Mariart plugin) on a blanket run, so existing code is reformatted only when you point the
fixer at its path explicitly. `.editorconfig` alone keeps indentation and line endings
consistent with no installation required.
