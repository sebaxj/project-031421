# import packages
import argparse
import random
import time

from pythonosc import udp_client

def msg_send():
    """send OSC message to client 

    This program sends 10 random values between 0.0 and 1.0 to the /filter address,
    waiting for 1 seconds between each value.
    """

    parser = argparse.ArgumentParser()
    parser.add_argument("--ip", default="127.0.0.1", help="The ip of the OSC server")
    parser.add_argument("--port", type=int, default=5005, help="The port the OSC server is listening on")
    args = parser.parse_args()

    client = udp_client.SimpleUDPClient(args.ip, args.port)

    for x in range(10):
        client.send_message("/bpm/hrv/br", [59.0, 1.0, 99.0])
        time.sleep(1)

"""
    Main Program
    entry point: main()
"""
def main():
    print('\n--- osc_client.py main() ---')

    # send 10 messages 
    msg_send()

    # all done!
    print('\nexiting...')

# run as a standalone file
if __name__ == '__main__':
    main()
