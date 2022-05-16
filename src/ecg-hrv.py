'''
TODO:
    1. Write descriptions for each method. [DONE]
    2. Develop runningHR()
    3. Develop computePeaks()
'''
# import packages
import heartpy as hp 
import matplotlib.pyplot as plt
from heartpy.datautils import rolling_mean
from  heartpy.peakdetection import check_peaks, detect_peaks, fit_peaks

'''
Global Variables 
'''
# sampling rate for ECG 
SAMPLE_RATE = 250

def readECG(filepath):
    '''reads ECG data

    Funcion that reads heart data from a csv file into a 1-d array.

    Parameters
    ----------
    filepath : string
        path to the csv file to be read

    Returns
    -------
    data : 1-d array
        ECG data
    '''

    return hp.get_data(filepath)

def computePeaks(data): # TODO
    '''computes QRS complex of ECG data

    Funcion that reads heart data from a 1-d array and computes the QRS complex 
    and specifically the R peak of the data..

    Parameters
    ----------
    data : 1-d array
        1-d array holding ECG data

    Returns
    -------
    None
    '''

    # run analysis for heart rate and breathing rate
    WORKING_DATA, MEASURES = hp.process(data, SAMPLE_RATE)

    # visualise in plot of custom size
    rol_mean = rolling_mean(data, windowsize=0.75, sample_rate=SAMPLE_RATE)
    peaks = fit_peaks(data, rol_mean, sample_rate=SAMPLE_RATE)
#     WORKING_DATA = check_peaks(peaks['RR_list'], peaks['peaklist'], peaks['ybeat'])
    peaklist = peaks['peaklist']
    ybeat = peaks['ybeat']
    plt.title("TEST")
    plt.plot(data, alpha=0.5, color='blue', label="raw signal")
    plt.plot(data, color ='green', label="moving average")
    plt.scatter(peaklist, ybeat, color='red', label="average: %.1f BPM" %MEASURES['bpm'])
    plt.legend(loc=4, framealpha=0.6)
    plt.show()
    analyzed_plot = hp.plotter(working_data=WORKING_DATA, measures=MEASURES, show=False)
    analyzed_plot.show() # TODO: why is this not showing?
    
    # display computed measures
    for measure in MEASURES.keys():
        print('%s: %f' %(measure, MEASURES[measure]))

    # detect peaks
    rol_mean = rolling_mean(data, windowsize=0.75, sample_rate=SAMPLE_RATE)
 #    peaks = detect_peaks(data, rol_mean, ma_perc=20, sample_rate=SAMPLE_RATE)
 # fit_peaks is more accurate than detect_peaks because it uses a varrying threshold
    print("PEAKS: ", peaks['peaklist'])
    print("RR Indices:", peaks['RR_indices'])
    print("RR List:", peaks['RR_list'])
    print("PEAKS ROLL MEAN: ", peaks['rolling_mean'])
    print("ROLLING MEAN: ", rol_mean)

def runningHR(data, length, overlap): # TODO
    '''computes running HR

    Funcion that reads heart data from a 1-d array and computes the running 
    HR over defined segments (seconds)

    Parameters
    ----------
    data : 1-d array
        1-d array holding ECG data
    length : int or float
        length in seconds of a single segment 
    overlap : int or float
        0 <= int or float < 1 of overlap between segments

    Returns
    -------
    None
    '''

    WORKING_DATA, MEASURES = hp.process_segmentwise(data, sample_rate=SAMPLE_RATE, segment_width=length, segment_overlap=overlap)

    # display computed measures
    for key in MEASURES.keys():
        print(key, ":", MEASURES[key])

def plotData(data, length, width):
    '''plot ECG data

    Funcion that plots heart data from a 1-d array

    Parameters
    ----------
    data : 1-d array
        1-d array holding ECG data
    length : int or float
        length of figure size 
    width : int or float
        width of figure size 

    Returns
    -------
    None
    '''

    plt.figure(figsize=(length,width))
    plt.plot(data)
    plt.show()

def main():
    print("\n--- hrv-ecg.py main() ---")

    # read data from csv file
    data = readECG("data/e0103.csv")

    # view raw data
    # plotData(data, 12, 4)

    # run peak detection analysis
    computePeaks(data)

    # calculate HR over time
    runningHR(data, 5, 0.1)

if __name__ == "__main__":
    main()
