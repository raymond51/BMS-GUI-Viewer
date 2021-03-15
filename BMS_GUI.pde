import controlP5.*; //<>//
import processing.serial.*; //library to access serial comms

//Debugging console messages
boolean printlineEnable=true;//Enable/disable println message to console [FOR DEBUGGING PURPOSES]
boolean eventActionDisplay = false; //Enable/disable event and controller messages
boolean printBuffer = true;//Enable/disable print sensor value buffers

public static float[] sensorValues = new float[25]; //battery pack voltage, pack current, temperature, 0,cellv1,cellv2,cellv3,cellv4,cellv5, SOC_1, SOC_2, SOC_3, SOC_4, SOC_5,XR_error,alert_error,uv_error,ov_error,scd_error,ocd_error
//Serial comms
Serial port;
String Buffer; //holds the csv received 
final int baudRate = 9600; //define baud rate of serial communicate
DropdownList commsdroplist; 
String portName;
boolean serialConnected = false;
boolean mockupSerial = false;
ControlP5 cP5; //create object of GUI class

//Chart info
static final int chartxPos = 870;
static final int chartDefaultHeight = 100;
static final int chartxBase = 110;
// plots
Graph LineGraph_Battery_pack_V = new Graph(chartxPos, chartxBase, 1000, chartDefaultHeight, color (0, 0, 0));
Graph LineGraph_Battery_pack_current = new Graph(chartxPos, (chartxBase+(chartDefaultHeight*2)*1), 1000, chartDefaultHeight, color (0, 0, 0));
Graph LineGraph_Battery_pack_cell_temp = new Graph(chartxPos, (chartxBase+(chartDefaultHeight*2)*2), 1000, chartDefaultHeight, color (0, 0, 0));
Graph LineGraph_unused = new Graph(chartxPos, (chartxBase+(chartDefaultHeight*2)*3), 1000, chartDefaultHeight, color (0, 0, 0));
float[] barChartValues = new float[6];
float[][] lineGraphValues = new float[6][100];
float[] lineGraphSampleNumbers = new float[100];
String[] nums;
final int graphDisplays = 4;

/*------------------------------------------------------------------------------------------------------------------------------------------------
*/
void setup() {
  surface.setTitle("BMS data viewer"); // Software Title
  size(1920, 1000);//define the size of windows
  centerWindow();
  background(0);//set background to RGB value of 0,0,0 -> BLACK background
  cP5 = new ControlP5(this);

  //drop down menu for coms
  commsdroplist = cP5.addDropdownList("Select COM PORT").setPosition(280, 25);
  // add items to the dropdownlist
  for (int i=0; i<=15; i++) {
    commsdroplist.addItem("COM " + i, i);
  }

  //COM connect button
  cP5.addButton("CONNECT").setPosition(400,20).setSize(80,40).setColorBackground(color(44, 132, 255));
  cP5.addButton("PING").setPosition(610,20).setSize(80,40).setColorBackground(color(44, 132, 255));
  //stop recording
    cP5.addButton("STOP").setPosition(700,20).setSize(80,40).setColorBackground(color(44, 132, 255));
  //Enable emulation mode
    cP5.addButton("EMULATION MODE").setPosition(610,70).setSize(170,40).setColorBackground(color(44, 132, 255));
  initDisplayElements();

  setChartSettings(); //init chart
  // build x axis values for the line graph
  for (int i=0; i<lineGraphValues.length; i++) {
    for (int k=0; k<lineGraphValues[0].length; k++) {
      lineGraphValues[i][k] = 0;
      if (i==0)
        lineGraphSampleNumbers[k] = k;
    }
  }
}

/*------------------------------------------------------------------------------------------------------------------------------------------------
 @Brief:Main loop
 */
