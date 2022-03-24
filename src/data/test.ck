// adc => Gain g => dac;
// .5 => g.gain;

SinOsc s => dac;
.25 => s.gain;
440 => s.freq;

while( true ) {
    <<< now >>>;
    200::ms => now; 
}
