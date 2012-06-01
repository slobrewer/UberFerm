prevScriptStatus=-1;
beerTemp=200; //only used for control panel
fridgeTemp=50; //only used for control panel	

$(document).ready(function(){
	
	//Control Panel
	$('#control-panel').tabs();
	
	$("#controls button#refresh").button({ 	icons: {primary: "ui-icon-arrowrefresh-1-e"}	}).click(function(){
			drawProfileChartAndTable();
		});		
	
	$("#controls button#edit").button({	icons: {primary: "ui-icon-wrench" } }).click(function(){
			window.open("https://docs.google.com/spreadsheet/ccc?key=0AgHYRKRROsRFdHQ2d0c4RkROQUtOV3lZbHFfRVV1N1E");
		});
	
	$("#controls button#apply").button({ icons: {primary: "ui-icon-arrowthickstop-1-n"}
	}).click(function(){
		$.post('upload_profile.php', function(answer) {
			statusMessage("highlight","Profile uploaded");
		});
	});
		
	$("button#apply-settings").button({ icons: {primary: "ui-icon-check"}
	}).click(function(){
	 	applySettings();
	});
		
	//Constant beer temperature control buttons
	$("#beer-temp span.temperature").text(String((beerTemp/10).toFixed(1)));
	$("#fridge-temp span.temperature").text(String((fridgeTemp/10).toFixed(1)));
	
	$("button#beer-temp-up").button({ 	icons: {primary: "ui-icon-triangle-1-n"}	}).bind({
		mousedown: function() {
			beerTemp=(beerTemp+1)%300; //keep bewteen 0 and 30.0 degrees
			$("#beer-temp span.temperature").text(String((beerTemp/10).toFixed(1)));
			beerTempUpTimeOut = window.setInterval(function(){
				beerTemp=(beerTemp+1)%300; //keep bewteen 0 and 30.0 degrees
				$("#beer-temp span.temperature").text(String((beerTemp/10).toFixed(1)));
			}, 100);
		},
		mouseup: function(){
			if(typeof(beerTempUpTimeOut)!='undefined')
				clearInterval(beerTempUpTimeOut);
		},
		mouseleave: function(){
			if(typeof(beerTempUpTimeOut)!='undefined')
				clearInterval(beerTempUpTimeOut);
		}
		});

	$("button#beer-temp-down").button({ 	icons: {primary: "ui-icon-triangle-1-s"}	}).bind({
		mousedown: function() {
			beerTemp=(beerTemp+299)%300; //keep bewteen 0 and 30.0 degrees
			$("#beer-temp span.temperature").text(String((beerTemp/10).toFixed(1)));
			beerTempDownTimeOut = window.setInterval(function(){
				beerTemp=(beerTemp+299)%300; //keep bewteen 0 and 30.0 degrees
				$("#beer-temp span.temperature").text(String((beerTemp/10).toFixed(1)));
			}, 100);
		},
		mouseup: function(){
			if(typeof(beerTempDownTimeOut)!='undefined')
				clearInterval(beerTempDownTimeOut);
			
		},
		mouseleave: function(){
			if(typeof(beerTempDownTimeOut)!='undefined')
				clearInterval(beerTempDownTimeOut);
		}
		});	
		
	//Constant fridge temperature control buttons
	$("button#fridge-temp-up").button({ 	icons: {primary: "ui-icon-triangle-1-n"}	}).bind({
		mousedown: function() {
			fridgeTemp=(fridgeTemp+301)%300; //keep bewteen 0 and 30.0 degrees
			$("#fridge-temp span.temperature").text(String((fridgeTemp/10).toFixed(1)));
			fridgeTempUpTimeOut = window.setInterval(function(){
				fridgeTemp=(fridgeTemp+301)%300; //keep bewteen 0 and 30.0 degrees
				$("#fridge-temp span.temperature").text(String((fridgeTemp/10).toFixed(1)));
			}, 100);
		},
		mouseup: function(){
			if(typeof(fridgeTempUpTimeOut)!='undefined')
				clearInterval(fridgeTempUpTimeOut);
		},
		mouseleave: function(){
			if(typeof(fridgeTempUpTimeOut)!='undefined')
				clearInterval(fridgeTempUpTimeOut);
		}
		});	
	$("button#fridge-temp-down").button({ 	icons: {primary: "ui-icon-triangle-1-s"}	}).bind({
		mousedown: function() {
			fridgeTemp=(fridgeTemp+299)%300; //keep bewteen 0 and 30.0 degrees
			$("#fridge-temp span.temperature").text(String((fridgeTemp/10).toFixed(1)));
			fridgeTempDownTimeOut = window.setInterval(function(){
				fridgeTemp=(fridgeTemp+299)%300; //keep bewteen 0 and 30.0 degrees
				$("#fridge-temp span.temperature").text(String((fridgeTemp/10).toFixed(1)));
			}, 100);
		},
		mouseup: function(){
			if(typeof(fridgeTempDownTimeOut)!='undefined')
				clearInterval(fridgeTempDownTimeOut);
		},
		mouseleave: function(){
			if(typeof(fridgeTempDownTimeOut)!='undefined')
				clearInterval(fridgeTempDownTimeOut);
		}
		});	
	
	//Maintenance Panel
	$('#maintenance-panel')
	.dialog({
		autoOpen: false,
		title: 'Maintenance Panel',
		height: 700,
		width: 1000,
	    open: function(){
	        // hide beer chart, because it displays through the panel in chrome
	        $('#beer-chart').css('visibility', 'hidden');
	        // show profile chart
	        $('#profileChartDiv').css('visibility', 'hidden');
	    },
	    close: function(){
	        // show beer-chart
	        $('#beer-chart').css('visibility', 'visible');
	        // show profile chart
	        $('#profileChartDiv').css('visibility', 'visible');
	    }		
	});
	
	$('#maintenance-panel').tabs();	
	
	$("button#maintenance").button({	icons: {primary: "ui-icon-newwin" } }).click(function(){
		$("#maintenance-panel").dialog("open");
	});
	$(".script-status").button({	icons: {primary: "ui-icon-alert" } });
	$(".script-status span.ui-button-text").text("Checking script..");	
	
	$("button#refresh-beer-chart").button({	icons: {primary: "ui-icon-refresh" } }).click(function(){
		refreshBeerChart();
	});
	
	$("button#apply-interval").button({	icons: {primary: "ui-icon-check" } }).click(function(){
		$.post('socketmessage.php', {messageType: "interval", message: String($("select#interval").val())});
	});
	
	$("button#apply-beer-name").button({	icons: {primary: "ui-icon-check" } }).click(function(){
		$.post('socketmessage.php', {messageType: "name", message: $("input#beer-name").val()});
	});
	
	
	loadControlPanel();		
	checkScriptStatus(); //will call refreshLcd and alternate between the two
	refreshBeerChart();
	drawProfileChartAndTable();
});


