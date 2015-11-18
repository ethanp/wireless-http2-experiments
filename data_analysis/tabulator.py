# 11/14/15
# Ethan Petuchowski
#
# Crunches stats over the TCP connection data
#
# This is what each line of raw data looks like (pretty-fied)
# {
#     "time":"11:16:11:39:45:966",
#     "exper": "TCP",
#     "data": {
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

decoder = json.JSONDecoder()

fiveConnData = []
oneConnData = []

with open('../DataServer/data.txt') as f:
    for l in f:
        data = decoder.decode(l)

        # TODO for new data
        # if data['exper'] != 'TCP':
        #     continue

        data_time = datetime.strptime(data['time'], '%m:%d:%H:%M:%S:%f').replace(year=2015)
        print data_time
        print 'bytes:', data['bytes']
        for res in data['results']:
            print res['FIRST_BYTE']
