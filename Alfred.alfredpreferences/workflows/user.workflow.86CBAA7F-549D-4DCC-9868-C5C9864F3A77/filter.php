<?php
/**
 * @todo Make this so that there is an alternate action that allows the workflow
 *       to open the google translate page instead of just copying text.
 *       https://translate.google.com/#auto/en/Testing%20One%20Two%20Three
 */

require_once( 'Alphred.phar' );
require_once( 'languageCodes.php' );
require_once( 'functions.php' );

$alphred = new Alphred([ 'config_handler' => 'json' ]);

$languages = $alphred->config_read( 'languages' );
if ( empty( $languages ) ) {
	$languages = [
		'fr' => 'French',
		'el' => 'Greek',
		'de' => 'German'
	];
	$alphred->config_set( 'languages', $languages );
}

if ( ( ! isset( $argv[1] ) ) || ( empty( $argv[1] ) ) ) {
	$alphred->add_result([
		'title' => 'Type to translate...',
		'valid' => false,
	]);
	$alphred->add_result([
		'title'        => 'Enable / Disable Languages',
		'autocomplete' => '.configure',
		'valid'        => false,
	]);
	print $alphred->to_xml();
	exit(0);
}

if ( 0 === strpos( $argv[1], '.configure' ) ) {
	$filter = trim( str_replace( '.configure', '', $argv[1] ) );

	foreach ( $codes as $code => $name) :
		if ( ! empty( $filter ) ) {
			if ( false !== stripos( $name, $filter ) ) {
				if ( in_array( $name, $languages ) ) {
					$alphred->add_result([
						'title'    => "Disable {$name}",
						'icon'     => 'icons/check.png',
						'valid'    => true,
						'arg'      => json_encode([
														'action' => 'disable',
														'code'   => $code
						              ]),
						'subtitle' => "{$name} ({$code})",
					]);
				} else {
					$alphred->add_result([
						'title'    => "Enable {$name}",
						'icon'     => 'icons/cancel.png',
						'valid'    => true,
						'arg'      => json_encode([
														'action' => 'enable',
														'code'   => $code
		                      ]),
						'subtitle' => "{$name} ({$code})",
					]);
				}
			}
		} else if ( in_array( $name, $languages ) ) {
			$alphred->add_result([
				'title'    => "Disable {$name}",
				'icon'     => 'icons/check.png',
				'valid'    => true,
				'arg'      => json_encode([
												'action' => 'disable',
												'code'   => $code
                      ]),
				'subtitle' => "{$name} ({$code})",
			]);
		} else {
			$alphred->add_result([
				'title'    => "Enable {$name}",
				'icon'     => 'icons/cancel.png',
				'valid'    => true,
				'arg'      => json_encode([
												'action' => 'enable',
												'code'   => $code
				              ]),
				'subtitle' => "{$name} ({$code})",
			]);
		}
	endforeach;

	print $alphred->to_xml();
	exit(0);
}
$text = $argv[1];

foreach ( $languages as $code => $name ) :
	// Construct the very long query.
	$query = construct_query( $text, $code );

	// Grab the information from Google Translate and cache it for about a month.
	$trans = $alphred->get( $query, [ 'user_agent' => 'alfredworkflow' ], 2419200 );

	// Google gives us something that looks like garbled JSON. So, let's fix it.
	$string = fix_garbled_json( $trans );

	$alphred->add_result([
		'title'        => trim( str_replace("\n", ' ', $string) ),
		'subtitle'     => "{$name}: {$text}",
		'icon'         => "icons/{$code}.png",
		'arg'          => json_encode([
												'action'      => 'translate', // This is a generic one
												'translation' => trim( $string ),
												'original'    => $text,
												'code'        => $code,
												'listen'      => urlencode( trim( $string ) ),
                      ]),
		'valid'          => true,
		'subtitle_cmd'   => 'Open in Web Browser',
		'subtitle_alt' 	 => 'Listen to Translation',
	]);
endforeach;

print $alphred->to_xml();
exit(0);