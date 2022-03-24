//----------------
// filename: main.ck
// author: Sebastian James (sebaxj@ccrma.stanford.edu)
// date: March 2022
// desc: 
//----------------

// Global Variables

// filename and path for biosignals.txt
me.sourceDir() + "biosignals.txt" => string FILENAME;

// number of lines in file
3555 => int NUM_LINES;

// array to store biodata 
float BIODATA[NUM_LINES];

// instance of FileIO
FileIO FIO;

// UGen Patch
SinOsc s; 
// 0.25 => s.gain;


// Keyboard input instance 
Hid hi;
HidMsg msg;

// key to toggle BIODATA SinOsc
22 => int BIODATA_KEY;

// key to activate Pan (x)
27 => int PAN_KEY;

// key to activate Echo (c)
6 => int ECHO_KEY;

// key to activate LPF (v)
25 => int LPF_KEY;

int LISA_CONTROLLER;
int DRUM_MACHINE;

// Boolean values to activate/deactivate filters
0 => int PAN_BOOL;
0 => int ECHO_BOOL;
0 => int LPF_BOOL;

// track index of BIODATA
int INDEX;

// CHORDS ARRAYS 
// min
[0., 3., 7., 0.] @=> float min[];
    
// min4/2
[-2., 0., 3., 7.] @=> float min42[];
    
// dim
[-12., 3., 6., 0.] @=> float dim[];
    
// Maj
[0., 4., 7., 12.] @=> float maj[];
    
// V7
[0., 4., 7., 10.] @=> float v7[];
    
// fully dim 7
[0., 3., 6., 9.] @=> float dim7[];

// Synth instance
Synth SYNTH;
10 => int T; // initialize chuck time progress in playchord loop in synth

// Main Function
main();

//----------------
// name: main()
// desc: entry point
//----------------
fun void main() {
	if(!openFile(FILENAME)) me.exit();
	readFile();

	// initiate keyboard for input
	initKeyboard();

	// spork shreds
	Machine.add(me.dir() + "pads.ck") => DRUM_MACHINE;
	Machine.add(me.dir() + "lisa.ck") => LISA_CONTROLLER;

	// spork keyboard function 
	spork ~ kb();

	// spork sonification algorithm
	spork ~ sonifyAlgo();

	// spork effect functions
	spork ~ panEffect();
	spork ~ echoEffect();
	spork ~ lpfEffect();

	while(true) {
// 		for(0 => INDEX; INDEX < BIODATA.cap(); INDEX++) {
// 				(BIODATA[INDEX] * 100.00) + 240.0 => s.freq;
// 				<<< s.freq() >>>;
// 				100::ms => now;
// 			}
		100::ms => now;
		}
	}

//----------------
// name: openFile()
// desc: open a file in the file stream
//----------------
fun int openFile(string filename) {
	FIO.open(filename, FileIO.READ);

	// ensure file opened okay
	if(!FIO.good()) {
			cherr <= "Can't open file: " <= filename <= " for reading" <= IO.newline();
			return 0;
		}
	cherr <= "File: " <= filename <=  " successfully opened for reading" <= IO.newline();
	return 1;
	}

//----------------
// name: readFile()
// desc: reads line from a file into an array (float)
//----------------
fun void readFile() {
	for(0 => int i; i < NUM_LINES; i++) {
			Std.atof(FIO.readLine()) => BIODATA[i];
		}
	}

//----------------
// name: initKeyboard()
// desc: intiate a keyboard for input
//----------------
fun void initKeyboard() {
	// which keyboard
	0 => int device;

	// get from command line
	if( me.args() ) me.arg(0) => Std.atoi => device;
	
	// open keyboard (get device number from command line)
	if( !hi.openKeyboard( device ) ) me.exit();
	if(hi.name() != "Keychron K6" && hi.name() != "Apple Internal Keyboard / Trackpad") me.exit();
	
	<<< "keyboard '" + hi.name() + "' ready", "" >>>;

	}

//----------------
// name: panEffect()
// desc: Panning effect for output
//----------------
fun void panEffect() {
    10::ms => dur T;
    0.0 => float t;
	while(true) {
		while(PAN_BOOL) {
            Math.sin(t) => SYNTH.pan.pan;
            T / second * 2.5 +=> t;
            T => now;
		}
		0 => SYNTH.pan.pan;
		10::ms => now;
	}
}

//----------------
// name: echoEffect()
// desc: Echo effect for output
//----------------
fun void echoEffect() {
	while(true) {
		while(ECHO_BOOL) {

		10::ms => now;
		}
		10::ms => now;
	}
}

