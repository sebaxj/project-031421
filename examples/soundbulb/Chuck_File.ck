//Coded by Kunwoo Kim
//kunwoo@ccrma.stanford.edu
//Music256A Assignment 3 - Sound Peeking
//Chuck Code used with SoundBulb.cpp

//------------------------------------------
//-------------Global Variables-------------
//------------------------------------------

//boolean for breaking the lightbulb
int break_stop;
0 => break_stop;

//Probability float for lightbulb getting bugged
float bug_prob;
1 => bug_prob;

//Melodyline for "My Favorite Things"
int mymelody1[];
[ 76, 83,83, 78,76,76, 71,76,76, 78,76,76, 88,95,95, 90,88,88, 83,88,88, 90,88,88, 88,95,93, 88,90,86, 86,93,91, 84,84,84, 83,84,86, 88,90,91, 93,95,93, 87,87,87 ] @=> mymelody1;

//Harmonyline1 for "My Favorite Things"
int mymelody2[];
[ 76,83,83, 78,76,76, 71,76,76, 78,76,76, 76,83,83, 78,76,76, 71,76,76, 78,76,76, 76,83,81, 76,78,74, 74,81,79, 72,72,72, 71,72,74, 76,78,79, 81,83,81, 75,75,75 ] @=> mymelody2;

//Harmonyline2 for "My Favorite Things"
int mymelody3[];
[ 43,43,43, 40,40,40, 43,43,43, 40,40,40, 36,36,36, 40,40,40, 36,36,36, 40,40,40, 49,49,49, 42,42,42, 47,47,47, 40,40,40, 47,47,47, 52,52,52, 45,45,45, 51,51,51 ] @=> mymelody3;

//Harmonyline3 for "My Favorite Things"
int mymelody4[];
[ 40,40,40, 43,43,43, 40,40,40, 43,43,43, 40,40,40, 36,36,36, 40,40,40, 36,36,36, 45,45,45, 38,38,38, 43,43,43, 36,36,36, 43,43,43, 48,48,48, 42,42,42, 47,47,47 ] @=> mymelody4;

//Harmonyline4 for "My Favorite Things"
int mymelody5[];
[  43,43,43, 40,40,40, 43,43,43, 40,40,40, 36,36,36, 40,40,40, 36,36,36, 40,40,40, 49,49,49, 42,42,42, 47,47,47, 40,40,40, 47,47,47, 52,52,52, 45,45,45, 51,51,51 ] @=> mymelody5;

//Harmonyline5 for "My Favorite Things"
int mymelody6[];
[ 40,40,40, 43,43,43, 40,40,40, 43,43,43, 40,40,40, 36,36,36, 40,40,40, 36,36,36, 45,45,45, 38,38,38, 43,43,43, 36,36,36, 43,43,43, 48,48,48, 42,42,42, 47,47,47 ] @=> mymelody6;


//------------------------------------------
//-------Narrative 1. Clarinet Theme--------
//------------------------------------------

//Call Clarinet Sound & Assign values
Clarinet melody1 => PoleZero f1 => Gain gmelody1 => NRev r1 => dac;
.80 => r1.gain;
.3 => r1.mix;
.99 => f1.blockZero;

//Clarinet Function that plays "My Favorite Things" just the melody
fun void clarinet_theme()
{
    // clear
    melody1.clear( 1.0 );
    
    // set
    Math.random2f( 0.1, 0.2 ) => melody1.noiseGain;
    Math.random2f( 4, 8 ) => melody1.vibratoFreq;
    Math.random2f( 0.25, 0.30 ) => melody1.vibratoGain;
    Math.random2f( .25, .3 ) => melody1.pressure;
    
    // play notes
    for( int i; i < mymelody1.cap(); i++ )
    {
        play1( mymelody1[i] + 5, 0.05);
        500::ms => now;
    }
    // turn off gain
    0 => r1.gain;
}

//play function for clarinet theme
fun void play1( float note, float velocity )
{
    // start the note
    Std.mtof( note ) => melody1.freq;
    velocity => melody1.noteOn;
}

//call clarinet theme to play
clarinet_theme();


//------------------------------------------
//-------Narrative 2. Clarinet Bugged-------
//------------------------------------------

