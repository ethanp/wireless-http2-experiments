# 11/14/15
# Ethan Petuchowski
#
# Crunches stats over the TCP connection data
#
# This is what each line of raw data looks like (pretty-fied)
#   NOTE: time values are and intervals are in MICROSECONDS (secondsE-6)
#
# {
#     "time":"11:16:11:39:45:966",
#     "data": {
#         "exper": "TCP",
#         "onWifi": true,
#         "bytes":838860,
#         "results": [
#             {
#                 "FIRST_BYTE":172238,
#                 "LAST_BYTE":194548,
#                 "START_TIME":1447695585390338,
#                 "CLOSED":194684,
#                 "OPEN":2746,
#                 "START":5
#             },
#             "conns"-1 (here, 4) more of these
#         ],
#         "conns":5
#     }
# }
#
#

import json
from collections import defaultdict
from datetime import datetime
import numpy as np
import matplotlib.pyplot as plt

decoder = json.JSONDecoder()
timestamp_format = '%m:%d:%H:%M:%S:%f'

FIRST_BYTE = 'FIRST_BYTE'
LAST_BYTE = 'LAST_BYTE'
START_TIME = 'START_TIME'
CLOSED = 'CLOSED'
OPEN = 'OPEN'
START = 'START'

TCP_EVENTS = [
    START_TIME,
    START,
    OPEN,
    FIRST_BYTE,
    LAST_BYTE,
    CLOSED
]


def parse_timestamp(raw):
    return datetime.strptime(raw, timestamp_format).replace(year=2015)


def avg(a_list):
    return float(sum(a_list)) / len(a_list)


"""
{
    is_wifi {
        num_conns : {
            conn_event :  {
                num_bytes : [ timestamps from different trials ]
            }
        }
    }
}
"""
results = defaultdict(lambda:
                      defaultdict(lambda:
                                  defaultdict(lambda:
                                              defaultdict(list))))


def print_results():
    for conn_type, aa in results.items():
        for num_conns, bb in aa.items():
            for event, cc in bb.items():
                print conn_type, num_conns, event
                for bytes_dl, result_list in sorted(cc.items()):
                    print bytes_dl, sorted(result_list)


def add_result(conn_type, num_conns, tcp_event, num_bytes, timestamp):
    results[conn_type][num_conns][tcp_event][num_bytes].append(timestamp)


def collect(data_loc):
    """
    :type data_loc: str
    """
    with open(data_loc) as f:
        for l in f:
            raw = decoder.decode(l)
            # timestamp = parse_timestamp(raw['time'])
            data = raw['data']
            if data['exper'] != 'TCP': continue
            conn_type = 'wifi' if data['onWifi'] else 'lte'
            for result in data['results']:
                for tcp_event, timestamp in result.iteritems():
                    add_result(
                        conn_type=conn_type,
                        num_conns=data['conns'],
                        tcp_event=tcp_event,
                        num_bytes=data['bytes'],
                        timestamp=timestamp
                    )

            print_results()

collect('../DataServer/data.txt')
