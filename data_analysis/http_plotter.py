# 11/19/15
# Ethan

from pylab import plot, show, xlim, figure, \
    hold, ylim, legend, boxplot, setp, axes
import matplotlib.pyplot as plt
import http_tabulator
from http_tabulator import WIFI, LTE, HTTP_1, HTTP_2
import os

os.chdir('/Users/Ethan/code/my-code/wireless-http2-experiments/data_analysis')

"""
 DATA CATALOG
 ------------

11, 28, 16: in Boston
iPhone LTE is [37, 12.0, 3.6]
iPhone WiFi (2.4GHz) is [18, 22.7, 2.0].
"""

month = 11
date_hours = {28: [16]}

results = http_tabulator.collect(data_locs=[
    '../DataServer/%d-%d-%d_data.txt' % (month, date, hour)
    for date, hours in date_hours.items()
    for hour in hours
    ])


def avg(a_list):
    return float(sum(a_list)) / len(a_list)


def mins_maxs_avgs(arr):
    return (
        [min(i) for i in arr],
        [max(i) for i in arr],
        [avg(i) for i in arr]
    )


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
1. there's a one set of 2 box plots for each of the CONN_TYPES  "
2. and one box plot for each of the HTTP_VRSNS                  "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


def set_box_colors(box_plot):
    """ http://stackoverflow.com/a/16598291/1959155
    :param box_plot: a matplotlib boxplot
    """
    setp(box_plot['boxes'][0], color='blue')
    setp(box_plot['caps'][0], color='blue')
    setp(box_plot['caps'][1], color='blue')
    setp(box_plot['whiskers'][0], color='blue')
    setp(box_plot['whiskers'][1], color='blue')
    setp(box_plot['fliers'][0], color='blue')
    setp(box_plot['fliers'][1], color='blue')
    setp(box_plot['medians'][0], color='blue')

    setp(box_plot['boxes'][1], color='red')
    setp(box_plot['caps'][2], color='red')
    setp(box_plot['caps'][3], color='red')
    setp(box_plot['whiskers'][2], color='red')
    setp(box_plot['whiskers'][3], color='red')
    setp(box_plot['fliers'][2], color='red')
    setp(box_plot['fliers'][3], color='red')
    setp(box_plot['medians'][1], color='red')


wifi_results = results[WIFI].values()
lte_results = results[LTE].values()

fig, axes = plt.subplots(nrows=1, ncols=2)
bp = axes[0].boxplot(wifi_results)
set_box_colors(bp)
axes[0].set_title('WIFI')

bp = axes[1].boxplot(lte_results)
set_box_colors(bp)
axes[1].set_title('LTE')

# set the legend
plt.legend([
    '$HTTP/1.1$',
    '$HTTP/2$'
], loc='best')
legend = plt.gca().get_legend()
legend.legendHandles[0].set_color('blue')
legend.legendHandles[1].set_color('red')

plt.show()
