<?php

/**
 * Optional PHP formatting config — enforces PSR-12.
 *
 * This file only does something if you install PHP CS Fixer:
 *     composer require --dev friendsofphp/php-cs-fixer
 * Then run:
 *     vendor/bin/php-cs-fixer fix
 *
 * It's safe to delete if you don't use PHP tooling — the .editorconfig still
 * keeps PHP indentation and line endings consistent on its own.
 */

$finder = PhpCsFixer\Finder::create()
    ->in(__DIR__ . '/projects')
    ->name('*.php')
    ->exclude(['vendor', 'node_modules']);

return (new PhpCsFixer\Config())
    ->setRiskyAllowed(false)
    ->setRules([
        '@PSR12' => true,
        'array_syntax' => ['syntax' => 'short'],
        'single_quote' => true,
        'no_unused_imports' => true,
        'ordered_imports' => true,
        'trailing_comma_in_multiline' => true,
        'no_trailing_whitespace' => true,
        'single_blank_line_at_eof' => true,
    ])
    ->setFinder($finder);
