/* 
 
 Image presentation application.
 
 Description:
 Two concecutive images are presented to the user, who then responds to one question.
 Two modes of response: manual input or slider are available.
 
 Author: Panos Mavros
 Centre for Advanced Spatial Analysis, University College London
 
 */

import controlP5.*;
import oscP5.*;
import netP5.*;
import java.util.Timer;
import java.util.TimerTask;

ControlP5 cp5;
OscP5 oscP5;
NetAddress myRemoteLocation;

// GUI
int fc = 10;
int w = 600;
int h = w;

// Elements
PImage stim_1;
PImage stim_2;
Textfield participantID;
Textfield response;
PrintWriter output;
Table table;
  
// Settings
int firstInterval = 2000;
int firstStimulus = 4000;
int secondInterval = 6000;
int secondStimulus = 8000;


// constants
int remainingTrials = 0; // gets updated in setup by the file
int startTime =0;
int index = 0; 
int startCountDown; // hadles delay before closing application
int od = 0; // correctResponse

// confirmations
boolean welcome = true;
boolean testing = false;
boolean trialInProgress = false;
boolean recording = false;
boolean distanceChanged = false;


void setup() {
  size(w, h);
  
  table = loadTable("experiment_settings.csv", "header, csv");
  println(table.getRowCount());
  
  remainingTrials = table.getRowCount();
  
//  for (TableRow row : table.rows()) {
//      int od = row.getInt("objectiveDistance");
//      String image_1 = row.getString("Image_1");
//      String image_2 = row.getString("Image_2"); 
//  }
//  
 

  PFont font = createFont("arial", 24);
  textFont(font);
  textSize(24);
  cp5 = new ControlP5(this);

  participantID = cp5.addTextfield("Participant_ID")
    .setPosition(20, 100)
      .setSize(200, 40)
        .setFont(font)
          .setFocus(true)
            .setColor(color(255, 0, 0))
              ;

  cp5.addBang("start")
    .setPosition(240, 100)
      .setSize(80, 40)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
          ;  
        
  cp5.addSlider("distance")
     .setPosition(20,height-200)
      .setSize(400,20)
     .setRange(0,2000) // values can range from big to small as well
     .setValue(500)
     .setSliderMode(Slider.FIX)
     ;
       
 response = cp5.addTextfield("response")
 .setInputFilter(ControlP5.FLOAT)
    .setPosition(20, height-100)
      .setSize(200, 40)
        .setFont(font)
          .setFocus(true)
            .setColor(color(255, 0, 0))
              ;

  cp5.addButton("next")
    .setPosition(240, height-100)
      .setSize(80, 40)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)        
          ;    
          
          
  stim_1 = loadImage("Screen Shot 2015-10-30 at 16.01.10.png");
  stim_2 = loadImage("Screen Shot 2015-10-30 at 16.02.50.png");

  hideResponse();
  preloadImages();
  
  // for debugging
  remainingTrials=2;
}

void draw() {
  background(0);
 
 /*
   Experiment stage 
 */
  if (welcome) {
    // first get participant ID
    intro_screen();
  } else if (testing) {
    // then go through the trials
    showTrial ();
  } else {
    // finally thank participants and close gracefully
     textSize(24);
     text("That's it!\nThank you for taking part in this experiment.\nNow you can take a break,\nand then ask the researcher what to do next.", 20, height/2);    
     if(millis() - startCountDown > 10000){
       exit(); 
     }
  }
}

void intro_screen(){
  
}

void hideIntro() {
  cp5.get(Bang.class, "start").remove() ; 
  cp5.get(Textfield.class, "Participant_ID").hide();
  participantID.hide();
}

void showTrial () {
  textSize(12);
  textAlign(RIGHT, BOTTOM);
  text("Remaining rounds: "+remainingTrials, width-10, height-10);
  
  int elapsedTime = (millis()-startTime);

//int firstInterval = 2000;
//int secondInterval = 4000;
//int firstStimulus = 6000;
//int secondStimulus = 8000;

  if (trialInProgress) {

    // fixation
    if (elapsedTime < firstInterval) {
      fixationCross();
    } 
    // Image 1
    if (elapsedTime > firstInterval & elapsedTime < firstStimulus ) {
      image(stim_1, 0, 0);
      textAlign(CENTER, BOTTOM);
      text("Image 1", width/2, height/2);
    } 
    
    // fixation 
    if (elapsedTime > firstStimulus & elapsedTime < secondInterval ) {
      fixationCross();
    } 

    // Image 2
    if (elapsedTime > secondInterval & elapsedTime < secondStimulus ) {

      image(stim_2, 0, 0);
      textAlign(CENTER, BOTTOM);
      text("Image 2", width/2, height/2);
    } 

    // Response
    if (elapsedTime > 8000) {
      textSize(24);
      textAlign(LEFT, BOTTOM);
      text("What is the distance,\nbetween Location 1 and Location 2?", 20, height/2);
     
      if(!gettingResponse){
         askResponse();
         responseStart = millis();
         gettingResponse=true;
      }
      
    }
    
//    if (elapsedTime > 18000) {
//      trialInProgress=false;
//    }
  }
}

