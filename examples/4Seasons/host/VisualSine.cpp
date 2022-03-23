//-----------------------------------------------------------------------------
// name: Soundbulb.cpp
// desc: Realtime sound visualizer with optional narrative
//
// author: Kunwoo Kim (kunwoo@ccrma.stanford.edu)
//   date: fall 2017
//    for: Music 256A Assignment 3 - Sound Peeking
//  based: VisualSine by Ge Wang
//   uses: RtAudio by Gary Scavone
//-----------------------------------------------------------------------------
#include "RtAudio/RtAudio.h"
#include "chuck.h"
#include <math.h>
#include <stdlib.h>
#include <iostream>
#include <sstream>
#include <stdio.h>
using namespace std;

#ifdef __MACOSX_CORE__
#include <GLUT/glut.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#else
#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glut.h>
#endif

//FFT
#include "chuck_fft.h"



//-----------------------------------------------------------------------------
// function prototypes
//-----------------------------------------------------------------------------
void initGfx();
void idleFunc();
void displayFunc();
void reshapeFunc( GLsizei width, GLsizei height );
void keyboardFunc( unsigned char, int, int );
double compute_log_spacing( int fft_size, double factor );

// our datetype
#define SAMPLE float
// corresponding format for RtAudio
#define MY_FORMAT RTAUDIO_FLOAT32
// sample rate
#define MY_SRATE 44100
// number of channels
#define MY_CHANNELS 1
// for convenience
#define MY_PIE 3.14159265358979

#define SAMPLE                  float
#define RTAUDIO_FORMAT          RTAUDIO_FLOAT32
#define SND_BUFFER_SIZE         1024
#define SND_FFT_SIZE            ( SND_BUFFER_SIZE * 2 )

// sample rate
const long MY_SAMRATE = 44100;
// number of channels
const long MY_CHANNELNUMS = 1;
// frame size
const long MY_FRAMESIZE = 1024;

// Chuck sample rate
const t_CKFLOAT CHUCK_MY_SRATE = 44100;
// Chuck number of channels
const t_CKINT CHUCK_MY_CHANNELS = 1;

// global frequency (used for Chuck Sine Wave Testing)
float freq = 440;

// global audio buffer
SAMPLE g_fft_buffer[SND_FFT_SIZE];
SAMPLE g_audio_buffer[SND_BUFFER_SIZE]; // latest mono buffer (possibly preview)
SAMPLE g_stereo_buffer[SND_BUFFER_SIZE*2]; // current stereo buffer (now playing)
GLfloat g_window[SND_BUFFER_SIZE]; // DFT transform window
GLfloat g_log_positions[SND_FFT_SIZE/2]; // precompute positions for log spacing
GLint g_buffer_size = SND_BUFFER_SIZE;
GLint g_fft_size = SND_FFT_SIZE;

// real-time audio
RtAudio * g_audio = NULL;
GLboolean g_ready = FALSE;

// array of booleans for waterfall
GLboolean * g_draw = NULL;
// plot waterfall
GLboolean g_wutrfall = TRUE;
// which way the waterfall moves
GLboolean g_backwards = FALSE;
// draw play pointer
GLboolean g_draw_play = FALSE;
// waveform
GLboolean g_waveform = TRUE;

// gain
GLfloat g_gain = 1.0f;
GLfloat g_time_scale = 1.0f;
GLfloat g_freq_scale = 1.0f;
GLfloat g_lissajous_scale = 0.45f;

//global color for spectrum
GLfloat r = 0;
GLfloat b = 0;
GLfloat g = 0;

// how much to see
GLint g_time_view = 1;
GLint g_freq_view = 2;

// for log scaling
GLdouble g_log_space = 0;
//GLdouble g_log_factor = 1;
GLdouble g_log_factor = 0.1;

// the index associated with the waterfall
GLint g_wf = 0;
// starting a file
GLint g_starting = 0;

