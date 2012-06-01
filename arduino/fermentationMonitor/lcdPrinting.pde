#include "globals.h"
#include "enums.h"

//print all temperatures on the LCD
void lcdPrintAllTemperatures(void){
  lcdPrintTemperature(beerTemperatureActual,BEER_ACTUAL,0);
  lcdPrintTemperature(beerTemperatureSetting,BEER_SET,0);
  lcdPrintTemperature(fridgeTemperatureActual,FRIDGE_ACTUAL,0);
  lcdPrintTemperature(fridgeTemperatureSetting,FRIDGE_SET,0);
}

//print a temperature on the right location on the lcd.
void lcdPrintTemperature(float temperature, int pos, boolean printDegree){
  int temp=int(temperature+.5);
  switch(pos){
  case  BEER_ACTUAL:
    lcd.setCursor(7,1);
    break;
  case BEER_SET:
    lcd.setCursor(13,1);
    if(temp == 0){
      lcd.print(" -  ");
      return;
    }
    break;
  case FRIDGE_ACTUAL:
    lcd.setCursor(7,2);
    break;
  case FRIDGE_SET: 
    lcd.setCursor(13,2);
    break;
  case TEMP_MENU: 
    lcd.setCursor(0,2);
    break;
  case TEMP_CONFIRM: 
    lcd.setCursor(11,1);
    break;
  }
  int decimal = temp % 10;
  int whole = temp/10;
  if(whole < 10){
    lcd.print(" ");
  }
  lcd.print(whole);
  lcd.print(".");
  lcd.print(decimal);
  if(printDegree){
    lcd.print(" ");
    lcdPrintDegreeCelcius();
  }
}

//print the stationary text on the lcd.
void lcdPrintStationaryText(void){
  lcd.clear();
  lcd.home();

  lcd.setCursor(0,0);
  // help:  "01234567890123456789" 
  lcd.print("Mode: ");

  lcd.setCursor(0,1);
  lcd.print("Beer   00.0  00.0 "); 
  lcdPrintDegreeCelcius(); 

  lcd.setCursor(0,2);
  lcd.print("Fridge 00.0  00.0 "); 
  lcdPrintDegreeCelcius();

  lcd.setCursor(0,3);
  lcd.print("Starting up...");
}

//print degree sign + C
void lcdPrintDegreeCelcius(void){
  lcd.write(0b11011111);
  lcd.print("C");
}

// Print mode on the right location on the first line, after Mode: 
void lcdPrintMode(void){
   lcd.setCursor(6,0);
   switch(mode){
     case FRIDGE_CONSTANT:
        lcd.print("Fridge Const. ");
        break;
     case BEER_CONSTANT:
        lcd.print("Beer Constant ");
        break;
     case BEER_PROFILE:
        lcd.print("Beer Profile  ");
        break;
    default:
        lcd.print("Invalid mode  ");
        break;
   }  
}

// print the current state on the last line of the lcd
void lcdPrintState(void){
  if(state!=previousState){ //only print state when it has changed
    lcd.setCursor(0,3); 
    lcd.print("                    "); //clear line
  }
  // allign:  "01234567890123456789" 
  lcd.setCursor(0,3); 
  switch (state){
  case IDLE:
    if(previousState==IDLE){
      lcd.setCursor(9,3);
      lcd.print((millis()-max(lastCoolTime,lastHeatTime))/1000);
      lcd.print(" s");      
    }
    else{
      lcd.print("Idle for ");
      lcd.print((millis()-max(lastCoolTime,lastHeatTime))/1000);
      lcd.print(" s");
    }
    break;
  case STARTUP:
    lcd.print("Starting up...");
    break;
  case COOLING:
    if(previousState==COOLING){
      lcd.setCursor(12,3);
      lcd.print((millis()-lastIdleTime)/1000);
      lcd.print(" s");      
    }
    else{
      lcd.print("Cooling for ");
      lcd.print((millis()-lastIdleTime)/1000);
      lcd.print(" s");
    }
    break;
  case HEATING:
    if(previousState==HEATING){
      lcd.setCursor(12,3);
      lcd.print((millis()-lastIdleTime)/1000);
      lcd.print(" s");      
    }
    else{
      lcd.print("Heating for ");
      lcd.print((millis()-lastIdleTime)/1000);
      lcd.print(" s");
    }
    break;
  case DOOR_OPEN:
    lcd.print("Door Open");
    break;   
  default:
    lcd.print("Unknown Status!");
    break;
  }
  previousState = state;
}

// print the static text of a menu page
void lcdPrintMenu(int menuPage){
  switch(menuPage){
    case MENU_TOP:
      lcd.clear();
      lcd.setCursor(0,0);
      //help:   "01234567890123456789" 
      lcd.print("Select Mode:");

      lcd.setCursor(0,1);
      lcd.print("  Beer Profile");

      lcd.setCursor(0,2);
      lcd.print("  Beer Constant");

      lcd.setCursor(0,3);
      lcd.print("  Fridge Constant"); 
    break;

    case MENU_BEER_SETTING:
      lcd.clear();
      lcd.setCursor(0,0);
      lcd.print("Set new constant");
      lcd.setCursor(0,1);
      lcd.print("beer temperature:");
      lcd.setCursor(0,2);
      lcd.print("    "); lcdPrintDegreeCelcius();
    break;

    case MENU_FRIDGE_SETTING:
      lcd.clear();
      lcd.setCursor(0,0);
      lcd.print("Set new constant");
      lcd.setCursor(0,1);
      lcd.print("fridge temperature:");
      lcd.setCursor(0,2);
      lcd.print("    "); lcdPrintDegreeCelcius();
    break;
    
    case MENU_PROFILE_SETTING:
      lcd.clear();
      lcd.setCursor(0,0);
      lcd.print("Press OK to confirm");
      lcd.setCursor(0,1);
      lcd.print("profile mode");
    break;  
  }

}

// 3 functions to print conformation of a setting via the menu
void lcdPrintBeerSetting(void){
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("Beer temperature");
    lcd.setCursor(0,1);
    lcd.print("is set to ");
    lcdPrintTemperature(beerTemperatureSetting,TEMP_CONFIRM,1);
}

void lcdPrintProfileSetting(void){
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("Mode is set to:");
    lcd.setCursor(0,1);
    lcd.print("Beer Profile");
    lcd.setCursor(0,2);
    lcd.print("(Set profile in");
    lcd.setCursor(0,3);
    lcd.print("web interface)");
}

void lcdPrintFridgeSetting(void){
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("Fridge temperature");
    lcd.setCursor(0,1);
    lcd.print("is set to ");
    lcdPrintTemperature(fridgeTemperatureSetting,TEMP_CONFIRM,1);
}

void lcdReadContents  (void){
  lcd.setCursor(0,0);
  for(int i =0;i<20;i++){
      lcdText[0][i] = lcd.readChar();
  }
  for(int i =0;i<20;i++){
      lcdText[2][i] = lcd.readChar();
  }
  lcd.setCursor(0,1);
  for(int i =0;i<20;i++){
      lcdText[1][i] = lcd.readChar();
  }
  for(int i =0;i<20;i++){
      lcdText[3][i] = lcd.readChar();
  }
}