int i = 0; // loop variable
void draw() {
  background(0); // set background to be black color
  drawConsole(); 
  
  /* Read serial and update values */
  //if (mockupSerial || serialPort.available() > 0) {
  String myString = ""; //temporary buffer used when no serial connected
  //if (!mockupSerial&&serialConnected) {
  if (serialConnected) {
    myString = Buffer;
  } else {
    if(mockupSerial){
    myString = mockupSerialFunction();
    }else{
    myString = "0,0,0,0,0,0";
    }
  }

  nums = split(myString, ',');
  // update line graph
  for (i=0; i<graphDisplays; i++) {
    try {
      if (i<lineGraphValues.length) { //loop to the amount of graph displayed = 4
        for (int k=0; k<lineGraphValues[i].length-1; k++) {
          lineGraphValues[i][k] = lineGraphValues[i][k+1];
        }
        if (serialConnected) {
          if(i==2){
          lineGraphValues[i][lineGraphValues[i].length-1] = sensorValues[i]/100.0;
          }else{
          lineGraphValues[i][lineGraphValues[i].length-1] = sensorValues[i]/1000.0; //correct offset multiplication
          }
        } else {
          lineGraphValues[i][lineGraphValues[i].length-1] = float(nums[i])*1;
        }
      }
    }
    catch (Exception e) {
    }
  }


  // draw the line graphs
  LineGraph_Battery_pack_V.DrawAxis();
  for (i=0; i<lineGraphValues.length; i++) {
    LineGraph_Battery_pack_V.GraphColor = color(200, 46, 232); //set color of lines

    LineGraph_Battery_pack_V.LineGraph(lineGraphSampleNumbers, lineGraphValues[0]); //view graph values of RPM at array of index 0
  }


  LineGraph_Battery_pack_current.DrawAxis();
  for (i=0; i<lineGraphValues.length; i++) {
    LineGraph_Battery_pack_current.GraphColor = color(232, 158, 12);//color of graph lines

    LineGraph_Battery_pack_current.LineGraph(lineGraphSampleNumbers, lineGraphValues[1]);
  }

  LineGraph_Battery_pack_cell_temp.DrawAxis();
  for (i=0; i<lineGraphValues.length; i++) {
    LineGraph_Battery_pack_cell_temp.GraphColor = color(131, 255, 20);

    LineGraph_Battery_pack_cell_temp.LineGraph(lineGraphSampleNumbers, lineGraphValues[2]);
  }

  LineGraph_unused.DrawAxis();
  for (i=0; i<lineGraphValues.length; i++) {
    LineGraph_unused.GraphColor = color(255, 0, 0);

    LineGraph_unused.LineGraph(lineGraphSampleNumbers, lineGraphValues[3]);
  }

  if (serialConnected||mockupSerial) {
    updateConsoleBox();
  }
}


void centerWindow() {
  if (frame!=null) {
    frame.setLocation(displayWidth/2-width/2, displayHeight/2-height/2);
  }
}

/*------------------------------------------------------------------------
 @Brief:Configure graph settings
 */
void setChartSettings() {
  LineGraph_Battery_pack_V.yLabel="";
  LineGraph_Battery_pack_V.xLabel="";
  LineGraph_Battery_pack_V.xMax=0; 
  LineGraph_Battery_pack_V.xMin=-100;
  LineGraph_Battery_pack_V.Title="Battery pack voltage (V)";  
  LineGraph_Battery_pack_V.yDiv=5;  
  LineGraph_Battery_pack_V.yMax=25; 
  LineGraph_Battery_pack_V.yMin=0;
  //----------------------
  LineGraph_Battery_pack_current.yLabel="";
  LineGraph_Battery_pack_current.xLabel="";
  LineGraph_Battery_pack_current.xMax=0; 
  LineGraph_Battery_pack_current.xMin=-100;
  LineGraph_Battery_pack_current.Title="Pack Current (A)";  
  LineGraph_Battery_pack_current.yDiv=3;  
  LineGraph_Battery_pack_current.yMax=3; 
  LineGraph_Battery_pack_current.yMin=0;
  //-----------------------
  LineGraph_Battery_pack_cell_temp.yLabel="";
  LineGraph_Battery_pack_cell_temp.xLabel="";
  LineGraph_Battery_pack_cell_temp.xMax=0; 
  LineGraph_Battery_pack_cell_temp.xMin=-100;
  LineGraph_Battery_pack_cell_temp.Title="Cell Temperature (degrees C)";  
  LineGraph_Battery_pack_cell_temp.yDiv=6;  
  LineGraph_Battery_pack_cell_temp.yMax=60; 
  LineGraph_Battery_pack_cell_temp.yMin=0;
  //------------------------
  LineGraph_unused.yLabel="";
  LineGraph_unused.xLabel="";
  LineGraph_unused.xMax=0; 
  LineGraph_unused.xMin=-100;
  LineGraph_unused.Title="";  
  LineGraph_unused.yDiv=6;  
  LineGraph_unused.yMax=120; 
  LineGraph_unused.yMin=0;
}

void initDisplayElements() {
  //desc: a slider horiz or verti
  //param: name,minimum,maximum,default value(float),x,y,width,height
  cP5.addSlider("Cell 1", 0, 100, 128, 50, 270, 40, 150);
  cP5.addSlider("Cell 2", 0, 100, 128, 150, 270, 40, 150);  
  cP5.addSlider("Cell 3", 0, 100, 128, 250, 270, 40, 150);  
  cP5.addSlider("Cell 4", 0, 100, 128, 350, 270, 40, 150);  
  cP5.addSlider("Cell 5", 0, 100, 128, 450, 270, 40, 150);  
}

