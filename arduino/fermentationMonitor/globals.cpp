#include "enums.h"
#include <OLEDFourBit.h>

// State variables
unsigned char state=STARTUP;
unsigned char previousState=IDLE;
unsigned char mode;
unsigned char doPosPeakDetect=0;
unsigned char doNegPeakDetect=0;

// Fast filtered temperatures
float beerTemperatureActual; 
float beerTemperatureSetting=20; 
float fridgeTemperatureActual; 
float fridgeTemperatureSetting=20;
float fridgeTempFiltFast[4];
float fridgeTempFast[4]; //input for filter
float beerTempFast[4];
float beerTempFiltFast[4];

// Slow filtered temperatures
float fridgeTempFiltSlow[4];
float fridgeTempSlow[4]; //input for filter
float beerTempSlow[4];
float beerTempFiltSlow[4];
float beerSlope;

// keep history of beer temps, to calculate slope
float beerTempHistory[30];
unsigned char beerTempHistoryIndex;

// Control parameters
float heatOvershootEstimator;
float coolOvershootEstimator;
float fridgeSettingForNegPeakEstimate;
float fridgeSettingForPosPeakEstimate;
float negPeak;
float posPeak;
float differenceIntegral;

//Timers 
unsigned long sampleTimerFast = 0;
unsigned long sampleTimerSlow = 0;
unsigned long slopeTimer = 0;
unsigned long settingsTimer = 0;

unsigned long lastCoolTime=0;
unsigned long lastHeatTime=0;
unsigned long lastIdleTime=0;

// LCD
OLEDFourBit lcd(3, 4, 5, 6, 7, 8, 9);
char lcdText[4][21];

