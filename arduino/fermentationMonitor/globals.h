#ifndef GLOBALS_H
#define GLOBALS_H

// pins
#define beerPin    A0
#define fridgePin  A1

//ADC 6 and 7 are not available as digital pins. Use analogRead() to read the buttons.
#define button1    A7
#define button2    A6
#define button3    A5

#define coolingPin 10 
#define heatingPin 11 
#define doorPin    12
 

// State variables
extern unsigned char mode; // Constant beer temperature, constant fridge temperature or beer temperature profile;
extern unsigned char state;
extern unsigned char previousState;
extern unsigned char doPosPeakDetect;
extern unsigned char doNegPeakDetect;

// Fast filtered temperatures
extern float beerTemperatureActual;
extern float beerTemperatureSetting;
extern float fridgeTemperatureActual;
extern float fridgeTemperatureSetting;

extern float fridgeTempFiltFast[4]; // Filtered data from sensors
extern float fridgeTempFast[4];     // Input from filter
extern float beerTempFast[4];
extern float beerTempFiltFast[4];

// Slow filtered Temperatures used for peak detection
extern float fridgeTempFiltSlow[4];
extern float fridgeTempSlow[4];
extern float beerTempSlow[4];
extern float beerTempFiltSlow[4];
extern float beerSlope;

//history for slope calculation
extern float beerTempHistory[30];
extern unsigned char beerTempHistoryIndex;

// Control parameters
extern float heatOvershootEstimator;
extern float coolOvershootEstimator;
extern float fridgeSettingForNegPeakEstimate;
extern float fridgeSettingForPosPeakEstimate;
extern float negPeak;
extern float posPeak;
extern float differenceIntegral;

//Timers 
extern unsigned long sampleTimerFast;
extern unsigned long sampleTimerSlow;
extern unsigned long slopeTimer;
extern unsigned long settingsTimer;
extern unsigned long lastCoolTime;
extern unsigned long lastHeatTime;
extern unsigned long lastIdleTime;

// LCD
extern char lcdText[4][21];
extern OLEDFourBit lcd;

#endif
