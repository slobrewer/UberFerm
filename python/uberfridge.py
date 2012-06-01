import serial
import time
from datetime import datetime
import gviz_api
import csv
import StringIO
import socket
from shutil import copyfile
import sys
import os

#local imports
import temperatureProfile

#	open serial	port
ser	=	serial.Serial('/dev/usb/tts/0',9600,timeout=2)	

# read name of current beer and create directory for the data if it does not exist
beerNameFile = open('/mnt/uberfridge/settings/currentBeerName.txt')
currentBeerName = beerNameFile.readline()
beerNameFile.close()
print >> sys.stderr, time.strftime("%b %d %Y %H:%M:%S   ") + "Notification: Script started for beer \"" + currentBeerName
dataPath = '/mnt/uberfridge/data/' + currentBeerName
wwwDataPath = '/opt/share/www/lighttpd/data/' + currentBeerName
if not os.path.exists(dataPath):
	os.makedirs(dataPath)
if not os.path.exists(wwwDataPath):
	os.makedirs(wwwDataPath)
	
# Read previous settings, strip newlines and trailing whitespaces for strings
modeFile = open('/mnt/uberfridge/settings/mode.txt','rU')
mode = modeFile.readline().rstrip('\n').rstrip()
temperatureSetting = int(modeFile.readline().rstrip('\n').rstrip())
modeFile.close()

intervalFile= open('/mnt/uberfridge/settings/interval.txt','rU')
serialRequestInterval = float(intervalFile.readline())
intervalFile.close()

serialCheckInterval = 5.0 #Check serial port for data every x seconds

print >> sys.stderr, time.strftime("%b %d %Y %H:%M:%S   ") + "Previous settings: mode = " + mode + ", temperature = " + str(temperatureSetting)

# Define Google data table description and create empty data table
description = {	"Time": 		("datetime","Time"),
				"BeerTemp": 	("number",	"Beer temperature"),
				"BeerSet":		("number",  "Beer setting"),
				"BeerAnn":		("string",	"Beer Annotate"),
				"FridgeTemp":	("number",	"Fridge temperature"),
				"FridgeSet":	("number",	"Fridge setting"),
				"FridgeAnn":	("string",	"Fridge Annotate")}
dataTable = gviz_api.DataTable(description)

# Keep track of day to make a new data tabe and file for each day to limit data table size
day = time.strftime("%Y-%m-%d")
lastDay = day

# define a JSON file to store the data table
jsonFileName= currentBeerName + '/' + currentBeerName + '-' + day
#if a file for today already existed, add suffix
if os.path.isfile('/mnt/uberfridge/data/' + jsonFileName + '.json'):
	i=1
	while (os.path.isfile('/mnt/uberfridge/data/' + jsonFileName + '-' + str(i) + '.json')):
		i=i+1	
	jsonFileName = jsonFileName + '-' + str(i)		
localJsonFileName = '/mnt/uberfridge/data/' + jsonFileName + '.json'

# Define a location on the webserver to copy the file to after it is written
wwwJsonFileName='/opt/share/www/lighttpd/data/' + jsonFileName + '.json'

# Define a CSV file to store the data as CSV (might be useful one day)
localCsvFileName = '/mnt/uberfridge/data/' + currentBeerName + '/' + currentBeerName + '.csv'
wwwCsvFileName = '/opt/share/www/lighttpd/data/' + currentBeerName + '/' + currentBeerName + '.csv'
		        
#create a listening socket to communicate with PHP		        
if os.path.exists('/tmp/BEERSOCKET'):
	os.remove('/tmp/BEERSOCKET') #if socket already exists, remove it
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.bind("/tmp/BEERSOCKET") #Bind /mnt/BEERSOCKET
s.setblocking(1) # set socket functions to be blocking
s.listen(5) # Create a backlog queue for up to 5 connections.
s.settimeout(serialCheckInterval)  # blocking socket functions wait 'serialCheckInterval' seconds.

#The arduino nano resets when linux connects to the serial port. Delay to give it time to restart.
time.sleep(8)

prevDataTime=0.0 #keep track of time between new data requests
prevTimeOut=time.time()

run = 1
lcdText = "Script starting up"
modeChanged = 0 #is set to high if mode is changed from the web interface

