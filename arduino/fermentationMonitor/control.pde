  #include "globals.h"
#include "enums.h"
#include <EEPROM.h>

// control defines
#define KpHeat 10
#define KpCool 5
#define Ki 0.02
#define KdCool -5
#define KdHeat -10

// Stay Idle when temperature is in this range
#define IDLE_RANGE_HIGH (+5)
#define IDLE_RANGE_LOW (-5)

// when peak falls between these limits, its good.
#define HEATING_TARGET_UPPER (+2)
#define HEATING_TARGET_LOWER (-1)
#define COOLING_TARGET_UPPER (+1)
#define COOLING_TARGET_LOWER (-2)

#define COOLING_TARGET ((COOLING_TARGET_UPPER+COOLING_TARGET_LOWER)/2)
#define HEATING_TARGET ((HEATING_TARGET_UPPER+HEATING_TARGET_LOWER)/2)

// maximum history to take into account, in seconds
#define MAX_HEAT_TIME_FOR_ESTIMATE 600
#define MAX_COOL_TIME_FOR_ESTIMATE 1200

float Kp;
float Kd;

// update fridge temperature setting, difference with beer setting is PID actuator
void updateSettings(void){  
  if(mode == BEER_CONSTANT || mode == BEER_PROFILE){   
    float beerTemperatureDifference =  beerTemperatureSetting-beerTempFiltSlow[3];
    if(abs(beerTemperatureDifference) < 5 && ((beerSlope <= 0.7 && beerSlope >= 0) || (beerSlope >= -1.4 && beerSlope <= 0))){     //difference is smaller than .5 degree and slope is almost horizontal
      if(abs(beerTemperatureDifference)> 0.5){
        differenceIntegral = differenceIntegral + beerTemperatureDifference;
      }
    }
    else{
      differenceIntegral = differenceIntegral*0.9;
    }
    
    if(beerTemperatureDifference<0){ //linearly go to cool parameters in 3 hours
      Kp = constrain(Kp+(KpCool-KpHeat)/(360*3), KpCool, KpHeat);
      Kd = constrain(Kd+(KdCool-KdHeat)/(360*3), KdHeat, KdCool);
    }
    else{ //linearly go to heat parameters in 3 hours
      Kp = constrain(Kp+(KpHeat-KpCool)/(360*3), KpCool, KpHeat);
      Kd = constrain(Kd+(KdHeat-KdCool)/(360*3), KdHeat, KdCool);
    }
    fridgeTemperatureSetting = constrain(beerTemperatureSetting + Kp* beerTemperatureDifference + Ki* differenceIntegral + Kd*beerSlope, 40, 300);      
  }
  else{
    // FridgeTemperature is set manually
    beerTemperatureSetting = 0;
  }
}

