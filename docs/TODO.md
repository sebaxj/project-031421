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
|----> scipy
|----> numpy?
|
|--> ChucK
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
