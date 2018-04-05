<?php
require_once('workflows.php');

$w = new Workflows;

# Navigate to data directory
$data = $w->home() . '/Library/Application\ Support/Alfred\ 2/Workflow\ Data';

# lists all the files inside the data directory
$data_dir = glob("$data" . '/*');


# grab bundle id from project folder
$plist_dir = $query . "/info.plist";

$cmd1 = 'defaults read ' . $plist_dir . ' "bundleid"';
$bundle_id = exec( "$cmd1" );

# Grab the data sub-directory's name to compare to the bundle id
foreach ( $data_dir as $data_subdir )
{
	// grab the end of the file path (the name of bundle_id)
	$data_subdir = basename( $data_subdir ).PHP_EOL;
    
    // if name of data directory matches the bundle_id
	if ( $data_subdir === $bundle_id )
    {
    	$path = $data . '/' . $bundle_id;
    	if ( is_dir( $path ) )
    	{
    		$match = TRUE;
    	}
        else
        {
            $match = FALSE;
        }
    }
}

# Ways to fix some issues
# in_array( $bundle_id, $data_subdir )
# preg_match()


if ( $match = TRUE )
{
	// then open the data directory in Finder
    $cmd = 'open -a Finder ' . $data . '/' . $bundle_id;
    exec( "$cmd" );
} else {
    $match = FALSE;
}

// if ( is_dir( $path ) ) {
//     echo $query;
//     $query = "Sorry! No Data Folder :(";
// }