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

// create an address in the receiver, expect a float
oin.addAddress( "/bpm/hrv/p_hrv/root/i, f f f f f" );

// Synth instance
Synth s;

// global variables to track OSC received variables
60.0 => float BASE_HR;
BASE_HR => float HR;
38.7 => float HRV;
0.5 => float P_HRV;
0 => float ROOT;
6.382 => float ENTROPY_OF_MU;
6.562 => float ENTROPY_OF_1SD;
ENTROPY_OF_MU => float ENTROPY;

// constants
4 => int BAR_LENGTH;

// call main function
main();

//--------
// name: main()
// desc: entry point
//--------
fun void main() { // {{{ TODO: remove

	<<< "Starting baseline()..." >>>;

	// play the baseline
	baseline();

	<<< "Finished baseline(), starting sonification algorithm in..." >>>;
	<<< "5" >>>;
	1::second => now;
	<<< "4" >>>;
	1::second => now;
	<<< "3" >>>;
	1::second => now;
	<<< "2" >>>;
	1::second => now;
	<<< "1" >>>;
	1::second => now;
	
	// spork the OSC server
	spork ~ oscServe();

	// spork sonify algorithm
	spork ~ sonify();

	// infinite loop
	while(true) {
		1::second => now;
	}
}
//}}} TODO: remove

//--------
// name: baseline()
// desc: play a random assortment of notes to hear a baseline
// root: C
// time signature: 4/4
// number of bars: 8
// bpm = 60 = BASE_HR
// P(beat is played) = p = 0.5 (random)
//--------
fun void baseline() { // {{{ TODO: remove

	// value of middle C [CONSTANT]
	60 => float MIDDLE_C;

	// int to track the octave of the root note
	float octave;

	for(0 => int i; i < 24; i++) {
		// for each beat there is a 0.5 probability of that beat being played
		// for the sake of simplicity, Math.random2(0, 1) generates 0 or 1 randomly
		// where 1 is mapped to success and 0 is mapped to failure

		// randomly choose a note from a 12-tone 
		// equally tempered scale from root
		// Math.random2(0, 12) generates a interval above the root
		MIDDLE_C + (12 * Math.random2(-2, 2)) => octave;
		do {
				Math.random2(0, 12) => ROOT;
		} while(ROOT == 1 || ROOT == 6 || ROOT == 8 || ROOT == 10);

		// randomly choose a value for entropy in the range +- 1SD of HRV
		Math.random2f(5.661, 7.103) => ENTROPY;

		// randomly choose a value for HR in the range [30, 100]
		Math.random2f(30, 100) => HR;

		// randomly choose a value for HRV in the range [10, 62]
		Math.random2f(10, 62) => HRV;

		if(Math.random2(0, 1)) {
			spork ~ s.play(octave + ROOT, 1.0, 100::ms, 80::ms, 0.5, 200::ms);
			(HR / BASE_HR)::second => now;
		} else {
			// do nothing
			(HR / BASE_HR)::second => now;
		}
	}

	// reset HR, HRV, ENTROPY, and ROOT values
	BASE_HR => float HR;
	38.7 => float HRV;
	0 => float ROOT;
	ENTROPY_OF_MU => float ENTROPY;

}
// }}} TODO: remove

//--------
// name: cal_HR_octave()
// desc: passed a raw HR value and returns octave of root
//--------
fun int cal_HR_octave(float hr) { // {{{ TODO: remove
	
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
// }}} TODO: remove

//--------
// name: sonify()
// desc: primary sonification algorithm
//--------
fun void sonify() { // {{{ TODO: remove

	// value of middle C [CONSTANT]
	60 => float MIDDLE_C;

	float root;

	// infinite event loop
	while(true) {
		cal_HR_octave(HR) + MIDDLE_C => root;
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
// }}} TODO: remove

// TODO: Decompose this method into its own file and use events to signal between
// shreds.
//--------
// name: oscServe()
// desc: function to handle the OSC server 
//--------
fun void oscServe() { // {{{ TODO: remove

	// infinite event loop
	while( true )
	{
	    // wait for event to arrive
	    oin => now;
	
	    // grab the next message from the queue. 
	    while( oin.recv(msg) )
	    { 
	
	        // fetch the first data element as float
	        msg.getFloat(0) => HR;
	        // fetch the second data element as float
	        msg.getFloat(1) => HRV;
	        // fetch the third data element as float
	        msg.getFloat(2) => P_HRV;
			// fetch the fourth data element as an float 
			msg.getFloat(3) => ROOT;
			// fetch the fifth data element as a float
			msg.getFloat(4) => ENTROPY;
	
	        // print
	        <<< "got (via OSC):", "[BPM]:", HR, "[HRV]:", HRV, "[CDF of HRV]:", P_HRV, "[ROOT]:", ROOT, "[I(x)]:", ENTROPY >>>;
	    }
	}
}
// }}} TODO: remove

//--------
// CLASS
// name: Synth
// desc: synth instrument class 
//--------
class Synth { // {{{ TODO: remove

	fun void play(float root, float vel, dur a, dur d, float s, dur r) { // {{{ TODO: remove

		[0., 4., 7., 12., -5., 16.] @=> float consonantMaj[];
		[0., 3., 7., 12., -5., 15.] @=> float consonantMin[];
		[0., 3., 6., 12., -6., 15.] @=> float dim[];

		if(HRV < 27.6) {
			if(ROOT == 11) {
				if(ENTROPY > ENTROPY_OF_1SD) {
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));

					// refactory period  for reverb
					5::second => now;

				} else {
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));

					// refactory period  for reverb
					5::second => now;

				}
			} else {
				if(ENTROPY > ENTROPY_OF_1SD) {
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));

					// refactory period  for reverb
					5::second => now;

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
						
					// refactory period  for reverb
					5::second => now;

				}
			}
		} else {
			if(ROOT == 0 || ROOT == 5 || ROOT == 7 || ROOT == 12) {
				if(ENTROPY > ENTROPY_OF_1SD) {
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));

					// refactory period  for reverb
					5::second => now;

				} else {
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMaj[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));

					// refactory period  for reverb
					5::second => now;

				}
			} else if(ROOT == 2 || ROOT == 3 || ROOT == 4 || ROOT == 9) {
				if(ENTROPY > ENTROPY_OF_1SD) {
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + consonantMin[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));

					// refactory period  for reverb
					5::second => now;
					
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

					// refactory period  for reverb
					5::second => now;
					
				}
			} else if(ROOT == 11) {
				if(ENTROPY > ENTROPY_OF_1SD) {
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));

					// refactory period  for reverb
					5::second => now;

				} else {
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));
					((HR / BASE_HR) / 5)::second => now;
					spork ~ playNote(root + dim[Math.random2(0,5)], vel, a, d, s, r, Math.random2f(-1, 1));

					// refactory period  for reverb
					5::second => now;

				}
			}
		}
	}
	// }}} TODO: remove

	fun void playNote(float root, float vel, dur a, dur d, float s, dur r, float p) { // {{{ TODO: remove

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
	// }}} TODO: remove
}
// }}} TODO: remove




















