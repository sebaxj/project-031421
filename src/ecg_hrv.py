# import packages
import heartpy as hp 
import matplotlib.pyplot as plt
import time
import math
from scipy import stats
import numpy as np
import csv

# import OSC client
import osc_client as osc

"""
    Global Variables 
"""
# array of scale degrees
SCALE_DEGREE = [0, 2, 4, 6, 7, 9, 11]
SCALE_DEGREE_m = [0, 2, 3, 6, 7, 9, 11]

# arrays of root note PDF's 
# I
I1 = [0.00, 0.00, 0.02, 0.00, 0.08, 0.10, 0.80]
I2 = [0.10, 0.10, 0.05, 0.05, 0.30, 0.10, 0.30]
I3 = [0.20, 0.10, 0.18, 0.10, 0.30, 0.02, 0.10]
I4 = [0.15, 0.14, 0.14, 0.14, 0.15, 0.14, 0.14]
I5 = [0.20, 0.10, 0.08, 0.12, 0.30, 0.10, 0.10]
I6 = [0.40, 0.10, 0.00, 0.10, 0.08, 0.30, 0.02]
I7 = [0.30, 0.00, 0.00, 0.30, 0.30, 0.10, 0.00]

# ii, iii, IV, or vi
S1 = [0.00, 0.20, 0.30, 0.08, 0.02, 0.10, 0.30]
S2 = [0.00, 0.30, 0.30, 0.00, 0.05, 0.05, 0.30]
S3 = [0.10, 0.30, 0.08, 0.05, 0.12, 0.05, 0.30]
S4 = [0.10, 0.04, 0.00, 0.05, 0.26, 0.30, 0.25]
S5 = [0.10, 0.16, 0.04, 0.15, 0.30, 0.15, 0.10]
S6 = [0.10, 0.05, 0.00, 0.10, 0.40, 0.15, 0.20]
S7 = [0.00, 0.10, 0.00, 0.00, 0.60, 0.00, 0.30]

# V or Vii
D1 = [0.00, 0.10, 0.30, 0.10, 0.02, 0.40, 0.08]
D2 = [0.00, 0.20, 0.30, 0.10, 0.02, 0.30, 0.08]
D3 = [0.20, 0.20, 0.00, 0.08, 0.10, 0.30, 0.12]
D4 = [0.30, 0.10, 0.00, 0.00, 0.20, 0.20, 0.20]
D5 = [0.45, 0.05, 0.00, 0.12, 0.25, 0.05, 0.08]
D6 = [0.50, 0.00, 0.00, 0.05, 0.30, 0.05, 0.10]
D7 = [0.70, 0.00, 0.00, 0.00, 0.25, 0.05, 0.00]

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


def processAll(data, data_sample_rate, log=False):
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
    data_sample_rate : float
        sample rate of the ECG data
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
    WORKING_DATA, MEASURES = hp.process(data, sample_rate=data_sample_rate, clean_rr=True, 
            clean_rr_method='quotient-filter', report_time=True, high_precision=False, high_precision_fs=1000.0)
    
    # display computed measures
    if log:
        print('\nECG data analyed as whole...\n')
        for measure in MEASURES.keys():
            print('%s: %f' %(measure, MEASURES[measure]))

    return WORKING_DATA, MEASURES

