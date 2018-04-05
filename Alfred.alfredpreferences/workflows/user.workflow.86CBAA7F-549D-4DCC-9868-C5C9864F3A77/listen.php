<?php
// Instructions on getting audio from Google Translate
// https://gist.github.com/alotaiba/1728771

require_once( 'Alphred.phar' );
require_once( 'languageCodes.php' );
require_once( 'functions.php' );

$args = json_decode( $argv[1], true );

// Download the file and feed `afplay` the filename
$audio_file = get_audio( $args['translation'], $args['code'] );
exec( "afplay '{$audio_file}'" );

function construct_listen_query( $text, $code ) {
	// I.e. "http://translate.google.com/translate_tts?ie=UTF-8&client=t&tl=en&q=hello+world"
	return "http://translate.google.com/translate_tts?ie=UTF-8&client=t&tl={$code}&q=" . urlencode( $text );
}

// Grabs the audio using an Alphred download request
function get_audio( $text, $code ) {
	$alphred = new Alphred([ 'config_handler' => 'json' ]);
	// Download the file and return the filename
	return $alphred->download( construct_listen_query( $text, $code ), [ 'user_agent' => 'alfredworkflow' ], 86400 );
}