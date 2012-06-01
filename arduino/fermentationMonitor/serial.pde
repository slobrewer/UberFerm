#include "globals.h"
#include "enums.h"

void handleSerialCommunication(void){
  int newTemp;
  if (Serial.available() > 0) 
  {
    char inByte = Serial.read();
    switch(inByte)
    {
    case 'r': //Data request     
      serialPrintTemperatures();      
      break;
    case 'b': //Set to constant beer temperature
      beerTemperatureSetting = numberFromSerial();
      mode = BEER_CONSTANT;
      initControl();
      updateSettings();
      saveSettings(); //write new settings to EEPROM
      doNegPeakDetect=0;
      doPosPeakDetect=0;
      lastCoolTime=0;
      lastHeatTime=0;
      previousState=0xFF; //force LCD update
      state=IDLE;
      lcdPrintState();
      serialBeerMessage(BEER_SETTING_FROM_SERIAL);
      break;
    case 'p': //Set profile temperature
      beerTemperatureSetting = numberFromSerial();
      mode = BEER_PROFILE;
      updateSettings();
      if(abs(beerTemperatureSetting - eepromReadInt(EEPROM_BEER_SETTING))>=5){
          initControl();
          updateSettings();
          saveSettings(); //write new settings to EEPROM every half degree difference
          doNegPeakDetect=0;
          doPosPeakDetect=0;
          lastCoolTime=0;
          lastHeatTime=0;
          previousState=0xFF; //force LCD update      
          state=IDLE;
          lcdPrintState();
      }
      serialBeerMessage(BEER_SETTING_FROM_PROFILE);
      break;
    case 'f': //Set to constant fridge temperature
      newTemp = numberFromSerial();
      if(abs(newTemp-fridgeTemperatureSetting)>3){
        doNegPeakDetect=0;
        doPosPeakDetect=0;
        lastCoolTime=0;
        lastHeatTime=0;
        previousState=0xFF; //force LCD update
        state=IDLE;
        lcdPrintState();
        initControl();
      }
      mode = FRIDGE_CONSTANT;
      fridgeTemperatureSetting = newTemp;
      updateSettings();
      saveSettings(); //write new settings to EEPROM
      serialFridgeMessage(FRIDGE_SETTING_FROM_SERIAL);
      break;
    case 's': //Settings requested
      switch(mode){
        case BEER_CONSTANT:
          Serial.println("beer");
          Serial.println(int(beerTemperatureSetting+.5));
          break;
        case FRIDGE_CONSTANT:
          Serial.println("fridge");
          Serial.println(int(fridgeTemperatureSetting+.5));
          break;
        case BEER_PROFILE:
          Serial.println("profile");
          Serial.println(int(beerTemperatureSetting+.5));
          break;        
      }
      break;
    case'l': //lcd contents requested
      lcdReadContents();
      Serial.print(lcdText[0]);Serial.print("<BR>");
      Serial.print(lcdText[1]);Serial.print("<BR>");
      Serial.print(lcdText[2]);Serial.print("<BR>");
      Serial.println(lcdText[3]);
      break;
    default:
      Serial.println(".Invalid command Received by Arduino");      
    }
    Serial.flush(); 
  }  
}

int numberFromSerial(void)
{
  char numberString[8];
  unsigned char index=0;
  delay(10);
  while(Serial.available() > 0)
  {
    delay(10);
    numberString[index++]=Serial.read();      
    if(index>6)
    {
      break; 
    }
  }
  numberString[index]=0;
  return atoi(numberString);
}

void serialPrintTemperatures(void){
      Serial.print(beerTemperatureActual/10);
      Serial.print(";");
      Serial.print(beerTemperatureSetting/10);
      Serial.print(";");
      Serial.print(";");
      Serial.print(fridgeTemperatureActual/10);
      Serial.print(";");
      Serial.print(fridgeTemperatureSetting/10);
      Serial.println(";");
}


