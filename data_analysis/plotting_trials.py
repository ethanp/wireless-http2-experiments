# 11/19/15
# Ethan

import numpy as np
import matplotlib.pyplot as plt
import tabulator

""" LET'S START WITH THE WIFI CHART """

plt.figure()
plt.xscale('log', basex=2)
plt.yscale('log', basey=2)
plt.title('TCP for WiFi for 1 conn')
plt.grid(True)

results = tabulator.collect('../DataServer/data.txt')
# one_plottable = sorted(results[tabulator.WIFI][1][tabulator.CLOSED].items())
# x = [i[0] for i in one_plottable]
# y = [i[1] for i in one_plottable]
# the_mins = [min(arr) for arr in y]
# the_maxs = [max(arr) for arr in y]
# the_avgs = [tabulator.avg(arr) for arr in y]

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

# TODO here's how I think this ought to be plotted
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


x = sorted(one_conn_res[tabulator.OPEN].keys())


def plot_stuff(axx, data1, data2):
    axx.set_xscale('log', basex=2)
    axx.set_yscale('log', basey=2)
    axx.grid(True)

    def do_id(d):
        just_what_i_needed = sorted(d.items())
        y = [i[1] for i in just_what_i_needed]
        mn, mx, av = mins_maxs_avgs(y)
        axx.errorbar(x, av, yerr=[mn, mx])
    do_id(data1)
    do_id(data2)
    axx.legend(
    [
        '$One\ Conn$',
        '$Five\ Conn$'
    ],
    loc='lower right'
)

fig, axs = plt.subplots(nrows=2, ncols=3)
ax = axs[0, 0]
ax.set_title(tabulator.OPEN)
plot_stuff(ax, one_conn_res[tabulator.OPEN], five_conn_res[tabulator.OPEN])

# With 4 subplots, reduce the number of axis ticks to avoid crowding.
# ax.locator_params(nbins=4)

# ax = axs[0,1]
# ax.errorbar(x, y, xerr=xerr, fmt='o')
# ax.set_title('Hor. symmetric')
#
# ax = axs[1,0]
# ax.errorbar(...)
#
# fig.suptitle('Variable errorbars')

plt.show()
