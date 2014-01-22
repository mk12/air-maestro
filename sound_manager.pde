// Copyright 2014 Mitchell Kember and Aaron Bungay. Subject to the MIT License.

import beads.*;

final int kGainGlideTime = 33;      // transition time for gain (ms)
final int kFrequencyGlideTime = 33; // transition time for frequency (ms)
final int kMaxScales = 6;           // maximum number of scale divisions

// Return a frequency in hertz given a pitch (value between 0 and 1,
// where 0 represents the lowest pitch and 1 represents the highest)
// in the given scale (nonnegative integer).
float frequency(int scale, float pitch) {
  return 27.5 * pow(2, scale + pitch);
}

// Manages multiple gliding sound tracks simultaneously.
class SoundManager {
  AudioContext context;
  ArrayList<Gain> gains;            // references needed for killing later
  ArrayList<Glide> gainGlides;      // for changing gain values on the fly
  ArrayList<Glide> frequencyGlides; // for changing frequency values on the fly
  
  // Creates a new empty sound manger (no sound tracks).
  SoundManager() {
    this.context = new AudioContext();
    this.gains = new ArrayList<Gain>();
    this.gainGlides = new ArrayList<Glide>();
    this.frequencyGlides = new ArrayList<Glide>();
  }
  
  // Adds a new sound track beginning with the given pitch and volume
  // (both are values between 0 and 1) in the given scale (nonnegative integer).
  void addTrack(int scale, float pitch, float volume) {
    Glide gainGlide = new Glide(this.context, volume, kGainGlideTime);
    Glide freqGlide = new Glide(this.context, frequency(scale, pitch), kFrequencyGlideTime);
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
    // Kill it first. This will let the context know that we're done with it.
    this.gains.get(n).kill();
    this.gains.remove(n);
    this.gainGlides.remove(n);
    this.frequencyGlides.remove(n);
  }
  
  // Updates the nth sound track (beginning at zero) to the given pitch and volume
  // (both are values between 0 and 1) in the given scale (nonnegative integer).
  void update(int n, int scale, float pitch, float volume) {
    gainGlides.get(n).setValue(volume);
    frequencyGlides.get(n).setValue(frequency(scale, pitch));
  }
  
  // Begins playing all sound tracks.
  void startPlaying() {
    this.context.start();
  }
  
  // Stops playing all sound tracks.
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
