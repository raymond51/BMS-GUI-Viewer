// If you want to debug the plotter without using a real serial port

int mockupValue = 0; // real time value subject to volitality
int mockupDirection = 10; //incremental value, used to create linear triangular waveforms
int delayIncrementer = 0;
float lastEmulatedGearVal = 0;


//csv generation function, we will be using space a delimiters not commas
String mockupSerialFunction() {
  //triangle wave generator
  mockupValue = (mockupValue + mockupDirection);
  if (mockupValue > 100)
    mockupDirection = -10;
  else if (mockupValue <= 0)
    mockupDirection = 10;
   
  String r = ""; //initialising csv string
  for (int i = 0; i<6; i++) {//6 test cases for 6 different graphs, we only have 4 graphs
    //each incremental case indicates increments in csv e.g case 0 corrosponds to position 1 in csv
    switch (i) {
    case 0: 
      float buff0=0+(mockupValue);
      r += buff0+","; //using divisor such as 7 to fit triangle wave on small scale graphs
      sensorValues[0]=buff0;
      break;
    case 1: 
    if(delayIncrementer<10){
      float buff1 = lastEmulatedGearVal;
      r += buff1+",";
      sensorValues[1]=buff1;
       delayIncrementer+=1;
    }else{
      float temp = random(3);
      r += temp+",";
      lastEmulatedGearVal=temp;
      delayIncrementer=0;
    }
      break; 
    case 2: 
    float buff2 = 40*cos(mockupValue*(2*3.14)/1000);
      r += buff2+",";
      sensorValues[2]=buff2;
      break;
    case 3:
    float buff3 = mockupValue/4;
      r += buff3+",";
      sensorValues[3]=buff3;
      break;
    case 4: 
       sensorValues[4]= 11 + random(-2,2);
      break;
    case 5:
      
      break;
    }
    if (i < 7)
      r += '\r'; // return carriage to simulate a newline, required to terminate csv string
  }
  delay(10);
  return r;
}
