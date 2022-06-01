# import packages
import argparse
from pythonosc import udp_client

def msg_send(bpm, hrv, p_hrv, root):
    """send OSC message to client 

    This program sends 10 random values between 0.0 and 1.0 to the /filter address,
    waiting for 1 seconds between each value.

    Parameters
    ----------
    bpm : float
        value of BPM from heat data
    hrv : float
        value of HRV from heat data
    p_hrv : float
        value of CDF of HRV observation
    root : float
        scale degree of root

    Returns
    -------
    0 (success), else failure
    """

    # setup message parse with server IP and port
    parser = argparse.ArgumentParser()
    parser.add_argument("--ip", default="127.0.0.1", help="The ip of the OSC server")
    parser.add_argument("--port", type=int, default=5005, help="The port the OSC server is listening on")
    args = parser.parse_args()

    # create the client
    client = udp_client.SimpleUDPClient(args.ip, args.port)

    # send the message
    client.send_message("/bpm/hrv/p_hrv/root", [bpm, hrv, p_hrv, float(root)])

    # all done! exit successfully...
    return 0

"""
    Main Program
    entry point: main()
"""
def main():
    print('\n--- osc_client.py main() ---')

    # all done!
    print('\nexiting...')

# run as a standalone file
if __name__ == '__main__':
    main()
