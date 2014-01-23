// Copyright 2014 Mitchell Kember and Aaron Bungay. Subject to the MIT License.

import beads.*;

final int kGainGlideTime = 30;      // transition time for gain (ms)
final int kFrequencyGlideTime = 30; // transition time for frequency (ms)
final int kMaxScales = 6;           // maximum number of scale divisions
final int kDefaultNScales = 4;      // initial number of scale divisions
final int kLowestFrequency = 110;   // the frequency for scale=0, pitch=0
final float kDefaultVolume = 0.3;   // default volume that hasn't been made louder

// Return a frequency in hertz given a pitch (value between 0 and 1,
// where 0 represents the lowest pitch and 1 represents the highest)
// in the given scale (nonnegative integer).
float frequency(int scale, float pitch) {
  return kLowestFrequency * pow(2, scale + pitch);
}

// Manages multiple gliding sound tracks simultaneously.
class SoundManager {
  AudioContext context;
  ArrayList<Gain> gains;            // references needed for killing later
  ArrayList<Glide> gainGlides;      // for changing gain values on the fly
  ArrayList<Glide> frequencyGlides; // for changing frequency values on the fly
  ArrayList<Float> volumeLevels;    // main volume level saved for each track
  
  // Creates a new empty sound manger (no sound tracks).
  SoundManager() {
    this.context = new AudioContext();
    this.gains = new ArrayList<Gain>();
    this.gainGlides = new ArrayList<Glide>();
    this.frequencyGlides = new ArrayList<Glide>();
    this.volumeLevels = new ArrayList<Float>();
  }
  
  // Adds a new sound track with default settings.
  void addTrack() {
    this.addTrack(0, 0, kDefaultVolume);
  }
  
  // Adds a new sound track with the given pitch and volume (both are values
  // between 0 and 1) in the given scale (nonnegative integer). The actual volume
  // of the track will remain zero until the fadeIn method is called.
  void addTrack(int scale, float pitch, float volume) {
    float freq = frequency(scale, pitch);
    Glide gainGlide = new Glide(this.context, 0, kGainGlideTime);
    Glide freqGlide = new Glide(this.context, freq, kFrequencyGlideTime);
    WavePlayer player = new WavePlayer(this.context, freqGlide, Buffer.SINE);
    Gain gain = new Gain(this.context, 1, gainGlide);
    gain.addInput(player);
    this.context.out.addInput(gain);
    // Add the glides to the manager's lists.
    this.gains.add(gain);
    this.gainGlides.add(gainGlide);
    this.frequencyGlides.add(freqGlide);
    this.volumeLevels.add(new Float(volume));
  }
  
  // Removes the nth track from the manager.
  void removeTrack(int n) {
    // Just to be absolutely sure that it stops playing.
    this.fadeOut(n);
    // Kill it. This will let the context know that we're done with it.
    this.gains.get(n).kill();
    this.gains.remove(n);
    this.gainGlides.remove(n);
    this.frequencyGlides.remove(n);
  }
  
  // Updates the nth sound track to the given pitch (value between 0 and 1)
  // in the given scale (nonnegative integer less than kMaxScales).
  void updateFrequency(int n, int scale, float pitch) {
    this.frequencyGlides.get(n).setValue(frequency(scale, pitch));
  }
  
  // Sets the nth sound track to the given volume (value between 0 and 1).
  // The actual volume of the track will not change until the fadeIn method is called.
  void setVolume(int n, float volume) {
    this.volumeLevels.set(n, new Float(volume));
  }
  
  // Fades the track's volume down to zero.
  void fadeOut(int n) {
    this.gainGlides.get(n).setValue(0);
  }
  
  // Fades the track's volume to its value in the volumeLevels list.
  void fadeIn(int n) {
    this.gainGlides.get(n).setValue(this.volumeLevels.get(n));
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