def processBySegment(data, data_sample_rate, length, overlap, log=False):
    """computes running HR

    Funcion that reads heart data from a 1-d array and computes the running 
    HR over defined segments (seconds)

    Parameters
    ----------
    data : 1-d array
        1-d array holding ECG data
    data_sample_rate : float
        sample rate of the ECG data
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

    WORKING_DATA, MEASURES = hp.process_segmentwise(data, sample_rate=data_sample_rate, segment_width=length, segment_overlap=overlap)

    # display computed measures
    if log:
        print('\nECG data analyzed in', length, 'second segments with', overlap * length, 'second overlap...\n')
        for key in MEASURES.keys():
            print(key, ':', MEASURES[key], '\n')

    return WORKING_DATA, MEASURES

def calRoot(hrv, root):
    """calculate the root note from the hrv

    Function takes in HRV and calculates the root note of the chord to be 
    played from the HRV scale degree PDF.

    Parameters
    --------

    hrv : float
        HRV value
    root : float 
        value of previous scale degree

    Returns
    --------

    root : float 
        scale degree of root note

    """

    if root == 0 or root == 12:
        if hrv < 16.5:
            return np.random.choice(SCALE_DEGREE_m, 1, p=I1)[0]
        elif hrv >= 16.5 and hrv < 22.1:
            return np.random.choice(SCALE_DEGREE_m, 1, p=I2)[0]
        elif hrv >= 22.1 and hrv < 27.6:
            return np.random.choice(SCALE_DEGREE_m, 1, p=I3)[0]
        elif hrv >= 27.6 and hrv < 38.7:
            return np.random.choice(SCALE_DEGREE, 1, p=I4)[0]
        elif hrv >= 38.7 and hrv < 49.8:
            return np.random.choice(SCALE_DEGREE, 1, p=I5)[0]
        elif hrv >= 49.8 and hrv < 55.5:
            return np.random.choice(SCALE_DEGREE, 1, p=I6)[0]
        elif hrv >= 55.5:
            return np.random.choice(SCALE_DEGREE, 1, p=I7)[0]
    if root == 0 or root == 2 or root == 3 or root == 4 or root == 5 or root == 9:
        if hrv < 16.5:
            return np.random.choice(SCALE_DEGREE_m, 1, p=S1)[0]
        elif hrv >= 16.5 and hrv < 22.1:
            return np.random.choice(SCALE_DEGREE_m, 1, p=S2)[0]
        elif hrv >= 22.1 and hrv < 27.6:
            return np.random.choice(SCALE_DEGREE_m, 1, p=S3)[0]
        elif hrv >= 27.6 and hrv < 38.7:
            return np.random.choice(SCALE_DEGREE, 1, p=S4)[0]
        elif hrv >= 38.7 and hrv < 49.8:
            return np.random.choice(SCALE_DEGREE, 1, p=S5)[0]
        elif hrv >= 49.8 and hrv < 55.5:
            return np.random.choice(SCALE_DEGREE, 1, p=S6)[0]
        elif hrv >= 55.5:
            return np.random.choice(SCALE_DEGREE, 1, p=S7)[0]
    elif root == 11 or root == 7:
        if hrv < 16.5:
            return np.random.choice(SCALE_DEGREE_m, 1, p=D1)[0]
        elif hrv >= 16.5 and hrv < 22.1:
            return np.random.choice(SCALE_DEGREE_m, 1, p=D2)[0]
        elif hrv >= 22.1 and hrv < 27.6:
            return np.random.choice(SCALE_DEGREE_m, 1, p=D3)[0]
        elif hrv >= 27.6 and hrv < 38.7:
            return np.random.choice(SCALE_DEGREE, 1, p=D4)[0]
        elif hrv >= 38.7 and hrv < 49.8:
            return np.random.choice(SCALE_DEGREE, 1, p=D5)[0]
        elif hrv >= 49.8 and hrv < 55.5:
            return np.random.choice(SCALE_DEGREE, 1, p=D6)[0]
        elif hrv >= 55.5:
            return np.random.choice(SCALE_DEGREE, 1, p=D7)[0]

    return 0

def information_of_x(p):
    """information of p(HRV)

    Function takes in the PDF of an observed HRV value and returns the information 
    (from information theory/Shannon Entropy) provided by the HRV value.

    A highly likely HRV value yields low suprisal (high probability of HRV occuring).
    A lowly likely HRV value yields high suprisal (low probability of HRV occuring).

    Parameters
    --------
    p : float 
        PDF of P(X = HRV)

    Returns
    --------
    I(E) : float 
        Information of p in bits: I(p(E)) = -math.log(p)

    """

    return -math.log2(p)


"""
    Main Program
    entry point: main()
