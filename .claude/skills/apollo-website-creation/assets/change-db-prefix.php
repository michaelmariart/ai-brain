<?php

/**
 * Change a WordPress site's database prefix — tables, the option names and usermeta
 * keys that embed the prefix, and wp-config.php.
 *
 * Read db-prefix.md before running this. The collision rule in step 3 is a judgement
 * call about which of two competing rows is the live one, not a mechanical detail.
 *
 * Usage:
 *   php change-db-prefix.php --path="<wp root>" --port=<port> [--new=wp_] [--dry-run]
 *
 * Back up the database first. This script does not.
 */

declare(strict_types=1);

$options = getopt('', ['path:', 'port:', 'new::', 'old::', 'dry-run']);

if (!isset($options['path'], $options['port'])) {
    exit("Usage: php change-db-prefix.php --path=\"<wp root>\" --port=<port> [--new=wp_] [--dry-run]\n");
}

$path   = rtrim((string) $options['path'], '\\/');
$port   = (int) $options['port'];
$new    = (string) ($options['new'] ?? 'wp_');
$dryRun = isset($options['dry-run']);

if (!preg_match('/^[A-Za-z0-9_]+_$/', $new)) {
    exit("Refusing to use '$new' as a prefix: letters, numbers and underscores only, ending in an underscore.\n");
}

$configFile = $path . DIRECTORY_SEPARATOR . 'wp-config.php';

if (!is_readable($configFile)) {
    exit("Cannot read $configFile\n");
}

$config = file_get_contents($configFile);

/**
 * Pull a define() value out of wp-config.php.
 */
function readConstant(string $config, string $name): string
{
    if (!preg_match('/define\s*\(\s*[\'"]' . $name . '[\'"]\s*,\s*[\'"](.*?)[\'"]\s*\)/', $config, $matches)) {
        exit("Could not find $name in wp-config.php\n");
    }

    return $matches[1];
}

$db = new mysqli(
    '127.0.0.1',
    readConstant($config, 'DB_USER'),
    readConstant($config, 'DB_PASSWORD'),
    readConstant($config, 'DB_NAME'),
    $port
);

if ($db->connect_error) {
    exit('Connect failed: ' . $db->connect_error . "\n");
}

// Work out the prefix in use from the options table, unless we were told.
$old = (string) ($options['old'] ?? '');

if ($old === '') {
    $found = [];
    $result = $db->query("SHOW TABLES LIKE '%options'");

    while ($row = $result->fetch_array()) {
        $found[] = substr($row[0], 0, -strlen('options'));
    }

    if (count($found) !== 1) {
        exit("Could not determine the current prefix (found: " . implode(', ', $found) . "). Pass --old=<prefix>.\n");
    }

    $old = $found[0];
}

if ($old === $new) {
    exit("Tables are already on the '$new' prefix. Nothing to do.\n");
}

$cut  = strlen($old) + 1;
$like = str_replace('_', '\_', $old) . '%';

echo "Changing prefix: $old  ->  $new" . ($dryRun ? '   [DRY RUN]' : '') . "\n\n";

// 1. Tables.
$tables = [];
$result = $db->query("SHOW TABLES LIKE '" . str_replace('_', '\_', $old) . "%'");

while ($row = $result->fetch_array()) {
    $tables[] = $row[0];
}

$clashes = $db->query("SHOW TABLES LIKE '" . str_replace('_', '\_', $new) . "%'")->num_rows;

if ($clashes > 0) {
    exit("Aborted: $clashes table(s) already use the '$new' prefix. Resolve by hand.\n");
}

foreach ($tables as $table) {
    $target = $new . substr($table, strlen($old));

    if ($dryRun) {
        echo "  would rename  $table  ->  $target\n";
        continue;
    }

    if (!$db->query("RENAME TABLE `$table` TO `$target`")) {
        exit("Failed renaming $table: " . $db->error . "\n");
    }
}

echo count($tables) . ($dryRun ? ' tables would be renamed.' : ' tables renamed.') . "\n\n";

// From here on the tables carry the new prefix (unless this is a dry run).
$optionsTable  = ($dryRun ? $old : $new) . 'options';
$usermetaTable = ($dryRun ? $old : $new) . 'usermeta';

// 2. Report the collisions before touching anything — see db-prefix.md.
$result = $db->query(
    "SELECT o.option_name FROM `$optionsTable` o
     JOIN `$optionsTable` n ON n.option_name = CONCAT('$new', SUBSTRING(o.option_name, $cut))
     WHERE o.option_name LIKE '$like'"
);

while ($row = $result->fetch_array()) {
    echo "  stale duplicate (a live '$new' twin exists, old copy dropped): {$row[0]}\n";
}

if ($dryRun) {
    echo "\nDry run — no changes made, and wp-config.php not touched.\n";
    exit(0);
}

// 3. Options: drop the stale copy where a live twin exists, rename the rest.
$db->query(
    "DELETE o FROM `$optionsTable` o
     JOIN `$optionsTable` n ON n.option_name = CONCAT('$new', SUBSTRING(o.option_name, $cut))
     WHERE o.option_name LIKE '$like'"
);
echo $db->affected_rows . " stale duplicate options deleted.\n";

$db->query(
    "UPDATE `$optionsTable`
     SET option_name = CONCAT('$new', SUBSTRING(option_name, $cut))
     WHERE option_name LIKE '$like'"
);
echo $db->affected_rows . " option names updated.\n";

// 4. Usermeta: same rule, per user.
$db->query(
    "DELETE o FROM `$usermetaTable` o
     JOIN `$usermetaTable` n ON n.user_id = o.user_id
          AND n.meta_key = CONCAT('$new', SUBSTRING(o.meta_key, $cut))
     WHERE o.meta_key LIKE '$like'"
);
echo $db->affected_rows . " stale duplicate usermeta rows deleted.\n";

$db->query(
    "UPDATE `$usermetaTable`
     SET meta_key = CONCAT('$new', SUBSTRING(meta_key, $cut))
     WHERE meta_key LIKE '$like'"
);
echo $db->affected_rows . " usermeta keys updated.\n";

// 5. wp-config.php.
$updated = preg_replace(
    '/(\$table_prefix\s*=\s*)[\'"].*?[\'"]\s*;/',
    "$1'" . $new . "';",
    $config,
    1,
    $count
);

if ($count === 1 && $updated !== null) {
    file_put_contents($configFile, $updated);
    echo "wp-config.php \$table_prefix set to '$new'.\n";
} else {
    echo "WARNING: could not update \$table_prefix in wp-config.php — set it to '$new' by hand.\n";
}

echo "\nDone. Now verify through WordPress: core is-installed, user list (roles!), and a front-end 200.\n";
