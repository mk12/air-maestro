import processing.video.*;

Capture video;

void setup() {
  size(640, 480);
  video = new Capture(this, width, height);
  video.start();
}

void draw() {
  if (video.available()) {
    video.read();
    video.loadPixels();
    loadPixels();
    // Copy video.
    for (int i = 0; i < video.pixels.length; i++) {
      pixels[i] = video.pixels[i];
    }
    updatePixels();
  }
}
