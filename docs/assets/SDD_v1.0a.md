# Software Design Document v1.0a: Capstone Project in the Music Department

_author: Sebastian James_  
_11/21/21_

## I. OVERVIEW

This is a proposal for a capstone project in the music major at
Stanford University. I intend to implement a biosignal sonification
exhibit where one can view their vital signs artfully sonified. Vital sign
sensors will read data into a C++ program running on a Raspberry Pi/Arduino,
and communicate with a ChucK sonification algorithm to output a live musical
representation of an individual's biodata.

## II. CONTEXT

The goal of this software design document is to outline a capstone
project proposal in the Music Major at Stanford University, with a
concentration in Human Computer Interaction. I have always found
myself stretched between a desire to practice medicine, and a passion
for playing music. It seemed that neither interest would allow the
other to dominate.

A requirement for graduation with a Bachelor's of Arts in Music at
Stanford University is the **capstone project**. This is defined
as the _"culmination of the 16 units of coursework in your focus area."_
Though the core of the department focuses on a traditional music education
with classes in music history, ear training, and music theory, the
concentration allows for interdisciplinary exploration. I have chosen to
design my own concentration: **Human Computer Interaction**. The culmination
of my concentration has focused an interdisciplinary application of music to
the domain of neuroscience, audiovisual design, and computer generated sound
processing and synthesis. Therefore, my **proposal for a capstone project is the
development of artful biosignal sonification software**.

#### i. GOALS

The goals for this project are as follows:

- Artful biosignal sonification software
- Implementation of playback and livestream mode:
  - Playback mode would allow a complete dataset to be played through the
    sonification algorithm to generate an output file.
  - Livestream implements a direct pipeline from hardware sensors to biosignal
    aquisition, digital signal processing (DSP) algorithms, to sound synthesis in
    an instantaneous format.
  - Ultimately, a audiovisual exhibit to **artfully** represent human vitals in
    the domain of music.

## III. PROPOSED SOLUTION

The proposed implementation of software for my capstone project is as follows.

In `sonifyBiosignals_Ex/` There is a prototype of my proposed capstone. A
Python script using a music framework running on a Java VM takes in a biosignal
dataset stored in `biosignals.txt`. The format of the data is saved in the
following format:

`[time(hour:minute:second:milisecond)] [skin conductance (microsiemens)] [blood pressure (ratio of systolic to diastolic)]`

Over time, the Python script maps skin conductance to a pitch (C3-C6), and
blood pressure to both a scale step in a two octave scale [0, 24] and a
dynamic magnitude [0, 127]. As skin conductance doesn't varry greatly, the
pitch at a certain time point is the sum of a base pitch computed from
skin conductance and pitch variation between 0 and 24 scale steps computed
from blood pressure, played at a dynamic computed from blood pressure where
each value is calculated relative to the minimum and maximum blood pressure
in the dataset.

The output is a MIDI value which can be used in any musical context.

Though this example covers a specific and narrow scope, it is a foundation
which I will build upon. I will design an algorithm in ChucK to represent raw
signal data in a musical format. To do this, I will experiment with various
parameters so that heart rate, blood presure, temperature, and pulse oximetry
(and perhaps skin conductance as well) work in a system to accurately, yet
artfully represent the emotional and physiological state of the user.

#### i. SYSTEM ARCHITECTURE

This software will use C++ to gather and process biodata, and send that
data to ChucK for sonification. I am still uncertain if ChucK will be
used natively with C++ so as to compile a single program which can run
on a specified platform, of if a C++ program will communicate with ChucK
over an Open Sound Control (OSC) protocol. Additionally, I am still uncertain
how biodata will be collected live, and what the target platform will be
(laptop, Raspberry Pi, etc.). Though, in the past I have implemented an
electrocardiogram (ECG) machine using electrodes and various capacitive
filters running on an Arduino.

The system architecture I propose is a basic vitals machine using
electrodes and sensors to create an isolated exhibit where individuals may
hook themselves up to an ECG, temperature probe, blood pressure cuff, galvanic
skin response sensor, and pulse oximetry sensor to view their vitals sonified
live. The vital sign sensors would run through a Raspberry Pi/Arduino running
the proposed C++/ChucK software.

#### ii. SYSTEM DESIGN

```
[ECG pads, temperature probe, blood pressure cuff,
galvanic skin response, and pulse oximetry LED]
|
|
|
––––> [Microcontroller]
|
|
|
––––> [Data collection and processing]
|
|
|
––––> [Data Sonification]
|
|
|
––––> [DAC Output]
```

## IV. TIMELINE

**Fall Quarter 2021: 1 Unit Music 199**

- write documentation (DONE)
- prototype using Jython (DONE)
- compile build of C++ and ChucK (DONE – see `src/`)

**Winter Quarter 2022: 1 Unit Music 199**

- gather datasets which will be used to test software
- build out `host` to read datasets and process data
- seamless communication between processed data in C++ and ChucK
- build data aquisition hardware to read 5 vital signs into `host`
- END GOAL: MVP

**Spring Quarter 2022: 2 Unit Music 199**

- build out ChucK sonification algorithm
- futher build out software to transition from an MVP to a polished product
- refactor (if needed)
- ship out final audiovisual exhibit software and hardware.
