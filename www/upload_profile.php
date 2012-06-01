<?php
	$output1 = shell_exec("wget -nv -O /mnt/uberfridge/settings/tempprofile.csv  \"http://spreadsheets.google.com/tq?key=0AgHYRKRROsRFdHQ2d0c4RkROQUtOV3lZbHFfRVV1N1E&tq=select D,E&tqx=out:csv\" 2>&1");
	$output2 = shell_exec("cp /mnt/uberfridge/settings/tempprofile.csv /mnt/uberfridge/settings/currentprofile.csv 2>&1");
	echo "Profile copied, wget output:" . $output1 . $output2;
?>