int responseStart = 0;
boolean gettingResponse = false;

void askResponse() {
  
  response.setVisible(true);
  response.clear();
  cp5.get(Slider.class, "distance").setVisible(true);
  cp5.get(Slider.class, "distance").setValue(500);
  cp5.get(Button.class, "next").setVisible(true);
  distanceChanged = false;
}

void hideResponse() {
  response.setVisible(false);
  cp5.get(Slider.class, "distance").setVisible(false);
  cp5.get(Button.class, "next").setVisible(false);
}



void logResponse(){
  
  int responseTime = millis() - responseStart;
  float subjectiveDistance = response.getValue();
  subjectiveDistance = cp5.get(Slider.class, "distance").getValue();
  
  println("distance is: "+response.getText()+" or "+cp5.get(Slider.class, "distance").getValue()+" after "+ responseTime );
        //  "index, image_1, image_2, response, responseTime, time, epoch"
    String log = lastIndex+","+
      table.getRow(lastIndex).getString("Image_1")+","+
      table.getRow(lastIndex).getString("Image_2")+","+
      table.getRow(lastIndex).getInt("objectiveDistance")+","+
      subjectiveDistance+","+
      responseTime+","+
      hour()+":"+minute()+":"+second()+","+
      System.currentTimeMillis();
    
    registerLog(log);  // Write data to the file
  
  gettingResponse = false;
  
}

int lastIndex = 0;

void trial(){
  lastIndex = index;
  trialInProgress=true;
  startTime = millis();
  distanceChanged = false;

}

void nextTrial(){
  
  hideResponse();
  
  println(remainingTrials);
  
  if(remainingTrials > 1){
    // go to next trial
    
    trial();
    
  } else {
    
    // that's it!
    testing = false;
    dataCollectionFinished();
    hideResponse();
    startCountDown = millis();
   
  }
  
  remainingTrials--;
  
}

void preloadImages(){
  
  index = table.getRowCount() - remainingTrials;   
  stim_1 = loadImage(table.getRow(index).getString("Image_1"));
  stim_2 = loadImage(table.getRow(index).getString("Image_2"));
  od = table.getRow(index).getInt("objectiveDistance");
  
}

public void controlEvent(ControlEvent theEvent) {
//  println(theEvent.getController().getName());

  if (theEvent.getController().getName()=="start") {
    
    // check participant has entered a name
    
   
    String id = participantID.getText();
   
    if(id!=null && id!=""&& id.length()> 0) {
      String timestamp = month()+year()+day()+"T"+hour()+"-"+minute()+"-"+second();
      output = createWriter("data/OxfordStreet_"+id+"_"+timestamp+"_data.csv"); 
      recording = true;
      
      // setup header
      String log = "index, image_1, image_2, correctResponse, response, responseTime, time, epoch";    
      registerLog(log);
      
      
      hideIntro();
      welcome = false;
      testing=true;
      trialInProgress= true;
      startTime = millis();
    
    
    } else {    
      textAlign(CENTER, LEFT);
      text("Did you enter your Participant ID?", 20, 20);   
    }
  }
  
  if (theEvent.getController().getName()=="distance") {
    distanceChanged = true;
  }
  
  if (theEvent.getController().getName()=="next") {
    println( int(response.getText()));
    if(int(response.getText())>=10){
      distanceChanged = true;
    }
      
    
      // confirm we have a response      
      if(distanceChanged){
        // hide response so that participants cannot change them
        hideResponse();  
        logResponse(); 
        nextTrial(); 
      }
    }
}


void registerLog (String thisLog) {
  output.println(thisLog);
  output.flush(); // Writes the remaining data to the file
}


void dataCollectionFinished() {

  if(recording){
//    "index, image_1, image_2, response, responseTime, time, epoch"
    String log = 1000+"end_of_experiment,"+ "NA" +", NA,"+ millis() +","+  System.currentTimeMillis();
    registerLog(log);  // Write data to the file
  
    output.flush();  // Writes the remaining data to the file
    output.close();  // Finishes the file
    println("closed file");
    
  } else {
    exit();  // Stops the program
  }
}

// disable ESC
void keyPressed(){
  if(key==27)
    key=0;
}

