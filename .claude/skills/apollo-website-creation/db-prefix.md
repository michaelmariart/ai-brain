# Forcing the database prefix to `wp_`

Every Apollo site runs on the `wp_` prefix. Cloned sites frequently don't — they arrive
carrying the previous client's prefix (e.g. `tenterfieldcare_`), sometimes with
`wp-config.php` and the tables disagreeing with each other.

**Symptom of a mismatch:** WordPress reports itself as *not installed* and redirects
everything to the installer, even though the content is all there.

## What actually has to change

A prefix change is four things, not one. Miss any of them and the site half-works.

| # | What | Why |
|---|---|---|
| 1 | Every `<old>_*` **table** | The obvious one. |
| 2 | **Option names** that embed the prefix — above all `<old>_user_roles` | Lose this and every role definition vanishes. |
| 3 | **Usermeta keys** that embed the prefix — `<old>_capabilities`, `<old>_user_level`, `<old>_user-settings`, `<old>_user-settings-time`, `<old>_dashboard_quick_press_last_post_id`, `<old>_persisted_preferences`, plus Yoast's `<old>_wpseo-*` and `<old>_yoast_notifications` | Lose these and every user silently drops to no role. |
| 4 | `$table_prefix` in **`wp-config.php`** | Check it — on a clone it may already be `wp_` while the tables are not. |

## The trap: names that only *look* like a prefix

Some option names start with `wp_` as part of their own name, nothing to do with the
table prefix:

- `wp_attachment_pages_enabled`, `wp_calendar_block_has_published_posts` (WordPress core)
- `wp_smush_*` (the Smush plugin)

A naive earlier prefix change renames these to `<old>_smush_*` and friends. Core and the
plugins then simply recreate the correct `wp_`-named option alongside them. So when
changing back to `wp_` you hit **duplicate key errors** on `option_name`, and you have
two rows with a legitimate claim to the same name.

**The rule:** where a `wp_` twin already exists, the twin is the live value — it is what
core or the plugin has been reading and writing all along. **Delete the `<old>_` copy;
never overwrite the twin.** Where there is no twin, rename normally.

Sanity-check this rather than trusting it blindly — compare the two values before
deleting. The stale copy is usually visibly older (e.g. a `plugin_installed` timestamp
against the twin's much later `plugin_upgraded`).

The same collision can in principle occur in usermeta, per user; apply the same rule.

## Procedure

### 1. Back up first — always

```powershell
$dump = "C:\Users\michael\AppData\Roaming\Local\lightning-services\mariadb-10.6.23+0\bin\win32\bin\mysqldump.exe"
& $dump --host=127.0.0.1 --port=<port> --user=root --password=root --single-transaction --routines --events local > backup-before-prefix-change.sql
```

Write it somewhere durable, not a session temp folder. Find `<port>` per
[local-wp-cli.md](local-wp-cli.md).

### 2. Look before you leap

Confirm what you are actually dealing with:

- `SHOW TABLES` — what is the real current prefix?
- `SHOW TABLES LIKE 'wp\_%'` — is anything already on the target prefix?
- The `$table_prefix` line in `wp-config.php` — does it agree with the tables?
- Which option names and usermeta keys carry the old prefix, and which of those already
  have a `wp_` twin.

### 3. Run the change

```bash
php assets/change-db-prefix.php --path="C:\Users\michael\Local Sites\<site>\app\public" --port=<port> --dry-run
```

Read the plan, then re-run without `--dry-run`. It renames the tables, applies the
collision rule to options and usermeta, and updates `wp-config.php`.

Run it with Local's PHP and mysqli loaded — see [local-wp-cli.md](local-wp-cli.md).

### 4. Verify through WordPress

Database counts alone don't prove the site works:

```
wp core is-installed                          # exit 0
wp option get home
wp user list --fields=ID,user_login,roles     # roles must still be populated
```

Then load the front end and confirm HTTP 200. Roles are the test that matters — they
depend on `wp_user_roles` *and* `wp_capabilities` both being right.

### 5. Expect two harmless leftovers

Option **values** (not names) can still mention the old prefix:

- `bsr_data` — Better Search Replace's remembered form state. Repopulates on next use.
- `bvruleset` — a BlogVault/MalCare firewall ruleset. Regenerates.

Neither affects the site. Mention them; don't chase them.
