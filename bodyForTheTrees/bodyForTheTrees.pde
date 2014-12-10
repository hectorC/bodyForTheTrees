/* Code for the interactive video, sound and performer project "bodyForTheTrees (bFTT)"
 * by Hector Centeno, Jessica Kee, Sachiko Murakami and Adam Owen
 * Licensed under Creative Commons Attribution-ShareAlike 3.0 Unported [ http://creativecommons.org/licenses/by-sa/3.0/ ]
 */


import damkjer.ocd.*;
import processing.serial.*;

import oscP5.*;
import netP5.*;

// Set this to false on the sketch running on the slave computer
boolean isMaster = true;

float inByteFlex;
float inByteLeftHand;
float inByteRightHand;
float inByteYaw, inBytePitch, inByteRoll;
float rawYaw, rawPitch;
float oldYaw = 0;
float oldPitch = 0;
float oldRoll = 0;
float oldCamYaw = 0;
float oldCamPitch = 0;
float oldCamRoll = 0;

boolean showData = true;

color backColor;
int LEDbrightness;

int numReadings[] = {
  8, 4, 4, 20, 20, 20
}; // number of readings for each sensor so we can smooth differently: flex, IR1, IR2, yaw, pitch and roll
float smthReadings[][] = new float[6][20];
int smthIndex[] = new int[6];
float smthTotal[] = new float[6];

float cameraX = 722;
float cameraZ = 1050;
float camPerlin = 100;
float ledPerlin = 100;
Serial myPort; 

boolean explodeArmed = false;
boolean spikingArmed = false;
float explode = 0;

boolean isExploding = false;
boolean isSpiking = false;

OscP5 oscP5;
NetAddress myRemoteLocation, myLocalLocation;

String inValues[] = new String[4];

Camera camera;

float camDist;
float camMax = 1500;
float camMin = 800;

float spikeTimer;
boolean spikeTrigger = false;
int spikeDir = -1;

Tree tree[] = new Tree[25];

PImage overlay, back;

void setup() { 
  size(1024, 768, P3D);

  camDist = camMin;
  camera = new Camera(this);
  camera.aim(width/2, height/2, 0);

  for (int i=0; i < tree.length; i++) { 
    tree[i] = new Tree();
    tree[i].zPos = random(-500, 500);
  }

  for (int i=0; i<inValues.length; i++) {
    inValues[i] = "";
  }

  smooth(2);

  oscP5 = new OscP5(this, 8001);
  myRemoteLocation = new NetAddress("169.254.142.201", 8001);
  myLocalLocation = new NetAddress("127.0.0.1", 8010);

  if (isMaster) {
    println(Serial.list());
    String portName = Serial.list()[15];
    myPort = new Serial(this, portName, 9600);
    myPort.bufferUntil('\n');
  }

  backColor = color(224, 213, 85);
  LEDbrightness = 5;
} 