//Call clarinet sounds for 6 parts
Clarinet cmelody1 => PoleZero cf1 => Gain cgmelody1 => NRev cr1 => dac;
Clarinet cmelody2 => PoleZero cf2 => Gain cgmelody2 => NRev cr2 => dac;
Clarinet cmelody3 => PoleZero cf3 => Gain cgmelody3 => NRev cr3 => dac;
Clarinet cmelody4 => PoleZero cf4 => Gain cgmelody4 => NRev cr4 => dac;
Clarinet cmelody5 => PoleZero cf5 => Gain cgmelody5 => NRev cr5 => dac;
Clarinet cmelody6 => PoleZero cf6 => Gain cgmelody6 => NRev cr6 => dac;

//Call sqaure wave sounds for 6 parts
SqrOsc csqrmel1 => PoleZero csqf1 => NRev csqr1 => dac;
SqrOsc csqrmel2 => PoleZero csqf2 => NRev csqr2 => dac;
SqrOsc csqrmel3 => PoleZero csqf3 => NRev csqr3 => dac;
SqrOsc csqrmel4 => PoleZero csqf4 => NRev csqr4 => dac;
SqrOsc csqrmel5 => PoleZero csqf5 => NRev csqr5 => dac;
SqrOsc csqrmel6 => PoleZero csqf6 => NRev csqr6 => dac;

//Assign clarinet values
.70 => cr1.gain => cr2.gain;
.40 => cr3.gain => cr4.gain => cr5.gain => cr6.gain;
.5 => cr1.mix => cr2.mix;
.2 => cr3.mix => cr4.mix => cr5.mix => cr6.mix;
.99 => cf1.blockZero => cf2.blockZero => cf3.blockZero => cf4.blockZero => cf5.blockZero => cf6.blockZero;

//Assign sqaure wave values
0 => csqr1.gain => csqr2.gain => csqr3.gain => csqr4.gain => csqr5.gain => csqr6.gain;
.2 => csqr1.mix => csqr2.mix => csqr3.mix => csqr4.mix => csqr5.mix => csqr6.mix;
.99 => csqf1.blockZero => csqf2.blockZero => csqf3.blockZero => csqf4.blockZero => csqf5.blockZero => csqf6.blockZero;

//Function that plays clarinet theme bugged
fun void clarinet_theme_bugged()
{
    // clear
    cmelody1.clear( 1.0 );
    cmelody2.clear( 1.0 );
    cmelody3.clear( 1.0 );
    cmelody4.clear( 1.0 );
    cmelody5.clear( 1.0 );
    cmelody6.clear( 1.0 );
    
    // set
    Math.random2f( 0.1, 0.2 ) => cmelody1.noiseGain;
    Math.random2f( 4, 8 ) => cmelody1.vibratoFreq;
    Math.random2f( 0.25, 0.30 ) => cmelody1.vibratoGain;
    Math.random2f( .25, .3 ) => cmelody1.pressure;
    
    Math.random2f( 0.1, 0.2 ) => cmelody2.noiseGain;
    Math.random2f( 4, 8 ) => cmelody2.vibratoFreq;
    Math.random2f( 0.25, 0.50 ) => cmelody2.vibratoGain;
    Math.random2f( .25, .5 ) => cmelody2.pressure;
    
    Math.random2f( 0, 0 ) => cmelody3.noiseGain;
    Math.random2f( 1, 2 ) => cmelody3.vibratoFreq;
    Math.random2f( 0.05, 0.1 ) => cmelody3.vibratoGain;
    Math.random2f( .1, .2 ) => cmelody3.pressure;
    
    Math.random2f( 0, 0 ) => cmelody4.noiseGain;
    Math.random2f( 1, 2 ) => cmelody4.vibratoFreq;
    Math.random2f( 0.05, 0.1 ) => cmelody4.vibratoGain;
    Math.random2f( .1, .2 ) => cmelody4.pressure;
    
    Math.random2f( 0, 0 ) => cmelody5.noiseGain;
    Math.random2f( 1, 2 ) => cmelody5.vibratoFreq;
    Math.random2f( 0.05, 0.1 ) => cmelody5.vibratoGain;
    Math.random2f( .1, .2 ) => cmelody5.pressure;
    
    Math.random2f( 0, 0 ) => cmelody6.noiseGain;
    Math.random2f( 1, 2 ) => cmelody6.vibratoFreq;
    Math.random2f( 0.05, 0.1 ) => cmelody6.vibratoGain;
    Math.random2f( .1, .2 ) => cmelody6.pressure;
    
    //Depending on the bug probability, it plays either clarinet or square wave for melody 1 & 2
    for( int i; i < mymelody1.cap(); i++ )
    {
        if ( (bug_prob * (i+0.01)/(mymelody1.cap()+0.01) ) > Math.random2f(0,1) )
        {
            csqplay1( mymelody1[i] );
            0 => cr1.gain;
            .015 => csqr1.gain;
        }
        else
        {
            cplay1( mymelody1[i] + 5, 0.05);
            0.60 => cr1.gain;
            0 => csqr1.gain;
        }
        
        if ( (bug_prob * (i+0.01)/(mymelody1.cap()+0.01) ) > Math.random2f(0,1) )
        {
            csqplay2( mymelody2[i] );
            0 => cr2.gain;
            .015 => csqr2.gain;
        }
        else
        {
            cplay2( mymelody2[i] + 5, 0.05);
            0.60 => cr2.gain;
            0 => csqr2.gain;
        }
        cplay2( mymelody2[i] + 5, 0.05);
        cplay3( mymelody3[i] + 17, 0.05);
        cplay4( mymelody4[i] + 17, 0.05);
        cplay5( mymelody5[i] + 5, 0.05);
        cplay6( mymelody6[i] + 5, 0.05);
        500::ms => now;
    }
    //Reset Gain
    0 => cr1.gain => cr2.gain;
    0 => cr3.gain => cr4.gain => cr5.gain => cr6.gain;
    0 => csqr1.gain => csqr2.gain;
}