// delay for pseudo-Lissajous in mono stuff
GLint g_delay = SND_BUFFER_SIZE/2;

// number of real-time audio channels
GLint g_sndout = 0;
GLint g_sndin = 2;

// for waterfall
struct Pt2D { float x; float y; };
Pt2D ** g_spectrums = NULL;
GLuint g_depth = 80; // for john: 64
GLfloat g_z = 0.0f;
GLboolean g_z_set = FALSE;
GLfloat g_space = .12f; // for john: .1f
GLboolean g_downsample = FALSE;
GLint g_ds = 0; // downsample amount

// for time domain waterfall
SAMPLE ** g_waveforms = NULL;
GLfloat g_wf_delay_ratio = 1.0f / 3.0f;
GLuint g_wf_delay = (GLuint)(g_depth * g_wf_delay_ratio + .5f);
GLuint g_wf_index = 0;

// keeps track of maximum amplitude
float max_amp = 0;

// width and height
long g_width = 1024;
long g_height = 720;
// global buffer
SAMPLE * g_buffer = NULL;
long g_bufferSize;

// global variables
bool g_draw_dB = false;
ChucK * the_chuck = NULL;
int break_counter = 0;
bool break_status = false;
float lightbulb_constant = 47.0f;

 //Making ellipse
float cos_skew=1.0f;
float sin_skew=1.0f;
float fader = 1.0f;

//Input
float max_radius = 6.0;
float time_gain = 2.0f;

// boolean to keep track of narrative key
GLboolean narrativekey = FALSE;

// stringstream for compiling chuck code
stringstream ss;


//-----------------------------------------------------------------------------
// name: help()
// desc: ...
//-----------------------------------------------------------------------------
void help()
{
    fprintf( stderr, "----------------------------------------------------\n" );
    fprintf( stderr, "SoundBulb (1.0)\n" );
    fprintf( stderr, "Kunwoo Kim\n" );
    fprintf( stderr, "http://www.kunwookimm.com/\n" );
    fprintf( stderr, "----------------------------------------------------\n" );
    fprintf( stderr, "'q' - quit the program\n" );
    fprintf( stderr, "'n' - play narrative\n" );
    fprintf( stderr, "\n" );
}


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
    
    // make output of chuck the buffer
    the_chuck -> run(input, output, MY_FRAMESIZE);

    // fill
    for( int i = 0; i < numFrames; i++ )
    {
        // assume mono
        g_buffer[i] = output[i];
        // zero output
        input[i] = 0;
    }

    return 0;
}


//-----------------------------------------------------------------------------
// name: initChucK()
// desc: initialize ChucK
//-----------------------------------------------------------------------------
bool initChucK()
{
    // Instantiate ChucK
    the_chuck = new ChucK;
    
    // Set parameters of ChucK
    if (narrativekey == TRUE)
    {
        char myDirectory[512];
        getcwd( myDirectory, 512);
        the_chuck->setParam( CHUCK_PARAM_WORKING_DIRECTORY, myDirectory );
    }
    
    the_chuck->setParam(CHUCK_PARAM_SAMPLE_RATE, CHUCK_MY_SRATE);
    the_chuck->setParam(CHUCK_PARAM_OUTPUT_CHANNELS, CHUCK_MY_CHANNELS);
    the_chuck->setParam(CHUCK_PARAM_INPUT_CHANNELS, CHUCK_MY_CHANNELS);
    
    // Initialize ChucK
    the_chuck->init();

    return true;
}


