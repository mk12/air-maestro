// Copyright 2014 Mitchell Kember and Aaron Bungay. Subject to the MIT License.

final int kMinPoints = 100;     // minimum points to consider an object detected
final int kMaxThreshold = 300;  // upper limit for an object's threshold
final int kCircleSize = 10;     // size of the indicator circle (pixels)
final int kCircleMargin = 10;   // distance from the edge for corner circles (pixels)
final int kNormalStroke = 1;    // stroke width for an object's circle
final int kActiveStroke = 3;    // stroke width for an active object's circle
final int UNDETECTED = -1;      // x-value representing an absence of location
final color UNSET = color(255); // color used to represent an uninitialized object

// Returns the total difference between c1 and c2; that is, the sum
// of the component differences: |r1-r2| + |g1-g2| + |b1-b2|.
int totalDifference(color c1, color c2) {
  // Use bit-shifting for quick access to components.
  int r = (c1 >> 16 & 0xFF) - (c2 >> 16 & 0xFF);
  int g = (c1 >> 8 & 0xFF) - (c2 >> 8 & 0xFF);
  int b = (c1 & 0xFF) - (c2 & 0xFF);
  return abs(r) + abs(g) + abs(b);
}

// Tracks the locations and speeds of multiple objects by colour in live video.
// Each object is described with two values: a colour and a threshold. The colour
// should be fairly representative of the entire object, and the threshold represents
// the amount of deviation from the main colour allowed. Each time the scan method
// is called, Tracker updates the location to the object's centroid (centre of mass)
// and calculates speed based on the change in location since the last frame.
// An object that could not be detected is represented by a location whose x-value
// is set to UNDETECTED.
class Tracker {
  int nObjects;
  color[] colors;
  int[] thresholds;
  PVector[] locations;
  PVector[] speeds;
  
  // Creates a new tracker with a maximum capacity of n objects.
  Tracker(int n) {
    this.nObjects = 0;
    this.colors = new color[n];
    this.thresholds = new int[n];
    this.locations = new PVector[n];
    this.speeds = new PVector[n];
    // Populate the location and speed arrays with PVectors.
    for (int i = 0; i < n; i++) {
      this.locations[i] = new PVector(UNDETECTED, 0);
      this.speeds[i] = new PVector(0, 0);
    }
  }
  
  // Tracks an object with colour c using thresh as the threshold.
  void addObject(color c, int thresh) {
    // Add to the end of the arrays.
    this.colors[this.nObjects] = c;
    this.thresholds[this.nObjects] = thresh;
    this.nObjects++;
  }
  
  // Stops tracking the nth object. Removes it from all arrays and
  // slides others objects down (object indices will change).
  void removeObject(int n) {
    if (this.nObjects > 0) { // sanity check
      for (int i = 0; i < this.nObjects - 1; i++) {
        // Rewrite all the elements to cover the gap.
        int index = (i < n) ? i : i+1;
        this.colors[i] = this.colors[index];
        this.thresholds[i] = this.thresholds[index];
        this.locations[i] = this.locations[index];
      }
      this.nObjects--;
    }
  }
  
  // Sets the the color of the nth object to c.
  void setColor(int n, color c) {
    this.colors[n] = c;
  }
  
  // Adds delta to the threshold of the nth object.
  // Does not go below 0 or above kMaxThreshold.
  void addToThreshold(int n, int delta) {
    this.thresholds[n] = constrain(this.thresholds[n] + delta, 0, kMaxThreshold);
  }
  
  // Scans the given image and updates the locations and speeds of all objects.
  // If mask is true, writes the screen pixels array with black and object
  // colors to visualize the thresholds. If mask is false, copies the video
  // pixels to the screen pixels array unchanged.
  // See the project website for a description of the algorithm used here.
  void scan(PImage img, boolean mask) {
    int[] nPoints = new int[this.nObjects]; // number of points found
    int[] xSums = new int[this.nObjects];   // sum of x-values of points
    int[] ySums = new int[this.nObjects];   // sum of y-values of points
    loadPixels();
    for (int y = 0; y < img.height; y++) {
      for (int x = 0; x < img.width; x++) {
        // Convert the 2D coordinates to an index into the flat pixels array.
        int index = y * img.width + x;
        int mirroredIndex = (y + 1) * img.width - x - 1;
        color c = video.pixels[mirroredIndex];
        // Copy the pixel to screen only if we are not displaying the mask.
        pixels[index] = mask? color(0) : c;
        for (int i = 0; i < this.nObjects; i++) {
          // Skip uninitialized objects.
          if (this.colors[i] == UNSET) {
            continue;
          }
          // Check if the colour difference is within the threshold.
          if (totalDifference(c, this.colors[i]) <= this.thresholds[i]) {
            xSums[i] += x;
            ySums[i] += y;
            nPoints[i]++;
            if (mask) {
              pixels[index] = this.colors[i];
            }
          }
        }
      }
    }
    updatePixels();
    // Divide the sums to obtain the average coordinates for each object.
    // If there are insufficient points, mark the object as undetected.
    for (int i = 0; i < this.nObjects; i++) {
      // Skip uninitialized objects.
      if (this.colors[i] == UNSET) {
        continue;
      }
      // If we have enough points to call this a detected object:
      if (nPoints[i] >= kMinPoints) {
        float x = xSums[i] / nPoints[i];
        float y = ySums[i] / nPoints[i];
        this.speeds[i].x = x - this.locations[i].x;
        this.speeds[i].y = y - this.locations[i].y;
        this.locations[i].x = x;
        this.locations[i].y = y;
      } else {
        this.locations[i].x = UNDETECTED;
      }
    }
  }
  
  // Draws a small circle at the centroid of each object.
  // Draws it in the top-left corner for uninitialized objects.
  // Draws it in the top-right corner for undetected objects.
  // Draws the active object with a thicker-outlined circle.
  void drawIndicators(int active) {
    int cm = kCircleMargin, cs = kCircleSize;
    int nLeft = 0, nRight = 0;
    for (int i = 0; i < this.nObjects; i++) {
      PVector p = this.locations[i];
      fill(this.colors[i]);
      strokeWeight(i == active ? kActiveStroke : kNormalStroke);
      if (this.colors[i] == UNSET) {
        // Draw uninitialized object's circles on the left.
        ellipse(cm + nLeft*cs, cm, cs, cs);
        nLeft++;
      } else if (p.x == UNDETECTED) {
        // Draw undetected object's circles on the right.
        ellipse(width - cm - nRight*cs, cm, cs, cs);
        nRight++;
      } else {
        // Draw detected object circles on the centroid.
        ellipse(width - p.x, p.y, cs, cs);
      }
    }
  }
}
