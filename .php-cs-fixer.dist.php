<?php

/**
 * PHP formatting config - PSR-12 (plus a few modern defaults).
 *
 * Applies to PHP that Claude generates. Requires PHP CS Fixer:
 *     composer require --dev friendsofphp/php-cs-fixer
 *
 *   vendor/bin/php-cs-fixer fix                  # safe default: in-workspace projects only
 *   vendor/bin/php-cs-fixer fix projects/mariart # existing code: ONLY when you ask, by path
 *
 * IMPORTANT: code Claude did not generate (e.g. the linked Mariart plugin) is NOT held to
 * PSR-12. The finder below excludes such folders so a blanket `fix` leaves them untouched.
 * To reformat existing/third-party code on request, pass its path explicitly (a path
 * argument overrides this finder). Add any other linked-in project names to $exclude.
 */

$exclude = [
    'vendor',
    'node_modules',
    'mariart',   // linked-in third-party plugin - keep its own style; format only on request
];

$finder = PhpCsFixer\Finder::create()
    ->in(__DIR__ . '/projects')
    ->name('*.php')
    ->followLinks(false)   // don't descend into linked-in (non-Claude) projects
    ->exclude($exclude);

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
