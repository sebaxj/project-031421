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

The architecture of this project was as follows:

```txt
|--> Python 3
|----> heartpy: library to extract measures of HRV (RMSSD) and HR
|----> matplotlib: to plot ECG data and check HRV and HR analysis
|----> scipy: to calculate statistical distributions
|
|--> ChucK
```
