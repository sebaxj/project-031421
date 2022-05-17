//-----------------------------------------------------------------------------
// name: main.cpp
// desc: Capstone Project: Biosignal Analysis
//
// author:
//   date: Spring 2022
//   uses: RtAudio by Gary Scavone
//   thanks to: Ge Wang (ge@ccrma.stanford.edu), Chris Chafe, Takako Fujioka
//-----------------------------------------------------------------------------
#include "RtAudio/RtAudio.h"
#include "chuck.h"
#include <Python.h>
#include <iostream>
#include <math.h>
#include <stdlib.h>
#include <unistd.h>
using namespace std;

//-----------------------------------------------------------------------------
// Constants and Globals
//-----------------------------------------------------------------------------

// for convenience
#define MY_PIE 3.14159265358979

// our datetype
#define SAMPLE float

// corresponding format for RtAudio
#define MY_FORMAT RTAUDIO_FLOAT32

// sample rate
#define CHUCK_MY_SRATE 44100

// number of channels
#define MY_CHANNELS_IN 1
#define MY_CHANNELS_OUT 2

// number of channels
#define CHUCK_MY_CHANNELS 2

#define GREATER(a, b) (a > b ? a : b)

ChucK *the_chuck = NULL;

// Chuck sample rate
// const t_CKFLOAT CHUCK_MY_SRATE = 44100;
// Chuck number of channels
// const t_CKINT CHUCK_MY_CHANNELS = 2;

//-----------------------------------------------------------------------------
// name: callme()
// desc: audio callback
//-----------------------------------------------------------------------------
int callme(void *outputBuffer, void *inputBuffer, unsigned int numFrames,
           double streamTime, RtAudioStreamStatus status, void *data) {

  // cast!
  SAMPLE *input = (SAMPLE *)inputBuffer;
  SAMPLE *output = (SAMPLE *)outputBuffer;

  // compute chuck! Audio callback
  the_chuck->run(input, output, numFrames);

  // mute output -- TODO will need to disable this once ChucK produces output,
  // in order for you to hear it!
  //    for (int j = 0; j < MY_CHANNELS_OUT; j++) {
  //     output[i * MY_CHANNELS_OUT + j] = 0;
  //   }
  // cout << "END OF CALLBACK" << endl;

  return 0;
}

//-----------------------------------------------------------------------------
// name: main()
// desc: entry point
//-----------------------------------------------------------------------------
int main(int argc, char **argv) {

  // initialize the Python instance
  void Py_Initialize();

  // run a Python file
  FILE *PScriptFile = fopen("ecg-hrv.py", "r");
  if (PScriptFile) {
    // PyRun_SimpleFile(PScriptFile, "ecg-hrv.py");

    fclose(PScriptFile);
  }
  // Close the python instance
  void Py_Finalize();

  // instantiate RtAudio object
  RtAudio audio;

  // variables
  unsigned int bufferBytes = 0;
  // frame size
  unsigned int bufferFrames = 4096;

  // check for audio devices
  if (audio.getDeviceCount() < 1) {
    // nopes
    cout << "no audio devices found!" << endl;
    exit(1);
  }

  // let RtAudio print messages to stderr.
  audio.showWarnings(true);

  // set input and output parameters
  RtAudio::StreamParameters iParams, oParams;
  iParams.deviceId = audio.getDefaultInputDevice();
  iParams.nChannels = MY_CHANNELS_IN;
  iParams.firstChannel = 0;
  oParams.deviceId = audio.getDefaultOutputDevice();
  oParams.nChannels = MY_CHANNELS_OUT;
  oParams.firstChannel = 0;

  // create stream options
  RtAudio::StreamOptions options;

  // go for it
  try {
    // open a stream
    audio.openStream(&oParams, &iParams, MY_FORMAT, CHUCK_MY_SRATE,
                     &bufferFrames, &callme, (void *)&bufferBytes, &options);
  } catch (RtError &e) {
    // error!
    cout << e.getMessage() << endl;
    exit(1);
  }

  // compute
  bufferBytes =
      bufferFrames * GREATER(MY_CHANNELS_OUT, MY_CHANNELS_IN) * sizeof(SAMPLE);

  // set up chuck
  the_chuck = new ChucK();
  the_chuck->setParam(CHUCK_PARAM_SAMPLE_RATE,
                      CHUCK_MY_SRATE); // set sample rate
  the_chuck->setParam(CHUCK_PARAM_OUTPUT_CHANNELS,
                      CHUCK_MY_CHANNELS); // set number of channels in out
  the_chuck->setParam(CHUCK_PARAM_INPUT_CHANNELS,
                      MY_CHANNELS_IN); // set number of channels in
  the_chuck->setLogLevel(CK_LOG_INFO); // let chuck print more detailed log info
  the_chuck->init();                   // initialize chuck

  // ChucK file to compile
  the_chuck->compileFile("osc_server.ck", "");

  // start chuck
  the_chuck->start();

  // go for it
  try {
    // start stream
    audio.startStream();

  } catch (RtError &e) {
    // print error message
    cout << e.getMessage() << endl;
    goto cleanup;
  }

  // infinite loop to keep chuck running unless the vm crashes
  while (the_chuck->vm_running()) {
    usleep(10000);
  }

  // stop the stream.
  audio.stopStream();
  cerr << "cleaning up..." << endl;

cleanup:
  // close if open
  if (audio.isStreamOpen())
    audio.closeStream();

  // done
  return 0;
}