void draw() { 

  colorMode(HSB);
  
  // Background color and LED color
  color clr1 = color(145, 110, 255);
  color clr2 = color(6, 158, 245);
  if (oldYaw > 0) backColor = lerpColor(clr1, clr2, map(oldYaw, 0, 180, 0.0, 1.0f));
  if (oldYaw < 0) backColor = lerpColor(clr1, clr2, map(oldYaw, 0, -180, 0.0, 1.0f));

  ledPerlin += 0.02;
  LEDbrightness = (int)(200 * noise(ledPerlin)) + 55; // variate LED brightness with noise

  background(backColor);
  if (isMaster) {
    sendColor();
  }

  // Scene lighting
  ambientLight(123, 96, 223);
  lightSpecular(94, 0, 221);

  directionalLight(140, 255, 255, 0, 1, 0);
  directionalLight(0, 255, 255, -1, 0, 0);
  directionalLight(38, 255, 255, 1, 0, 0);

  // Camera positioning
  float arcAngle = oldCamPitch + inBytePitch;
  float circleAngle = oldCamYaw + inByteYaw;

  if (arcAngle > 0) arcAngle = 0;
  if (arcAngle < -30) arcAngle = -30;

  camPerlin += 0.00515;
  camera.jump(600, 168, camDist + (160 * (noise(camPerlin) - 0.5))); // Move camera back and forth slowly
  camera.arc(radians(oldCamPitch + inBytePitch));
  camera.circle(radians(oldCamYaw + inByteYaw));

  oldCamYaw = circleAngle;
  oldCamPitch = arcAngle;

  // Map sensor values to usable ranges for animation
  float mappedFlex, mappedLeftHand, mappedRightHand;
  mappedFlex = constrain(map(inByteFlex, 400, 529, 0, 700), 0, 700);
  mappedLeftHand = map(inByteLeftHand, 200, 800, 100, 300);
  mappedRightHand = map(inByteRightHand, 200, 800, 100, 300);

  // Flex sensor arming and triggering points
  float flexArm = 420;
  float flexTrigger = 430;
  float flexDissarm = 500;
  float spikeTime = 3000;

  // Gesture detection and visual animation
  if (inByteFlex != 0 && inByteFlex <= flexArm && isExploding == false && isSpiking == false && explode == 0 && explodeArmed == false && spikingArmed == false) {
    explodeArmed = true;
    spikingArmed = true;
    spikeTimer = millis();
    println("armed!");
  }

  if (((millis() - spikeTimer) > spikeTime) && isSpiking == false && isExploding == false && spikingArmed) {
    isSpiking = true;
    spikingArmed = false;
    explodeArmed = false;

    if (camDist == camMin) spikeDir = 1;
    if (camDist == camMax) spikeDir = -1;
  }

  if (isSpiking) {
    camDist = camDist + (6 * spikeDir);
    if (camDist > camMax) {
      camDist = camMax;
    }
    if (camDist < camMin) {
      camDist = camMin;
    }
  }

  if (isSpiking && (camDist == camMin || camDist == camMax)) {
    isSpiking = false;
  } 

  if (explodeArmed && inByteFlex > flexTrigger) {
    isExploding = true;
    explodeArmed = false;
    spikingArmed = false;
  }

  if (isExploding) explode = mappedFlex;

  if (isExploding && inByteFlex > flexDissarm) {
    isExploding = false;
  }

  if (isExploding == false && explode > 0) {
    explode = explode - 10;
    if (explode < 0) explode = 0;
  }

  ambient(204, 200, 50);

  // Draw the trees!
  int xTree = (width/2) - ((tree.length * 66) / 2);
  for (int i=0; i < tree.length; i++) { 
    pushMatrix();
    translate(xTree, 0, tree[i].zPos);
    tree[i].setCurlX((int)(mappedLeftHand + (15*i)));
    tree[i].setCurlY((int)(mappedRightHand + (15*i)));
    tree[i].explode = explode;
    tree[i].spikeDir = spikeDir;

    tree[i].draw();
    popMatrix();
    xTree = xTree + 66;
  }

  // Show the values from the sensors for calibration. It can be turned on/off by pressing the 'i' key
  if (showData) {
    camera();
    noLights();
    hint(DISABLE_DEPTH_TEST);
    textSize(21);
    fill(255);
    text("Flex: " + inByteFlex, 76, 22);
    text("Hand1: " + mappedLeftHand, 54, 42);
    text("Hand1 Raw: " + inByteLeftHand, 16, 62);
    text("Hand2: " + mappedRightHand, 53, 82);
    text("Hand2 Raw: " + inByteRightHand, 16, 102);
    hint(ENABLE_DEPTH_TEST);
  }

  camera.feed();
} 

void keyPressed() {
  if (key == 'i') showData = !showData;
}

