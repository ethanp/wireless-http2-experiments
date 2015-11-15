# 11/14/15
# Ethan Petuchowski
#
# Crunches stats over the TCP connection data

import json

decoder = json.JSONDecoder()
with open("../DataServer/data.txt") as f:
    for l in f:
        # print "raw string:", l[:-1]
        data = decoder.decode(l)['data']
        print "decoded:", data.keys()
        if 'bytes' in data:
            print data['bytes']
