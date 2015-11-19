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




class TcpResults(object):
    def __init__(self):
        super(TcpResults, self).__init__()
        self.data_loc = '../DataServer/data.txt'

    @staticmethod
    def result_type():
        """
        :return: {
            is_wifi {
                num_conns : {
                    conn_event :  {
                        num_bytes : [ timestamps from different trials ]
                    }
                }
            }
        }
        """
        return defaultdict(lambda:
                           defaultdict(lambda:
                                       defaultdict(lambda:
                                                   defaultdict(list))))

    @staticmethod
    def print_results(results):
        for wifi, aa in results.items():
            for conns, bb in aa.items():
                for event, cc in bb.items():
                    print wifi, conns, event
                    for bytes_dl, result_list in sorted(cc.items()):
                        print bytes_dl, sorted(result_list)

    def collect_from_log(self):

        results = self.result_type()

        with open(self.data_loc) as f:
            for l in f:
                raw = decoder.decode(l)

                # for filtering
                # timestamp = parse_timestamp(raw['time'])

                data = raw['data']

                if data['exper'] != 'TCP':
                    continue

                is_wifi = 'wifi' if data['onWifi'] else 'lte'
                num_conns = data['conns']
                num_bytes = data['bytes']

                for r in data['results']:
                    for k, v in r.iteritems():
                        results[is_wifi][num_conns][k][num_bytes].append(v)

                self.print_results(results)


if __name__ == '__main__':
    TcpResults().collect_from_log()
