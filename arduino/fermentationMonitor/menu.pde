#include "globals.h"
#include "enums.h"

//display a the menu at the given page
void menu(int menuPage){ 
  int newTemp =-1;
  switch(menuPage){
     case MENU_TOP:
       lcdPrintMenu(MENU_TOP);
       while(analogRead(button3)>900); //wait for button3 release
       switch(menuChoice(3)){
         case 0:
           menu(MENU_PROFILE_SETTING);
           break;        
         case 1:
           menu(MENU_BEER_SETTING);
           break;
         case 2:
           menu(MENU_FRIDGE_SETTING);
           break;
         default:
           break;//timeout
       }
       break;
     case MENU_BEER_SETTING:
        lcdPrintMenu(MENU_BEER_SETTING);
        newTemp = menuTemp(beerTemperatureSetting);
        if(newTemp>0){
          beerTemperatureSetting = newTemp;
          mode=BEER_CONSTANT;
          doNegPeakDetect=0;
          doPosPeakDetect=0;
          lastCoolTime=0;
          lastHeatTime=0;
          lcdPrintBeerSetting();
          saveSettings();
          delay(3000);
        }
        break;
     case MENU_FRIDGE_SETTING:
        lcdPrintMenu(MENU_FRIDGE_SETTING);
        newTemp = menuTemp(fridgeTemperatureSetting);
        if(newTemp>0){
          fridgeTemperatureSetting = newTemp;
          mode=FRIDGE_CONSTANT;
          doNegPeakDetect=0;
          doPosPeakDetect=0;
          lastCoolTime=0;
          lastHeatTime=0;
          lcdPrintFridgeSetting();
          saveSettings();
          delay(3000);
        }
        break;
      case MENU_PROFILE_SETTING:
        lcdPrintMenu(MENU_PROFILE_SETTING);
        if(menuConfirm()){
          lcdPrintProfileSetting();
          mode=BEER_PROFILE;
          doNegPeakDetect=0;
          doPosPeakDetect=0;
          lastCoolTime=0;
          lastHeatTime=0;
          saveSettings();
          delay(3000);
        }
        break;

  }
  lcdPrintStationaryText(); //put stationary text back on the lcd
  previousState=0xFF; //force LCD update      
  state=IDLE;
  lcdPrintState();
  lcdPrintMode();
}

// let the user pick one of the options in the menu and draw an arrow at the active choice
int menuChoice(int numberOfOptions){ 
  int choice=0;
  lcd.setCursor(0,1);
  lcd.print(">");
  
  unsigned long resetTime=millis();
  while(millis() < (resetTime + 10000)){ //timeout after 10 seconds
    if(analogRead(button2)>900){ //up
      if(millis() > (resetTime+300)){ //increase every half second
        resetTime=millis();
        choice = (choice-1+numberOfOptions)%numberOfOptions;
        //clear arrows
        lcd.setCursor(0,1);
        lcd.print(" "); 
        lcd.setCursor(0,2);
        lcd.print(" ");
        lcd.setCursor(0,3);
        lcd.print(" ");
        //print arrow for active choice
        lcd.setCursor(0,choice+1);
        lcd.print(">");
      }
    }
    if(analogRead(button1)>900){ //down
      if(millis() > (resetTime+300)){ //decrease every half second
        resetTime=millis();
        //clear arrows
        choice = (choice+1)%numberOfOptions;
        lcd.setCursor(0,1);
        lcd.print(" ");
        lcd.setCursor(0,2);
        lcd.print(" ");
        lcd.setCursor(0,3);
        lcd.print(" ");
        //print arrow for active choice
        lcd.setCursor(0,choice+1);
        lcd.print(">");
      }
    } 
    if(analogRead(button3)>900){ //confirm button
      while(analogRead(button3)>100); //wait for release
      return choice;
    }
  }
  return -1;
}

int menuTemp(int initialTemp){
  int newTemp;
  unsigned long resetTime=millis();
  newTemp = initialTemp;
  lcdPrintTemperature(newTemp, TEMP_MENU,1);
  while(millis() < (resetTime + 10000)){ //timeout after 10 seconds
    if(analogRead(button2)>900){
      if(millis() > (resetTime+500)){ //increase every half second
        newTemp=(newTemp+1)%300; //keep between 0 and 30 degrees
        resetTime=millis(); //reset timeout
        lcdPrintTemperature(newTemp, TEMP_MENU,1);
      }
    }
    if(analogRead(button1)>900){
      if(millis() > (resetTime+500)){ //decrease every half second
        newTemp=(newTemp+299)%300; //keep between 0 and 30 degrees
        resetTime=millis(); //reset timeout
        lcdPrintTemperature(newTemp, TEMP_MENU,1);
      }
    }
    if(analogRead(button3)>900){ //confirm button
      while(analogRead(button3)>100); //wait for release
      return newTemp;
    }
  }
  return -1; //return -1 on timeout
}

boolean menuConfirm(){
  unsigned long resetTime=millis();
  while(millis() < (resetTime + 10000)){ //timeout after 10 seconds
    if(analogRead(button3)>900){ //confirm button
      while(analogRead(button3)>100); //wait for release
      return 1;
    }
  }
  return 0;
}


