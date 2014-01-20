import processing.video.*;

// INSTRUCTIONS
// 1. Left-click with the mouse on the first object you want to track, and drag
//    until the translucent circle covers most of the object.
// 2. Right-click and drag to do the same thing for the second object.
// 3. Press space bar to toggle displaying the mask instead of the video.
// 4. Adjust the first threshold using the up and down arrow keys until the object
//    is mostly covered and there is a minimal amoint of noise elsewhere.
// 5. Adjust the second threshold using the left and right arrow keys.
// 6. Press space again and watch the tracking.

final int defaultThreshold = 100;  // threshold used in the beginning
final int thresholdAdjustment = 3; // adjustment made by arrow keys

Capture video;
Tracker tracker;
boolean mask = false; // display mask (true) or video (false)

int resetColor = -1;  // nonnegative: resetting nth object's color
PVector startDrag = new PVector(0, 0); // center of color sample
boolean doneDragging = false; // flag set by mouseReleased

void setup() {
  size(640, 480);
  video = new Capture(this, width, height);
  video.start();
  // Create a Tracker that can track two objects at once.
  tracker = new Tracker(2);
  // Add a red object and a green object.
  tracker.track(color(210, 0, 50), defaultThreshold);
  tracker.track(color(0, 200, 20), defaultThreshold);
}

void keyPressed() {
  int n = thresholdAdjustment;
  if (key == CODED) {
    // Adjust the threshold of the first object (up/down) or the
    // second object (right/left).
    if (keyCode == UP) {
      tracker.addToThreshold(0, n);
    } else if (keyCode == DOWN) {
      tracker.addToThreshold(0, -n);
    } else if (keyCode == RIGHT) {
      tracker.addToThreshold(1, n);
    } else if (keyCode == LEFT) {
      tracker.addToThreshold(1, -n);
    }
  } else if (key == 32) { // spacebar
    // Start or stop displaying the mask.
    mask = !mask;
  }
}

void mousePressed() {
  startDrag.x = mouseX;
  startDrag.y = mouseY;
  resetColor = (mouseButton == LEFT) ? 0 : 1;
}

void mouseReleased() {
  // We can't take the average of the sample and reset the object
  // color here because video.pixels is not available. Instead,
  // we set this flag and do it in the draw function.
  if (resetColor >= 0) {
    doneDragging = true;
  }
}

void draw() {
  if (!video.available()) {
    return;
  }
  video.read();
  video.loadPixels();
  // Scan the video for objects and indicate them with circles.
  tracker.scan(video, mask);
  tracker.drawIndicators();
  // Check if we are dragging (either in the process or just finished).
  if (resetColor >= 0) {
    PVector endDrag = new PVector(mouseX, mouseY);
    float radius = PVector.sub(startDrag, endDrag).mag();
    if (doneDragging) {
      // Reset the nth object's color to the average of the pixels in the circle.
      int r = int(radius) + 1;
      tracker.setColor(resetColor, sampleAverage(video, startDrag, r));
      doneDragging = false;
      resetColor = -1;
    } else {
      // Draw a circle overlay to show where the sample will be taken.
      fill(255, 127);
      ellipse(startDrag.x, startDrag.y, radius*2, radius*2);
    }
  }
}

// Calculates the average of the pixel colors within the given circle.
color sampleAverage(PImage img, PVector center, int radius) {
  int n = 0;
  int r = 0, g = 0, b = 0;
  // Make sure we don't go out of bounds.
  int startX = constrain(floor(center.x-radius), 0, img.width-1);
  int startY = constrain(floor(center.y-radius), 0, img.height-1);
  int endX = constrain(ceil(center.x+radius), 0, img.width-1);
  int endY = constrain(ceil(center.y+radius), 0, img.height-1);
  for (int y = startY; y < endY; y++) {
    for (int x = startX; x < endX; x++) {
      float distSq = PVector.sub(center, new PVector(x, y)).magSq();
      // If this point in the square lies inside the circle:
      if (distSq <= radius*radius) {
        color c = img.pixels[y*img.width+x];
        // Use bit-shifting for quick access to components.
        r += c >> 16 & 0xff;
        g += c >> 8 & 0xff;
        b += c & 0xff;
        n++;
      }
    }
  }
  // Make sure we don't divide by zero.
  if (n == 0) {
    return color(0);
  }
  // Divide each component by the sum to get the average color.
  return color(r/n, g/n, b/n);
}