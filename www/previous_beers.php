<!DOCTYPE html> 
<html> 
<head> 
  <meta charset="utf-8" /> 
  <title>UberFridge: previous beers</title> 
  
</head> 
<body> 

<div id="beer-selector">
	<span>Select the beer you would like to view:</span>
	<select id="prev-beer-name">
		<?php
		foreach(glob('data/*', GLOB_ONLYDIR) as $dir)
		{
		    $dir = basename($dir);
		    echo '<option value="', $dir, '">', $dir, '</option>';
		}  
		
		?>	
	</select>
	<button id="prev-beer-show">Show</button>
	<button id="download-csv">Download CSV</button>		
</div>
<div id="prev-beer-chart" style="width:900px;	height:400px;"></div>	

<script>
	$("button#prev-beer-show").button({ icons: {primary: "ui-icon-circle-triangle-e"} }).click(function(){
	 	drawBeerChart(String($("select#prev-beer-name").val()), "prev-beer-chart" );
	});
	$("button#download-csv").button({ icons: {primary: "ui-icon-arrowthickstop-1-s"} }).click(function(){
		var url = "data/" + String($("select#prev-beer-name").val()) + "/" + String($("select#prev-beer-name").val()) + ".csv";
	 	
	 	window.open(encodeURI(url), 'Download CSV' );
	});				
</script>


</body> 
</html>
