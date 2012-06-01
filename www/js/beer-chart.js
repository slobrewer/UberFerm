/* Give name of the beer to display and div to draw the graph in */
function drawBeerChart(beerName, div){ 
	var beerChart;
	var beerData;
	    
	$.post("get_beer_files.php", {"beername": beerName}, function(answer){
		var combinedJson;
		var first = true;
		var files = eval(answer);
		//document.write(files);
		//alert(fileNames.length);
		
		for(i=0;i<files.length;i++){
			
			filelocation = files[i];
			var jsonData = $.ajax({
					url: filelocation,
					dataType:"json",
		    		async: false
	      			}).responseText;
      		var evalledJsonData = eval("("+jsonData+")");
			//document.write(jsonData + "<br>");
			if(first){ 
				combinedJson = evalledJsonData;
				first = false;
			}
			else{
				combinedJson.rows  = combinedJson.rows.concat(evalledJsonData.rows);
			}
		}
		var beerData = new google.visualization.DataTable(combinedJson);
		var beerChart = new google.visualization.AnnotatedTimeLine(document.getElementById(div));
    	beerChart.draw(beerData, {
               'displayAnnotations': true,
               'scaleType': 'maximized',
               'displayZoomButtons': false,
               'allValuesSuffix': "\u00B0 C",
               'numberFormats': "##.0",
              'displayAnnotationsFilter' : true});
	});	
}
