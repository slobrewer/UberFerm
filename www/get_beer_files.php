<?php	
	$beerName = $_POST["beername"];
	$fileNames = array();
  	$currentBeerDir = 'data/' . $beerName;
  	$handle = opendir($currentBeerDir);
  	$first = true;
  	$i=0;
  	while (false !== ($file = readdir($handle))){  // iterate over all json files in directory
		  $extension = strtolower(substr(strrchr($file, '.'), 1));
		  if($extension == 'json' ){
		  	$jsonFile =  $currentBeerDir . '/' . $file;
				$filenames[$i] = $jsonFile;
				$i=$i+1;
			}
		}
		closedir($handle);
		if(empty($filenames)){
			echo "";
		}
		else{
			echo json_encode($filenames);
		}
?>