//----------------
// name: lpfEffect()
// desc: LPF effect for output
//----------------
fun void lpfEffect() {
	while(true) {
		while(LPF_BOOL) {
		10::ms => now;

		}
		10::ms => now;
	}
}

//----------------
// name: kb()
// desc: watch for keyboard input
//----------------
fun void kb()
{
    // infinite event loop
    while( true )
    {
        // wait on HidIn as event
        hi => now;
        
        // messages received
        while( hi.recv( msg ) )
        {
            // button donw
            if( msg.isButtonDown() )
            {
                if( msg.which == BIODATA_KEY )
                {
					if(SYNTH.getGain() == 0) {
							SYNTH.modulateGain(1.0);
						} else {
								SYNTH.modulateGain(0.0);
							}
                }
				if(msg.which == PAN_KEY) {
					if(PAN_BOOL) {
						0 => PAN_BOOL;
					} else {
						1 => PAN_BOOL;
					}
				}
				if(msg.which == ECHO_KEY) {
					if(ECHO_BOOL) {
						0 => ECHO_BOOL;
					} else {
						1 => ECHO_BOOL;
					}

				}
				if(msg.which == LPF_KEY) {
					if(LPF_BOOL) {
						0 => LPF_BOOL;
					} else {
						1 => LPF_BOOL;
					}

				}
                if(msg.which == 9) {
                    Machine.remove(LISA_CONTROLLER);
                }
            }
        }
    }
}

//----------------
// name: sonifyAlgo()
// desc: algorithm to sonify biodata
//----------------
fun void sonifyAlgo() {
	SYNTH.patch(1);
		while(true) {
 		for(0 => INDEX; INDEX < BIODATA.cap(); INDEX++) {
			// check for current index of BIODATA 

			if(BIODATA[INDEX] > 2.4) {
				<<< "Dominant" >>>;
				spork ~ SYNTH.run(81, v7);
			} else if(BIODATA[INDEX] > 2.1 && BIODATA[INDEX] <= 2.4) {
				<<< "Major" >>>;
				spork ~ SYNTH.run(69, maj);
			} else if(BIODATA[INDEX] <= 2.1 && BIODATA[INDEX] > 1.8){
				<<< "Minor" >>>;
				spork ~ SYNTH.run(57, min);
			} else if(BIODATA[INDEX] <= 1.8) {
				<<< "Diminished" >>>;
				spork ~ SYNTH.run(45, dim7);
			}

 			100::ms => now;
 		}

	}

	SYNTH.patch(0);
}


/////////////////
// SYNTH CLASS //
/////////////////
class Synth {

    // Global UGen //
    LPF low => NRev rev => Gain gain => Pan2 pan;
    
    1.0 => gain.gain;
	0 => pan.pan;
    
    // Set Param for UGen //
    // mix reverb
    0.2 => rev.mix;
    
    // set LPF
    500 => low.freq;
    0.8 => low.Q;
    0.5 => low.gain;

    fun void patch(int var) {
        if(var == 1) gain => dac;
        if(var == 0) gain !=> dac;
    }

	fun void modulateGain(float value) {
			value => gain.gain;
		}

	fun float getGain() {
		return gain.gain();
		}
    
    fun void playChord(int root, float chord[], float vel, 
    dur a, dur d, float s, dur r) {
        // ugens "local" to the function
        TriOsc osc[4];
        ADSR e => low;
        
        // patch
        for(0 => int i; i < osc.cap(); i++) {
            osc[i] => e;
        }
        
        // freq and gain
        for(0 => int i; i < osc.cap(); i++) {
            Std.mtof(root + chord[i]) => osc[i].freq;
            vel => osc[i].gain;
        }
        
        // open env (e is your envelope)
        e.set(a, d, s, r);
        e.keyOn();
        
        // A through end of S
        e.releaseTime() => now;
        
        // close env
        e.keyOff();
        
        // release
        e.releaseTime() => now;

		e !=> low;

        // patch
        for(0 => int i; i < osc.cap(); i++) {
            osc[i] !=> e;
        }
    }
    
    fun void vel(float f) {
        f => gain.gain;
    }
    
    fun float getVel() {
        return gain.gain();
    }
    
    fun void play(int root, float chord[]) {
        
        .5 => float vel;
        
        for(0 => int i; i < 8; i++) {
            playChord(root, chord, vel, T::ms, T::ms, 0.5, (T*2)::ms);
            
            T::ms => now;
            vel - .2 => vel;
        }
    }
    
    fun void run(int root, float chord[]) {
        play(root, min);
        (T*20)::ms => now;
    }
}















