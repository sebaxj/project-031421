# Final Report: Spring 2022 Quarter Report

_author: Sebastian James_  
_06/02/2022_

## I. OVERVIEW

This report details the completion of my senior capstone project as described
in [SDD v1.0a](./SDD_v1.0a.pdf).

## II. PROGRESS SINCE WINTER 2022 QUARTER REPORT

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
In [Winter 2022 Quarter Report](./WIN2022-REPORT.pdf) I detailed a plan to
transition from the amplitude analysis program written in Winter Quarter,
to an algorithm incorporating heart rate variability (HRV), live data
aquisition, pulse oximetrey, and blood pressure readings. However, after
spending sufficient time on ECG HRV analysis, I deecided to approach this project
with depth in heart data as opposed to breadth accross numerous biosignal parameters.
In addition to analyzing raw ECG data to calculate HRV and heart rate (HR), I used probability and
statistics to add additional measures of heart health. Using information theory
and Shannon Entropy, I calculated the information content of an observed HRV value
relative to a mean to measure how _suprising_ observed HRV values are.
Since the milestones summarized in [Winter 2022 Quarter Report](./WIN2022-REPORT.pdf),
I have accomplished the following:

1. Development of ECG processing and analysis software using `Python`.
2. Development of an electrocardiogram (ECG) sonification algorithm utilizing
   hear rate, heart rate variability, statistics, and information theory to represent
   ECG data in a musical paradigm.

## III. METHODS

In this section, I will detail the methods used in the final iteration of my
senior capstone project.

#### i. ECG Data Analysis in `Python`

The architecture of the ECG analysis pipeline in Python is as follows:

```txt
|--> Python 3
|----> heartpy: library to extract measures of HRV (RMSSD) and HR
|----> matplotlib: to plot ECG data and check HRV and HR analysis
|----> scipy: to calculate statistical distributions
|----> numpy: to randomly calculate the root note from a probability mass function
|----> pythonosc: open sound control (OSC) library to implement and OSC client in python to communicate with ChucK
```