//-----------------------------------------------------------------------------
// name: main()
// desc: entry point
//-----------------------------------------------------------------------------
int main( int argc, char ** argv )
{

    // print usage
    help();

    //--------VISUAL PREPARATION--------------------
    // initialize GLUT
    glutInit( &argc, argv );
    // init gfx
    initGfx();
    //------------------**---------------------
    


    //----------AUDIO PREPARATION-------------------
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
    //------------------**---------------------


    //---INITIALIZING CHUCK && COMPILE CHUCK CODE-------

    // NOTE: init ChucK (see function above)
    if( !initChucK() )
        exit( 1 );

    // make Chuck take input
    //declare stringstream for chuck compiling
    //ss << "adc => dac; while(true) 1::second => now;";
    //the_chuck->compileCode(ss.str(), "");

    if (narrativekey == FALSE)
        {
            // make Chuck take input
            //declare stringstream for chuck compiling
            ss << "adc => Gain gadc => dac; 0.5 => gadc.gain; external Event myEvent; myEvent => now;";
            the_chuck->compileCode(ss.str(), "");
        }

    //------------------**---------------------


    //--------SETTING AUDIO PARAMETERS---------------
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
    //------------------**---------------------


    //---------OPEN STREAM & CALL AUDIO CALLBACK------
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
    //------------------**---------------------


    //-----------SET BUFFER------------
    // compute
    bufferBytes = bufferFrames * MY_CHANNELS * sizeof(SAMPLE);
    // allocate global buffer
    g_bufferSize = bufferFrames;
    g_buffer = new SAMPLE[g_bufferSize];
    memset( g_buffer, 0, sizeof(SAMPLE)*g_bufferSize );
    //------------------**---------------------


    //-----------START STREAMING--------------
    // go for it
    try {
        // start stream
        audio.startStream();
        
        // let GLUT handle the current thread from here
        glutMainLoop();
        
        // stop the stream.
        audio.stopStream();
    }
    catch( RtError& e )
    {
        // print error message
        cout << e.getMessage() << endl;
        goto cleanup;
    }
    //------------------**------------------------

    cleanup:
    // close if open
    if( audio.isStreamOpen() )
        audio.closeStream();
    
    // done
    return 0;
}




//-----------------------------------------------------------------------------
// Name: reshapeFunc( )
// Desc: called when window size changes
//-----------------------------------------------------------------------------
void initGfx()
{
    //------INITIALIZE & CREATE WINDOW----------------
    // double buffer, use rgb color, enable depth buffer
    glutInitDisplayMode( GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH );
    // initialize the window size
    glutInitWindowSize( g_width, g_height );
    // set the window postion
    glutInitWindowPosition( 100, 100 );
    // create the window
    glutCreateWindow( "SoundBulb" );

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
    glEnable( GL_BLEND ); glClearColor(0.0,0.0,0.0,0.0);
    //------------------**----------------------------
    

    //------CALL FUNCTIONS TO PREP FOR CHANGES-----------
    // set the idle function - called when idle
    glutIdleFunc( idleFunc );
    // set the display function - called when redrawing
    glutDisplayFunc( displayFunc );
    // set the reshape function - called when client area changes
    glutReshapeFunc( reshapeFunc );
    // set the keyboard function - called on keyboard events
    glutKeyboardFunc( keyboardFunc );
    //------------------**-----------------------
    
    
    
    // set clear color
    glClearColor( 0, 0, 0, 1 );
    // enable color material
    glEnable( GL_COLOR_MATERIAL );
    // enable depth test
    glEnable( GL_DEPTH_TEST );


    // initialize
    g_waveforms = new SAMPLE *[g_wf_delay];

    for( int i = 0; i < g_wf_delay; i++ )
    {
        // allocate memory (stereo)
        g_waveforms[i] = new SAMPLE[g_buffer_size * 2];
        // zero it
        memset( g_waveforms[i], 0, g_buffer_size * 2 * sizeof(SAMPLE) );
    }

    // initialize
    g_spectrums = new Pt2D *[g_depth];

    for( int i = 0; i < g_depth; i++ )
    {
        g_spectrums[i] = new Pt2D[SND_FFT_SIZE];
        memset( g_spectrums[i], 0, sizeof(Pt2D)*SND_FFT_SIZE );
    }
    g_draw = new GLboolean[g_depth];
    memset( g_draw, 0, sizeof(GLboolean)*g_depth );

    // compute log spacing
    g_log_space = compute_log_spacing( g_fft_size / 2, g_log_factor );

}




