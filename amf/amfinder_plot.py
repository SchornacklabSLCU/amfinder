# AMFinder - amfinder_plot.py
#
# MIT License
# Copyright (c) 2021 Edouard Evangelisti, Carl Turner
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

"""
Plots accuracy and loss after training.

Functions
-----------

:function initialize: Defines plot style.
:function draw: draws a loss/accuracy plot.

"""



import io
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as pyplot
from matplotlib.ticker import MaxNLocator



def initialize():
    """ Defines graph style. """

    pyplot.style.use('classic')



def draw(history, epochs, title, x_range, t_name, v_name):
    """ """

    pyplot.clf()

    pyplot.grid(True)

    t_values = history[t_name]
    v_values = history[v_name]
    pyplot.plot(x_range, t_values, 'b-o', label='Test set')
    pyplot.plot(x_range, v_values, 'g-s', label='Validation set')

    pyplot.xlabel('Epoch')
    pyplot.ylabel('Value')
    pyplot.title(title)

    padding = 0.1
    legend_pos = 'upper right'

    if title[0:4] == 'Loss':

        pyplot.xlim(-padding, epochs + padding)

    else:

        legend_pos = 'lower right'
        pyplot.axis([-padding, epochs + padding, 0, 1])

    axes = pyplot.gca()
    axes.autoscale(enable=True, axis='x', tight=False)
    axes.xaxis.set_major_locator(MaxNLocator(integer=True))

    pyplot.legend(loc=legend_pos)
    pyplot.draw()

    plot_data = io.BytesIO()
    pyplot.savefig(plot_data, format='png')

    return plot_data
