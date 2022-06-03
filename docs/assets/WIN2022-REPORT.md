# Winter 2022 Quarter Report  
  
_author: Sebastian James_  
_03/23/22_  
  
## I. OVERVIEW  

This report summarizes the progress on my senior capstone project 
as described in [SDD v1.0a](./SDD_v1.0a.pdf).  
  
## II. DELIVERABLES  
  
Thus far, I have implemented a C++ program which reads in a `.txt` file 
containing ECG and BP data. This data is then fed to a `ChucK` algorithm 
which interprets and feeds back the sonified data. With this algorithm, 
certain amplitudes correspond to the tonality of a chord which is played 
through an `ADSR` envelope. Furthermore, it is possible to toggle stereo output, 
a `LPF`, and an `Echo` effects. The following section will discuss next steps.  
  
## III. NEXT STEPS  
  
I have 10 more weeks to finish this project. In those ten weeks, I plan to 
accomplish the following:  
  
#### i. Transition from an amplitude analysis to heart rate variability (HRV). 
My primary aim with this project was to create a system which sonifies the ***interpretation*** 
of ones biodata. In order to do so, simply reflecting the amplpitude of an ECG wave 
with the tonality of a chord wouldn't suffice. However, HRV has been recognized to be a 
valuable health statistic in reflecting one's cardiovascular strength. Therefore, my 
algorithm will alter certain musical paramters based on the HRV of the patient. These 
musical parameters include timbre, tonality, and pitch.  
  
#### ii. Implement a system to imitate live data aquisition. 
In order to remain in a reasonable expectation of scope, I am refraining from designing a 
system to read data live from a patient. Such a system would require me to build ECG hardware 
and software to read electircal amplitudes from electrodes attached to a patient. However, in 
order to imitate such a system I intend to implement software which reads data from a biodata bank 
file at a consistent and reasonable rate.  
  
#### iii. Add functionality for pulse oximetrey and blood pressure readings. 
Lastly, I plan to add functionality to analyze and sonify pulse oximetrey and blood pressure 
data. While this might seem like an unreasonable amount of work, I need only alter my algorithm 
slightly to alter sonification output according to blood pressure and pulse oximetrey 
data - which typically remains consistent. One solution would be to check blood pressure and 
pulse oximetery data every 20 heart readings.  
  
## IV. CONCLUSION  

Linked below is a `wav` file for the sonification algorithm I have implplemented thus far.  
  
[winter2022-checkin.wav](./winter2022-checkin.wav)
