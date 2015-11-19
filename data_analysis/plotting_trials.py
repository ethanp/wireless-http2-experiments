# 11/19/15
# Ethan

import numpy as np
import matplotlib.pyplot as plt

import tabulator

results = tabulator.collect('../DataServer/data.txt')
one_plottable = sorted(results[tabulator.WIFI][1][tabulator.CLOSED].items())
x = [i[0] for i in one_plottable]
y = [i[1] for i in one_plottable]
the_mins = [min(arr) for arr in y]
the_maxs = [max(arr) for arr in y]
the_avgs = [tabulator.avg(arr) for arr in y]

# x = np.arange(0.1, 4, 0.5)
# y = np.exp(-x)
# y2 = np.exp(x)


plt.figure()
plt.errorbar(x, the_avgs, yerr=[the_mins, the_maxs])
plt.xscale('log', basex=2)
plt.yscale('log', basey=2)
plt.title("The TCP Graph")
plt.grid(True)

plt.legend(
    [
        #'$y = x$',
        '$y = 2x$'
    ],
    loc='upper left'
)

plt.show()


