import time
import csv

def getNewTemp():
	temperatureReader = csv.reader(open('/mnt/uberfridge/settings/currentprofile.csv','rb'), delimiter=',',quoting=csv.QUOTE_ALL)
	temperatureReader.next() #discard the first row, which is the table header
	prevTemp = -1;
	nextTemp = -1;
	prevDate = -1;
	nextDate = -1;
	interpolatedTemp = -1;
	
	
	now = time.mktime(time.localtime()) # get current time in seconds since epoch
	
	for	row	in temperatureReader:
		datestring = row[0]
		if(datestring != "null"):
			temperature = float(row[1])
			prevTemp = nextTemp
			nextTemp = temperature
			prevDate = nextDate
			nextDate = time.mktime(time.strptime(datestring, "%d/%m/%Y %H:%M:%S"));
			timeDiff = now - nextDate;
			if(timeDiff < 0):
				if(prevDate == -1):
					interpolatedTemp = nextTemp #first setpoint is in the future
					break;
				else:
					interpolatedTemp = (now - prevDate)/(nextDate-prevDate)*(nextTemp-prevTemp)+prevTemp
					break;
					
	if(interpolatedTemp == -1): #all setpoints in the past
		interpolatedTemp = nextTemp
	return int(interpolatedTemp*10+.5) #retun temp in tenths of degrees
				