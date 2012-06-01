<?php
$fh = fopen("/mnt/uberfridge/settings/currentBeerName.txt", 'r') or die("can't open current beer name file");
$beerName = fgets($fh);
fclose($fh);
?>
<!DOCTYPE html >
<html>
	<head>
		<meta http-equiv="content-type" content="text/html; charset=utf-8" />
		<title>UberFridge reporting for duty!</title>
		<link type="text/css" href="css/redmond/jquery-ui-1.8.16.custom.css" rel="stylesheet" />
		<link rel="stylesheet" href="css/style.css" />
		<script type="text/javascript" src="js/jquery-1.6.2.min.js"></script>
		<script type="text/javascript" src="js/jquery-ui-1.8.16.custom.min.js"></script>
		<script type="text/javascript" src="http://www.google.com/jsapi"></script>
		<script type="text/javascript" src="js/main.js"></script>
		<script type="text/javascript" src="js/control-panel.js"></script>
		<script type="text/javascript" src="js/beer-chart.js"></script>

		<script type="text/javascript">
		
		function refreshBeerChart(){
				drawBeerChart(<?php echo "\"" . $beerName . "\""; ?>, "beer-chart" );
		}

	
		</script>
	</head>
	<body>
		<div id="beer-panel" class="ui-widget ui-widget-content ui-corner-all">
			<div id="top-bar" class="ui-widget ui-widget-header ui-corner-all">
				<div id="lcd" class="lcddisplay"><br>Live display<br>Waiting to update..</div>
				<div id="logo-container">
					<img src="logo.png">
					<br>
					<span id="beername">Fermenting: <?php echo $beerName;?></span>
				</div>
				<button class="script-status ui-state-error"></button>
				<button id="maintenance">Maintenance panel</button>
			</div>
			<div id="beer-chart" style="width:900px;	height:400px;"></div>
			<button id="refresh-beer-chart"></button>
		</div>
		
		<div id="control-panel">
			<ul>
				<div id="control-bar-text">
					<div id="set-mode-text">Set temperature mode:</div>
					<div id="status-text">Status:</div>
				</div>
				<li><a href="#profile_control"><span>Beer profile</span></a></li>
				<li><a href="#beer_constant_control"><span>Beer constant</span></a></li>
				<li><a href="#fridge_constant_control"><span>Fridge constant</span></a></li>
				<button id="apply-settings">Apply</button>
				<div id="status-message" class="ui-state-error ui-corner-all">
					<p>
						<span id="icon" class="ui-icon ui-icon-alert" style="float: left; margin-right: .3em;"></span>
						<span id="message">Not loaded</span> 
					</p>
				</div>
			</ul>
			<div id="profile_control">
				<div id="controls">
					<button id="refresh">Refresh</button>
					<button id="edit">Edit profile</button>
					<button id="apply">Upload Profile</button>
				</div>
				<div id="profileTableDiv"></div>
				<div id="profileChartDiv" style="width: 400px;	height: 280px;"></div>
			</div>
			<div id="beer_constant_control">
				<div id="beer-temp" class="temp-display">
					<div class="temp-container"><span class="temperature"></span></div>
					<button id="beer-temp-up" class="temp-up"></button>
					<span class="degree">&deg;C</span>
					<button id="beer-temp-down" class="temp-down"></button>
				</div>
			</div>
			<div id="fridge_constant_control">
				<div id="fridge-temp" class="temp-display">
					<div class="temp-container"><span class="temperature"></span></div>
					<button id="fridge-temp-up" class="temp-up"></button>
					<span class="degree">&deg;C</span>
					<button id="fridge-temp-down" class="temp-down"></button>
				</div>
			</div>	
					
		</div>
		
		<div id="maintenance-panel" style="overflow:auto; padding-bottom: 10px;">
			<ul>
				<li><a href="#settings"><span>Settings</span></a></li>
				<li><a href="logs.php"><span>Log files</span></a></li>
				<li><a href="previous_beers.php"><span>Previous Beers</span></a></li>
				<li><a href="#reprogram-arduino"><span>Reprogram Arduino</span></a></li>
				<!--kinda dirty to have buttons in the ul, but the ul is styled as a nice header by jQuery UI --> 
				<button class="script-status"</button> 	
			</ul>	
				<div id="reprogram-arduino">
					<div id="script-warning" class="ui-widget-content ui-corner-all" style="padding:5px;">
						<p>Verify that script is not running before uploading new firmware!</p>
						<div style="padding: 15px 0;">
							<form action="program_arduino.php" method="post" enctype="multipart/form-data">
								<label for="file">Filename:</label>
								<input type="file" name="file" id="file" /> <!-- add max file size-->
								<input type="submit" name="Program" value="Program" />
							</form>
						</div>
					</div>
				</div>
			<div id="settings">
				<div id="settings-container" class="ui-widget-content ui-corner-all">
					<div class="setting-container">
						<span>Interval between data points for logging:</span>
						<select id="interval">	
						  <option value="30">30 Seconds</option>
						  <option value="60">1 Minute</option>
						  <option value="120">2 Minutes</option>
						  <option value="300">5 Minutes</option>
						  <option value="600">10 Minutes</option>
						  <option value="1800">30 Minutes</option>
						  <option value="3600">1 hour</option>
						</select> 
						<button id="apply-interval" class="apply">Apply</button>
					</div>
					<div class="setting-container">
						<span>Start new beer:</span>
						<input id="beer-name" value="Enter new or existing name.." size=30 type="text">
						<button id="apply-beer-name" class="apply">Apply</button>
					</div>
				</div>
			</div>
		</div>
	</body>
</html>
