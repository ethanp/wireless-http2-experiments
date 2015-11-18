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
from datetime import datetime
from collections import defaultdict

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
    return datetime.strptime(raw, timestamp_format). \
        replace(year=2015)


def avg(a_list):
    return float(sum(a_list)) / len(a_list)


class TcpResults(object):
    def __init__(self):
        super(TcpResults, self).__init__()
        self.data_loc = '../DataServer/data.txt'

    def collect_from_log(self):

        # { num_bytes : { event : [avg per run] } }
        single_results = {
            'wifi': defaultdict(lambda: defaultdict(list)),
            'lte': defaultdict(lambda: defaultdict(list))
        }
        fiver_results = {
            'wifi': defaultdict(lambda: defaultdict(list)),
            'lte': defaultdict(lambda: defaultdict(list))
        }
        with open(self.data_loc) as f:
            for l in f:
                raw = decoder.decode(l)

                # for filtering the data to only the TCP experiment
                # if data['exper'] != 'TCP':
                #     continue

                # for filtering to a specific RUN of the experiment
                # timestamp = parse_timestamp(raw['time'])

                data = raw['data']
                is_five = data['conns'] == 5
                is_wifi = 'wifi' if data['onWifi'] else 'lte'
                num_bytes = data['bytes']
                if is_five:
                    collector = defaultdict(list)
                    for r in data['results']:
                        for k, v in r.iteritems():
                            collector[k].append(v)
                    for k, v in collector.iteritems():
                        fiver_results[is_wifi][num_bytes][k].append(float(sum(v)) / 5)

                else:  # single conn
                    for k, v in data['results'][0].iteritems():
                        single_results[is_wifi][num_bytes][k].append(v)

        # for i in sorted(single_results.items()):
        #     print i[0], avg(i[1][LAST_BYTE])
        #
        # for i in sorted(fiver_results.items()):
        #     print i[0], avg(i[1][LAST_BYTE])

        for i in zip(
                sorted(single_results['wifi'].items()),
                sorted(fiver_results['wifi'].items())
        ):
            print i[0][0], avg(i[0][1][LAST_BYTE]) - avg(i[1][1][LAST_BYTE])

        for i in zip(
            sorted(single_results['lte'].items()),
            sorted(fiver_results['lte'].items())
        ):
            print i[0][0], avg(i[0][1][LAST_BYTE]) - avg(i[1][1][LAST_BYTE])

if __name__ == '__main__':
    TcpResults().collect_from_log()
