"""
TODO:
    1. Part I:
        i. Write descriptions for each method. [DONE]
        ii. Develop processBySegment()
        iii. Create OSC connection (2 ways) between Python and ChucK
        iv. Construct a way to analyze new data while sending the computer HRV and BPM 
        from the old data
    2. Part II:
    3. Part III:


Part I: HRV and BPM Analysis Pipeline:
    1. read ECG data from csv file and import into a 1-d array [readECG(data)] [DONE]
    2. analyze data for BPM and R peaks [DONE]
    3. Compute HRV by RR algorithm [DONE]
    4. Develop an OSC connection between Python and ChucK
    5. Using a constant tempo (BPM), construct a piece using the calcualted HRV (TODO: How?)

Part II: Continuous HRV and BPM Pipeline:
    1. read ECG data in frames from CSV file and process it by segments (TODO: How long are segments?)
    2. During the overlap period, send analyzed parameters to ChucK while analyzing the new data

Part III: Either convert this program to C++ or find a way to wrap it in a C++ program:
    1. How to wrap a Python program into a C++ file to compile the entire thing into an executable
    or...
    2. Convert this program into a C++ program by going through the HeartPy library and converting it to 
    C++ code
"""

# import packages
import heartpy as hp 
import matplotlib.pyplot as plt
from heartpy.datautils import rolling_mean
from  heartpy.peakdetection import check_peaks, detect_peaks, fit_peaks

"""
    Global Variables 
"""
# sampling rate for ECG 
SAMPLE_RATE = 250

"""
    Helper Functions
"""

def readECG(filepath):
    """reads ECG data

    Funcion that reads heart data from a csv file into a 1-d array.

    Parameters
    ----------
    filepath : string
        path to the csv file to be read

    Returns
    -------
    data : 1-d array
        ECG data
    """

    return hp.get_data(filepath)

def plotECG(data, title, peaklist=None, ybeat=None, bpm=None, show=False):
    """displays of ECG data

    Funcion that reads heart data from a 1-d array and displays the raw signal, 
    estimated BPM, and computed peaks.

    Parameters
    ----------
    data : 1-d array
        1-d array holding ECG data
    title : string 
        title of the plot 
    peaklist : 1-d array
        array of R peaks. Default is None
    ybeat : 1-d array
        array of heart beats. Default is None
    bpm : float 
        average BPM over data. Default is None
    show : bool
        determines whether the generated matplotlib image is shown or not.
        Default is False

    Returns
    -------
    ecg_plot : matplotlib object
        matplotlib object containing computed ECG data and measures
    """

    # if no peak list or ybeat are specified, plot the raw signal only
    if (peaklist == None) or (ybeat == None):
        plt.figure()
        plt.plot(data)

        # OPTIONAL: show plot
        if show:
            plt.show()
            
        return plt

    # name the plot
    plt.title(title)
    
    # plot the raw signal
    plt.plot(data, alpha=0.5, color='blue', label='raw signal')

    # plot the estimated R peaks
    if bpm == None:
        plt.scatter(peaklist, ybeat, color='red', label='average: N/A BPM')
    else:
        plt.scatter(peaklist, ybeat, color='red', label='average: %.1f BPM' %bpm)

    # add the bells and whistles
    plt.legend(loc=4, framealpha=0.6)

    # OPTIONAL: show plot
    if show:
        plt.show()

    return plt


def processAll(data, log=False): # TODO
    """"computes measures of ECG data

    Funcion that reads heart data from a 1-d array and computes the following measures:
        bpm: float
        ibi: float
        sdnn: float
        sdsd: float
        rmssd: float
        pnn20: float
        pnn50: float
        hr_mad: float
        sd1: float
        sd2: float
        s: float
        sd1/sd2: float
        breathingrate: float

    Parameters
    ----------
    data : 1-d array
        1-d array holding ECG data
    log : bool 
        bool to specifiy if the computed measures should be printed or not. 
        Default is False

    Returns
    -------
    WORKING_DATA : dict 
        dict containing all working data from HeartPy
    MEASURES : dict
        dict containing the computed measures
    """

    # run analysis for heart rate and breathing rate
    # setting high_precision to True will enable a more specific calculation of R peaks
    WORKING_DATA, MEASURES = hp.process(data, sample_rate=SAMPLE_RATE, clean_rr=True, 
            clean_rr_method='quotient-filter', report_time=True, high_precision=False, high_precision_fs=1000.0)

    # TODO: Figure out where this goes
    # rol_mean = rolling_mean(data, windowsize=0.75, sample_rate=SAMPLE_RATE)

    # peaks = fit_peaks(data, rol_mean, sample_rate=SAMPLE_RATE)
    # peaks = detect_peaks(data, rol_mean, ma_perc=20, sample_rate=SAMPLE_RATE)
    # fit_peaks is more accurate than detect_peaks because it uses a varrying threshold

    #  WORKING_DATA = check_peaks(peaks['RR_list'], peaks['peaklist'], peaks['ybeat'])
    # peaklist = peaks['peaklist']
    # ybeat = peaks['ybeat']
    
    # display computed measures
    if log:
        print('\nECG data analyed as whole...\n')
        for measure in MEASURES.keys():
            print('%s: %f' %(measure, MEASURES[measure]))

    return WORKING_DATA, MEASURES

def processBySegment(data, length, overlap, log=False): # TODO
    """computes running HR

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
    log : bool 
        bool to specifiy if the computed measures should be printed or not. 
        Default is False

    Returns
    -------
    WORKING_DATA : dict 
        dict containing all working data from HeartPy
    MEASURES : dict
        dict containing the computed measures
    """

    WORKING_DATA, MEASURES = hp.process_segmentwise(data, sample_rate=SAMPLE_RATE, segment_width=length, segment_overlap=overlap)

    # display computed measures
    if log:
        print('\nECG data analyzed in', length, 'second segments with', overlap * length, 'second overlap...\n')
        for key in MEASURES.keys():
            print(key, ':', MEASURES[key], '\n')

    return WORKING_DATA, MEASURES

"""
    Main Program
    entry point: main()
"""
def main():
    print('\n--- hrv_ecg.py main() ---')

    # read data from csv file
    data = readECG('data/e0103.csv')

    # view raw data
    plotECG(data, 'Raw ECG without peak detection', show=False)

    # run peak detection analysis
    WORKING_DATA, MEASURES = processAll(data)

    # plot data
    plotECG(data, 'Raw ECG', WORKING_DATA['peaklist'], WORKING_DATA['ybeat'], MEASURES['bpm'], show=False)

    # extract HRV
    # MEASURES['RMSDD'] contains the root mean of successive differences between normal heartbeats
    # let dti be the difference of (dri+1 - dri), the difference between heartbeats in ms. 
    # let n be the number of differences computed (dt0...i)
    # rmsdd = sqrt((sum(pow(dti, 2)) / n))
    # see https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5624990/
    hrv = MEASURES['rmssd']

    # calculate HR over time
    processBySegment(data, 5, 0.1)

    # all done!
    print('\nexiting...')

# run as a standalone file
if __name__ == '__main__':
    main()