void updateState(void){
  float estimatedOvershoot;
  float estimatedPeakTemperature;
  //update state
  if(digitalRead(doorPin) == HIGH){ 
    if(state!=DOOR_OPEN){
       serialFridgeMessage(FRIDGE_DOOR_OPEN);
    }
    state=DOOR_OPEN;
    return;
  }
  switch(state){
    case STARTUP:
    case IDLE:
      lastIdleTime=millis();
      if(((timeSinceCooling() > 900000UL || doNegPeakDetect==0) && (timeSinceHeating()>600000UL || doPosPeakDetect==0)) || state==STARTUP){ //if cooling is 15 min ago and heating 10
        if(fridgeTemperatureActual> fridgeTemperatureSetting+IDLE_RANGE_HIGH){
          if(mode!=FRIDGE_CONSTANT){
            if(beerTempFiltSlow[3]>beerTemperatureSetting+0.5){ // only start cooling when beer is too warm (0.05 degree idle space)
              state=COOLING;
            }
          }
          else{
            state=COOLING;
          }
          return;
        }
        if(fridgeTemperatureActual< fridgeTemperatureSetting+IDLE_RANGE_LOW){
          if(mode!=FRIDGE_CONSTANT){
            if(beerTempFiltSlow[3]<beerTemperatureSetting-0.5){ // only start heating when beer is too cold (0.05 degree idle space)
              state=HEATING;
            }
          }
          else{
            state=HEATING;
          }
          return;
        }
      }
      if(timeSinceCooling()>1800000UL){ //30 minutes
        doNegPeakDetect=0;  //peak would be from drifting in idle, not from cooling
      }
      if(timeSinceHeating()>900000UL){ //20 minutes
        doPosPeakDetect=0;  //peak would be from drifting in idle, not from heating
      }
      break; 
    case COOLING:
      doNegPeakDetect=1;
      lastCoolTime = millis();    
      estimatedOvershoot = coolOvershootEstimator  * min(MAX_COOL_TIME_FOR_ESTIMATE, (float) timeSinceIdle()/(1000))/60;
      estimatedPeakTemperature = fridgeTemperatureActual - estimatedOvershoot;
      if(estimatedPeakTemperature <= fridgeTemperatureSetting + COOLING_TARGET){
        fridgeSettingForNegPeakEstimate=fridgeTemperatureSetting;
        state=IDLE;
        return;
      }
      break;
    case HEATING:
       lastHeatTime=millis();
       doPosPeakDetect=1;    
       estimatedOvershoot = heatOvershootEstimator * min(MAX_HEAT_TIME_FOR_ESTIMATE, (float) timeSinceIdle()/(1000))/60;
       estimatedPeakTemperature = fridgeTemperatureActual + estimatedOvershoot;
      if(estimatedPeakTemperature >= fridgeTemperatureSetting + HEATING_TARGET){
        fridgeSettingForPosPeakEstimate=fridgeTemperatureSetting;
        state=IDLE;
        return;
      }
      break;
    case DOOR_OPEN:
      if(digitalRead(doorPin) == LOW){ 
         serialFridgeMessage(FRIDGE_DOOR_CLOSED);
         state=IDLE;
         return;
      }
    default:
      state = 0xFF; //go to unknown state, should never happen
  }
}

void updateOutputs(void){
  switch (state){
  case IDLE:
  case STARTUP:
    digitalWrite(coolingPin, LOW);
    digitalWrite(heatingPin, LOW);
    break;
  case COOLING:
    digitalWrite(coolingPin, HIGH); 
    digitalWrite(heatingPin, LOW);
    break;
  case HEATING:    
  case DOOR_OPEN:
    digitalWrite(coolingPin, LOW); 
    digitalWrite(heatingPin, HIGH);
    break;
  default:
    digitalWrite(coolingPin, LOW); 
    digitalWrite(heatingPin, LOW);
    break;
  }
}

