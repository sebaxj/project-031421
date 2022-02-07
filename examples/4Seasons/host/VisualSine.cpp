//-----------------------------------------------------------------------------
// name: 4Seasons-Elena.cpp
// desc: 256a first milestone of a visualizer.
//
// author: Elena Georgieva
// date: fall 2018
// thanks to Ge Wang, Jack Atherton, Kunwoo Kim.
//-----------------------------------------------------------------------------


#include "RtAudio/RtAudio.h"
#include "chuck.h"
#include <math.h>
#include <stdlib.h>
#include <iostream>
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

// complex type
typedef struct { float re ; float im ; } complex;

// complex absolute value
#define cmp_abs(x) ( sqrt( (x).re * (x).re + (x).im * (x).im ) )

#include "../core/util_xforms.h"


//-----------------------------------------------------------------------------
// function prototypes
//-----------------------------------------------------------------------------
void initGfx();
void idleFunc();
void displayFunc();
void reshapeFunc( GLsizei width, GLsizei height );
void keyboardFunc( unsigned char, int, int );
void mouseFunc( int button, int state, int x, int y );
double compute_log_spacing( int fft_size, double factor );

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
const t_CKINT CHUCK_MY_CHANNELS = 2;

// global frequency (used for Chuck Sine Wave Testing)
float freq = 440;
int SEASON = 0;

//from soudnbulb example
//////////////////////////////
//Making ellipse
float cos_skew=1.0f;
float sin_skew=1.0f;
float fader = 1.0f;
float lightbulb_constant = 47.0f;

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

// width and height
long g_width = 1024;
long g_height = 720;
// global buffer
SAMPLE * g_buffer = NULL;
long g_bufferSize;

// global variables
bool g_draw_dB = false;
ChucK * the_chuck = NULL;

// stringstream for compiling chuck code
stringstream ss;
//-----------------------------------------------------------------------------
// name: help()
// desc: instructions printed in terminal
//-----------------------------------------------------------------------------
void help()
{
    fprintf( stderr, "----------------------------------------------------\n" );
    fprintf( stderr, "4Seasons\n");
    fprintf( stderr, "Use 'w' to see Winter\n");
    fprintf( stderr, "Use 's' to see Spring\n");
    fprintf( stderr, "Use 'u' to see Summer\n");
    fprintf( stderr, "Use 'f' to see Fall\n\n");
    fprintf( stderr, "'q' to quit. Enjoy!!\n");
}


//-----------------------------------------------------------------------------
// name: callme()
// desc: audio callback
//copies left channel into gbuffer, modify to get chuck sound to work
//-----------------------------------------------------------------------------
int callme( void * outputBuffer, void * inputBuffer, unsigned int numFrames,
            double streamTime, RtAudioStreamStatus status, void * data )
{
    // cast!
    SAMPLE * input = (SAMPLE *)inputBuffer;
    SAMPLE * output = (SAMPLE *)outputBuffer;
    
    // compute chuck! Audio callback
    the_chuck -> run(input, output, numFrames);

    
    // fill
    for( int i = 0; i < numFrames; i++ )
    {
        // copy the input to visualize only the left-most channel
        //g_buffer[i] = input[i*MY_CHANNELS];
        
        // also copy in the output from chuck to our visualizer
        g_buffer[i] = output[i*MY_CHANNELS];

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
    //print usage
    help();
    
    // AUDIO AND VIDEO PREPARATION
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
    
    // initialize GLUT
    glutInit( &argc, argv );
    // init gfx
    initGfx();
    
    
    // SET AUDIO PARAMS
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
    
    // SET BUFFER
    // compute
    bufferBytes = bufferFrames * MY_CHANNELS * sizeof(SAMPLE);
    // allocate global buffer
    g_bufferSize = bufferFrames;
    g_buffer = new SAMPLE[g_bufferSize];
    memset( g_buffer, 0, sizeof(SAMPLE)*g_bufferSize );
    
    
    /// INITIALIZE CHUCK AND COMPILE CHUCK CODE HERE
    // set up chuck
    the_chuck = new ChucK();
    the_chuck->setParam(CHUCK_PARAM_SAMPLE_RATE, CHUCK_MY_SRATE);
    the_chuck->setParam(CHUCK_PARAM_OUTPUT_CHANNELS, CHUCK_MY_CHANNELS);
    the_chuck->setParam(CHUCK_PARAM_INPUT_CHANNELS, CHUCK_MY_CHANNELS);
    the_chuck->init();
    //ss << "adc => dac; while(true) 1::second => now;";
    //the_chuck->compileCode(ss.str(), "");
    the_chuck->compileFile("narrative.ck","");
    
    
    //START STREAMING
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
    // double buffer, use rgb color, enable depth buffer
    glutInitDisplayMode( GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH );
    // initialize the window size
    glutInitWindowSize( g_width, g_height );
    // set the window postion
    glutInitWindowPosition( 100, 100 );
    // create the window
    glutCreateWindow( "4Seasons-Elena" );
    
    // Taken from SoundBulb Example ///////////////
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable( GL_BLEND ); glClearColor(0.0,0.0,0.0,0.0);
    
    
    //------CALL FUNCTIONS TO PREP FOR CHANGES-----------
    // set the idle function - called when idle
    glutIdleFunc( idleFunc );
    // set the display function - called when redrawing
    glutDisplayFunc( displayFunc );
    // set the reshape function - called when client area changes
    glutReshapeFunc( reshapeFunc );
    // set the keyboard function - called on keyboard events
    glutKeyboardFunc( keyboardFunc );
    // set the mouse function - called on mouse stuff
    glutMouseFunc( mouseFunc );
    
    // set clear color
    glClearColor( 0, 0, 0, 1 );
    // enable color material
    glEnable( GL_COLOR_MATERIAL );
    // enable depth test
    glEnable( GL_DEPTH_TEST );
    
    // From SoundBulb Example///////////////////
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
        case 'w': //What season is it? 'w' for winter
            SEASON = 0;
            break;
        case 's': //'s' for Spring
            SEASON = 1;
            break;
        case 'u': //'u' for Summer
            SEASON = 2;
            break;
        case 'f': //'f' for Fall
            SEASON = 3;
            break;
        case 'Q':
        case 'q': //'q' to quit
            exit(1);
            break;
            
        case 'd':
            g_draw_dB = !g_draw_dB;
            break;
    }
    
    glutPostRedisplay( );
}

