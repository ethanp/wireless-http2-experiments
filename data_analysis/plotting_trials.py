# 11/19/15
# Ethan

import numpy as np
import matplotlib.pyplot as plt
import tabulator
import os

os.chdir('/Users/Ethan/code/my-code/wireless-http2-experiments/data_analysis')

results = tabulator.collect('../DataServer/data.txt')

def old_plot_idea():
    """ NOTE: I'm not using this one anymore """
    plt.figure()
    plt.xscale('log', basex=2)
    plt.yscale('log', basey=2)
    plt.title('TCP for WiFi for 1 conn')
    plt.grid(True)

    one_conn_res = results[tabulator.WIFI][1]
    five_conn_res = results[tabulator.WIFI][5]
    
    def plot_them(dater):
        for event, data in dater.items():
            if event == tabulator.START_TIME: continue
            # recall: data is instance of { num_bytes, [ timestamps ] }
            just_what_i_needed = sorted(data.items())
            x = [i[0] for i in just_what_i_needed]
            y = [i[1] for i in just_what_i_needed]
            the_mins = [min(arr) for arr in y]
            the_maxs = [max(arr) for arr in y]
            the_avgs = [tabulator.avg(arr) for arr in y]
            plt.errorbar(x, the_avgs, yerr=[the_mins, the_maxs])

    plot_them(one_conn_res)
    plot_them(five_conn_res)

    plt.legend(
        [
            # '$y = x$',
            '$y = 2x$'
        ],
        loc='upper left'
    )


"""
1. there's a one graph for each of the events OPEN, FIRST_BYTE, LAST_BYTE
2. on each graph there's both the ONE_CONN case and the FIVE_CONN case
3. there's one set of graphs for each of WIFI, LTE
4. the three WIFI graphs are on the top row, and the LTEs on the bottom row [2x3] or whatever
"""


def mins_maxs_avgs(arr):
    return (
        [min(i) for i in arr],
        [max(i) for i in arr],
        [tabulator.avg(i) for i in arr]
    )

byte_vals = sorted(results[tabulator.WIFI][1][tabulator.OPEN].keys())

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

    subplot.legend(
        [
            '$One\ Conn$',
            '$Five\ Conn$'
        ],
        loc='lower right'
    )

wifi_modes = [
    tabulator.WIFI,
    tabulator.LTE
]
events = [
    tabulator.OPEN,
    tabulator.FIRST_BYTE,
    tabulator.LAST_BYTE
]

fig, axs = plt.subplots(nrows=len(wifi_modes), ncols=len(events))
for row, wifi_mode in enumerate(wifi_modes):
    for col, evt in enumerate(events):
        plot_stuff(
            subplot=axs[row, col],
            event=evt,
            is_wifi=wifi_mode)

for row in axs:
    for sbplt in row:
        pass

plt.show()
