#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Apr  8 10:42:23 2022

@author: msi
"""

import pandas as pd
import numpy as np
import sys
import os
import gc
import re
import matplotlib.pyplot as plt
from sklearn.metrics import accuracy_score
from sklearn.metrics import confusion_matrix
from sklearn.metrics import ConfusionMatrixDisplay

labels = pd.read_csv("results/accuracy/00_labels_checked.csv")
labels = labels.loc[labels.comment != "corrupt"]
labels = labels.loc[labels.comment != "water sound"]
lbls = list(set(labels.checked_label))
lbls.sort()

accuracy_score(labels.checked_label, labels.ResNet_label)
accuracy_score(labels.checked_label[labels.checked_label == "noise"],
               labels.ResNet_label[labels.checked_label == "noise"])
accuracy_score(labels.checked_label[labels.checked_label == "flight"],
               labels.ResNet_label[labels.checked_label == "flight"])
accuracy_score(labels.checked_label[labels.checked_label == "chicks"],
               labels.ResNet_label[labels.checked_label == "chicks"])
accuracy_score(labels.checked_label[labels.checked_label == "crow"],
               labels.ResNet_label[labels.checked_label == "crow"])


cm = confusion_matrix(labels.checked_label, labels.ResNet_label,
                      normalize = "true")
disp = ConfusionMatrixDisplay(confusion_matrix=cm,
                              display_labels = lbls)
disp.plot()
plt.show()

labels.loc[np.logical_and(labels.ResNet_label == "noise" ,
                          labels.checked_label == "crow"), :]

labels.loc[np.logical_and(labels.ResNet_label == "noise" ,
                          labels.checked_label == "flight"), :]