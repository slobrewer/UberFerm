<!DOCTYPE html> 
<head>  
  <title>UberFridge programming arduino!</title> 
</head> 
<body style="font-family: Arial;border: 0 none;"> 

<?php
if ($_FILES["file"]["error"] > 0)
  {
  echo "Error: " . $_FILES["file"]["error"] . "<br />";
  }
else
  {
  echo "Uploaded <b>" . $_FILES["file"]["name"] . "</b> to the Arduino with avrdude";
  echo " (size: " . ($_FILES["file"]["size"] / 1024) . " Kb)<br />";
  }
?>

<br />
<h3> avrdude output: <h3>
<?php
$filename = $_FILES["file"]["tmp_name"];
$file = escapeshellcmd($filename);
$output = shell_exec("LD_LIBRARY_PATH=\"\" avrdude -p m328p -c arduino -b 57600 -P /dev/usb/tts/0 -C /opt/etc/avrdude.conf -U flash:w:".trim($file)." 2>&1"); 
?>
<div style="background-color:black; color:white; border-color:#ADD6FF; border-style:ridge; border-width:5px; padding: 10px 10px">
<?php
echo "<pre>$output</pre>";
?> 
</div>

</body> 
</html>
