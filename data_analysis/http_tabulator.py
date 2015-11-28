# 11/14/15
# Ethan Petuchowski
#
# Crunches stats over the TCP connection data
#
# This is what each line of raw data looks like (pretty-fied)
#   NOTE: time values and intervals are in MICROSECONDS (secondsE-6)
#
# {
#   "time": "11:28:16:20:46:472",
#   "data": {
#     "onWifi": false,
#     "exper": "http",
#     "results": [
#       {
#         "START_TIME": 1448745357308713,
#         "CLOSED": 4014690,
#         "START": 787
#       },
#       {
#         many more of the same
#       }
#     ]
#   }
# }
#

import json
from collections import defaultdict
from datetime import datetime

decoder = json.JSONDecoder()
timestamp_format = '%m:%d:%H:%M:%S:%f'

CLOSED = 'CLOSED'
START = 'START'
WIFI = 'wifi'
LTE = 'lte'
HTTP_1 = 'http1'
HTTP_2 = 'http2'

CONN_TYPES = [WIFI, LTE]
HTTP_EVENTS = [START, CLOSED]
HTTP_VRSNS = [HTTP_1, HTTP_2]


def parse_timestamp(raw):
    return datetime.strptime(raw, timestamp_format).replace(year=2015)


"""
is_wifi :
    is_http2 :
        [ total times from different trials ]
"""
results = defaultdict(lambda: defaultdict(list))


def print_results():
    for w in CONN_TYPES:
        for h in HTTP_VRSNS:
            print len(results[w][h]), sum(results[w][h])


def add_result(conn_type, http_vrsn, total_time):
    results[conn_type][http_vrsn].append(total_time)


def collect(data_locs):
    """
    :param data_locs: either a list of or single data file path
    :return: the combined results therein
    """
    if isinstance(data_locs, str):
        data_locs = [data_locs]
    for data_loc in data_locs:
        print 'opening', data_loc
        with open(data_loc) as data_file:
            for json_string in data_file:
                json_data = decoder.decode(json_string)
                data = json_data['data']
                if data['exper'] != 'http': continue
                conn_type = WIFI if data['onWifi'] else LTE
                num_results = len(data['results'])
                for i, result in enumerate(data['results']):
                    http_vrsn = HTTP_1 if float(i) / num_results < .5 else HTTP_2
                    add_result(
                        conn_type=conn_type,
                        http_vrsn=http_vrsn,
                        total_time=result[CLOSED] - result[START])
    return results


if __name__ == '__main__':
    collect('../DataServer/11-28-16_data.txt')
    print_results()