//-----------------------------------------------------------------------------
// Name: idleFunc( ) Taken form SoundBulb Example
// Desc: callback from GLUT
//-----------------------------------------------------------------------------
void idleFunc( )
{
    // render the scene
    glutPostRedisplay( );
}


//-----------------------------------------------------------------------------
// Name: map_log_spacing( ) Taken from SoundBulb Example
// Desc: ...
//-----------------------------------------------------------------------------
inline double map_log_spacing( double ratio, double power )
{
    // compute location
    return ::pow(ratio, power) * g_fft_size/g_freq_view;
}



//-----------------------------------------------------------------------------
// Name: compute_log_spacing( ) Taken from SoundBulb Example
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

// function that takes wavelength input and sets r,g,b colors WINTER TONES
void spectral_color_winter(double l) // RGB <- lambda l = < 380,780 > [nm]
{
    if (l<400.0){ r=.839; g=.999; b=.984;}
    else if (l<480){ r=.701; g=.890; b=.956;}
    else if (l<560){ r= .705; g=.705; b=.999;}//lav
    else if (l<630){ r= .168; g=.196; b=.560;}
    else  {r=.137; g=.027; b=.270;} //dark
}

// function that takes wavelength input and sets r,g,b colors SPRING TONES
void spectral_color_spring(double l) // RGB <- lambda l = < 380,780 > [nm]
{
    if (l<380.0){ r=.964; g=.725; b=.678;}
    else if (l<460){ r=.933; g=.435; b=.407;}
    else if (l<520){ r=.964; g=.560; b=.235;}
    else if (l<580){ r= .776; g=.843; b=.725;} //mint
    else  {r=.368; g=.552; b=.352;} //dk grn
}

// function that takes wavelength input and sets r,g,b colors SUMMER TONES
void spectral_color_summer(double l) // RGB <- lambda l = < 380,780 > [nm]
{
    if (l<400.0){ r= .999; g=.349; b=.560;}
    else if (l<480){ r=.992; g=.541; b=.368;}
    else if (l<560){ r=.878; g=.890; b=.0001;}
    else if (l<630){ r=.003; g=.866; b=.866;}
    else  {r=.0001; g=.749; b=.352;}
}


void spectral_color_fall(double l) // RGB <- lambda l = < 380,780 > [nm] FALL TONES
{
    if (l<380.0){ r=.831; g=.521; b=.109;} //most dull orange
    else if (l<480){ r= .999; g=.407; b=.015;}
    else if (l<560){ r=.847; g=.188; b=.0001;}
    else if (l<620){ r=.682; g=.439; b=.039;}
    else  {r=.639; g=.164; b=.164;} //brightest
}



