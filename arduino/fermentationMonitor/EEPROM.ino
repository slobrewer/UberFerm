#include <EEPROM.h>
#include "globals.h"

int eepromReadInt(int address){
   int value = 0x0000;
   value = value | (EEPROM.read(address) << 8);
   value = value | EEPROM.read(address+1);
   return value;
}

void eepromWriteInt(int address, int value){
   EEPROM.write(address, (value >> 8) & 0xFF );
   EEPROM.write(address+1, value & 0xFF);
}

float eepromReadFloat(int address){
   union u_tag {
     byte b[4];
     float fval;
   } u;   
   u.b[0] = EEPROM.read(address);
   u.b[1] = EEPROM.read(address+1);
   u.b[2] = EEPROM.read(address+2);
   u.b[3] = EEPROM.read(address+3);
   return u.fval;
}

void eepromWriteFloat(int address, float value){
   union u_tag {
     byte b[4];
     float fval;
   } u;
   u.fval=value;

   EEPROM.write(address  , u.b[0]);
   EEPROM.write(address+1, u.b[1]);
   EEPROM.write(address+2, u.b[2]);
   EEPROM.write(address+3, u.b[3]);
}

void saveSettings(void){
  // write new settings to EEPROM to save be able to reload them after a reset
  // Check if settings in EEPROM are still  correct to keep writes minimal (only 100.000 cycles)
  if(mode!=EEPROM.read(EEPROM_MODE)){
    EEPROM.write(EEPROM_MODE,mode);
  }
  int beerTemperatureSettingInt = int(beerTemperatureSetting+.5);
  if(beerTemperatureSettingInt != eepromReadInt(EEPROM_BEER_SETTING)){
    eepromWriteInt(EEPROM_BEER_SETTING,beerTemperatureSettingInt);
  }
  int fridgeTemperatureSettingInt = int(fridgeTemperatureSetting+.5);
  if(fridgeTemperatureSettingInt != eepromReadInt(EEPROM_FRIDGE_SETTING)){
    eepromWriteInt(EEPROM_FRIDGE_SETTING,fridgeTemperatureSettingInt);
  }
  if(heatOvershootEstimator != eepromReadFloat(EEPROM_HEAT_ESTIMATOR)){
     eepromWriteFloat(EEPROM_HEAT_ESTIMATOR, heatOvershootEstimator);
  }
  if(coolOvershootEstimator != eepromReadFloat(EEPROM_COOL_ESTIMATOR)){
     eepromWriteFloat(EEPROM_COOL_ESTIMATOR, coolOvershootEstimator);
  }
}

void loadSettings(void){
  mode = EEPROM.read(EEPROM_MODE);
  if(mode > BEER_PROFILE){
    //setting in EEPROM is invalid
    mode = BEER_CONSTANT;
  }
  beerTemperatureSetting = eepromReadInt(EEPROM_BEER_SETTING);
  if(beerTemperatureSetting > 300 | beerTemperatureSetting <0){
    //setting in EEPROM is invalid
    beerTemperatureSetting = 200;
  }
  fridgeTemperatureSetting = eepromReadInt(EEPROM_FRIDGE_SETTING);  
  if(fridgeTemperatureSetting > 300 | fridgeTemperatureSetting <0){
    //setting in EEPROM is invalid
    fridgeTemperatureSetting = 200;
  }
  heatOvershootEstimator = eepromReadFloat(EEPROM_HEAT_ESTIMATOR);
  if(heatOvershootEstimator < 0 || heatOvershootEstimator > 1000 || heatOvershootEstimator==0x0000){ //incorrect value in EEPROM
     heatOvershootEstimator=0.2;
  }  
  coolOvershootEstimator = eepromReadFloat(EEPROM_COOL_ESTIMATOR);
  if(coolOvershootEstimator < 0 || coolOvershootEstimator > 1000 || coolOvershootEstimator==0x0000){ //incorrect value in EEPROM{
    coolOvershootEstimator=5;
  }  
}
