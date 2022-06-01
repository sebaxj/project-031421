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
	3. Calculate the updated probability of oberving such a RMSDD given the prior (initially 0.5). TODO: How to calculate this and use this?
	4. Calculate the PDF of observed HRV (mu = 38.7, SD = 33.27)
	5. Send the raw HR and complement of bayesian probability of HRV observation and PDF calculation to ChucK
STOP

ChucK
START
1. For each note:
	2. The probability of a note actually being played is the complement of the PDF of the
	observed PDF.
	3. Choose the root.
		4. If HR is lower than 40 then HR is in C1 octave.
		5. If HR is between 40 and 55 then HR is in C3 octave.
		6. If HR is between 55 and 75 then HR is in C4 octave.
		7. If HR is between 75 and 90 then HR is in C5 octave.
		8. If HR is greater than 90 then HR is in C6 octave.
		9. The root is determined by the HRV tier table below.
```

`HRV Tiers (mu = 38.7, SD = 33.27) [https://onlinelibrary.wiley.com/doi/epdf/10.1111/j.1542-474X.2011.00417.x]`

| hrv range      |  I   |  ii  | iii  |  IV  |  V   |  vi  | vii  |
| :------------- | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| <11.1          | 0.08 | 0.28 | 0.2  | 0.08 | 0.1  | 0.1  | 0.16 |
| <27.6 && >11.1 | 0.15 | 0.2  | 0.18 | 0.1  | 0.1  | 0.1  | 0.17 |
| <38.7 && >27.6 | 0.18 | 0.1  | 0.15 | 0.1  | 0.27 | 0.12 | 0.08 |
| >38.7 && <49.8 | 0.2  | 0.1  | 0.15 | 0.05 | 0.2  | 0.18 | 0.12 |
| >49.8 && <55.3 | 0.3  | 0.08 | 0.1  | 0.1  | 0.22 | 0.1  | 0.1  |
| >55.3          | 0.32 | 0.1  | 0.05 | 0.19 | 0.2  | 0.1  | 0.04 |

```txt
			10. If the previous root is I, ii, iii, IV, or vi:
				11. The root is determined by the HRV tier table below.
```

| hrv range      |  I   |  ii  | iii  |  IV  |  V   |  vi  | vii  |
| :------------- | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| <11.1          | 0.08 | 0.28 | 0.2  | 0.08 | 0.1  | 0.1  | 0.16 |
| <27.6 && >11.1 | 0.15 | 0.2  | 0.18 | 0.1  | 0.1  | 0.1  | 0.17 |
| <38.7 && >27.6 | 0.18 | 0.1  | 0.15 | 0.1  | 0.27 | 0.12 | 0.08 |
| >38.7 && <49.8 | 0.2  | 0.1  | 0.15 | 0.05 | 0.2  | 0.18 | 0.12 |
| >49.8 && <55.3 | 0.3  | 0.08 | 0.1  | 0.1  | 0.22 | 0.1  | 0.1  |
| >55.3          | 0.32 | 0.1  | 0.05 | 0.19 | 0.2  | 0.1  | 0.04 |

```txt
			12. If the previous root is V or vii:
				13. The root is determined from the following PMF:
```

| hrv range      |  I   |  ii  | iii  |  IV  |  V   |  vi  | vii  |
| :------------- | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| <11.1          | 0.10 | 0.00 | 0.00 | 0.00 | 0.20 | 0.50 | 0.20 |
| <27.6 && >11.1 | 0.30 | 0.00 | 0.00 | 0.00 | 0.10 | 0.40 | 0.20 |
| <38.7 && >27.6 | 0.20 | 0.00 | 0.00 | 0.00 | 0.30 | 0.40 | 0.10 |
| >38.7 && <49.8 | 0.30 | 0.00 | 0.00 | 0.00 | 0.40 | 0.20 | 0.10 |
| >49.8 && <55.3 | 0.30 | 0.00 | 0.00 | 0.00 | 0.50 | 0.10 | 0.10 |
| >55.3          | 0.40 | 0.00 | 0.00 | 0.00 | 0.50 | 0.00 | 0.00 |

```txt
	14. Choose the depth of notes to be played.
		15. If HRV is 27.6 or less:
			16. If the root is vii, then the notes come from a diminished chord.
				Array of MIDI note intervals above a root, chosen from randomly: [0, 3, 6, 12, -6, 15]
			17. Else, the notes from from a minor chord.
				Array of MIDI note intervals above a root, chosen from randomly: [0, 3, 7, 12, -5, 15]
		18. Else:
			19. If the root is vii, then the notes come from a diminished chord.
				Array of MIDI note intervals above a root, chosen from randomly: [0, 3, 6, 12, -6, 15]
			20. Else, if the root is ii, iii, vi, then the notes come from a minor chord.
				Array of MIDI note intervals above a root, chosen from randomly: [0, 3, 7, 12, -5, 15]
			21. Else, the notes come from a major chord.
				Array of MIDI note intervals above a root, chosen from randomly: [0, 4, 7, 12, -5, 16]
	22. Play the array of notes
	23. Wait the duration between notes as calculated by HR.
		24. HR / 60 bpm is the time in seconds between notes.
STOP
```

## TODO:

1. Refine compositional algoritm:
    - Add chords to fill out texture
