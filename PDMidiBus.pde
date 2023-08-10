/*
  In case of null pointer on startup download the .jar from https://github.com/micycle1/themidibus/releases/tag/p4
  Replace the .jar downloaded via Processing lib manager: /Users/user/Documents/Processing/libraries/themidibus/library
  MidiKeys is a good test keyboard for MacOS: https://github.com/flit/MidiKeys
*/

import themidibus.*;
import processing.serial.*;

String serialAddress = "/dev/tty.usbmodemPDU1_Y0075281"

Serial serialPort = null;
MidiBus myBus;
boolean serialActive = false;
PImage playdate;
ArrayList<byte[]> byteCodes = new ArrayList<byte[]>();
ArrayList<ScreenNote> notes;

byte[] noteOff;

void setup() {
  size(200, 400);
  
  noStroke();
  
  textSize(18);
  
  playdate = loadImage("logo.png"); 
  
  for(int i = 1 ; i <= 127 ; i++){
    byteCodes.add(loadBytes("mn" + i + ".luac"));
  }
  
  noteOff = loadBytes("mn_off.luac");

  printArray(Serial.list());
  MidiBus.list();
  myBus = new MidiBus(this, 1, -1);
  notes = new ArrayList<ScreenNote>();
}

void draw() {
  background(247, 205, 85);
  image(playdate, 0, -30);
  
  fill(255, 100);
  for (int i = notes.size()-1 ; i >= 0; i--){
    ScreenNote note = notes.get(i);
    note.update().draw();
    if(note.sent) notes.remove(i);
  }
    
  fill(0);
  if(!serialActive){
    text("Serial Inactive", 10, 365);
    text("(Press 'C' to start)", 10, 385);
  }
}

void keyPressed() {
  if(key == 'c'){
    if(serialActive){
      println("Closing serial connection.");
      serialPort.clear();
      serialPort.stop();
      serialPort = null;
      serialActive = false;
    }else{
      println("Starting serial connection...");
      serialPort = new Serial(this, serialAddress, 115200);
      serialActive = true;
    }
  }
}

class ScreenNote {
  
  Note note;
  float x;
  float y;
  float diam = 25;
  boolean sending = true;
  boolean sent = false;
  float targetY = random(70, 140);
  
  ScreenNote(Note note) {
    this.note = note;
    x = map(note.pitch(), 0, 127, 0, width);
    y = height - 30;
  }
  
  ScreenNote update(){
    if (sent) return this;
    
    if (sending){
       y -= 6;
       diam -= 0.25;
      if(y < targetY){
        sending = false;
      }
      draw();
    }else{
      diam -= 1;
      if(diam < 1){
        sent = true;
      }else{
        draw();
      }
    }
    
    return this;
  }
  
  void draw(){
    ellipse(x, y, diam, diam);
  }
}

void noteOn(Note note) {
  println("Note on: "+note.pitch());
  
  if(serialActive){
    byte[] byteCode = byteCodes.get(note.pitch());
    serialPort.write("eval " + byteCode.length + "\n");
    serialPort.write(byteCode);
  }
  
  notes.add(new ScreenNote(note));
}

void noteOff(Note note) {
  println("Note Off");
  if(serialActive){
    serialPort.write("eval " + noteOff.length + "\n");
    serialPort.write(noteOff);
  }
}

void dispose(){
  println("stopping midi bus...");
  myBus.dispose();
  println("done");
}