//-----------------------------------------------------------------------------
// Name: mouseFunc( )
// Desc: handles mouse stuff
//-----------------------------------------------------------------------------
void mouseFunc( int button, int state, int x, int y )
{
    if( button == GLUT_LEFT_BUTTON )
    {
        // when left mouse button is down
        if( state == GLUT_DOWN )
        {
        }
        else
        {
        }
    }
    else if ( button == GLUT_RIGHT_BUTTON )
    {
        // when right mouse button down
        if( state == GLUT_DOWN )
        {
        }
        else
        {
        }
    }
    else
    {
    }
    
    glutPostRedisplay( );
}


//-----------------------------------------------------------------------------
// Name: displayFunc( )
// Desc: callback function invoked to draw the client area
//-----------------------------------------------------------------------------
void displayFunc( )
{
    // local state
    static GLfloat zrot = 0.0f, c = 0.0f;
    
    // from SoundBulb example
    SAMPLE * buffer = g_fft_buffer, * ptr;
    GLint i;
    GLfloat ytemp, fval, fval_time;
    
    // clear the color and depth buffers
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
    // line width
    glLineWidth( 1.0 );
    // define a starting point, Replaced w this, taken from SoundBulb
    GLfloat x = -5.0f, inc = 3.6f / g_buffer_size, y = 2.0f; //x is lenght across
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
        glTranslatef(0, -3.5, 0.0f ); //second value is height of where its drawn
        glLineWidth(0.5f);
        glEnd();
        glLineWidth(4.0f); //line fatness
        
        // Time Domain Signal Visualizer (aka the filament)
        glBegin( GL_LINE_STRIP );
        {
            // loop through samples
            for( i = 0; i < g_bufferSize; i++ )
            {
                //color of freq domain spectrum
                if (i < g_bufferSize/2)
                    glColor4f( .999, .999, .999, 0.3f + 2 * ((i + 0.01f) / g_bufferSize) );
                else
                    glColor4f( .999, .999, .999, 1.3f - 2 *((i - g_bufferSize/2 + 0.01f) /g_bufferSize) );
                glVertex2f( x , .5*buffer[i] ); //height of amplitude?
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
    
    g_draw[g_wf] = g_wutrfall;
    if( !g_starting )
        g_draw[(g_wf+g_wf_delay)%g_depth] = true;
    
    // reset drawing variables
    x = -5.0f; y =-4.0f;
    inc = 3.6f / g_fft_size;
    
    // save current matrix state
    glPushMatrix();
    glTranslatef(0, 1, 1* g_z); //0 0 5
    glLineWidth(1.0f);
    
    // loop through each layer of waterfall
    for( i = 0; i < g_depth; i++ ) //means go over all g_depth lines
    {
        fval = (1.5*(g_depth - i) / (float)(g_depth));
        // set vertex normals
        glNormal3f( 0.0f, 1.0f, 0.0f );
        
        Pt2D * pt = g_spectrums[(g_wf+i)%g_depth];
        
        int circle_num = 200; //number of dots, decrease this if the computer can't handle it
        float circle_piece = (g_fft_size/g_freq_view)/circle_num;
        
        for (GLint k = 0; k< circle_num; k++)
        {
            glBegin( GL_POINTS ); // Points to make it look cool
            
            for( GLint j = k * circle_piece; j < (k+1) * (g_fft_size/g_freq_view)/(circle_num); j++, pt++ )
            {
                float angle = (circle_num*2*MY_PIE*j)/(g_fft_size/g_freq_view);
                //angle = angle/12;
                float radius = sqrt(pow(g_log_positions[j]/2048.0f, 2) + pow(g_spectrums[(g_wf+i)%g_depth][j].y, 2));
                //radius = radius*4;
                // draw the vertex
                float d = g_backwards ? g_depth - (float) i : (float) i;
                //which season is it?
                if (SEASON == 0)
                    spectral_color_winter(400 + ((j+1.0f)/(g_fft_size/g_freq_view) * 300.0f));
                else if (SEASON == 1)
                    spectral_color_spring(400 + ((j+1.0f)/(g_fft_size/g_freq_view) * 300.0f));
                else if (SEASON == 2)
                    spectral_color_summer(400 + ((j+1.0f)/(g_fft_size/g_freq_view) * 300.0f));
                else
                    spectral_color_fall(400 + ((j+1.0f)/(g_fft_size/g_freq_view) * 300.0f));

                glColor4f(r, g, b, fader);

                // Does not appear if it is quiet enough
                if (radius < 2.1)
                    glColor4f(0,0,0,0);
                
                // how fast the circles disperse from the lightbulb
                float projection ;
                    projection = 120 - (30 * radius/2.1)-50;
                
                
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
    
    
    // wtrfll
    // advance index
    g_wf--;
    // mod
    g_wf = (g_wf + g_depth) % g_depth;

    
    // end primitive
    glEnd();

    // flush!
    glFlush( );
    // swap the double buffer
    glutSwapBuffers( );
}