"""
def main():
    print('\n--- hrv_ecg.py main() ---')

    # read data from csv file
    # data = readECG('data/e0103.csv') # sample rate = 250
    # data = readECG('data/e0110.csv') # sample rate = 250
    # data = readECG('data/e0124.csv') # sample rate = 250
    # data = readECG('data/afib.csv') # sample rate = 360
    data = readECG('data/nsr.csv') # sample rate = 360

    # set sample rate 
    data_sample_rate = 360

    # view raw data
    plotECG(data, 'Raw ECG without peak detection', show=True)

    # run peak detection analysis
    # MEASURES['RMSDD'] contains the root mean of successive differences between normal heartbeats
    # let dti be the difference of (dri+1 - dri), the difference between heartbeats in ms. 
    # let n be the number of differences computed (dt0...i)
    # rmsdd = sqrt((sum(pow(dti, 2)) / n))
    # see https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5624990/
    WORKING_DATA, MEASURES = processAll(data, data_sample_rate)

    # plot data
    plotECG(data, 'Raw ECG', WORKING_DATA['peaklist'], WORKING_DATA['ybeat'], MEASURES['bpm'], show=True)

    # calculate HR over 10 second segments
    # MEASURES['RMSDD'] contains the root mean of successive differences between normal heartbeats
    # let dti be the difference of (dri+1 - dri), the difference between heartbeats in ms. 
    # let n be the number of differences computed (dt0...i)
    # rmsdd = sqrt((sum(pow(dti, 2)) / n))
    # see https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5624990/
    WORKING_DATA, MEASURES = processBySegment(data, data_sample_rate, 10, 0.1)

    # create HRV normal distribution 55.3
    mu = 38.7
    sd = 33.27
    X = stats.norm(mu, sd)

    print('I(mean of HRV) = %.3f' % information_of_x(X.pdf(mu)))
    print('I(mu + 0.3SD) = %.3f' % information_of_x(X.pdf(mu + (0.3 * sd))))
    print('I(mu + 0.5SD) = %.3f' % information_of_x(X.pdf(mu + (0.5 * sd))))
    print('I(mu + 1SD) = %.3f' % information_of_x(X.pdf(mu + (1 * sd))))
    print('I(mu + 1.5SD) = %.3f' % information_of_x(X.pdf(mu + (1.5 * sd))))
    print('I(mu + 2SD) = %.3f' % information_of_x(X.pdf(mu + (2 * sd))))
    print('I(mu - 0.3SD) = %.3f' % information_of_x(X.pdf(mu - (0.3 * sd))))
    print('I(mu - 0.5SD) = %.3f' % information_of_x(X.pdf(mu - (0.5 * sd))))
    print('I(mu - 1SD) = %.3f' % information_of_x(X.pdf(mu - (1 * sd))))

    # array to store bpm, hrv, p_hrv, root, and i_x values
    csv_columns = ['bpm','rmssd','cdf(rmssd)', 'root', 'I(rmssd)']
    dict_arr = []

    # send to ChucK at 10 second intervals
    print('\nsending measures for segmented (10 seconds) data')
    root = 0 # initialize root variable outside for loop so it can be tracked over multiple iterations
    for i in range(len(MEASURES['bpm'])):
        bpm = MEASURES['bpm'][i]
        hrv = MEASURES['rmssd'][i]
        p_hrv = X.cdf(MEASURES['rmssd'][i])
        root = calRoot(MEASURES['rmssd'][i], root)
        i_x = information_of_x(X.pdf(MEASURES['rmssd'][i]))

        # check that values are legal (non NaN) and send to OSC client
        if(math.isnan(bpm) == False and math.isnan(hrv) == False and math.isnan(p_hrv) == False and math.isnan(i_x) == False):
            # round values to three decimal places (except root)
            bpm = round(bpm, 3)
            hrv = round(hrv, 3)
            p_hrv = round(p_hrv, 3)
            i_x = round(i_x, 3)

            # send values
            osc.msg_send(bpm, hrv, p_hrv, root, i_x, 0)

            # store values in array to exported as csv file later
            new_dict = {csv_columns[0] : bpm, csv_columns[1] : hrv, csv_columns[2] : p_hrv, csv_columns[3] : root, csv_columns[4] : i_x}
            dict_arr.append(new_dict)

            time.sleep(10)

    
    # send '1' as status to signal end
    osc.msg_send(60, mu, 0.5, 0, 6, 1)

    # export data arrays
    csv_file = "nsr-MLII.csv"
    try:
        with open(csv_file, 'w') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=csv_columns)
            writer.writeheader()
            for data in dict_arr:
                writer.writerow(data)
    except IOError:
        print("I/O error")

    # all done!
    print('\nexiting...')

# run as a standalone file
if __name__ == '__main__':
    main()
