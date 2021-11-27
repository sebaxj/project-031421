// Elena Gerogieva
// Music 256a, Homework 1
// Chuck code for the "narrative" component of the assignment


/////////////////////////////////////////////// 
// WINTER: "RAIN" 
// thanks to the 220a course
/////////////////////////////////////////////// 

class RainDrop
{
    // "rain"
    Impulse rain => LPF filter;
    // connect
    filter => Gain left;
    filter => Gain right;
}
// drops per second (try changing this over time)
50 => int N;
fun void panLinear( float pan, UGen left, UGen right )
{
    // clamp to bounds
    if( pan < 0 ) 0 => pan;
    else if( pan > 1 ) 1 => pan;
    
    // set gains
    1-pan => left.gain;
    pan => right.gain;
}
// constant power panning, expect pan=[0,1]
fun void panPower( float pan, UGen left, UGen right )
{
    // clamp to bounds
    if( pan < 0 ) 0 => pan;
    else if( pan > 1 ) 1 => pan;
    
    // set gains
    Math.cos( pan * pi / 2 ) *20 => left.gain;
    Math.sin( pan * pi / 2 ) *20=> right.gain;
}
// set a global value
0 => int LINEAR;
1 => int CONSTANTPOWER;

fun void panning( int which, float pan, UGen left, UGen right )
{
    if( which == LINEAR ) panLinear( pan, left, right);
    else if( which == CONSTANTPOWER ) panPower( pan, left, right );
}

// the drop
fun void oneDrop( RainDrop drop, float lowerFreq, float upperFreq, int panType )
{
    // randomize filter
    Math.random2f(lowerFreq,upperFreq) => drop.filter.freq;
    // randomize pan
    panning( panType, Math.random2f(0,1), drop.left, drop.right );
    // fire an impulse
    Math.random2f(.1,.8) => drop.rain.next;
}

fun float timeUntilNext( float lambda )
{ return -Math.log(1-Math.random2f(0,1)) / lambda; }
// define the "clip" as a function
fun void rainClip(dur myDur, int N)
{
    RainDrop rain[N];   
    // reverb
    JCRev rL => dac.left;
    JCRev rR => dac.right;
    // mix
    .2 => rL.mix => rR.mix;
    
    // connect
    for( int i; i < rain.size(); i++ )
    {
        rain[i].left => rL;
        rain[i].right => rR;
    }
    
    // counter
    int counter;
    
    now => time myBeg;
    myBeg + myDur => time myEnd;
    while (now < myEnd)
    {
        // LFO on upper freq
        800 + 2200*(1+Math.sin(now/second*.2))/2 => float upperFreq;
        // drop of rain
        oneDrop( rain[counter], 500, upperFreq, CONSTANTPOWER );
        // increment
        counter++;
        // modulo by rain array size
        rain.size() %=> counter;
        // wait (Poisson: from 220b)
        timeUntilNext(N)::second => now;
    }
    //extra time for reverb tails
    200::ms => now;
}
// TIME 0, start the clip
spork ~rainClip(22::second, N); // launch clip in independent shred for 20 secs
20::second => now; // this master shred needs to remain alive while it's playing
//me.yield(); // on this exact sample, yield master shred so sporked one can finish    first

//400::ms => now; //wait a sec

/////////////////////////////////////////////// 
// SPRING "HERE COMES THE SUN" 
// Thanks to the Beatles 
/////////////////////////////////////////////// 

int mymelody1[];
[ 76, 72, 74, 76, 76, 76, 76, 76, 76, 74, 74, 72, 72, 69, 69, 72, 72, 74, 74, 72, 72, 69, 67, 67, 67, 67, 67, 67, 67, 76, 74, 74, 76, 76, 72, 72, 72, 76, 72, 74, 76, 76, 76, 76, 76, 76, 74, 74, 76, 76, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72] @=>mymelody1; // verse

Flute melody1 => PoleZero f1 => Gain gmelody1 => NRev r1 => dac;
.9 => r1.gain;
.4 => r1.mix;
.99 => f1.blockZero;
7 => melody1.gain; //gain here

fun void flute_theme()
{   
    Math.random2f( 0.1, 0.2 ) => melody1.noiseGain;
    Math.random2f( 4, 8 ) => melody1.vibratoFreq;
    Math.random2f( 0.35, 0.50 ) => melody1.vibratoGain;
    // play notes
    for( int i; i < mymelody1.cap(); i++ )
    {
        play1( mymelody1[i] + 5, 0.05);
        250::ms => now; //BPM speed here
    }
    // turn off gain ?
    0 => r1.gain;
}

