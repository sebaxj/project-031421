# TODO

_last updated: 6/1/22_

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
	Or, calculate the shannon entropy and apply that value to the probability that a chord is played.
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
		9. The root is determined by the conditions below:
```

`HRV Tiers (mu = 38.7, SD = 33.27) [https://onlinelibrary.wiley.com/doi/epdf/10.1111/j.1542-474X.2011.00417.x]`

```txt
			10. If the previous root is I:
				11. The root is determined by the HRV tier table below.
```

| hrv range       |  I   |  ii  | iii  |  IV  |  V   |  vi  | vii  |
| :-------------- | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| <16.5           | 0.00 | 0.00 | 0.02 | 0.00 | 0.08 | 0.10 | 0.80 |
| <22.1 && >=16.5 | 0.10 | 0.10 | 0.05 | 0.05 | 0.30 | 0.10 | 0.30 |
| <27.6 && >=22.1 | 0.20 | 0.10 | 0.18 | 0.10 | 0.30 | 0.02 | 0.10 |
| <38.7 && >=27.6 | 0.15 | 0.14 | 0.14 | 0.14 | 0.15 | 0.14 | 0.14 |
| <49.8 && >=38.7 | 0.20 | 0.10 | 0.08 | 0.12 | 0.30 | 0.10 | 0.10 |
| <55.5 && >=49.8 | 0.40 | 0.10 | 0.00 | 0.10 | 0.08 | 0.30 | 0.02 |
| >=55.5          | 0.30 | 0.00 | 0.00 | 0.30 | 0.30 | 0.10 | 0.00 |

```txt
			11. If the previous root is ii, iii, IV, or vi:
				12. The root is determined by the HRV tier table below.
```

| hrv range       |  I   |  ii  | iii  |  IV  |  V   |  vi  | vii  |
| :-------------- | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| <16.5           | 0.00 | 0.20 | 0.30 | 0.08 | 0.02 | 0.10 | 0.30 |
| <22.1 && >=16.5 | 0.00 | 0.30 | 0.30 | 0.00 | 0.05 | 0.05 | 0.30 |
| <27.6 && >=22.1 | 0.10 | 0.30 | 0.08 | 0.05 | 0.12 | 0.05 | 0.30 |
| <38.7 && >=27.6 | 0.10 | 0.04 | 0.00 | 0.05 | 0.26 | 0.30 | 0.25 |
| <49.8 && >=38.7 | 0.10 | 0.16 | 0.04 | 0.15 | 0.30 | 0.15 | 0.10 |
| <55.5 && >=49.8 | 0.10 | 0.05 | 0.00 | 0.10 | 0.40 | 0.15 | 0.20 |
| >=55.5          | 0.00 | 0.10 | 0.00 | 0.00 | 0.60 | 0.00 | 0.30 |

```txt
			13. If the previous root is V or vii:
				14. The root is determined from the following PMF:
```

| hrv range       |  I   |  ii  | iii  |  IV  |  V   |  vi  | vii  |
| :-------------- | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| <16.5           | 0.00 | 0.10 | 0.30 | 0.10 | 0.02 | 0.40 | 0.08 |
| <22.1 && >=16.5 | 0.00 | 0.20 | 0.30 | 0.10 | 0.02 | 0.30 | 0.08 |
| <27.6 && >=22.1 | 0.20 | 0.20 | 0.00 | 0.08 | 0.10 | 0.30 | 0.12 |
| <38.7 && >=27.6 | 0.30 | 0.10 | 0.00 | 0.00 | 0.20 | 0.20 | 0.20 |
| <49.8 && >=38.7 | 0.45 | 0.05 | 0.00 | 0.12 | 0.25 | 0.05 | 0.08 |
| <55.5 && >=49.8 | 0.50 | 0.00 | 0.00 | 0.05 | 0.30 | 0.05 | 0.10 |
| >=55.5          | 0.70 | 0.00 | 0.00 | 0.00 | 0.25 | 0.05 | 0.00 |

```txt
	15. Choose the depth of notes to be played.
		16. If HRV is 27.6 or less:
			17. If the root is vii, then the notes come from a diminished chord.
				Array of MIDI note intervals above a root, chosen from randomly: [0, 3, 6, 12, -6, 15]
			18. Else, the notes from from a minor chord.
				Array of MIDI note intervals above a root, chosen from randomly: [0, 3, 7, 12, -5, 15]
		19. Else:
			20. If the root is vii, then the notes come from a diminished chord.
				Array of MIDI note intervals above a root, chosen from randomly: [0, 3, 6, 12, -6, 15]
			21. Else, if the root is ii, iii, vi, then the notes come from a minor chord.
				Array of MIDI note intervals above a root, chosen from randomly: [0, 3, 7, 12, -5, 15]
			22. Else, the notes come from a major chord.
				Array of MIDI note intervals above a root, chosen from randomly: [0, 4, 7, 12, -5, 16]
	23. Play the array of notes
	24. Wait the duration between notes as calculated by HR.
		25. HR / 60 bpm is the time in seconds between notes.
STOP
```

## TODO:

1. Refine `baseline()` function.
2. Add more heart data.
3. Clean up code.
4. Write final writeup.
5. Embed python in C++ code.
