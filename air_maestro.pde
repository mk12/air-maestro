// Copyright 2014 Mitchell Kember and Aaron Bungay. Subject to the MIT License.

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
    controller.draw(video);
  }
}

void keyPressed() {
  if (key == CODED) {
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
