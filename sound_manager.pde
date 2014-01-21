import beads.*;

final int gainGlideTime = 33;      // transition time for gain (ms)
final int frequencyGlideTime = 33; // transition time for frequency (ms)
final int maxScales = 6;           // maximum number of scales

// Return a frequency in hertz given a pitch (value between 0 and 1,
// where 0 represents the lowest pitch and 1 represents the highest)
// in the given scale.
float frequency(int scale, float pitch) {
  switch(scale) {
    case 0: return 27.5 + 27.5*pitch;
    case 1: return 55 + 55*pitch;
    case 2: return 110 + 110*pitch;
    case 3: return 220 + 220*pitch;
    case 4: return 440 + 440*pitch;
    case 5: return 880 + 880*pitch;
    default: return 0;
  }
}

// Manages multiple gliding sound tracks simultaneously.
class SoundManager {
  AudioContext context;
  ArrayList<Gain> gains;
  ArrayList<Glide> gainGlides;      // for changing gain values on the fly
  ArrayList<Glide> frequencyGlides; // for changing frequency values on the fly
  
  // Create a new empty sound manger (no sound tracks).
  SoundManager() {
    this.context = new AudioContext();
    this.gains = new ArrayList<Gain>();
    this.gainGlides = new ArrayList<Glide>();
    this.frequencyGlides = new ArrayList<Glide>();
  }
  
  // Adds a new sound track beginning with the given pitch and volume
  // (both are values between 0 and 1) in the given scale given scale (0 <= scale < nScales).
  void addTrack(int scale, float pitch, float volume) {
    Glide gainGlide = new Glide(this.context, volume, gainGlideTime);
    Glide freqGlide = new Glide(this.context, frequency(scale, pitch), frequencyGlideTime);
    WavePlayer player = new WavePlayer(this.context, freqGlide, Buffer.SINE);
    Gain gain = new Gain(this.context, 1, gainGlide);
    gain.addInput(player);
    this.context.out.addInput(gain);
    // Add the glides to the manager's lists.
    this.gains.add(gain);
    this.gainGlides.add(gainGlide);
    this.frequencyGlides.add(freqGlide);
  }
  
  // Removes the nth track from the manager.
  void removeTrack(int n) {
    this.gains.get(n).kill();
    this.gains.remove(n);
    this.gainGlides.remove(n);
    this.frequencyGlides.remove(n);
  }
  
  // Update the nth sound track (beginning at zero) to the given pitch and volume
  // (both are values between 0 and 1) in the given scale (0 <= scale < nScales).
  void update(int n, int scale, float pitch, float volume) {
    gainGlides.get(n).setValue(volume);
    frequencyGlides.get(n).setValue(frequency(scale, pitch));
  }
  
  // Begin playing all sound tracks.
  void startPlaying() {
    this.context.start();
  }
  
  // Stop playing all sound tracks.
  void stopPlaying() {
    this.context.stop();
  }
  
  // Toggles the playing state (starts or stops).
  void togglePlaying() {
    if (this.context.isRunning()) {
      this.context.stop();
    } else {
      this.context.start();
    }
  }
}
