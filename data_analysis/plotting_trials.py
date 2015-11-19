# 11/19/15
# Ethan

import numpy as np
import matplotlib.pyplot as plt

x = np.arange(0.1, 4, 0.5)
y = np.exp(-x)
y2 = np.exp(x)

plt.figure()
plt.errorbar(x, y, yerr=0.4)
plt.errorbar(x, y2, yerr=y2/2)
plt.title("Simplest errorbars, 0.2 in x, 0.4 in y")

plt.legend(
    [
        '$y = x$', 
        '$y = 2x$'
    ], 
    loc='upper left'
)

plt.show()
