<?php
	error_reporting(E_ALL ^ E_WARNING);
	$messageType = $_POST["messageType"];
	$data = $_POST["message"];

	$sock = open_socket();
	if($sock){
		switch($messageType){
			case "checkScript":
				socket_write($sock, "ack", 1024);
				$answer = socket_read($sock, 1024);
				if($answer = "ack"){
					echo 1;
				}
				else{
					echo 0;
				}
				break;
			case "getmode":
				socket_write($sock, "mode", 1024);
				switch(socket_read($sock, 1024)){
					case "profile":
						echo 1;
						break;
					case "beer":
						echo 2;
						break;
					case "fridge":
						echo 3;
						break;
					default:
						echo "\"error\"";
				}
				break;
			case "setprofile":
				socket_write($sock, "profile", 1024);
				break;
			case "setbeer":
				$modestring = "b" . $data;
				socket_write($sock, $modestring, 1024);
				break;
			case "setfridge":
				$modestring = "f" . $data;
				socket_write($sock, $modestring, 1024);
				break;
			case "stopscript":
				socket_write($sock, "quit", 1024);
				break;
			case "lcd":
				socket_write($sock, "lcd", 1024);
				$lcdText = socket_read($sock, 1024);
				echo str_replace(chr(0xDF), "&deg;", $lcdText);
				break;
			case "interval":
				$modestring = "i" . $data;
				socket_write($sock, $modestring, 1024);
				break;
			case "name":
				$modestring = "n" . $data;
				socket_write($sock, $modestring, 1024);
				break;
			case "gettemp":
				socket_write($sock, "temperature", 1024);
				echo socket_read($sock, 1024);
				break;					
		}
		socket_close($sock);
	}
	else{
		echo false;
	}
?>
<?php
function open_socket()
{
	$sock = socket_create(AF_UNIX, SOCK_STREAM, 0);
	if ($sock === false) {
    return false;
	}	
	else {
		if(socket_connect($sock, '/tmp/BEERSOCKET')){
			socket_set_option($sock, SOL_SOCKET, SO_RCVTIMEO, array('sec' => 15, 'usec' => 0));
			return $sock;	
		}
		else{
			return false;
		}
	}
}
?>