void serialBeerMessage(int messageType){
      Serial.print(beerTemperatureActual/10);
      Serial.print(";");
      Serial.print(beerTemperatureSetting/10);
      Serial.print(";");

      switch(messageType){
        case BEER_SETTING_FROM_SERIAL:
          Serial.print("\"Beer temperature setting changed to ");
          Serial.print(int(beerTemperatureSetting+.5)/10); Serial.print("."); Serial.print(int(beerTemperatureSetting+.5)%10);    
          Serial.print(" via web interface.\"");
          break;
        case BEER_SETTING_FROM_FRIDGE:
          Serial.print("\"Beer temperature setting changed to ");
          Serial.print(int(beerTemperatureSetting+.5)/10); Serial.print("."); Serial.print(int(beerTemperatureSetting+.5)%10);    
          Serial.print(" via fridge menu.\"");
          break;  
        case BEER_SETTING_FROM_PROFILE:
          Serial.print("\"Beer temperature setting changed to ");
          Serial.print(int(beerTemperatureSetting+.5)/10); Serial.print("."); Serial.print(int(beerTemperatureSetting+.5)%10);    
          Serial.print(" according to temperature profile.\"");
          break;
        default:
          Serial.println("\"Error: Unknown Beer Message Type!\"");
      }
      
      
      Serial.print(";");
      Serial.print(fridgeTemperatureActual/10);
      Serial.print(";");
      Serial.print(fridgeTemperatureSetting/10);
      Serial.println(";");
}

void serialFridgeMessage(int messageType){
      Serial.print(beerTemperatureActual/10); 
      Serial.print(";");
      Serial.print(beerTemperatureSetting/10);
      Serial.print(";");
      Serial.print(";");
      Serial.print(fridgeTemperatureActual/10);
      Serial.print(";");
      Serial.print(fridgeTemperatureSetting/10);
      Serial.print(";");
      
      switch(messageType){
        case FRIDGE_SETTING_FROM_SERIAL:
          Serial.print("\"Fridge temperature setting changed to ");
          Serial.print(int(fridgeTemperatureSetting+.5)/10); Serial.print("."); Serial.print(int(fridgeTemperatureSetting+.5)%10);    
          Serial.println(" via web interface.\"");
          break;
        case FRIDGE_SETTING_FROM_FRIDGE:
          Serial.print("\"Fridge temperature setting changed to ");
          Serial.print(int(fridgeTemperatureSetting+.5)/10); Serial.print("."); Serial.print(int(fridgeTemperatureSetting+.5)%10);    
          Serial.println(" via fridge menu.\"");
          break;
        case FRIDGE_DOOR_OPEN:
          Serial.println("\"Fridge door opened\"");
          break;
        case FRIDGE_DOOR_CLOSED:
          Serial.println("\"Fridge door closed\"");
          break;
        case POSPEAK:
          Serial.print("\"Positive peak detected: ");
          Serial.print(int(posPeak+.5)/10); Serial.print("."); Serial.print(int(posPeak+.5)%10);    
          Serial.print(" instead of ");
          Serial.print(int(fridgeSettingForPosPeakEstimate+.5)/10); Serial.print("."); Serial.print(int(fridgeSettingForPosPeakEstimate+.5)%10);
          Serial.print(" New estimator = ");
          Serial.print(heatOvershootEstimator);
          Serial.println(" \"");
          break;
        case NEGPEAK:
          Serial.print("\"Negative peak detected: ");
          Serial.print(int(negPeak+.5)/10); Serial.print("."); Serial.print(int(negPeak+.5)%10);
          Serial.print(" instead of ");
          Serial.print(int(fridgeSettingForNegPeakEstimate+.5)/10); Serial.print("."); Serial.print(int(fridgeSettingForNegPeakEstimate+.5)%10);
          Serial.print(" New estimator = ");
          Serial.print(coolOvershootEstimator);
          Serial.println(" \"");
          break;
        case POSDRIFT:
          Serial.print("\"Drifting after heating too short: ");
          Serial.print(int(posPeak+.5)/10); Serial.print("."); Serial.print(int(posPeak+.5)%10);    
          Serial.print(" New estimator = ");
          Serial.print(heatOvershootEstimator);
          Serial.println(" \"");
          break;
        case NEGDRIFT:
          Serial.print("\"Drifting after cooling too short: ");
          Serial.print(int(negPeak+.5)/10); Serial.print("."); Serial.print(int(negPeak+.5)%10);    
          Serial.print(" New estimator = ");
          Serial.print(coolOvershootEstimator);
          Serial.println(" \"");
          break;          
          
        case ARDUINO_START:
          Serial.println("\" Arduino restarted! \"");
          break;
        default:
          Serial.println("\"Error: Unknown Fridge Message Type!\"");
      }
}
