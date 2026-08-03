<?php
	/**
	 *	Set up our theme.
	 */

	namespace Mariart\Theme\{{NAMESPACE}};

	if (!defined ('ABSPATH')) {
		die ();
	} // if ()


	define ('MARIART_THEME_{{CONST_PREFIX}}_BASE_URI', __DIR__);
	define ('MARIART_THEME_{{CONST_PREFIX}}_BASE_URL', get_stylesheet_directory_uri ());
