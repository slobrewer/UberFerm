function drawProfileChartAndTable() {
	drawProfileChart();
	drawProfileTable();
}

function drawProfileChart() {
  	var query = new google.visualization.Query('https://docs.google.com/spreadsheet/tq?range=D:E&key=0AgHYRKRROsRFdHQ2d0c4RkROQUtOV3lZbHFfRVV1N1E&gid=0');
    query.send(handleProfileChartQueryResponse);    
}
function handleProfileChartQueryResponse(response) {
  if (response.isError()) {
    alert('Error in query: ' + response.getMessage() + ' ' + response.getDetailedMessage());
    return;
  }
	var profileData = response.getDataTable();
	profileChart = new google.visualization.AnnotatedTimeLine(document.getElementById('profileChartDiv'));
 	profileChart.draw(profileData, {
           'displayAnnotations': true,
           'scaleType': 'maximized',
           'displayZoomButtons': false,
           'allValuesSuffix': "\u00B0 C",
           'numberFormats': "##.0",
          'displayAnnotationsFilter' : true});
}

function drawProfileTable() {
  	var query = new google.visualization.Query('https://docs.google.com/spreadsheet/tq?range=C:E&where=D<date "2070-01-01"&key=0AgHYRKRROsRFdHQ2d0c4RkROQUtOV3lZbHFfRVV1N1E&gid=0');
    query.send(handleProfileTableQueryResponse);    
}
function handleProfileTableQueryResponse(response) {
  if (response.isError()) {
    alert('Error in query: ' + response.getMessage() + ' ' + response.getDetailedMessage());
    return;
  }
	var profileData = response.getDataTable();
	var profileTable = new google.visualization.Table(document.getElementById('profileTableDiv'));
 	profileTable.draw(profileData,null);
}

function statusMessage(messageType, messageText){
	$("#status-message").removeClass("ui-state-error ui-state-default ui-state-highlight");
	$("#status-message p span#icon").removeClass("ui-icon-error ui-icon-check ui-icon-info");
	switch(messageType){
		case "normal":
				$("#status-message p span#icon").addClass("ui-icon-check");
				$("#status-message").addClass("ui-state-default");
			break;
		case "error":	
				$("#status-message p span#icon").addClass("ui-icon-error");
				$("#status-message").addClass("ui-state-error");
			break;
		case "highlight":
				$("#status-message p span#icon").addClass("ui-icon-info");
				$("#status-message").addClass("ui-state-highlight");
				$("#status-message").addClass( "ui-state-highlight");
			break;	
	}
	$("#status-message p span#message").text(messageText);
}	