// basic play functions for clarinet bugged theme
fun void cplay1( float note, float velocity )
{
    // start the note
    Std.mtof( note ) => cmelody1.freq;
    velocity => cmelody1.noteOn;
}

fun void cplay2( float note, float velocity )
{
    // start the note
    Std.mtof( note ) => cmelody2.freq;
    velocity => cmelody2.noteOn;
}

fun void cplay3( float note, float velocity )
{
    // start the note
    Std.mtof( note ) => cmelody3.freq;
    velocity => cmelody3.noteOn;
}

fun void cplay4( float note, float velocity )
{
    // start the note
    Std.mtof( note ) => cmelody4.freq;
    velocity => cmelody4.noteOn;
}

fun void cplay5( float note, float velocity )
{
    // start the note
    Std.mtof( note ) => cmelody5.freq;
    velocity => cmelody5.noteOn;
}

fun void cplay6( float note, float velocity )
{
    // start the note
    Std.mtof( note ) => cmelody6.freq;
    velocity => cmelody6.noteOn;
}

fun void csqplay1( float note)
{
    // start the note
    Std.mtof( note ) => csqrmel1.freq;
}

fun void csqplay2( float note)
{
    // start the note
    Std.mtof( note ) => csqrmel2.freq;
}

//call the function to play
clarinet_theme_bugged();


//------------------------------------------
//------Narrative 3. Squarewave Break-------
//------------------------------------------

//Call 10 sqaurewave sounds that will break the lightbulb
SqrOsc sqbrmel1 => PoleZero sqbf1 => NRev sqbr1 => dac;
SqrOsc sqbrmel2 => PoleZero sqbf2 => NRev sqbr2 => dac;
SqrOsc sqbrmel3 => PoleZero sqbf3 => NRev sqbr3 => dac;
SqrOsc sqbrmel4 => PoleZero sqbf4 => NRev sqbr4 => dac;
SqrOsc sqbrmel5 => PoleZero sqbf5 => NRev sqbr5 => dac;
SqrOsc sqbrmel6 => PoleZero sqbf6 => NRev sqbr6 => dac;
SqrOsc sqbrmel7 => PoleZero sqbf7 => NRev sqbr7 => dac;
SqrOsc sqbrmel8 => PoleZero sqbf8 => NRev sqbr8 => dac;
SqrOsc sqbrmel9 => PoleZero sqbf9 => NRev sqbr9 => dac;
SqrOsc sqbrmel10 => PoleZero sqbf10 => NRev sqbr10 => dac;

//Assign values
.015 => sqbr1.gain;
0 => sqbr2.gain => sqbr3.gain => sqbr4.gain => sqbr5.gain => sqbr6.gain => sqbr7.gain => sqbr8.gain => sqbr9.gain => sqbr10.gain;
.2 => sqbr1.mix => sqbr2.mix => sqbr3.mix => sqbr4.mix => sqbr5.mix => sqbr6.mix => sqbr7.mix => sqbr8.mix => sqbr9.mix => sqbr10.mix;
.99 => sqbf1.blockZero => sqbf2.blockZero => sqbf3.blockZero => sqbf4.blockZero => sqbf5.blockZero => sqbf6.blockZero => sqbf7.blockZero => sqbf8.blockZero => sqbf9.blockZero => sqbf10.blockZero;

