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
// SinOsc s; 

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

	// spork sonification algorithm
	spork ~ sonifyAlgo();

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















