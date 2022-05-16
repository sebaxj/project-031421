'''
TODO:
    1. Write descriptions for each method.
    2. Develop runningHR()
    3. Develop analyzePeaks()
'''
# import packages
import heartpy as hp 
import matplotlib.pyplot as plt
from heartpy.datautils import rolling_mean
from  heartpy.peakdetection import detect_peaks

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

def analyzePeaks(data): # TODO

    # run analysis for heart rate and breathing rate
    WORKING_DATA, MEASURES = hp.process(data, SAMPLE_RATE)

    # visualise in plot of custom size
    analyzed_plot = hp.plotter(working_data=WORKING_DATA, measures=MEASURES, show=False)
    analyzed_plot.show() # TODO: why is this not showing?
    
    # display computed measures
    for measure in MEASURES.keys():
        print('%s: %f' %(measure, MEASURES[measure]))

    # detect peaks
    rol_mean = rolling_mean(data, windowsize=0.75, sample_rate=SAMPLE_RATE)
    peaks = detect_peaks(data, rol_mean, ma_perc=20, sample_rate=SAMPLE_RATE)

def runningHR(data): # TODO
    WORKING_DATA, MEASURES = hp.process_segmentwise(data, sample_rate=SAMPLE_RATE, segment_width=40, segment_overlap=0.25)

    # display computed measures
    print(WORKING_DATA)
    print(MEASURES)

def main():
    print("\n--- hrv-ecg.py main() ---")

    # read data from csv file
    data = readECG("data/e0103.csv")

    # view raw data
    plt.figure(figsize=(12,4))
    plt.plot(data)
    plt.show()

    # run peak detection analysis
    analyzePeaks(data)

    # calculate HR over time
    runningHR(data)

if __name__ == "__main__":
    main()
