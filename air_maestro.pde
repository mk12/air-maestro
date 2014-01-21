import processing.video.*;

final int maxBatons = 5; // maximum number of batons to track
final int defaultThreshold = 100; // threshold used in the beginning
final int thresholdAdjustment = 3; // adjustment made by arrow keys and scroll wheel
final int NOT_DRAGGING = -1; // x-value that indicates that we are not dragging
final int overlayAlpha = 127; // alpha value of the overlay circle for taking a color sample

Capture video;
Tracker tracker;
SoundManager sound;

int activeBaton = 0; // the index of the currently active baton
boolean mask = false; // display video (false) or mask (true)
PVector startDrag = new PVector(NOT_DRAGGING, 0); // center of color sample
boolean doneDragging = false; // flag set by mouseReleased

// Adds an uninitialized baton to the tracker and sound manager.
void addBaton() {
  if (tracker.nObjects < maxBatons) {
    tracker.addObject(UNSET, defaultThreshold);
    sound.addTrack(0, 0);
  }
}

// Removes the nth baton from the tracker and sound manager.
void removeBaton(int n) {
  if (tracker.nObjects > 0) {
    tracker.removeObject(n);
    sound.removeTrack(n);
  }
}

void setup() {
  size(640, 480);
  video = new Capture(this, width, height);
  video.start();
  tracker = new Tracker(maxBatons);
  sound = new SoundManager();
  addBaton();
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      // Increase the active baton's threshold.
      tracker.addToThreshold(activeBaton, thresholdAdjustment);
    } else if (keyCode == DOWN) {
      // Decrease the active baton's threshold.
      tracker.addToThreshold(activeBaton, -thresholdAdjustment);
    } else if (keyCode == RIGHT) {
      // Cycle the active baton to the right.
      activeBaton = (activeBaton + 1) % tracker.nObjects;
    } else if (keyCode == LEFT) {
      // Cycle the active baton to the left (make sure we don't go negative).
      activeBaton = (activeBaton - 1 + tracker.nObjects) % tracker.nObjects;
    }
  } else if (key == 'z') {
    // Start or stop displaying the mask.
    mask = !mask;
  } else if (key == 'a') {
    addBaton();
  } else if (key == 'x') {
    removeBaton(activeBaton);
  } else if (key == 32) { // space bar
    sound.togglePlaying();
  }
}

void mouseWheel(MouseEvent event) {
  // Increase the active baton's threshold or decrease it depending
  // on scroll direction.
  tracker.addToThreshold(activeBaton, event.getCount() * thresholdAdjustment);
}

void mousePressed() {
  startDrag.x = mouseX;
  startDrag.y = mouseY;
}

void mouseReleased() {
  // We can't take the average of the sample and reset the object
  // color here because video.pixels is not available. Instead,
  // we set this flag and do it in the draw function.
  if (startDrag.x != NOT_DRAGGING) {
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
  tracker.drawIndicators(activeBaton);
  // Check if we are dragging (either in the process or just finished).
  if (startDrag.x != NOT_DRAGGING) {
    PVector endDrag = new PVector(mouseX, mouseY);
    float radius = PVector.sub(startDrag, endDrag).mag();
    if (doneDragging) {
      // Reset the nth object's color to the average of the pixels in the circle.
      int r = int(radius) + 1;
      tracker.setColor(activeBaton, sampleAverage(video, startDrag, r));
      doneDragging = false;
      startDrag.x = NOT_DRAGGING;
    } else {
      // Draw a circle overlay to show where the sample will be taken.
      fill(255, overlayAlpha);
      strokeWeight(1);
      ellipse(startDrag.x, startDrag.y, radius*2, radius*2);
    }
  }
  // Update our sound production.
  for (int i = 0; i < tracker.nObjects; i++) {
    if (tracker.locations[i].x == UNDETECTED) {
      sound.update(i, 0, 0);
    } else {
      // TODO: Format this better.
      sound.update(i, 1.0-tracker.locations[i].y/height, constrain(tracker.speeds[i].mag()/100, 0, 1));
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
