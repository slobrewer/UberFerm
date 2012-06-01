<?php
	shell_exec("python -u /mnt/uberfridge/uberfridge.py 1>/mnt/uberfridge/stdout.txt 2>>/mnt/uberfridge/stderr.txt &"); 
	shell_exec("rm -f /tmp/uberfridge_dontrun");
?>