void drawConsole() { 
  //draw outline rect console
  stroke(255);
  fill(0);
  rect(30, 530, 720, 440);
  //draw top right console
  stroke(255);
  fill(0);
  rect(790, 5, 1100, 50);
}

/*------------------------------------------------------------------------
 @Brief:function to handle CP5 interrupts
 */
void controlEvent(ControlEvent theEvent) {
  String name = theEvent.getController().getName();
  if (name.equals("CONNECT")) {
    try {
      port = new Serial(this, portName, baudRate);
      port.bufferUntil('\n');
      serialConnected=true;
      //Indicate to the user that the com port connection is secured
      theEvent.getController().setCaptionLabel("Connected"); 
      theEvent.getController().setColorBackground(color(53, 255, 73));
    }
    catch(Exception e) {
      if (printlineEnable)
        System.err.println("Error opening Serial port "+ portName);
      e.printStackTrace();
    }
    if (printlineEnable)
      println("Connected to " + portName + " at Baud rate: " + baudRate);
  } else if (name.equals("PING")) {
    port.write('P');
  } else if (name.equals("STOP")) {
  } else if (name.equals("Select COM PORT")) {
    portName = "COM"+int(theEvent.getController().getValue());
  } else if (name.equals("EMULATION MODE")) {
    mockupSerial = !mockupSerial;
    if(mockupSerial)
   theEvent.getController().setColorBackground(color(53, 255, 73)); //set the background color of the button to green for user indication
    else
    theEvent.getController().setColorBackground(color(44, 132, 255));  
  } 

  if (eventActionDisplay) {
    if (theEvent.isGroup()) {
      // check if the Event was triggered from a ControlGroup
      println("event from group : "+theEvent.getGroup().getValue()+" from "+theEvent.getGroup());
    } else if (theEvent.isController()) {
      println("event from controller : "+ int(theEvent.getController().getValue())+" from "+theEvent.getController());
    }
  }
}

/*------------------------------------------------------------------------
 @Brief:function to handle serial interupts
 */
void serialEvent(Serial port) {
  Buffer = port.readString();//read csv into buffer
  sensorValues = float(split(Buffer, ','));//Separate csv
  if (printBuffer)
    println(Buffer);
}

/*------------------------------------------
 @Brief: Update values within the console box
 */
void updateConsoleBox() {
  try {
    cP5.getController("Cell 1").setValue(sensorValues[9]);
    cP5.getController("Cell 2").setValue(sensorValues[10]);
    cP5.getController("Cell 3").setValue(sensorValues[11]);
    cP5.getController("Cell 4").setValue(sensorValues[12]);
    cP5.getController("Cell 5").setValue(sensorValues[13]);

    
    textSize(25);
    //left side text
    text("Console Box", 260, 525);
    text("State of charge", 260, 200);
    textSize(18);
    text("Battery Pack Voltage: "+sensorValues[0]/1000.0+" V", 300, 600);
    text("Load Current: "+sensorValues[1]/1000.0+" A", 300, 620);
    text("Temperature of cells: "+sensorValues[2]/100.0+" C", 300, 640);
    text("Cell 1 V:"+sensorValues[4]/1000.0 , 300, 750);
    text("Cell 2 V:"+sensorValues[5]/1000.0 , 300, 790);
    text("Cell 3 V:"+sensorValues[6]/1000.0 , 300, 830);
    text("Cell 4 V:"+sensorValues[7]/1000.0 , 300, 870);
    text("Cell 5 V:"+sensorValues[8]/1000.0 , 300, 910);
    //--------------------------------------------------
    //right side text
    text("BMS Status ", 700, 600);
    text("XR error: " +sensorValues[14] , 700, 620);
    text("Alert error: "+sensorValues[15], 700, 640);
    text("Under-volt error: "+sensorValues[16], 700, 660);
    text("Over-volt error: " +sensorValues[17], 700, 680);
    text("Short-circuit error: " +sensorValues[18], 700, 700);
    text("Over-current discharge error: " +sensorValues[19], 700, 720);
    text("MOSFET Status ", 700, 760);
    text("Charge Fet enabled? " +sensorValues[20], 700, 780);
    text("Discharge Fet enabled?  " +sensorValues[21], 700, 800);
  }
  catch(Exception e) {
    if (printlineEnable)
      System.err.println("NULL sensor values");
    e.printStackTrace();
  }
}
