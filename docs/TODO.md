# TODO

_last updated: 5/15/22_

## Preamble

This project has reached a crossroads. Initially, I had proposed using
`C++` to build a biosignal sonification tool which utilized `ChucK` and
compiled down to an executable which may be employed on a microcomputer.
This was done with the interest in algorithm speed, versitility, and a
cross-platform approach in mind. However, due to the lack of adequete
libraries for processing and analysis of electrocardiogram (ECG) in `C++`
and the ease of ECG proccessing, analysis, and annotation in `Python`,
this project will now need to move to a repository based off `Python`.
After sufficient development in `Python`, it will be possible to export
the sonification algorithm to `C++`, but `Python` used for initial development.

## The new architecture of this project will be as follows:

```txt
|--> Python 3
|----> heartpy
|----> matplotlib
|----> scipy (to calculate statistical distributions)
|
|--> ChucK
```

## Compositional Algorithm

```txt
Algorithm 1: Bayesian Approach
Python:
START
1. Calculate the RMSDD and HR of heart data in 10 second segments.
2. For each segment:
	3. Calculate the updated probability of oberving such a RMSDD given the prior (initially 0.5).
	4. Calculate the PDF of observed HRV (mu = 38.7, SD = 33.27)
	4. Send the raw HR and complement of bayesian probability of HRV observation and PDF calculation to ChucK
STOP

ChucK
START
1. For each note:
	2. Choose the root.
		3. If HR is lower than 40 then HR is in C1 octave.
		4. If HR is between 40 and 55 then HR is in C3 octave.
		5. If HR is between 55 and 75 then HR is in C4 octave.
		6. If HR is between 75 and 90 then HR is in C5 octave.
		7. If HR is greater than 90 then HR is in C6 octave.
		8. PDF of HRV determines probability of I/IV/V/vi,
		the complement determines probability of ii/iii/vii
	9. Choose the depth of notes to be played.
		5. If HR is ...
		6. If HRV is ...
	10. Play the array of notes
	11. Wait the duration between notes as calculated by HR.
		12. HR / 60 bpm is the time in seconds between notes.
STOP

HRV Tiers (mu = 38.7, SD = 33.27) [https://onlinelibrary.wiley.com/doi/epdf/10.1111/j.1542-474X.2011.00417.x]
--------------------------------------------------------------------------
|  HRV range	|	I  |  ii  |  iii  |   IV  |   V |   vi |   vii |  I  |
--------------------------------------------------------------------------
|27.61 - 49.79  |	   |      |       |       |     |      |       |     |
|		 	    |	   |      |       |       |     |      |       |     |
|		 	    |	   |      |       |       |     |      |       |     |
|		 	    |	   |      |       |       |     |      |       |     |
|		 	    |	   |      |       |       |     |      |       |	 |
|		 	    |	   |      |       |       |     |      |       |	 |

```

## TODO:

1. Initiate Pyenv environment for this project:
    - Python 3
    - heartpy
    - matplotlib
    - numpy
    - scipy
2. Create a pipeline for reading ECG data:  
   i. First, create a script for plotting ECG data and analyzing peaks (QRS complex).  
   ii. Second, turn the script into a realtime process for reading and analyzing ECG data.
3. Develop an algorithm for calcualting HRV and abstracting health markers from a running  
   average of HRV.
4. Connect Python and ChucK via an OSC server.