//Call noise sound that will happen at the break
Noise awnoise => BiQuad af => dac;
.99 => af.prad;
0 => af.gain;
1 => af.eqzs;

//Function to call square wave break theme
fun void sqrwave_break()
{   
    while (break_stop == 0)
    {
        //1st harmony
        Std.mtof(75) => sqbrmel1.freq;
        500::ms => now;
        //2nd harmony
        Std.mtof(75) => sqbrmel1.freq;
        Std.mtof(80) => sqbrmel2.freq;
        Std.mtof(70) => sqbrmel3.freq;
        .020 => sqbr2.gain => sqbr3.gain;
        500::ms => now;
        //3rd harmony
        Std.mtof(75) => sqbrmel1.freq;
        Std.mtof(80) => sqbrmel2.freq;
        Std.mtof(85) => sqbrmel3.freq;
        Std.mtof(70) => sqbrmel4.freq;
        Std.mtof(65) => sqbrmel5.freq;
        .020 => sqbr4.gain => sqbr5.gain;
        500::ms => now;
        //4th harmony
        Std.mtof(75) => sqbrmel1.freq;
        Std.mtof(80) => sqbrmel2.freq;
        Std.mtof(85) => sqbrmel3.freq;
        Std.mtof(70) => sqbrmel4.freq;
        Std.mtof(65) => sqbrmel5.freq;
        Std.mtof(60) => sqbrmel6.freq;
        Std.mtof(55) => sqbrmel7.freq;
        .020 => sqbr6.gain => sqbr7.gain;
        500::ms => now;
        //5th harmony
        Std.mtof(75) => sqbrmel1.freq;
        Std.mtof(80) => sqbrmel2.freq;
        Std.mtof(85) => sqbrmel3.freq;
        Std.mtof(90) => sqbrmel4.freq;
        Std.mtof(70) => sqbrmel5.freq;
        Std.mtof(65) => sqbrmel6.freq;
        Std.mtof(60) => sqbrmel7.freq;
        Std.mtof(55) => sqbrmel8.freq;
        .020 => sqbr8.gain;
        500::ms => now;
        Std.mtof(75) => sqbrmel1.freq;
        Std.mtof(80) => sqbrmel2.freq;
        Std.mtof(85) => sqbrmel3.freq;
        Std.mtof(90) => sqbrmel4.freq;
        Std.mtof(70) => sqbrmel5.freq;
        Std.mtof(65) => sqbrmel6.freq;
        Std.mtof(60) => sqbrmel7.freq;
        Std.mtof(55) => sqbrmel8.freq;
        Std.mtof(50) => sqbrmel9.freq;
        Std.mtof(95) => sqbrmel10.freq;
        .030 => sqbr9.gain => sqbr10.gain;
        0.005 => af.gain;
        1200::ms => now;
        
        //Reset Gain
        0 => af.gain;
        0 => sqbr1.gain => sqbr2.gain => sqbr3.gain => sqbr4.gain => sqbr5.gain => sqbr6.gain => sqbr7.gain => sqbr8.gain => sqbr9.gain => sqbr10.gain;
        1 => break_stop;
    }   
}

//Call Squarewave break theme to play
sqrwave_break();


//------------------------------------------
//------Narrative 4. Squarewave Theme-------
//------------------------------------------

//melody for square wave theme
int mysqmelody [];
[ 76,83,83, 78,76,76, 71,76,76, 78,76,76, 76,83,83, 78,76,76, 71,76,76, 78,76,76, 76,83,81, 76,78,74, 74,81,79, 72,72,72, 71,72,74, 76,78,79, 81,83,81, 75,75,75 ] @=> mysqmelody;

//Call Squarewave sound and assign values
SqrOsc sqrmel1 => PoleZero sqf1 => NRev sqr1 => dac;
.005 => sqr1.gain;
.8 => sqr1.mix;
.99 => sqf1.blockZero;

//Call Background noise
Noise wnoise => BiQuad f => dac;
.99 => f.prad;
0 => f.gain;
1 => f.eqzs;

