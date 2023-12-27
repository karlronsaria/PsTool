import sys
import matplotlib.pyplot as plt
import numpy as np

labels = []
sizes = []
title = sys.argv[1] if len(sys.argv) > 1 else ""
unit = sys.argv[2] if len(sys.argv) > 2 else ""

for index in range(3, len(sys.argv) - 1, 2):
    labels.append(sys.argv[index])
    sizes.append(float(sys.argv[index + 1]))

sizes = np.array(sizes)
percent = 100. * sizes / sizes.sum()

labels = [
    '{0}  —  {1:1.2f} {2}  —  {3:1.2f}%'.format(i, j, unit, k)
        for i, j, k in zip(labels, sizes, percent)
]

fig1, ax1 = plt.subplots()

ax1.pie(
    sizes,
    startangle = 90,
    radius = 0.2,
    normalize = True
)

ax1.axis('equal')  # Equal aspect ratio ensures that pie is drawn as a circle.
ax1.set_position([
      0.3
    , 0.085
    , 0.8
    , 0.8
])

plt.legend(
    labels = labels,
    loc = 'center left',
    bbox_to_anchor = (-0.35, 0.5),
    fontsize = 9
)

plt.title(title)
plt.show()