function loadControlPanel(){
	$.post('socketmessage.php', {messageType: "getmode", message: ""}, function(mode){
		switch(parseInt(mode)){
			case 1:
				$.post('socketmessage.php', {messageType: "gettemp", message: ""}, function(temp){
					beerTemp=parseInt(temp);
					$("#beer-temp span.temperature").text(String((beerTemp/10).toFixed(1)));
				});
				$('#control-panel').tabs( "select" , 0);
				statusMessage("normal","Running in beer profile mode");
				break;
			case 2:
				$.post('socketmessage.php', {messageType: "gettemp", message: ""}, function(temp){
					beerTemp=parseInt(temp)
					$("#beer-temp span.temperature").text(String((beerTemp/10).toFixed(1)));
				});
				$('#control-panel').tabs( "select" , 1);
				statusMessage("normal","Running in beer constant mode");
				break;
			case 3:
				$.post('socketmessage.php', {messageType: "gettemp", message: ""}, function(temp){
					fridgeTemp=parseInt(temp)
					$("#fridge-temp span.temperature").text(String((fridgeTemp/10).toFixed(1)));
				});
				$('#control-panel').tabs( "select" , 2);
				statusMessage("normal","Running in fridge constant mode");
				break;
			default:
				statusMessage("error","Invalid mode ("+mode+") received");
		}
	});
}