void detectPeaks(void){  
  //detect peaks in fridge temperature to tune overshoot estimators
  if(doPosPeakDetect && state!=HEATING){
    if(fridgeTempFiltSlow[3] <= fridgeTempFiltSlow[2] && fridgeTempFiltSlow[2] >= fridgeTempFiltSlow[1]){ // maximum
      posPeak=fridgeTempFiltSlow[2];       
      if(posPeak>fridgeSettingForPosPeakEstimate+HEATING_TARGET_UPPER){
        //should not happen, estimated overshoot was too low, so adjust overshoot estimator
        heatOvershootEstimator=heatOvershootEstimator*(1.2+min((posPeak-(fridgeSettingForPosPeakEstimate+HEATING_TARGET_UPPER))*.03,0.3));
        saveSettings();
      }
      if(posPeak<fridgeSettingForPosPeakEstimate+HEATING_TARGET_LOWER){
        //should not happen, estimated overshoot was too high, so adjust overshoot estimator
        heatOvershootEstimator=heatOvershootEstimator*(0.8+max((posPeak-(fridgeSettingForPosPeakEstimate+HEATING_TARGET_LOWER))*.03,-0.3));
        saveSettings();
      }
      doPosPeakDetect=0;
      serialFridgeMessage(POSPEAK);
    }
    else if(timeSinceHeating() > 580000UL && timeSinceCooling() > 900000UL && fridgeTempFiltSlow[3] < fridgeSettingForPosPeakEstimate+HEATING_TARGET_LOWER){
      //there was no peak, but the estimator is too low. This is the heat, then drift up situation.
        posPeak=fridgeTempFiltSlow[3];
        heatOvershootEstimator=heatOvershootEstimator*(0.8+max((posPeak-(fridgeSettingForPosPeakEstimate+HEATING_TARGET_LOWER))*.03,-0.3));
        saveSettings();
        doPosPeakDetect=0;
        serialFridgeMessage(POSDRIFT);
    }
  }
  if(doNegPeakDetect && state!=COOLING){
    if(fridgeTempFiltSlow[3] >= fridgeTempFiltSlow[2] && fridgeTempFiltSlow[2] <= fridgeTempFiltSlow[1]){ // minimum
      negPeak=fridgeTempFiltSlow[2];
      if(negPeak<fridgeSettingForNegPeakEstimate+COOLING_TARGET_LOWER){
        //should not happen, estimated overshoot was too low, so adjust overshoot estimator
        coolOvershootEstimator=coolOvershootEstimator*(1.2+min(((fridgeSettingForNegPeakEstimate+COOLING_TARGET_LOWER)-negPeak)*.03,0.3));
        saveSettings();
      }
      if(negPeak>fridgeSettingForNegPeakEstimate+COOLING_TARGET_UPPER){
        //should not happen, estimated overshoot was too high, so adjust overshoot estimator
        coolOvershootEstimator=coolOvershootEstimator*(0.8+max(((fridgeSettingForNegPeakEstimate+COOLING_TARGET_UPPER)-negPeak)*.03,-0.3));
        saveSettings();
      }
      doNegPeakDetect=0;
      serialFridgeMessage(NEGPEAK); 
    } 
    else if(timeSinceCooling() > 1780000UL && timeSinceHeating() > 1800000UL && fridgeTempFiltSlow[3] > fridgeSettingForNegPeakEstimate+COOLING_TARGET_UPPER){
      //there was no peak, but the estimator is too low. This is the cool, then drift down situation.
        negPeak=fridgeTempFiltSlow[3];
        coolOvershootEstimator=coolOvershootEstimator*(0.8+max((negPeak-(fridgeSettingForNegPeakEstimate+COOLING_TARGET_UPPER))*.03,-0.3));
        saveSettings();
        doNegPeakDetect=0;
        serialFridgeMessage(NEGDRIFT); 
    }
  }
}


unsigned long timeSinceCooling(void){
  unsigned long currentTime = millis();
  unsigned long timeSinceLastOn;
  if(currentTime>=lastCoolTime){
    timeSinceLastOn = currentTime - lastCoolTime;
  }
  else{
    // millis() overflow has occured
    timeSinceLastOn = (currentTime + 1440000) - (lastCoolTime +1440000); // add a day to both for calculation
  }
  return timeSinceLastOn;
}


unsigned long timeSinceHeating(void){
  unsigned long currentTime = millis();
  unsigned long timeSinceLastOn;
  if(currentTime>=lastHeatTime){
    timeSinceLastOn = currentTime - lastHeatTime;
  }
  else{
    // millis() overflow has occured
    timeSinceLastOn = (currentTime + 1440000) - (lastHeatTime +1440000); // add a day to both for calculation
  }
  return timeSinceLastOn;
}


unsigned long timeSinceIdle(void){
  unsigned long currentTime = millis();
  unsigned long timeSinceLastOn;
  if(currentTime>=lastIdleTime){
    timeSinceLastOn = currentTime - lastIdleTime;
  }
  else{
    // millis() overflow has occured
    timeSinceLastOn = (currentTime + 1440000) - (lastIdleTime +1440000); // add a day to both for calculation
  }
  return timeSinceLastOn;
}

void initControl(void){
   if(beerTemperatureSetting<beerTempFiltSlow[3]){
     Kp=KpCool;
     Kd=KdCool;  
   }
   else{
     Kp=KpHeat;
     Kd=KdHeat;     
   }
}