//-----------------------------------------------------------------------------
// Name: reshapeFunc( )
// Desc: called when window size changes
//-----------------------------------------------------------------------------
void reshapeFunc( GLsizei w, GLsizei h )
{
    // save the new window size
    g_width = w; g_height = h;
    // map the view port to the client area
    glViewport( 0, 0, w, h );
    // set the matrix mode to project
    glMatrixMode( GL_PROJECTION );
    // load the identity matrix
    glLoadIdentity( );
    // create the viewing frustum
    gluPerspective( 45.0, (GLfloat) w / (GLfloat) h, 1.0, 300.0 );
    // set the matrix mode to modelview
    glMatrixMode( GL_MODELVIEW );
    // load the identity matrix
    glLoadIdentity( );
    // position the view point
    //gluLookAt( 0.0f, 0.0f, 10.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f );
    gluLookAt( 0.0f, 0.0f, 10.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f );
}




//-----------------------------------------------------------------------------
// Name: keyboardFunc( )
// Desc: key event
//-----------------------------------------------------------------------------
void keyboardFunc( unsigned char key, int x, int y )
{
    switch( key )
    {
        case 'q':
        exit(1);
        break;

        // key to play the narrative
        case 'n':    
        if (narrativekey == TRUE)
        {
            // make Chuck take input
            //declare stringstream for chuck compiling
            ss << "adc => Gain gadc => dac; 0.5 => gadc.gain; external Event myEvent; myEvent => now;";
            the_chuck->compileCode(ss.str(), "");
            the_chuck->compileFile("","");
            narrativekey = FALSE;
        }
        else 
        {
            the_chuck -> broadcastExternalEvent("myEvent");
            the_chuck->compileFile("Chuck_File", "");
            narrativekey = TRUE;
        }
        break;
    }
    
    glutPostRedisplay( );
}


//-----------------------------------------------------------------------------
// Name: idleFunc( )
// Desc: callback from GLUT
//-----------------------------------------------------------------------------
void idleFunc( )
{
    // render the scene
    glutPostRedisplay( );
}


//-----------------------------------------------------------------------------
// Name: map_log_spacing( )
// Desc: ...
//-----------------------------------------------------------------------------
inline double map_log_spacing( double ratio, double power )
{
    // compute location
    return ::pow(ratio, power) * g_fft_size/g_freq_view; 
}



//-----------------------------------------------------------------------------
// Name: compute_log_spacing( )
// Desc: ...
//-----------------------------------------------------------------------------
double compute_log_spacing( int fft_size, double power )
{
    int maxbin = g_fft_size; // for future in case we want to draw smaller range
    int minbin = 0; // what about adding this one?

    for(int i = 0; i < fft_size; i++)
    {
        // compute location
        g_log_positions[i] = map_log_spacing( (double)i/fft_size, power ); 
        // normalize, 1 if maxbin == fft_size
        g_log_positions[i] /= pow((double)maxbin/fft_size, power);
    }

    return 1/::log(fft_size);
}

// function that takes wavelength input and sets r,g,b colors
void spectral_color(double l) // RGB <- lambda l = < 380,780 > [nm]
{
         if (l<380.0) r=     0.00;
    else if (l<400.0) r=0.05-0.05*sin(MY_PIE*(l-366.0)/ 33.0);
    else if (l<435.0) r=     0.31*sin(MY_PIE*(l-395.0)/ 81.0);
    else if (l<460.0) r=     0.31*sin(MY_PIE*(l-412.0)/ 48.0);
    else if (l<540.0) r=     0.00;
    else if (l<590.0) r=     0.99*sin(MY_PIE*(l-540.0)/104.0);
    else if (l<670.0) r=     1.00*sin(MY_PIE*(l-507.0)/182.0);
    else if (l<730.0) r=0.32-0.32*sin(MY_PIE*(l-670.0)/128.0);
    else              r=     0.00;
         if (l<454.0) g=     0.00;
    else if (l<617.0) g=     0.78*sin(MY_PIE*(l-454.0)/163.0);
    else              g=     0.00;
         if (l<380.0) b=     0.00;
    else if (l<400.0) b=0.14-0.14*sin(MY_PIE*(l-364.0)/ 35.0);
    else if (l<445.0) b=     0.96*sin(MY_PIE*(l-395.0)/104.0);
    else if (l<510.0) b=     0.96*sin(MY_PIE*(l-377.0)/133.0);
    else              b=     0.00;
}