function stopScript(){
	$.post('socketmessage.php', {messageType: "stopscript", message: ""}, function(){ 	});
}

function startScript(){
	$.get('start_script.php');
}

function applySettings(){
	//Check which tab is open
	if($("#profile_control").hasClass('ui-tabs-hide') == false){
		$.post('socketmessage.php', {messageType: "setprofile", message: ""}, function(){ 	});	
		statusMessage("highlight","Mode set to beer profile");
	}
	else if($("#beer_constant_control").hasClass('ui-tabs-hide') == false){
		$.post('socketmessage.php', {messageType: "setbeer", message: String(beerTemp)}, function(){ 	});	
		statusMessage("highlight","Mode set to beer constant");
	}
	else if($("#fridge_constant_control").hasClass('ui-tabs-hide') == false){
		$.post('socketmessage.php', {messageType: "setfridge", message: String(fridgeTemp)}, function(){ 	});
		statusMessage("highlight","Mode set to fridge constant");
	}
	setTimeout(loadControlPanel,5000);
}

function refreshLcd(){
	$.post('socketmessage.php', {messageType: "lcd", message: ""}, function(lcdText){
		if(lcdText != false){
			$('#lcd').html(lcdText);
		}
		else{
			$('#lcd').html("Error: script <BR>not responding");
		}
		window.setTimeout(checkScriptStatus,5000);
	});
	
}

function checkScriptStatus(){
	$.post('socketmessage.php', {messageType: "checkScript", message: ""}, function(answer){
		if(answer !=prevScriptStatus){
			if(answer==1){
				$(".script-status span.ui-icon").removeClass("ui-icon-alert").addClass("ui-icon-check");
				$(".script-status").removeClass("ui-state-error").addClass("ui-state-default");
				$(".script-status span.ui-button-text").text("Script running");
				$(".script-status").unbind();
				$(".script-status").bind({
						click: function(){
										 stopScript();
										},
						mouseenter: function(){
									$(".script-status p span#icon").removeClass("ui-icon-check").addClass("ui-icon-stop");
									$(".script-status").removeClass("ui-state-default").addClass("ui-state-error");
									$(".script-status span.ui-button-text").text("Stop script");
									},
						mouseleave: function(){
									$(".script-status p span#icon").removeClass("ui-icon-stop").addClass("ui-icon-check");
									$(".script-status").removeClass("ui-state-error").addClass("ui-state-default");
									$(".script-status span.ui-button-text").text("Script running");
								}
						});					
			}
			else{
				$(".script-status span.ui-icon").removeClass("ui-icon-check").addClass("ui-icon-alert");
				$(".script-status").removeClass("ui-state-default").addClass("ui-state-error");
				$(".script-status span.ui-button-text").text("Script not running!");
				$(".script-status").unbind();
				$(".script-status").bind({
						click: function(){
										 startScript();
										},
						mouseenter: function(){
									$(".script-status span.ui-icon").removeClass("ui-icon-alert").addClass("ui-icon-play");
									$(".script-status").removeClass("ui-state-error").addClass("ui-state-default");
									$(".script-status span.ui-button-text").text("Start script");
									},
						mouseleave: function(){
									$(".script-status span.ui-icon").removeClass("ui-icon-play").addClass("ui-icon-alert");
									$(".script-status").removeClass("ui-state-default").addClass("ui-state-error");
									$(".script-status span.ui-button-text").text("Script not running!");
								}
						});		
			}
		}
		prevScriptStatus = answer;
		window.setTimeout(refreshLcd, 5000); //alternate refreshing script and lcd
	});

}

google.load('visualization', '1', {packages: ['annotatedtimeline', 'table']});
