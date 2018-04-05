<?php

function construct_query( $text, $code ) {
	$query =  "http://translate.google.com/translate_a/single?client=json&ie=UTF-8&oe=UTF-8";
	$query .= "&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t&dt=at";
	$query .= "&q=" . urlencode( $text );
	$query .= "&hl=en&sl=auto&";
	$query .= "tl=" . $code;
	return $query;
}

function fix_garbled_json( $trans ) {
	// Google gives us something that looks like garbled JSON. So, let's fix it.
	while ( false !== strpos( $trans, '[,' ) ) :
		$trans = str_replace( '[,', '[null,', $trans );
	endwhile;
	while ( false !== strpos( $trans, ',,' ) ) :
		$trans = str_replace( ',,', ',null,', $trans );
	endwhile;
  $trans = json_decode( $trans, true );
	$string = '';
	foreach ( $trans[0] as $t ) :
		$string .= trim( $t[0] ) . ' ';
	endforeach;

	return $string;
}