//play function for  theme
fun void play1( float note, float velocity )
{
    Std.mtof( note ) => melody1.freq;
    velocity => melody1.noteOn;
}


//call theme to play
flute_theme();
///400::ms => now; //wait a sec

/////////////////////////////////////////////// 
// SUMMER: "WAVES"
// Thanks to freesounds
/////////////////////////////////////////////// 

// sound file
me.sourceDir() + "/waves.wav" => string filename;
if( me.args() ) me.arg(0) => filename;

// the patch 
SndBuf buf => dac;
// load the file
filename => buf.read;

    0 => buf.pos;
    .6 => buf.gain;
    19700::ms => now; // play 19.6 seconds of the file

/////////////////////////////////////////////// 
// FALL: "CHORDS" 
// Composed by me
/////////////////////////////////////////////// 

// three osc's for voices
SawOsc foo => ADSR e => LPF lpf => dac;
SawOsc bar => e;
SawOsc baz => e;
// a, d, s, r for ADSR envelope
e.set( 100::ms, 20::ms, .4, 100::ms );
// quarter note duration
200::ms => dur Q;

// global variable for controling LPF freq
float value;
// slew
.2 => float slew;
// set amount of resonance on LPF cutoff
5 => lpf.Q;

// parallel shred: filter sweep
fun void sweep(dur myDur)
{
    now => time myBeg;
    myBeg + myDur => time myEnd;
    while( now< myEnd )
    {
        200 + Math.fabs(Math.sin( value * slew )*1200) => lpf.freq;
        .04 +=> value;
        5::ms => now;
    }
}
spork ~ sweep(27::second);

// main loop
now => time myBeg;
myBeg + 21::second => time myEnd;
while( now <myEnd )
{   
    // first set of chords, played twice 
    playChord( 26, 57, 64, Q*8 );
    playChord( 25, 40, 59, Q*6 );
    playChord( 25, 40, 59, Q*2 );
    playChord( 23, 50, 57, Q*3 );    
    playChord( 28, 50, 57, Q*1 );
    200::ms => now;
    playChord( 33, 49, 57, Q*11 );    
 
    playChord( 26, 57, 64, Q*8 );
    playChord( 25, 40, 59, Q*6 );
    playChord( 25, 40, 59, Q*2 );
    playChord( 23, 50, 57, Q*3 );    
    playChord( 28, 50, 57, Q*1 );
    200::ms => now;
    playChord( 33, 49, 57, Q*11 );
      
    //other set of chords, played twice
    playChord( 38, 59, 55, Q*8 );
    playChord( 38, 59, 55, Q*8 );
    playChord( 45, 50, 54, Q*6 );
    playChord( 33, 49, 52, Q*10 );
    
    //other set of chords
    playChord( 38, 59, 55, Q*8 );
    playChord( 38, 59, 55, Q*8 );
    playChord( 45, 50, 54, Q*6 );
    playChord( 33, 49, 52, Q*10 );
}

fun void playChord( float p1, float p2, float p3, dur T )
{
    // set freq
    p1 => Std.mtof => foo.freq;
    p2 => Std.mtof => bar.freq;
    p3 => Std.mtof => baz.freq;
    
    // reset variable for filter sweep
    0 => value;

    // open envelope
    e.keyOn();
    T-e.releaseTime() => now;
    e.keyOff();
    e.releaseTime() => now;
}

// play a note from the first osc (not used)
fun void playNote( float pitch, dur T )
{
    // set freq
    pitch => Std.mtof => foo.freq;
    // open envelope
    e.keyOn();
    T-e.releaseTime() => now;
    e.keyOff();
    e.releaseTime() => now;
}

// noise generator, biquad filter, dac (audio output) 
Noise n => BiQuad f => dac;
// set biquad pole radius
.99 => f.prad;
// set biquad gain
.05 => f.gain;
// set equal zeros 
1 => f.eqzs;
// our float
0.0 => float t;

// concurrent control
fun void wind_gain( )
{
    0.0 => float g; 
    
    // time loop to ramp up the gain / oscillate
    while( true )
    {
        Std.fabs( Math.sin( g ) ) => n.gain;
        g + .001 => g;
        2::ms => now;
    }
}

// wind closes piece
    spork ~ wind_gain();
    // sweep the filter resonant frequency
    100.0 + Std.fabs(Math.sin(t)) * 1000.0 => f.pfreq;
    t + .01 => t;
    // advance time
    6200::ms => now;
