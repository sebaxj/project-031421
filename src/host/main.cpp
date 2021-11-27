/*
 * main.cpp
 */

#include "RtAudio/RtAudio.h"
#include "chuck.h"
#include <math.h>
#include <stdlib.h>
#include <iostream>
using namespace std;

// our datetype
#define SAMPLE float
// corresponding format for RtAudio
#define MY_FORMAT RTAUDIO_FLOAT32
// sample rate
#define MY_SRATE 44100
// number of channels
#define MY_CHANNELS 2
// for convenience
#define MY_PIE 3.14159265358979

// global buffer
SAMPLE * g_buffer = NULL;
long g_bufferSize;

// global variables
ChucK * the_chuck = NULL;

// Chuck sample rate
const t_CKFLOAT CHUCK_MY_SRATE = 44100;
// Chuck number of channels
const t_CKINT CHUCK_MY_CHANNELS = 2;


//-----------------------------------------------------------------------------
// name: callme()
// desc: audio callback
//-----------------------------------------------------------------------------
int callme( void * outputBuffer, void * inputBuffer, unsigned int numFrames,
            double streamTime, RtAudioStreamStatus status, void * data )
{
    // cast!
    SAMPLE * input = (SAMPLE *)inputBuffer;
    SAMPLE * output = (SAMPLE *)outputBuffer;
    
    // compute chuck! Audio callback
	the_chuck->run(input, output, numFrames);
    
    // fill
    for( int i = 0; i < numFrames; i++ )
    {
        // copy the input to visualize only the left-most channel
        g_buffer[i] = input[i*MY_CHANNELS];
        
        // also copy in the output from chuck to our visualizer
        g_buffer[i] = output[i * MY_CHANNELS];

        // mute output -- TODO will need to disable this once ChucK produces output, in order for you to hear it!
        //for( int j = 0; j < MY_CHANNELS; j++ ) { output[i*MY_CHANNELS + j] = 0; }
    }
    
    
    
    return 0;
}




//-----------------------------------------------------------------------------
// name: main()
// desc: entry point
//-----------------------------------------------------------------------------
int main( int argc, char ** argv )
{
    // instantiate RtAudio object
    RtAudio audio;
    // variables
    unsigned int bufferBytes = 0;
    // frame size
    unsigned int bufferFrames = 1024;
    
    // check for audio devices
    if( audio.getDeviceCount() < 1 )
    {
        // nopes
        cout << "no audio devices found!" << endl;
        exit( 1 );
    }
    
    
    // let RtAudio print messages to stderr.
    audio.showWarnings( true );
    
    // set input and output parameters
    RtAudio::StreamParameters iParams, oParams;
    iParams.deviceId = audio.getDefaultInputDevice();
    iParams.nChannels = MY_CHANNELS;
    iParams.firstChannel = 0;
    oParams.deviceId = audio.getDefaultOutputDevice();
    oParams.nChannels = MY_CHANNELS;
    oParams.firstChannel = 0;
    
    // create stream options
    RtAudio::StreamOptions options;
    
    // go for it
    try {
        // open a stream
        audio.openStream( &oParams, &iParams, MY_FORMAT, MY_SRATE, &bufferFrames, &callme, (void *)&bufferBytes, &options );
    }
    catch( RtError& e )
    {
        // error!
        cout << e.getMessage() << endl;
        exit( 1 );
    }
    
    // compute
    bufferBytes = bufferFrames * MY_CHANNELS * sizeof(SAMPLE);
    // allocate global buffer
    g_bufferSize = bufferFrames;
    g_buffer = new SAMPLE[g_bufferSize];
    memset( g_buffer, 0, sizeof(SAMPLE)*g_bufferSize );
    
    // set up chuck
    the_chuck = new ChucK();
    the_chuck->setParam(CHUCK_PARAM_SAMPLE_RATE, CHUCK_MY_SRATE); // set sample rate
    the_chuck->setParam(CHUCK_PARAM_OUTPUT_CHANNELS, CHUCK_MY_CHANNELS); // set number of channels in and out
    the_chuck->setParam(CHUCK_PARAM_INPUT_CHANNELS, CHUCK_MY_CHANNELS);
    the_chuck->init();
    the_chuck->compileFile("test.ck","");
   
	// start streaming
    // go for it
    try {
        // start stream
        audio.startStream();
        
        // stop the stream.
        audio.stopStream();
    }
    catch( RtError& e )
    {
        // print error message
        cout << e.getMessage() << endl;
        goto cleanup;
    }
    
cleanup:
    // close if open
    if( audio.isStreamOpen() )
        audio.closeStream();
    
    // done
    return 0;
}