`ecg_hrv.py` handles ECG data analysis and communication with `ChucK`. ECG data is read from a `.csv` file containing
amplitudes over a designated sampling rate in Hz (samples per second). The `readECG()` function wraps a `heartpy`
function to extract amplitudes from a `.csv` file and imports them into an array which can then be further acted upon.
This raw data can be plotted to check for noise or artifacts before analyzing for HRV and HR. The ECG data is then
passed to `proceessBySegment()` which analyzes the the raw ECG data for measures of HR and HRV. This is done by first
calculating the R peak, the maximum electical voltage which appears in the QRS complex on an ECG and refers to
depolarization of the right and left ventricles of the heart and contraction of the large ventricular muscles (see [QRS Complex](https://en.wikipedia.org/wiki/QRS_complex)).

To identify heartbeats, a moving average is calculated using a window of 0.75 seconds on both sides of each data point.
The first and last 0.75 seconds of the signal are populated with the signal’s mean, no moving average is generated
for these sections. Regions of interest (ROI) are marked between two points of intersection where the signal
amplitude is larger than the moving average. This is much like the [_Pan-Tomkins Algorithm_](https://en.wikipedia.org/wiki/Pan%E2%80%93Tompkins_algorithm).

Once heartbeat peaks have been identified, HR, in beats per minute (bpm), can be calculated with the following equation

$$ HR(bpm) = \frac{60}{RR(s)} $$

where one minute (60 seconds) is divided by the time between two consecutive R peaks ($RR$) in seconds.

HRV is calculated as a measure of the root mean square of successive differences (RMSSD) which is the square root of the
mean time between R peaks ($RR_n$). RMSSD is calculated using the following equation

$$ RMSSD = \sqrt{\frac{1}{n - 2} \sum\_{i =0}^{n - 2} (RR\_{i} - RR\_{i + 1})^{2}} $$

where $n = $ the number of R-peaks used in analysis.

#### ii. Sonification in ChucK

```txt
|--> ChucK
|----> oscServ(): OSC server
|----> sonify(): ECG data sonification algorithm
|----> cal_HR_octave(): calculate octave of notes to be played as a function of HR
|----> Synth [CLASS]: Synthesizer instrument class
|----> baseline(): construct a melody from random chance as a baseline to compare the sonfication to
```

#### iii. Compositional Algorithm

Detailed here is the algorithm I developed for ECG biosignal sonification using HRV, HR, and
Shannon Entropy.

```txt
Note, that values used for HRV or HR cutoffs of tiers are arbitrarily chosen by preference and experience.

Python:
START
1. Calculate the RMSDD and HR of heart data in 10 second segments.
2. For each segment:
	3. Calculate the shannon entropy using the PDF of the observed HRV (mu = 38.7, SD = 33.27) and apply that value to the probability that a chord is played.
	4. Calculate the CDF of observed HRV (mu = 38.7, SD = 33.27)
	5. The root is determined by the conditions below:
```

`HRV Tiers (mu = 38.7, SD = 33.27) [https://onlinelibrary.wiley.com/doi/epdf/10.1111/j.1542-474X.2011.00417.x]`

```txt
		6. If the previous root is I (the default is I):
			7. The root is determined by the HRV PDF table below.
```

| HRV Range       |  I   |  ii  | iii  |  IV  |  V   |  vi  | vii  |
| :-------------- | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| <16.5           | 0.00 | 0.00 | 0.02 | 0.00 | 0.08 | 0.10 | 0.80 |
| <22.1 && >=16.5 | 0.10 | 0.10 | 0.05 | 0.05 | 0.30 | 0.10 | 0.30 |
| <27.6 && >=22.1 | 0.20 | 0.10 | 0.18 | 0.10 | 0.30 | 0.02 | 0.10 |
| <38.7 && >=27.6 | 0.15 | 0.14 | 0.14 | 0.14 | 0.15 | 0.14 | 0.14 |
| <49.8 && >=38.7 | 0.20 | 0.10 | 0.08 | 0.12 | 0.30 | 0.10 | 0.10 |
| <55.5 && >=49.8 | 0.40 | 0.10 | 0.00 | 0.10 | 0.08 | 0.30 | 0.02 |
| >=55.5          | 0.30 | 0.00 | 0.00 | 0.30 | 0.30 | 0.10 | 0.00 |

```txt
		8. If the previous root is ii, iii, IV, or vi:
			9. The root is determined by the HRV PDF table below.
```

| HRV Range       |  I   |  ii  | iii  |  IV  |  V   |  vi  | vii  |
| :-------------- | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| <16.5           | 0.00 | 0.20 | 0.30 | 0.08 | 0.02 | 0.10 | 0.30 |
| <22.1 && >=16.5 | 0.00 | 0.30 | 0.30 | 0.00 | 0.05 | 0.05 | 0.30 |
| <27.6 && >=22.1 | 0.10 | 0.30 | 0.08 | 0.05 | 0.12 | 0.05 | 0.30 |
| <38.7 && >=27.6 | 0.10 | 0.04 | 0.00 | 0.05 | 0.26 | 0.30 | 0.25 |
| <49.8 && >=38.7 | 0.10 | 0.16 | 0.04 | 0.15 | 0.30 | 0.15 | 0.10 |
| <55.5 && >=49.8 | 0.10 | 0.05 | 0.00 | 0.10 | 0.40 | 0.15 | 0.20 |
| >=55.5          | 0.00 | 0.10 | 0.00 | 0.00 | 0.60 | 0.00 | 0.30 |

```txt
		10. If the previous root is V or vii:
			11. The root is determined by the HRV PDF table below:
```

| HRV Range       |  I   |  ii  | iii  |  IV  |  V   |  vi  | vii  |
| :-------------- | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| <16.5           | 0.00 | 0.10 | 0.30 | 0.10 | 0.02 | 0.40 | 0.08 |
| <22.1 && >=16.5 | 0.00 | 0.20 | 0.30 | 0.10 | 0.02 | 0.30 | 0.08 |
| <27.6 && >=22.1 | 0.20 | 0.20 | 0.00 | 0.08 | 0.10 | 0.30 | 0.12 |
| <38.7 && >=27.6 | 0.30 | 0.10 | 0.00 | 0.00 | 0.20 | 0.20 | 0.20 |
| <49.8 && >=38.7 | 0.45 | 0.05 | 0.00 | 0.12 | 0.25 | 0.05 | 0.08 |
| <55.5 && >=49.8 | 0.50 | 0.00 | 0.00 | 0.05 | 0.30 | 0.05 | 0.10 |
| >=55.5          | 0.70 | 0.00 | 0.00 | 0.00 | 0.25 | 0.05 | 0.00 |

```txt
	12. Send the raw HR, raw HRV, CDF of HRV, root, and entropy calculation to ChucK
STOP

ChucK
START
1. For each note:
	2. The probability of a note actually being played is the CDF of the
	observed CDF.
	3. Choose the octave of the root.
		4. If HR is lower than 40 then HR is in C2 octave.
		5. If HR is between 40 and 55 then HR is in C3 octave.
		6. If HR is between 55 and 75 then HR is in C4 octave.
		7. If HR is between 75 and 90 then HR is in C5 octave.
		8. If HR is greater than 90 then HR is in C6 octave.
	9. Choose the depth of notes to be played.
		10. If HRV is 27.6 or less:
			11. If the root is vii, then the notes come from a diminished chord.
				Array of MIDI note intervals above a root, chosen from randomly: [0, 3, 6, 12, -6, 15]
			12. Else, the notes from from a minor chord.
				Array of MIDI note intervals above a root, chosen from randomly: [0, 3, 7, 12, -5, 15]
		13. Else:
			14. If the root is vii, then the notes come from a diminished chord.
				Array of MIDI note intervals above a root, chosen from randomly: [0, 3, 6, 12, -6, 15]
			15. Else, if the root is ii, iii, vi, then the notes come from a minor chord.
				Array of MIDI note intervals above a root, chosen from randomly: [0, 3, 7, 12, -5, 15]
			16. Else, the notes come from a major chord.
				Array of MIDI note intervals above a root, chosen from randomly: [0, 4, 7, 12, -5, 16]

	17. If the informational entropy value of the observed HRV value occuring is greater than 8.005
	(this value is the information of the mean HRV value (6.382) plus  one and a half the information value of
	standard deviation of the HRV distribution (33.27):
		18. Play the array of notes 3 times simultaneously to create polyphony.
		19. Wait the duration between notes as calculated by HR.
		20. HR / 60 bpm is the time in seconds between notes.
		21. Wait 5 seconds after all notes have been played before exiting the function to allow
		the reverb to ring out to complete silence.
	22. Else:
		23. Play the array of notes once.
		24. Wait the duration between notes as calculated by HR.
		25. HR / 60 bpm is the time in seconds between notes.
		26. Wait 5 seconds after all notes have been played before exiting the function to allow
		the reverb to ring out to complete silence.
STOP
```