while(run):
	# Check wheter it is a new day
	lastDay = day
	day = time.strftime("%Y-%m-%d")
	if lastDay != day:
		 #empty data table and write to new files
		dataTable.LoadData([])
		print >> sys.stderr, time.strftime("%b %d %Y %H:%M:%S   ") + "Notification: New day, dropping data table and creating new JSON file."
		jsonFileName= currentBeerName + '/' + currentBeerName + '-' + day
		localJsonFileName = '/mnt/uberfridge/data/' + jsonFileName + '.json'
		wwwJsonFileName='/opt/share/www/lighttpd/data/' + jsonFileName + '.json'
	
	try: # wait for incoming socket connections.
		conn, addr  = s.accept()
		data = conn.recv(1024)  #blocking receive, times out in 5 minutes
		if(len(data)<=1): #invalid data, too short
			if((time.time() - prevTimeOut) < serialCheckInterval):
				continue
		elif(data[0]=='q'):			#exit instruction received. Stop script.
			run=0
			dontrunfile = open('/tmp/uberfridge_dontrun',"w")
			dontrunfile.write("1")
			dontrunfile.close()
			if((time.time() - prevTimeOut) < serialCheckInterval):
				continue
		elif(data[0]=='a'):			#acknowledge request
			conn.send('ack')
			if((time.time() - prevTimeOut) < serialCheckInterval):
				continue
		elif(data[0]=='m'):			#echo mode setting
			conn.send(mode)
			if((time.time() - prevTimeOut) < serialCheckInterval):
				continue
		elif(data[0]=='t'):			#echo mode setting
			conn.send(str(temperatureSetting))
			if((time.time() - prevTimeOut) < serialCheckInterval):
				continue
		elif(data[0]=='b'):			#new constant beer temperature received
			newTemp = int(data[1:])
			if(newTemp>0 and newTemp<300):
				mode='beer'
				modeChanged=1;
				temperatureSetting=newTemp
				print >> sys.stderr, time.strftime("%b %d %Y %H:%M:%S   ") + "Notification: Beer temperature set to " + str(float(newTemp)/10) + " degrees Celcius"
		elif(data[0]=='f'):			#new constant fridge temperature received
			newTemp = int(data[1:])
			if(newTemp>0 and newTemp<300):
				mode='fridge'
				modeChanged=1;
				temperatureSetting=newTemp
				print >> sys.stderr, time.strftime("%b %d %Y %H:%M:%S   ") + "Notification: Fridge temperature set to " + str(float(newTemp)/10) + " degrees Celcius"
		elif(data[0]=='p'):			#mode set to profile, read temperatures from currentprofile.csv
			mode='profile'
			temperatureSetting = temperatureProfile.getNewTemp()
			modeChanged=1;
			print >> sys.stderr, time.strftime("%b %d %Y %H:%M:%S   ") + "Notification: Profile mode enabled"	
		elif(data[0]=='l'):			#lcd contents requested
			conn.send(lcdText)
		elif(data[0]=='i'):			#new interval received
			newInterval = int(data[1:])
			if(newInterval>5 and newInterval<5000):
				serialRequestInterval=float(newInterval);
				intervalFile = open('/mnt/uberfridge/settings/interval.txt',"w")
				intervalFile.write(str(newInterval))
				intervalFile.close()
				print >> sys.stderr, time.strftime("%b %d %Y %H:%M:%S   ") + "Notification: Interval changed to " + str(newInterval) + " seconds"
		elif(data[0]=='n'):			#new beer name
			newName = data[1:]
			if(len(newName)>3):		#shorter names are probably invalid
				beerNameFile = open('/mnt/uberfridge/settings/currentBeerName.txt',"w")
				beerNameFile.write(newName)
				beerNameFile.close()
				currentBeerName = newName
				
				dataPath = '/mnt/uberfridge/data/' + currentBeerName
				wwwDataPath = '/opt/share/www/lighttpd/data/' + currentBeerName
				if not os.path.exists(dataPath):
					os.makedirs(dataPath)
				if not os.path.exists(wwwDataPath):
					os.makedirs(wwwDataPath)
					
				jsonFileName= currentBeerName + '/' + currentBeerName + '-' + day
				#if a file for today already existed, add suffix
				if os.path.isfile('/mnt/uberfridge/data/' + jsonFileName + '.json'):
					i=1
					while (os.path.isfile('/mnt/uberfridge/data/' + jsonFileName + '-' + str(i) + '.json')):
						i=i+1	
					jsonFileName = jsonFileName + '-' + str(i)		
				localJsonFileName = '/mnt/uberfridge/data/' + jsonFileName + '.json'
				wwwJsonFileName='/opt/share/www/lighttpd/data/' + jsonFileName + '.json'
				localCsvFileName = '/mnt/uberfridge/data/' + currentBeerName + '/' + currentBeerName + '.csv'
				wwwCsvFileName = '/opt/share/www/lighttpd/data/' + currentBeerName + '/' + currentBeerName + '.csv'
				
				dataTable.LoadData([]) #discard data table
				
				print >> sys.stderr, time.strftime("%b %d %Y %H:%M:%S   ") + "Notification: restarted for beer: " + newName
				continue				
			
		else:
			print >> sys.stderr, time.strftime("%b %d %Y %H:%M:%S   ") + "Error: Received invalid packet on socket: " + data
		
		raise socket.timeout #raise exception to check serial for data immediately
	
	except socket.timeout: #Do serial communication and update settings every SerialCheckInterval
		prevTimeOut=time.time()
			
		while(1): #read all lines on serial interface
			line = ser.readline()
			if(line): #line available?							
			 	#process line
				if line.count(";")==5:
					#valid data received
					lineAsFile = StringIO.StringIO(line) #open line as a file to use it with csv.reader
					if '\0' in lineAsFile:
						print >> sys.stderr, time.strftime("%b %d %Y %H:%M:%S   ") + "CSV line from Arduino contains NULL byte, skipping line"
						continue
					
					lineAsFile = StringIO.StringIO(line) #reopen line as file, because checking for NULL byte causes the reader to not read anything 	
					reader = csv.reader(lineAsFile, delimiter=';',quoting=csv.QUOTE_NONNUMERIC)
					for	row	in reader: #Relace empty annotations with None
						if(row[2]==''):
							row[2]=None
						if(row[5]==''):
							row[5]=None
						#append new row to data table, print it to stdout and write complete datatable to json file		
						newRow= [{'Time': datetime.today(),'BeerTemp': row[0], 'BeerSet': row[1], 'BeerAnn': row[2], 'FridgeTemp': row[3], 'FridgeSet': row[4], 'FridgeAnn': row[5]}]
						print newRow
						dataTable.AppendData(newRow)
						jsonfile = open(localJsonFileName,'w')
						jsonfile.write(unicode(dataTable.ToJSon(columns_order=["Time", "BeerTemp",	"BeerSet", "BeerAnn", "FridgeTemp", "FridgeSet", "FridgeAnn"])))
						jsonfile.close() 
						copyfile(localJsonFileName,wwwJsonFileName) #copy to www dir. Do not write directly to www dir to prevent blocking www file.
												
						#write csv file too
						csvFile = open(localCsvFileName,"a")
						lineToWrite = time.strftime("%b %d %Y %H:%M:%S;" ) + line
						csvFile.write(lineToWrite)
						csvFile.close()
						copyfile(localCsvFileName,wwwCsvFileName)
						
					prevDataTime = time.time() #store time of last new data for interval check
				else:
					print >> sys.stderr, time.strftime("%b %d %Y %H:%M:%S   ") + "Error: Received	invalid	line: " + line
			elif((time.time() - prevDataTime) >= serialRequestInterval): #if no new data has been received for serialRequestInteval seconds, request it
				ser.write("r")		#	request	new	data from	arduino
				time.sleep(1)			# give the arduino time to respond
				continue
			elif(time.time() - prevDataTime > serialRequestInterval+2*serialCheckInterval):
				#something is wrong: arduino is not responding to data requests
				print >> sys.stderr, time.strftime("%b %d %Y %H:%M:%S   ") + "Error: Arduino is not responding to new data requests"
			else:
				break
						
		#check and update settings if necessary
		if(modeChanged):
			#Python has most recent mode settings 
			if(mode == "beer"):
				ser.write("b"+str(temperatureSetting))
			elif(mode == "fridge"):
				ser.write("f"+str(temperatureSetting))
			elif(mode == "profile"):
				ser.write("p"+str(temperatureSetting))
		else:
			#flush buffers to prevent old data to be read as settings
			ser.flush()
			#Arduino has most recent mode setting
			ser.write("s") #request settings
			line = ser.readline()
			if(line):
				arduinoMode = line.rstrip('\n').rstrip()
			else:
				continue #arduino is busy, probably in menu
			line = ser.readline()
			if(line):
				arduinoTemperature = int(line.rstrip('\n').rstrip())
			else:
				continue #arduino is busy, probably in menu
			
			if(mode == "profile" and arduinoMode=="profile"): #update temperatureSetting from profile
				newTemp = temperatureProfile.getNewTemp()
				if(newTemp>0 and newTemp<300):
					if(newTemp !=temperatureSetting): # if temperature has to be updated send settings to arduino
						temperatureSetting=newTemp
						ser.write("p"+str(temperatureSetting))
						modeChanged=1
			
			elif(mode != arduinoMode or temperatureSetting != arduinoTemperature):
				mode=arduinoMode
				temperatureSetting=arduinoTemperature
				modeChanged=1
				print >> sys.stderr, time.strftime("%b %d %Y %H:%M:%S   ") + "Mode set to " + mode + " " + str(temperatureSetting) + " in Arduino menu"			
			
		if(modeChanged):
			# Store new settings
			modeFile = open('/mnt/uberfridge/settings/mode.txt',"w")
			modeFile.write(mode + '\n')
			modeFile.write(str(temperatureSetting))
			modeFile.close()
			modeChanged=0
			continue #Arduino creates an annotation, so skip lcd update this time 
		
		#update lcdText
		ser.write('l')
		lcdText = ser.readline()
			
	except socket.error, e:
		print >>sys.stderr, time.strftime("%b %d %Y %H:%M:%S   ") + "socket error: %s" % e
			
ser.close()						# close	port
conn.shutdown(socket.SHUT_RDWR) # close socket
conn.close()
