# AI Brain — Coding Standards & Working Conventions

This file is read automatically by Claude Code. It applies to **all work done in this
workspace**, including every project under `projects/`. When building or editing code
here, follow these standards. When a project already has its own established style,
match that project first and use these as the baseline.

Primary stack: **HTML, CSS, JavaScript, PHP** (mostly small websites and holding pages).

---

## 1. Workspace layout

- All hands-on work lives in **`projects/`** (one subfolder per project). This folder is
  Git-ignored — see [PROJECTS.md](PROJECTS.md).
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

Handled by `.editorconfig`, `.prettierrc.json`, and `.php-cs-fixer.dist.php`:

| | Setting |
|---|---|
| Indentation | **2 spaces** (HTML/CSS/JS/JSON) · **4 spaces** (PHP, per PSR-12) |
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

- Follow **PSR-12** (4-space indent, one class per file, `<?php` with **no closing `?>`**
  in pure-PHP files).
- **Security first** — this is the most important part:
  - **Escape all output**: `htmlspecialchars($value, ENT_QUOTES, 'UTF-8')` before printing.
  - **Never build SQL by string concatenation.** Use **prepared statements** (PDO or
    mysqli with bound parameters).
  - **Validate and sanitise all input** (`$_GET`, `$_POST`, `$_REQUEST`, file uploads).
  - Keep DB credentials/keys in a **Git-ignored config file**, never in tracked code.
  - In production, `display_errors = Off`; log errors instead of showing them.
- Use type declarations and return types where practical; keep functions small.
- If a project is **WordPress**, follow the WordPress Coding Standards and use its APIs
  (`esc_html`, `wp_enqueue_script`, `$wpdb->prepare`, nonces) rather than raw PHP/SQL.

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

# PHP  (needs PHP + Composer + PHP CS Fixer)
vendor/bin/php-cs-fixer fix
```

Both are optional conveniences — `.editorconfig` alone keeps indentation and line endings
consistent with no installation required.
