#include "globals.h"
#include "enums.h"

#define NUM_READS 100
float readTemperature(int sensorpin){
   // read multiple values and sort them to take the mode
   int sortedValues[NUM_READS];
   for(int i=0;i<NUM_READS;i++){
     int value = analogRead(sensorpin);
     int j;
     if(value<sortedValues[0] || i==0){
        j=0; //insert at first position
     }
     else{
       for(j=1;j<i;j++){
          if(sortedValues[j-1]<=value && sortedValues[j]>=value){
            // j is insert position
            break;
          }
       }
     }
     for(int k=i;k>j;k--){
       // move all values higher than current reading up one position
       sortedValues[k]=sortedValues[k-1];
     }
     sortedValues[j]=value; //insert current reading
   }
   //return scaled mode of 10 values
   float returnval = 0;
   for(int i=NUM_READS/2-5;i<(NUM_READS/2+5);i++){
     returnval +=sortedValues[i];
   }
   returnval = returnval/10;
   return returnval*1100/1023;
}

void updateTemperatures(void){ //called every 200 milliseconds  
  fridgeTempFast[0] = fridgeTempFast[1]; fridgeTempFast[1] = fridgeTempFast[2]; fridgeTempFast[2] = fridgeTempFast[3]; 
  fridgeTempFast[3] = readTemperature(fridgePin); 

  // Butterworth filter with cutoff frequency 0.033*sample frequency (FS=5Hz)
  fridgeTempFiltFast[0] = fridgeTempFiltFast[1]; fridgeTempFiltFast[1] = fridgeTempFiltFast[2]; fridgeTempFiltFast[2] = fridgeTempFiltFast[3];
  fridgeTempFiltFast[3] =   (fridgeTempFast[0] + fridgeTempFast[3] + 3 * (fridgeTempFast[1] + fridgeTempFast[2]))/1.092799972e+03
              + ( 0.6600489526    * fridgeTempFiltFast[0]) + (  -2.2533982563     * fridgeTempFiltFast[1]) + ( 2.5860286592 * fridgeTempFiltFast[2] ); 

  fridgeTemperatureActual = fridgeTempFiltFast[3];

  beerTempFast[0] = beerTempFast[1]; beerTempFast[1] = beerTempFast[2]; beerTempFast[2] = beerTempFast[3]; 
  beerTempFast[3] = readTemperature(beerPin); 

  // Butterworth filter with cutoff frequency 0.01*sample frequency (FS=5Hz)
  beerTempFiltFast[0] = beerTempFiltFast[1]; beerTempFiltFast[1] = beerTempFiltFast[2]; beerTempFiltFast[2] = beerTempFiltFast[3];
  beerTempFiltFast[3] =   (beerTempFast[0] + beerTempFast[3] + 3 * (beerTempFast[1] + beerTempFast[2]))/3.430944333e+04
              + ( 0.8818931306    * beerTempFiltFast[0]) + (  -2.7564831952     * beerTempFiltFast[1]) + ( 2.8743568927 * beerTempFiltFast[2] ); 

  beerTemperatureActual = beerTempFiltFast[3];
}

void updateSlowFilteredTemperatures(void){ //called every 10 seconds
  // Input for filter
  fridgeTempSlow[0] = fridgeTempSlow[1]; fridgeTempSlow[1] = fridgeTempSlow[2]; fridgeTempSlow[2] = fridgeTempSlow[3]; 
  fridgeTempSlow[3] = fridgeTempFiltFast[3]; 
  
  // Butterworth filter with cutoff frequency 0.01*sample frequency (FS=0.1Hz)
  fridgeTempFiltSlow[0] = fridgeTempFiltSlow[1]; fridgeTempFiltSlow[1] = fridgeTempFiltSlow[2]; fridgeTempFiltSlow[2] = fridgeTempFiltSlow[3];
  fridgeTempFiltSlow[3] =   (fridgeTempSlow[0] + fridgeTempSlow[3] + 3 * (fridgeTempSlow[1] + fridgeTempSlow[2]))/3.430944333e+04
              + ( 0.8818931306    * fridgeTempFiltSlow[0]) + (  -2.7564831952     * fridgeTempFiltSlow[1]) + ( 2.8743568927 * fridgeTempFiltSlow[2] ); 
               
  beerTempSlow[0] = beerTempSlow[1]; beerTempSlow[1] = beerTempSlow[2]; beerTempSlow[2] = beerTempSlow[3]; 
  beerTempSlow[3] = beerTempFiltFast[3]; 
  
   // Butterworth filter with cutoff frequency 0.01*sample frequency (FS=0.1Hz)
  beerTempFiltSlow[0] = beerTempFiltSlow[1]; beerTempFiltSlow[1] = beerTempFiltSlow[2]; beerTempFiltSlow[2] = beerTempFiltSlow[3];
  beerTempFiltSlow[3] =   (beerTempSlow[0] + beerTempSlow[3] + 3 * (beerTempSlow[1] + beerTempSlow[2]))/3.430944333e+04
              + ( 0.8818931306    * beerTempFiltSlow[0]) + (  -2.7564831952     * beerTempFiltSlow[1]) + ( 2.8743568927 * beerTempFiltSlow[2] ); 
}

void updateSlope(void){ //called every minute
  beerTempHistory[beerTempHistoryIndex]=beerTempFiltSlow[3];
  beerSlope = beerTempHistory[beerTempHistoryIndex]-beerTempHistory[(beerTempHistoryIndex+1)%30];
  beerTempHistoryIndex = (beerTempHistoryIndex+1)%30;
}

void initFilters(void){
  beerTemperatureActual = readTemperature(beerPin);
  fridgeTemperatureActual = readTemperature(fridgePin);
  for(int i=0;i<4;i++){
    fridgeTempFast[i]=fridgeTemperatureActual;
    fridgeTempFiltFast[i]=fridgeTemperatureActual;
    beerTempFast[i]=beerTemperatureActual;
    beerTempFiltFast[i]=beerTemperatureActual;
  }
  for(int i=0;i<100;i++){
    updateTemperatures();
  }
  for(int i=0;i<4;i++){
    fridgeTempSlow[i]=fridgeTempFiltFast[3];
    fridgeTempFiltSlow[i]=fridgeTempFiltFast[3];
    beerTempSlow[i]=beerTempFiltFast[3];
    beerTempFiltSlow[i]=beerTempFiltFast[3];
  }
  for(int i=0;i<100;i++){
    updateSlowFilteredTemperatures();
  }
  for(int i=0;i<30;i++){
    beerTempHistory[i]=beerTempFiltSlow[3]; 
  }
  beerSlope=0;
  beerTempHistoryIndex=0;
}
