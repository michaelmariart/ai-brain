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

Handled by `.editorconfig` and `.prettierrc.json`. **PHP is styled by hand** to the
house conventions in §8 — no PHP auto-formatter is used:

| | Setting |
|---|---|
| Indentation | **2 spaces** (HTML/CSS/JS/JSON) · **4 spaces** (PHP — Mariart house style, see §8) |
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

## 8. PHP — Mariart house style

PHP follows the established style of the **Mariart WordPress plugin**
(`…/wp-content/plugins/mariart`). It is a deliberate, bespoke style — **not** PSR-12 and
**not** the default WordPress standard. **Do not run an auto-formatter on PHP** (PHP CS
Fixer / Prettier would strip these conventions). When editing existing files, match the
file you are in — including its indentation and line endings.

**Layout & structure**
- **4-space indentation**, no tabs. The whole file body is indented one level beneath the
  opening `<?php`.
- One class per file; the filename matches the class. Namespaced under `Mariart\…` and
  autoloaded from `library/`.
- Opening brace on the **same line** (`class Foo {`, `function bar () {`, `if (…) {`).
- `else` / `elseif` go on their **own line** after the closing brace — never cuddled.
- Annotate every closing brace with what it closes: `} // methodName ()`, `} // if ()`,
  `} // class Foo`.
- Generous vertical spacing (about three blank lines between methods).
- PHPDoc `/** … */` on classes, methods and properties.

**Spacing — the signature of this style**
- A **space before every `(`** — calls, definitions and control structures alike:
  `function register ()`, `add_action ('init', …)`, `if (empty ($x) === true)`.
- A **space before `[`** on array access: `$args ['key']`.
- No spaces just inside `( … )`; no spaces around the `.` concatenation operator: `$name.'s'`.

**Syntax & naming**
- **Long array syntax**: `array ( 'a' => 1 )`, not `[]`.
- **Single quotes** by default.
- Explicit boolean comparisons: `empty ($x) === true`, `… === false`.
- Classes `PascalCase`; methods `camelCase`; functions & local variables `snake_case`;
  constants `UPPER_SNAKE`.
- Private/protected properties **and** methods are prefixed with `_`: `$_slug`, `_init ()`.
- Singletons use the `Singleton` trait: `use Singleton;` + `getInstance ()`, with setup done
  in `_init ()`.

**WordPress & templates**
- Use WordPress APIs (`add_action`, `register_post_type`, `__ ()`, `_x ()`, `$wpdb->prepare`).
- Templates open with the guard `if (!defined ('ABSPATH')) { die (); }` and a `@var` docblock
  for the variables passed in.
- In templates use the **alternative syntax** (`foreach (…): … endforeach;`, `if (…): … endif;`).
- **Escape on output**: `esc_html ()`, `esc_attr ()`, `esc_url ()`, `wp_kses_post ()`.

**Security — non-negotiable**
- Escape all output; never trust `$_GET` / `$_POST` / `$_FILES` — validate and sanitise.
- Use `$wpdb->prepare ()` or WP query APIs — never concatenate SQL.
- Use nonces on forms and admin actions; keep credentials out of tracked code.

**Example**

```php
<?php
    namespace Mariart;

    class Example {

        /**
         *  @var string The item slug.
         */
        private $_slug;


        /**
         *  Register our hooks.
         */
        public function register () {
            if (empty ($this->_slug) === true) {
                return;
            } // if ()
            else {
                add_action ('init', array ($this, 'load'));
            } // else
        } // register ()

    } // class Example
```

> Legacy note: a little older code (e.g. one method in `Util.php`) uses tabs and double
> quotes. That's drift, not the standard — follow the 4-space / single-quote style above.

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
```

Prettier is an optional convenience — `.editorconfig` alone keeps indentation and line
endings consistent with no installation required. **Do not point Prettier or PHP CS Fixer
at PHP files** — the Mariart house style (§8) is intentionally not auto-formatter-friendly.
