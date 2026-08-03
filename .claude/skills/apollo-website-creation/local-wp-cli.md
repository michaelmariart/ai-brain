# Running WP-CLI and MySQL against a Local (Flywheel) site

Nothing is on `PATH` on this machine, and Local's bundled WP-CLI needs three separate
overrides before it will connect. Each failure looks unrelated to the real cause.

```powershell
$base = "C:\Users\michael\AppData\Roaming\Local\lightning-services\php-8.2.29+0\bin\win64"
$php  = "$base\php.exe"
$wp   = "C:\Program Files (x86)\Local\resources\extraResources\bin\wp-cli\wp-cli.phar"

& $php -d extension_dir="$base\ext" -d extension=mysqli $wp `
    --path="<site>\app\public" --require="<db-override>.php" <command>
```

## The three traps

1. **Use the PHP under `AppData\Roaming\Local`, not the one under
   `C:\Program Files (x86)\Local`.** PHP's `-d` parser chokes on the `(x86)` parentheses
   and reports a bogus `syntax error, unexpected '('`.
2. **Load mysqli explicitly** with `-d extension_dir=... -d extension=mysqli`. The CLI
   does not read Local's `php.ini`, so without it WordPress reports the MySQL extension
   as missing.
3. **Override `DB_HOST`.** `wp-config.php` says `localhost`, which works for the site's
   own PHP-FPM but not for an external process. Put it in a file loaded via `--require`,
   which wins because `wp-config.php`'s later `define()` then no-ops:

   ```php
   <?php
   define( 'DB_HOST', '127.0.0.1:<port>' );
   ```

   It emits a harmless `Constant DB_HOST already defined` warning on every command.

## Finding the port

Per-site, assigned by Local, and it changes whenever a site is recreated.

1. Get the site id from `%APPDATA%\Local\sites.json` (match on the site path).
2. Read `port` from `%APPDATA%\Local\run\<site-id>\conf\mariadb\my.cnf` — or
   `...\conf\mysql\my.cnf` on older sites. Which one exists depends on the database
   engine the site was created with, so search the folder rather than assuming.

The `conf/` folder inside the site directory itself holds only `.hbs` templates, not
real values.

## Querying the database directly

`wp db query` shells out to the `mysql` client, which is also not on `PATH` — it will
not work. Two ways round it:

- `wp eval-file <script.php>` to query through WordPress.
- A standalone PHP script using mysqli, run with the same PHP invocation above. This is
  the only option when WordPress won't boot (e.g. mid prefix change).

The MariaDB client binaries do exist if you need them directly:

```
C:\Users\michael\AppData\Roaming\Local\lightning-services\mariadb-10.6.23+0\bin\win32\bin\
```

(`mysqldump.exe`, `mariadb-dump.exe`.) Check the version folder actually present before
using it.

## PowerShell note

Native executables writing to stderr — `git push`, and WP-CLI's warnings — surface as a
red `NativeCommandError` even on success. Check the exit code or the actual output
before reporting a failure.
