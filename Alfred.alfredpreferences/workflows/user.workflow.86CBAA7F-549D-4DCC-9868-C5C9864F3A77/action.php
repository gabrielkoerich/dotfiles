<?php

require_once( 'Alphred.phar' );
require_once( 'languageCodes.php' );

$args = json_decode( $argv[1], true );

$alphred = new Alphred([ 'config_handler' => 'json' ]);
$languages = $alphred->config_read( 'languages' );

if ( in_array( $args['action'], [ 'enable', 'disable' ] ) ) {
	$code = $args['code'];
	$name = $codes[ $code ];

	if ( $args['action'] == 'enable' ) {
		if ( ! in_array( $name, $languages ) ) {
			$languages[ $code ] = $name;
		}
	} else if ( $args['action'] == 'disable' ) {
		if ( in_array( $name, $languages ) ) {
			unset( $languages[ $code ] );
		}
	}
	$alphred->config_set( 'languages', $languages );
} else {
	print $args['translation'];
}