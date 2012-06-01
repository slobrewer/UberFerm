<!DOCTYPE html> 
<html> 
<head> 
  <meta charset="utf-8" /> 
  <title>UberFridge log files</title> 
</head> 
<body style="font-family: Arial;"> 
<button id="refresh-logs" style="float:right">Refresh</button> 
<h3>stderr:</h3>
<div id="stderr" style="background:black; overflow:auto; height:200px; color:white; border-color:#ADD6FF; border-style:ridge; border-width:5px; padding: 10px 10px">
	<?php
	$file = file('/mnt/uberfridge/stderr.txt');
	foreach($file as $line) {
		echo $line . "<br>";
	}
	?>
</div>
<h3>stdout:</h3>
<div id="stdout" style="background:black; overflow:auto; height:200px; color:white; border-color:#ADD6FF; border-style:ridge; border-width:5px; padding: 10px 10px">
	<?php
	$file = file('/mnt/uberfridge/stdout.txt');
	foreach($file as $line) {
		echo $line . "<br>";
	}
	?>
</div>	



<script>
	stderrDiv = document.getElementById("stderr");
	stderrDiv.scrollTop = stderrDiv.scrollHeight;
	stdoutDiv = document.getElementById("stdout");
	stdoutDiv.scrollTop = stdoutDiv.scrollHeight;
	
$("#refresh-logs").button({ icons: {primary: "ui-icon-refresh"}
	}).click(function(){
	 	$('#maintenance-panel').tabs( "load" , 1);
	});		  
</script>

</body> 
</html>
