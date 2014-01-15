final int paperThreshold = 120;

class Tracker {
  int horizon;
  
  Tracker() {
  }
  
  // Scans the video pixels and initializes the tracker.
  void init(PImage img) {
    for (int y = 0; y < img.height; y++) {
      // Add up the brightness of every pixel in the row.
      int sum = 0;
      for (int x = 0; x < img.width; x++) {
        color c = img.pixels[y*img.height+x];
        sum += brightness(c);
      }
      // Check if the average brightness exceeds the threshold.
      if (sum / img.width > paperThreshold) {
        this.horizon = y;
        break;
      }
    }
  }
  
  // Scans the video pixels and detects fingertips touching the paper.
  void scan(PImage img) {
  }
}