// *******************************************
// This function is needed only by the master computer to get data from the XBee
// *******************************************
void serialEvent (Serial myPort) {
  String inString = myPort.readStringUntil('\n');

  if (inString != null) {
    // trim off any whitespace:
    inString = trim(inString);
    inValues = inString.split("#");
    if (inValues.length == 6) {
      rawPitch = constrain(float(inValues[4]), -70, 0);
      inByteFlex = smoothVal(float(inValues[0]), 0);
      inByteLeftHand = smoothVal(float(inValues[1]), 1);
      inByteRightHand = smoothVal(float(inValues[2]), 2);
      inByteYaw = smoothVal(shortestAngle(oldYaw, float(inValues[3])), 3);
      inBytePitch = smoothVal(shortestAngle(oldPitch, rawPitch), 4);
      inByteRoll = smoothVal(shortestAngle(oldRoll, float(inValues[5])), 5);
      oldYaw = float(inValues[3]);
      oldPitch = rawPitch;
      oldRoll = float(inValues[5]);

      OscMessage oscMes = new OscMessage("/flex");
      oscMes.add(inByteFlex);
      oscP5.send(oscMes, myRemoteLocation);

      oscMes.clear();
      oscMes.setAddrPattern("/leftHand");
      oscMes.add(inByteLeftHand);
      oscP5.send(oscMes, myRemoteLocation);

      oscMes.clear();
      oscMes.setAddrPattern("/rightHand");
      oscMes.add(inByteRightHand);
      oscP5.send(oscMes, myRemoteLocation);

      oscMes.clear();
      oscMes.setAddrPattern("/yaw");
      oscMes.add(inByteYaw);
      oscP5.send(oscMes, myRemoteLocation);

      oscMes.clear();
      oscMes.setAddrPattern("/pitch");
      oscMes.add(inByteRoll);
      oscP5.send(oscMes, myRemoteLocation);

      oscMes.clear();
      oscMes.setAddrPattern("/oldyaw");
      oscMes.add(oldYaw);
      oscP5.send(oscMes, myRemoteLocation);

      // For Csound
      oscMes.clear();
      oscMes.setAddrPattern("/flex");
      oscMes.add(inByteFlex);
      oscP5.send(oscMes, myLocalLocation);

      oscMes.clear();
      oscMes.setAddrPattern("/flex1");
      oscMes.add(map(inByteFlex, 200, 550, 3, 5));
      oscP5.send(oscMes, myLocalLocation);

      oscMes.clear();
      oscMes.setAddrPattern("/flex2");
      oscMes.add(map(inByteFlex, 200, 550, 1, 4));
      oscP5.send(oscMes, myLocalLocation);

      oscMes.clear();
      oscMes.setAddrPattern("/leftHand1");
      if (spikeDir == -1) {
        oscMes.add(map(constrain(inByteLeftHand, 200, 800), 200, 800, 0.2, 1.0));
      } else {
        oscMes.add(map(constrain(inByteLeftHand, 200, 800), 200, 800, 1.3, 3.3));
      }
      oscP5.send(oscMes, myLocalLocation);

      oscMes.clear();
      oscMes.setAddrPattern("/rightHand1");
      if (spikeDir == -1) {
        oscMes.add(map(constrain(inByteRightHand, 200, 800), 200, 800, 0.7, 1.0));
      } else {
        oscMes.add(map(constrain(inByteRightHand, 200, 800), 200, 800, 0.8, 1.5));
      }
      oscP5.send(oscMes, myLocalLocation);

      oscMes.clear();
      oscMes.setAddrPattern("/yaw1");
      oscMes.add(map(float(inValues[3]), -180, 180, 0, 1));
      oscP5.send(oscMes, myLocalLocation);

      oscMes.clear();
      oscMes.setAddrPattern("/pitch");
      oscMes.add(inByteRoll);
      oscP5.send(oscMes, myLocalLocation);

      oscMes.clear();
      oscMes.setAddrPattern("/exparmed");
      oscMes.add(explodeArmed ? 1 : 0);
      oscP5.send(oscMes, myLocalLocation);

      oscMes.clear();
      oscMes.setAddrPattern("/explode");
      oscMes.add(map(explode, 0, 700, 0.5, 2));
      oscP5.send(oscMes, myLocalLocation);

      oscMes.clear();
      oscMes.setAddrPattern("/spike");
      oscMes.add(isSpiking ? 1 : 0);
      oscP5.send(oscMes, myLocalLocation);

      oscMes.clear();
      oscMes.setAddrPattern("/spikedir");
      oscMes.add(spikeDir);
      oscP5.send(oscMes, myLocalLocation);
    }
  }
}

float shortestAngle(float sourceA, float targetA) {
  float a = targetA - sourceA;
  a += (a>180) ? -360 : (a<-180) ? 360 : 0;
  return a;
}

void sendColor() {
  byte message[] = new byte[4];
  color ledColor = color(hue(backColor), 255, 255);
  message[0] = (byte)red(ledColor);
  message[1] = (byte)green(ledColor);
  message[2] = (byte)blue(ledColor);
  message[3] = (byte)LEDbrightness;

  myPort.write(message);
}

float smoothVal(float val, int i) {
  smthTotal[i] = smthTotal[i] - smthReadings[i][smthIndex[i]];
  smthReadings[i][smthIndex[i]] = val;
  smthTotal[i] = smthTotal[i] + smthReadings[i][smthIndex[i]];
  smthIndex[i] = smthIndex[i] + 1;

  if (smthIndex[i] >= numReadings[i]) smthIndex[i] = 0;

  return smthTotal[i]/numReadings[i];
}

// *******************************************
// This function is needed only by the slave computer to get the sensor values via OSC
// *******************************************
void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.addrPattern().equals("/leftHand")) {
    inByteLeftHand = theOscMessage.get(0).floatValue();
  } else if (theOscMessage.addrPattern().equals("/rightHand")) {
    inByteRightHand = theOscMessage.get(0).floatValue();
  } else if (theOscMessage.addrPattern().equals("/yaw")) {
    inByteYaw = theOscMessage.get(0).floatValue();
  } else if (theOscMessage.addrPattern().equals("/pitch")) {
    inBytePitch = theOscMessage.get(0).floatValue();
  } else if (theOscMessage.addrPattern().equals("/flex")) {
    inByteFlex = theOscMessage.get(0).floatValue();
  }
}

