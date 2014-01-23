// Copyright 2014 Mitchell Kember and Aaron Bungay. Subject to the MIT License.

// INSTRUCTIONS
// (See the instructions page on the website for more details.)
// [drag] cover the baton with the circle to set its colour
// [z] toggle between video mode and mask mode
// [scroll] change the baton's threshold
// [space] start/stop playing sound
// [a] add another baton
// [left/right] cycle the active baton
// [x] delete the active baton
// [1-9] change the active baton's volume
// [,] decrease number of scales
// [,] increase number of scales
// [s] toggle showing scale lines on screen

import processing.video.*;

Capture video;
UIController controller;

void setup() {
  size(640, 480);
  video = new Capture(this, width, height);
  controller = new UIController();
  video.start();
  controller.addBaton();
}

void draw() {
  if (video.available()) {
    video.read();
    controller.trackAndDraw(video);
    controller.updateSound();
  }
}

void keyPressed() {
  if (key >= '1' && key <= '9') {
    controller.setActiveVolume((key - '0') / 9.0);
  } else if (key == CODED) {
    switch (keyCode) {
      case DOWN: controller.adjustActiveThreshold(-1); break;
      case UP: controller.adjustActiveThreshold(+1); break;
      case LEFT: controller.cycleActiveBaton(true); break;
      case RIGHT: controller.cycleActiveBaton(false); break;
    }
  } else {
    switch (key) {
      case 'a': controller.addBaton(); break;
      case 'x': controller.removeActiveBaton(); break;
      case 'z': controller.toggleMask(); break;
      case 's': controller.toggleScaleLines(); break;
      case ' ': controller.toggleSound(); break;
      case ',': controller.removeScale(); break;
      case '.': controller.addScale(); break;
    }
  }
}

void mouseWheel(MouseEvent event) {
  controller.adjustActiveThreshold(-event.getCount());
}

void mousePressed() {
  controller.beginSampling();
}

void mouseReleased() {
  controller.endSampling();
}