//-----------------------------------------------------------------------------
// Name: displayFunc( )
// Desc: callback function invoked to draw the client area
//-----------------------------------------------------------------------------
void displayFunc( )
{
    // local state
    static GLfloat zrot = 0.0f, c = 0.0f;
    // Added-by-Kunwoo
    SAMPLE * buffer = g_fft_buffer, * ptr;
    GLint i;
    GLfloat ytemp, fval, fval_time;

    // clear the color and depth buffers
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
    // line width
    glLineWidth( 1.0f );
    // define a starting point
    // soon to be used drawing offsets
    GLfloat x = -0.7f, inc = 3.6f / g_buffer_size, y = 2.0f;
    // increment
    GLfloat xinc = ::fabs(x*2 / g_bufferSize);
    

    // get the latest (possibly preview) window
    memset( buffer, 0, SND_FFT_SIZE * sizeof(SAMPLE) );

    // copy currently playing audio into buffer
    memcpy( buffer, g_buffer, g_buffer_size * sizeof(SAMPLE) );


    // apply hanning window
    hanning( g_window, g_buffer_size );
    apply_window( (float*)buffer, g_window, g_buffer_size );


    // draw the time domain waveform
    if( g_waveform )
    {
        // save the current matrix state
        glPushMatrix();
        // translate the waveform
        glTranslatef( 0, 0, 0.0f );
        glLineWidth(0.5f);

        // Draw line that holds the filament
        glBegin( GL_LINE_STRIP);
        spectral_color(410);
        glColor3f(r*2,g*2,b*2);
        glVertex3f(-0.7f, 0.0f, 0.0f);
        glVertex3f(-0.5f, -1.35f, -2.0f);
        glEnd();

        // Draw line that holds the filament
        glBegin( GL_LINE_STRIP);
        spectral_color(670);
        glColor3f(r*2,g*2,b*2);
        glVertex3f(0.7f, 0.0f, 0.0f);
        glVertex3f(0.5f, -1.35f, -2.0f);
        glEnd();


        // Lightbulb holder
        glBegin( GL_LINE_STRIP);
        for (int i = 0; i < 25; i++)
        {
            glColor4f(0.3, 0.3, 0.3, 1.01 - ((i+0.01f) / 25));
            glVertex3f(-0.5f, -1.38f - 0.05f * i, -2.0f - 0.2 * i);
            glVertex3f(0.5f, -1.38f - 0.05f * i, -2.0f - 0.2 * i);
        }
        
        glEnd();

        glLineWidth(1.0f);
        

        // If lightbulb is broken, change the lightbulb_constant to reconstruct lightbulb
        if (break_status == true)
            lightbulb_constant = (600 * 2 + 47) - break_counter * 2;

        
        // Lightbulb glass1
        glBegin( GL_LINE_STRIP);
        for (int i = 0; i < 40; i++)
        {  
            spectral_color(700 - ((i+1.0f)/40 * 300.0f));
            glColor4f(r*2,g*2,b*2, 1.0f * rand()/(RAND_MAX));
            float angle = 2 * MY_PIE * (i+0.001f) / (lightbulb_constant);
            glVertex2f(cos(angle-MY_PIE/3), 1.1*sin(angle-MY_PIE/3)+0.1);
        }
        glEnd();

        // Lightbulb glass1
        glBegin( GL_LINE_STRIP);
        for (int i = 0; i < 40; i++)
        {  
            spectral_color(700 - ((i+1.0f)/40 * 300.0f));
            glColor4f(r*2,g*2,b*2, 1.0f * rand()/(RAND_MAX));
            float angle = 2 * MY_PIE * (i+0.001f) / (lightbulb_constant);
            glVertex2f(cos(angle-MY_PIE/3) - 0.01, 1.1*sin(angle-MY_PIE/3)+0.075);
        }
        glEnd();
        
        // Lightbulb glass1
        glBegin( GL_LINE_STRIP);
        for (int i = 0; i < 40; i++)
        {  
            spectral_color(700 - ((i+1.0f)/40 * 300.0f));
            glColor4f(r*2,g*2,b*2, 1.0f * rand()/(RAND_MAX));
            float angle = 2 * MY_PIE * (i+0.001f) / (lightbulb_constant);
            glVertex2f(cos(angle-MY_PIE/3) + 0.01, 1.1*sin(angle-MY_PIE/3)+0.05);
        }
        glEnd();


        // Time Domain Signal Visualizer (aka the filament)
        glBegin( GL_LINE_STRIP );
        {
            // loop through samples
            for( i = 0; i < g_bufferSize; i++ )
            {
                if (i < g_bufferSize/2)
                glColor4f( 1.0f, 1.0f, 1.0f, 0.3f + 2 * ((i + 0.01f) / g_bufferSize) );
                else
                glColor4f( 1.0f, 1.0f, 1.0f, 1.3f - 2 *((i - g_bufferSize/2 + 0.01f) /g_bufferSize) );

                if (break_status)
                    glVertex2f( x, (64 - (break_counter)/5) * buffer[i]);
                else
                    glVertex2f( x , 4*buffer[i] );
                x += xinc;
            }
            glEnd();
        }
            // restore previous matrix state
        glPopMatrix();
    }

    //Reset Drawing Offsets
    x = -5.0f;

    // take forward FFT; result in buffer as FFT_SIZE/2 complex values
    rfft( (float *)buffer, g_fft_size/2, FFT_FORWARD );
    // cast to complex
    complex * cbuf = (complex *)buffer;

    // color
    glColor3f( .5, .5, 1 );
    // set vertex normals
    glNormal3f( 0.0f, 1.0f, 0.0f );


    // copy current magnitude spectrum into waterfall memory
    for( i = 0; i < g_fft_size/2; i++ )
    {
        // copy x coordinate
        g_spectrums[g_wf][i].x = x;
        // copy y, depending on scaling
        g_spectrums[g_wf][i].y = g_gain * g_freq_scale * 1.8f *
        ::pow( 20 * cmp_abs( cbuf[i] ), .5 ) + y;     
        // increment x
        x += inc + x;
    }

    // draw the right things
    g_draw[g_wf] = g_wutrfall;

    if( !g_starting )
        g_draw[(g_wf+g_wf_delay)%g_depth] = true;

    // reset drawing variables
    x = -5.0f; y =-4.0f;
    inc = 3.6f / g_fft_size;

    // save current matrix state
    glPushMatrix();
        // translate in world coordinate
    //glTranslatef( -5.5, -4, g_z );
    glTranslatef(0, 0, 5* g_z);
    glLineWidth(1.0f);

    for( i = 0; i < g_depth; i++ ) //means go over all g_depth lines
    {
        fval = (1.5*(g_depth - i) / (float)(g_depth));
        //glColor3f( 1.0 * fval, 1.0 * fval, 1.0 * fval );
        //float cval = 1 - (g_wf_delay - i) / (float)(g_wf_delay);
        //cval = 0.4f + cval * (1.0f - 0.4f);
        //glColor3f( 0.7f, cval, .4f);
        // set vertex normals
        glNormal3f( 0.0f, 1.0f, 0.0f );

        Pt2D * pt = g_spectrums[(g_wf+i)%g_depth];
        
        // Circle (Divide the frequency x-axis into circle_num number of circles)
        int circle_num = 30;
        float circle_piece = (g_fft_size/g_freq_view)/circle_num;

        // For each divided frequency x-axis, draw a circle and assign color
        for (GLint k = 0; k< circle_num; k++)
        {

            glBegin( GL_LINE_LOOP );

            for( GLint j = k * circle_piece; j < (k+1) * (g_fft_size/g_freq_view)/(circle_num); j++, pt++ )
            {
                float angle = (circle_num*2*MY_PIE*j)/(g_fft_size/g_freq_view);
                float radius = sqrt(pow(g_log_positions[j]/2048.0f, 2) + pow(g_spectrums[(g_wf+i)%g_depth][j].y, 2));
                // draw the vertex
                float d = g_backwards ? g_depth - (float) i : (float) i;

                //glColor3f( 1.0 * fval, 1.0 * fval, 1.0 * fval );
                spectral_color(400 + ((j+1.0f)/(g_fft_size/g_freq_view) * 300.0f));
                glColor4f(r*2 * fval, g*2 * fval, b*2 * fval, fader);

                // Make the signal not appear if it is quiet enough
                if (radius < 2.1)
                    glColor4f(0,0,0,0);
               
                // projection determines how fast the circles disperse from the lightbulb
                float projection ;
                if (break_status)
                    projection = 40;
                else
                    projection = 120 - (30 * radius/2.1);

                // in narrative mode, if the signal is greater than threshold, break the lightbulb
                if (narrativekey == TRUE)
                {
                    if (radius > 2.7  )
                    {
                    break_status = true;
                    break_counter = 0;
                    projection = 50;
                    }
                }
                // in realtime mode, if the signal is greater than threshold, break the lightbulb
                else
                {
                    if (radius > 8.00)
                    {
                    break_status = true;
                    break_counter = 0;
                    projection = 50;
                    }
                }
                
                // keep track of max amplitude
                if (radius > max_amp)
                {
                    max_amp = radius;
                    //cout << max_amp << endl;
                }

                // when the lightbulb is broken, skew the circle into random ellipses
                if (break_status == true)
                {
                    cos_skew = (rand()/(RAND_MAX+0.1f) + 1);
                    sin_skew = (rand()/(RAND_MAX+0.1f) + 1);
                    d = -i * break_counter/2;
                }

                // draw the entire fft spectrum that comes out of the lightbulb
                glVertex3f(cos_skew*radius/(pow(1.02, k)) * cos(-angle+MY_PIE/2) + (d/projection*cos(-angle+MY_PIE/2)), 
                    sin_skew*radius/(pow(1.02, k)) * sin(-angle+MY_PIE/2) + (d/projection*sin(-angle+MY_PIE/2)), 
                    -j/(g_fft_size/g_freq_view) + d/projection);
            }
            glEnd();
        }
        // back to default line width
        glLineWidth(1.0f);
    
    }
        // restore matrix state
    glPopMatrix();

    // check if the lightbulb is broken, and assign the right values
    if (break_status == true)
    {
        break_counter ++;
        fader = 1.5 - (break_counter+0.01f) * 1/600;
        
        // reset to normal mode if 600 non breakable signal cycles have passed
        if (break_counter > 600)
        {
            cos_skew = 1.0;
            sin_skew = 1.0;
            break_status = false;
            break_counter = 0;
            fader = 1.0;
        }
    }

        // wtrfll
        // advance index
        g_wf--;
        // mod
        g_wf = (g_wf + g_depth) % g_depth;


    //-------------------------------
    // end primitive
    glEnd();


    // flush!
    glFlush( );
    // swap the double buffer
    glutSwapBuffers( );
}