//Function for squarewave theme
fun void sqrwave_theme()
{   
    for( int i; i < mysqmelody.cap(); i++ )
    {
        0.001 => f.gain;
        //Random Transposition
        sqplay1( mysqmelody[i] + Math.random2(0,1));
        222::ms => now;
        
        //Fade out
        if (i == mysqmelody.cap() - 5)
        {
            0.0045 => sqr1.gain;   
        }
        else if (i == mysqmelody.cap() - 4)
        {
            0.0040 => sqr1.gain;  
        }
        else if (i == mysqmelody.cap() - 3)
        {
            0.0035 => sqr1.gain;  
        }
        else if (i == mysqmelody.cap() - 2)
        {
            0.0032 => sqr1.gain;  
        }
        else if (i == mysqmelody.cap() - 1)
        {
            0.0025 => sqr1.gain;  
        }
    }
    //Reset Gain
    0 => sqr1.gain;
    0 => f.gain;
}

//play function for squarewave theme
fun void sqplay1( float note)
{
    // start the note
    Std.mtof( note ) => sqrmel1.freq;
}

//Call squarewave theme function to play
sqrwave_theme();


//------------------------------------------
//--Narrative 5. Clarinet Theme Returned----
//------------------------------------------

//function for clarinet theme return
fun void clarinet_theme_return()
{
    // clear
    cmelody1.clear( 1.0 );
    cmelody2.clear( 1.0 );
    cmelody3.clear( 1.0 );
    cmelody4.clear( 1.0 );
    cmelody5.clear( 1.0 );
    cmelody6.clear( 1.0 );
    
    .50 => cr1.gain => cr2.gain;
    .20 => cr3.gain => cr4.gain => cr5.gain => cr6.gain;
    
    // set
    Math.random2f( 0.1, 0.2 ) => cmelody1.noiseGain;
    Math.random2f( 4, 8 ) => cmelody1.vibratoFreq;
    Math.random2f( 0.25, 0.30 ) => cmelody1.vibratoGain;
    Math.random2f( .25, .3 ) => cmelody1.pressure;
    
    Math.random2f( 0.1, 0.2 ) => cmelody2.noiseGain;
    Math.random2f( 4, 8 ) => cmelody2.vibratoFreq;
    Math.random2f( 0.25, 0.50 ) => cmelody2.vibratoGain;
    Math.random2f( .25, .5 ) => cmelody2.pressure;
    
    Math.random2f( 0, 0 ) => cmelody3.noiseGain;
    Math.random2f( 1, 2 ) => cmelody3.vibratoFreq;
    Math.random2f( 0.05, 0.1 ) => cmelody3.vibratoGain;
    Math.random2f( .1, .2 ) => cmelody3.pressure;
    
    Math.random2f( 0, 0 ) => cmelody4.noiseGain;
    Math.random2f( 1, 2 ) => cmelody4.vibratoFreq;
    Math.random2f( 0.05, 0.1 ) => cmelody4.vibratoGain;
    Math.random2f( .1, .2 ) => cmelody4.pressure;
    
    Math.random2f( 0, 0 ) => cmelody5.noiseGain;
    Math.random2f( 1, 2 ) => cmelody5.vibratoFreq;
    Math.random2f( 0.05, 0.1 ) => cmelody5.vibratoGain;
    Math.random2f( .1, .2 ) => cmelody5.pressure;
    
    Math.random2f( 0, 0 ) => cmelody6.noiseGain;
    Math.random2f( 1, 2 ) => cmelody6.vibratoFreq;
    Math.random2f( 0.05, 0.1 ) => cmelody6.vibratoGain;
    Math.random2f( .1, .2 ) => cmelody6.pressure;
    
    //play all six melodies and harmonies
    for( int i; i < mymelody1.cap(); i++ )
    {
        cplay1( mymelody1[i] -1, 0.05);
        cplay2( mymelody2[i] -1, 0.05);
        cplay3( mymelody3[i] + 11, 0.05);
        cplay4( mymelody4[i] + 11, 0.05);
        cplay5( mymelody5[i] -1, 0.05);
        cplay6( mymelody6[i] -1, 0.05);
        if ( i == mymelody1.cap() - 1)
        {
            2000::ms => now;
        }
        else
        {
            500::ms => now;
        }
        
    }
    //Reset gain
    0 => cr1.gain => cr2.gain;
    0 => cr3.gain => cr4.gain => cr5.gain => cr6.gain;
}

//Call Clarinet Function
clarinet_theme_return();