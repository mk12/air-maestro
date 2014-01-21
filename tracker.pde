final int minPoints = 100;    // minimum points needed to detect object
final int maxThreshold = 300; // upper limit for an object's threshold
final int circleSize = 10;    // size of the indicator circle
final int circleMargin = 10;  // distance from edge for uninitialized/undetected objects
final int normalStroke = 1;   // stroke width for an object's circle
final int activeStroke = 3;   // stroke width for an active object's circle
final int UNDETECTED = -1;    // x-value used to represent an absence of location
final color UNSET = color(0); // color used to represent an uninitialized object

// Returns the sum of the components of the absolute difference
// of colors c1 and c2.
int difference(color c1, color c2) {
  // Use bit-shifting for quick access to components.
  int r = (c1 >> 16 & 0xFF) - (c2 >> 16 & 0xFF);
  int g = (c1 >> 8 & 0xFF) - (c2 >> 8 & 0xFF);
  int b = (c1 & 0xFF) - (c2 & 0xFF);
  return abs(r) + abs(g) + abs(b);
}

// Tracks multiple colored objects in live video.
class Tracker {
  int nObjects;
  color[] colors;
  int[] thresholds;
  PVector[] locations;
  PVector[] speeds;
  
  // Create a new tracker with a maximum capacity of n objects.
  Tracker(int n) {
    this.nObjects = 0;
    this.colors = new color[n];
    this.thresholds = new int[n];
    this.locations = new PVector[n];
    this.speeds = new PVector[n];
    for (int i = 0; i < n; i++) {
      this.locations[i] = new PVector(UNDETECTED, 0);
      this.speeds[i] = new PVector(0, 0);
    }
  }
  
  // Track an object having the given color within the given threshold.
  void addObject(color c, int thresh) {
    this.colors[this.nObjects] = c;
    this.thresholds[this.nObjects] = thresh;
    this.nObjects++;
  }
  
  // Removes the nth object from all arrays and slides the others down.
  void removeObject(int n) {
    if (this.nObjects > 0) {
      for (int i = 0; i < this.nObjects-1; i++) {
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
  // Does not go below 0 or above maxThreshold.
  void addToThreshold(int n, int delta) {
    this.thresholds[n] = constrain(this.thresholds[n] + delta, 0, maxThreshold);
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
        color c = video.pixels[index];
        // Copy the pixel to screen only if we are not displaying the mask.
        pixels[index] = mask? color(0) : c;
        for (int i = 0; i < this.nObjects; i++) {
          // Skip uninitialized objects.
          if (this.colors[i] == UNSET) {
            continue;
          }
          // Check if the colour difference is within the threshold.
          if (difference(c, this.colors[i]) <= this.thresholds[i]) {
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
      if (nPoints[i] >= minPoints) {
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
  // Draw it in the top-left corner for uninitialized objects.
  // Draw it in the top-right corner for undetected objects.
  // Draws the active object with a thickly-outlined circle.
  void drawIndicators(int active) {
    int cs = circleSize;
    int nLeft = 0, nRight = 0;
    for (int i = 0; i < this.nObjects; i++) {
      PVector p = this.locations[i];
      fill(this.colors[i]);
      strokeWeight(i == active ? activeStroke : normalStroke);
      if (this.colors[i] == UNSET) {
        ellipse(circleMargin + nLeft*cs, circleMargin, cs, cs);
        nLeft++;
      } else if (p.x == UNDETECTED) {
        ellipse(width - circleMargin - nRight*cs, circleMargin, cs, cs);
        nRight++;
      } else {
        ellipse(p.x, p.y, cs, cs);
      }
    }
  }
}
