# 11/19/15
# Ethan

import matplotlib.pyplot as plt
import tabulator
import os

os.chdir('/Users/Ethan/code/my-code/wireless-http2-experiments/data_analysis')

# Note: the 11, 19, 21 data is from a period of high contention
# where the wifi (2.4GHz) is rated at [40, .99, 6.27]
# It is unclear what the cause of contention is.
# The computer on the same (5GHz) is rated at [13, 116, 22]
month, date, hour = 11, 19, 21

data_loc = '../DataServer/%d-%d-%d_data.txt' % (month, date, hour)
results = tabulator.collect(data_loc=data_loc)
byte_vals = sorted(results[tabulator.WIFI][1][tabulator.OPEN].keys())


def avg(a_list):
    return float(sum(a_list)) / len(a_list)


def mins_maxs_avgs(arr):
    return (
        [min(i) for i in arr],
        [max(i) for i in arr],
        [avg(i) for i in arr]
    )


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
1. there's a one graph for each of the events OPEN, FIRST_BYTE, LAST_BYTE
2. on each graph there's both the ONE_CONN case and the FIVE_CONN case
3. there's one set of graphs for each of WIFI, LTE
4. the three WIFI graphs are on the top row,
    and the LTEs on the bottom row [2x3] or whatever
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


def plot_stuff(subplot, event, is_wifi):
    subplot.set_xscale('log', basex=2)
    subplot.set_yscale('log', basey=2)
    subplot.grid(True)
    subplot.set_title(event)

    def do_id(d):
        just_what_i_needed = sorted(d.items())
        y = [i[1] for i in just_what_i_needed]
        mn, mx, av = mins_maxs_avgs(y)
        subplot.errorbar(byte_vals, av, yerr=[mn, mx])

    for num_conns, data in sorted(results[is_wifi].items()):
        do_id(data[event])

    # TODO ?
    # subplot.legend(
    #     [
    #         '$One\ Conn$',
    #         '$Five\ Conn$'
    #     ],
    #     loc='lower right'
    # )


wifi_modes = [
    tabulator.WIFI,
    tabulator.LTE
]
events = [
    tabulator.OPEN,
    tabulator.FIRST_BYTE,
    tabulator.LAST_BYTE
]

plt.legend([
    '$One\ Conn$',
    '$Five\ Conn$'
], loc='lower right')
fig, axs = plt.subplots(nrows=len(wifi_modes), ncols=len(events))
for row, wifi_mode in enumerate(wifi_modes):
    for col, evt in enumerate(events):
        plot_stuff(
            subplot=axs[row, col],
            event=evt,
            is_wifi=wifi_mode)

plt.show()
