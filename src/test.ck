SinOsc s => dac;
1 => s.gain;
440 => s.freq;

while(true) 10::ms => now; 
