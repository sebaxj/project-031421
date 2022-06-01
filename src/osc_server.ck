//----------------------------------------------------------------------------
// name: osc_server.ck
// desc: OpenSoundControl (OSC) receiver example
//----------------------------------------------------------------------------

// create our OSC receiver
OscIn oin;

// create our OSC message
OscMsg msg;

// use port 5005 (or whatever)
5005 => oin.port;

// create an address in the receiver, expect an int and a float
oin.addAddress( "/bpm/hrv/p_hrv/root, f f f f" );

// Synth instance
Synth s;

// global variables to track OSC received variables
60.0 => float BASE_HR;
BASE_HR => float HR;
28.0 => float HRV;
0.5 => float P_HRV;
0 => float ROOT;

// constants
4 => int BAR_LENGTH;

// call main function
main();

//--------
// name: main()
// desc: entry point
//--------
fun void main() {

	// play the baseline
	// baseline();
	
	// spork the OSC server
	spork ~ oscServe();

	// spork sonify algorithm
	spork ~ sonify();

	// infinite loop
	while(true) {
		1::second => now;
	}
}

//--------
// name: baseline()
// desc: play a random assortment of notes to hear a baseline
// root: C
// time signature: 4/4
// number of bars: 8
// bpm = 60 = BASE_HR
// P(beat is played) = p = 0.5 (random)
//--------
fun void baseline() {

	// define the root note (C)
	60 + (12 * Math.random2(-2, 2)) => int root;

	for(0 => int i; i < 24; i++) {
		// for each beat there is a 0.5 probability of that beat being played
		// for the sake of simplicity, Math.random2(0, 1) generates 0 or 1 randomly
		// where 1 is mapped to success and 0 is mapped to failure
		if(Math.random2(0, 1)) {
			// if a note is played, randomly choose a note from a 12-tone 
			// equally tempered scale from root
			// Math.random2(0, 12) generates a interval above the root
			spork ~ s.play(root + Math.random2(0, 12), 1.0, 100::ms, 80::ms, 0.5, 200::ms);
			(HR / BASE_HR)::second => now;
		} else {
			// do nothing
			(HR / BASE_HR)::second => now;
		}
	}
}

//--------
// name: cal_HR_octave()
// desc: passed a raw HR value and returns octave of root
//--------
fun int cal_HR_octave(float hr) {
	
	if(hr < 40) {
		return -24;
	} else if(hr >=40 && hr < 55) {
		return -12;
	} else if(hr >= 55 && hr < 75) {
		return 0;
	} else if(hr >= 75 && hr < 90) {
		return 12;
	} else if(hr >= 90) {
		return 24;
	}

	// default return 
	return 0;
}

//--------
// name: sonify()
// desc: primary sonification algorithm
//--------
fun void sonify() {

	float root;

	// infinite event loop
	while(true) {
		cal_HR_octave(HR) + 60 => root;
		if(Math.random2f(0, 1) <= (1 - P_HRV)) { // prob of note being played is the complement of the pdf
			// if a note is played, randomly choose a note from a 12-tone 
			// equally tempered scale from root
			// Math.random2(0, 12) generates a interval above the root
			spork ~ s.play(root + ROOT, 1.0, 100::ms, 80::ms, 0.5, 200::ms);
			(HR / BASE_HR)::second => now;
		} else {
			// do nothing
			(HR / BASE_HR)::second => now;
		}
	}

}

// TODO: Decompose this method into its own file and use events to signal between
// shreds.
//--------
// name: oscServe()
// desc: function to handle the OSC server 
//--------
fun void oscServe() {

	// infinite event loop
	while( true )
	{
	    // wait for event to arrive
	    oin => now;
	
	    // grab the next message from the queue. 
	    while( oin.recv(msg) )
	    { 
	        // expected datatypes (note: as indicated by "f")
	        float bpm;
			float hrv;
			float p_hrv;
			float root;
	
	        // fetch the first data element as float
	        msg.getFloat(0) => bpm => HR;
	        // fetch the second data element as float
	        msg.getFloat(1) => hrv => HRV;
	        // fetch the third data element as float
	        msg.getFloat(2) => p_hrv => P_HRV;
			// fetch the fourth data element as an float 
			msg.getFloat(3) => root => ROOT;
	
	        // print
	        <<< "got (via OSC):", "[BPM]:", bpm, "[HRV]:", hrv, "[CDF of HRV]:", p_hrv, "[ROOT]:", root >>>;
	    }
	}
}

//--------
// CLASS
// name: Synth
// desc: synth instrument class 
//--------
class Synth {

	fun void play(float root, float vel, dur a, dur d, float s, dur r) {

		[0., 4., 7., 12., -5., 16.] @=> float consonantMaj[];
		[0., 3., 7., 12., -5., 15.] @=> float consonantMin[];
		[0., 3., 6., 12., -6., 15.] @=> float dim[];

		if(HRV < 27.6) {
			if(ROOT == 11) {
				spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
			} else {
				spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
			}
		} else {
			if(ROOT == 0 || ROOT == 5 || ROOT == 7) {
				spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
			} else if(ROOT == 2 || ROOT == 3 || ROOT == 4 || ROOT == 9) {
				spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
			} else if(ROOT == 11) {
				spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
				spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
				((HR / BASE_HR) / 5)::second => now;
			}
		}

		// refactory period  for reverb
		5::second => now;
	}

	fun void playNote(float root, float vel, dur a, dur d, float s, dur r, float p) {

		// UGen patch
		TriOsc tri => ADSR e => Pan2 pan => LPF low => NRev rev => Gain g => dac;

		// UGen parameters
		1.0 => g.gain;
		0 => pan.pan;
		0.0 => rev.mix;
		500 => low.freq; 0.8 => low.Q; 0.5 => low.gain;
		vel => tri.gain;
		Std.mtof(root) => tri.freq;
		p => pan.pan;

		// open env
		e.set(a, d, s, r);
		e.keyOn();

		// play A through end of S
		e.releaseTime() => now;

		// close env
		e.keyOff();

		// release
		e.releaseTime() => now;

		// refactory period for reverb
		1::second => now;

		tri !=> e !=> pan !=> low !=> rev !=> g !=> dac;
	}
}




















