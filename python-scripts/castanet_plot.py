# CastANet - castanet_plot.py

import io
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from matplotlib.ticker import MaxNLocator


def initialize():
  plt.style.use('classic')


def draw(history, epochs, title, x_range, t_name, v_name):
    plt.clf()
    t_values = history[t_name]
    v_values = history[v_name]
    plt.grid(True)
    plt.plot(x_range, t_values, 'b-o', label='Training')
    plt.plot(x_range, v_values, 'g-s', label='Validation')
    plt.xlabel('Epoch')
    plt_ylabel = 'Percentage'
    plt_title = 'Loss'
    legend_pos = 'upper right'
    padding = 0.1
    if title == 'Loss':
        plt.xlim(-padding, epochs + padding)
    else:
        legend_pos = 'lower right'
        plt_title = 'Accuracy'
        plt.axis([-padding, epochs + padding, 0, 1])
    plt.ylabel(plt_ylabel)
    plt.title(plt_title)
    ax = plt.gca()
    ax.autoscale(enable=True, axis='x', tight=False)
    ax.xaxis.set_major_locator(MaxNLocator(integer=True))
    plt.legend(loc=legend_pos)
    plt.draw()
    plot_data = io.BytesIO()
    plt.savefig(plot_data, format='png')
    return plot_data
