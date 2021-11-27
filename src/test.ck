// sine oscillator as drone for A(69) and C#(73)
SinOsc a => JCRev r1 => dac;
SinOsc c => r1 => dac;

// "a" frequency to 440 Hz
Std.mtof(69) => a.freq;
Std.mtof(73) => c.freq;

// SinOsc amplitude
.04 => a.gain;
.02 => c.gain;

// set mix of reverb to original signal
.7 => r1.mix;

// arrray to store connosance values
[0, 2, 4, 7, 9, 11] @=> int arr[];

// impulse UGen to generate string "plucks"
Impulse imp => Delay str1 => dac;
str1 => str1;

0.98 => str1.gain;

// infinite loop to execute plucks
while(true)
{
        Std.mtof(57 + Math.random2(0,3) * 12 +
        arr[Math.random2(0,arr.size()-1)])::samp => str1.delay;
        1.0 => imp.next;
        0.5::second => now;
}
