// Copyright 2014 Mitchell Kember and Aaron Bungay. Subject to the MIT License.

final int kMaxBatons = 5;          // maximum number of batons to track
final int kThresholdSensivity = 3; // threshold change made my arrow keys and scroll wheel
final int kOverlayAlpha = 127;     // alpha value for sampling circle
final int kScaleLineWeight = 2;    // line weight for scale-dividing lines

final int kSamplingNone = 0;       // not currently sampling
final int kSamplingInProgress = 1; // sampling is in progress
final int kSamplingDone = 2;       // sampling is just finished and ready for use

// Returns the index into the flat img.pixels array give an (x,y) coordinate pair.
int index(PImage img, int x, int y) {
  return y * img.width + x;
}

// Returns the mirrored (horizontally reflected) index into the flat img.pixels array
// given an unmirrored (x,y) coordinate pair.
int mirroredIndex(PImage img, int x, int y) {
  return y * img.width + (img.width - 1) - x;
}

// Calculates the average of the pixel colors within the given circle.
// Note: Accesses img.pixels using mirrored x-coordinates.
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
      if (distSq <= radius * radius) {
        color c = img.pixels[mirroredIndex(img, x, y)];
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

// Controls and coordinates a Tracker and a Soundmanager.
class UIController {
  Tracker tracker;
  SoundManager sound;
  
  int activeBaton = 0; // index of the currently active baton
  int nScales = kDefaultNScales; // number of scale divisions
  boolean mask = false; // video mode (false) or mask mode (true)
  boolean scaleLines = true; // display lines separating scale divisions
  int samplingStatus = kSamplingNone; // we are not currently sampling
  PVector sampleCenter = new PVector(0, 0); // center of the sample circle
  
  // Creates a new UIController with default settings.
  UIController() {
    tracker = new Tracker(kMaxBatons);
    sound = new SoundManager();
  }
  
  // Adds an uninitialized baton to the controller.
  void addBaton() {
    if (this.tracker.nObjects < kMaxBatons) {
      tracker.addObject();
      sound.addTrack();
    }
  }
  
  // Removes the currently active baton from the controller.
  void removeActiveBaton() {
    if (this.tracker.nObjects > 0) {
      this.tracker.removeObject(this.activeBaton);
      this.sound.removeTrack(this.activeBaton);
    }
  }
  
  // Cycles through the batons. If back is true, cycles backwards.
  void cycleActiveBaton(boolean back) {
    this.activeBaton += (back? -1 : 1) + this.tracker.nObjects;
    this.activeBaton %= this.tracker.nObjects;
  }
  
  // Adjusts the threshold of the currently active baton. Direction should
  // be -1 for decreasing or 1 for increasing.
  void adjustActiveThreshold(int direction) {
    this.tracker.addToThreshold(this.activeBaton, direction * kThresholdSensivity);
  }
  
  // Sets the active baton's volume to the given level (value between 0 and 1).
  void setActiveVolume(float v) {
    this.sound.setVolume(this.activeBaton, v);
  }
  
  // Changes the active baton's wave shape (possible values are in sound_manager.pde).
  void setActiveWaveShape(int shape) {
    this.sound.setWaveShape(this.activeBaton, shape);
  }
  
  // Increases the number of scale divisions by one, noy exceeding kMaxScales.
  void addScale() {
    this.nScales = min(this.nScales + 1, kMaxScales);
  }
  
  // Decreases the number of scale divisons by one (unless there is only one).
  void removeScale() {
    this.nScales = max(this.nScales - 1, 1);
  }
  
  // Toggles between video mode and mask mode.
  void toggleMask() {
    this.mask = !this.mask;
  }
  
  // Toggles the scale division lines (does nothing if there is only one scale).
  void toggleScaleLines() {
    if (this.nScales > 1) {
      this.scaleLines = !this.scaleLines;
    }
  }
  
  // Begins playing sound or stops playing sound.
  void toggleSound() {
    this.sound.togglePlaying();
  }
  
  // Begins sampling a baton colour by a circle with its center under the cursor.
  void beginSampling() {
    this.samplingStatus = kSamplingInProgress;
    this.sampleCenter.x = mouseX;
    this.sampleCenter.y = mouseY;
  }
  
  // Ends the sampling process, using the distance between the current cursor
  // position and the initial cursor position (from beginSampling) as the radius.
  // The beginSampling method must be called before this.
  void endSampling() {
    if (this.samplingStatus == kSamplingInProgress) {
      this.samplingStatus = kSamplingDone;
    }
  }
  
  // Calculates the radius of the sample with its center at sampleCenter and
  // its edge extending to the current cursor position.
  float sampleRadius() {
    PVector mouse = new PVector(mouseX, mouseY);
    return PVector.sub(this.sampleCenter, mouse).mag();
  }
  
  // Draws the video or mask, tracks all batons and indicates their positions,
  // handles sampling (draws circle when in progress, and updates the baton color
  // if just finished), and draws scale divison lines if they are enabled.
  void trackAndDraw(PImage img) {
    img.loadPixels();
    // Scan the image and track the batons.
    this.tracker.scan(img, this.mask);
    this.tracker.drawIndicators(this.activeBaton);
    // Check if we are dragging a circle to reset a baton's color.
    if (this.samplingStatus == kSamplingInProgress) {
      this.drawSampleCircle();
    } else if (this.samplingStatus == kSamplingDone) {
      this.sampleAndUpdate(img);
    }
    // Draw scale lines if there are any and they want to see them.
    if (this.nScales > 1 && this.scaleLines) {
      drawScaleLines();
    }
  }
  
  // Draw a translucent circle over the area where the sample will be taken.
  void drawSampleCircle() {
    float diameter = 2 * this.sampleRadius();
    fill(255, kOverlayAlpha);
    strokeWeight(1);
    ellipse(this.sampleCenter.x, this.sampleCenter.y, diameter, diameter);
  }
  
  // Calculate the average color in the circle and update the active baton's color.
  void sampleAndUpdate(PImage img) {
    int radius = int(this.sampleRadius() + 1); // err on the side of too much (avoid zero)
    color c = sampleAverage(img, this.sampleCenter, radius);
    this.tracker.setColor(this.activeBaton, c);
    this.samplingStatus = kSamplingNone;
  }
  
  // Draws vertical lines to separate the scale columns.
  void drawScaleLines() {
    for (int i = 1; i < nScales; i++) {
      strokeWeight(kScaleLineWeight);
      stroke(mask? 255 : 0); // contrast with the background
      float x = float(i) / nScales * width;
      line(x, 0, x, height);
    }
  }
  
  // Updates the frequencies and volumes of each sound track.
  void updateSound() {
    for (int i = 0; i < this.tracker.nObjects; i++) {
      PVector p = this.tracker.locations[i];
      if (p.x == UNDETECTED) {
        // Fade out if the baton can't be found.
        this.sound.fadeOut(i);
      } else {
        // Otherwise, glide to the new scale and frequency.
        int scale = int(this.tracker.locations[i].x / width * nScales);
        float pitch = 1.0 - this.tracker.locations[i].y / height;
        this.sound.updateFrequency(i, scale, pitch);
        // This usually does nothing. If the baton was undetected last frame,
        // this will raise its volume from zero. If the baton's volume was
        // just changed, this will fade to the new value.
        this.sound.fadeIn(i);
      }
    }
  }
}
