import processing.video.*;

Capture video;
Tracker tracker;

int INIT = 0;
int PLAY = 1;
int mode = INIT;

void setup() {
  size(640, 480);
  stroke(255, 0, 0);
  video = new Capture(this, width, height);
  video.start();
  tracker = new Tracker();
}

void draw() {
  if (!video.available()) {
    return;
  }
  video.read();
  video.loadPixels();
  if (mode == INIT) {
    tracker.init(video);
    mode = PLAY;
    
  } else {
    loadPixels();
    // Copy video.
    for (int i = 0; i < video.pixels.length; i++) {
      pixels[i] = video.pixels[i];
    }
    updatePixels();
    line(0, height-tracker.horizon, width, height-tracker.horizon);
  }
}
