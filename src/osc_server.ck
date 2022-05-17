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
oin.addAddress( "/bpm/hrv/br, f f f" );

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
		float br;

        // fetch the first data element as float
        msg.getFloat(0) => bpm;
        // fetch the second data element as float
        msg.getFloat(1) => hrv;
        // fetch the third data element as float
        msg.getFloat(2) => br;

        // print
        <<< "got (via OSC):", "[BPM]:", bpm, "[HRV]:", hrv, "[BR]:", br >>>;
    }
}
