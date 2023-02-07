#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Apr  6 11:31:11 2022

@author: msi
"""

import sqlite3
import joblib
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import librosa
import os
import sys
import re
import gc
from sklearn.metrics import confusion_matrix
from sklearn.metrics import ConfusionMatrixDisplay
from sklearn.metrics import classification_report
from sklearn.metrics import balanced_accuracy_score
from sklearn.preprocessing import OneHotEncoder
from tensorflow.keras.applications.resnet_v2 import ResNet50V2

sys.path.insert(0, "./src/")
import utility_functions as uf

def main():
    
    # Create results directory
    if not os.path.exists("./results/accuracy/"):
        print("Creating results directory ('./results/accuracy/')")
        os.mkdir("./results/accuracy/")
        
    # Load trained model
    print("Loading trained model (ResNet50V2)")
    trained_model = ResNet50V2(weights='results/ResNet50V2_best_model.h5',
                               input_shape=(513,534,1), classes=4)
    categories = ('chicks', 'crow', 'flight', 'noise')
    print("\tLoaded!")
    
    # Load datasets
    data_test_path = 'data/test_db.h5'
    test_data = pd.read_csv('data/spectrograms_test.csv')
    train_data = pd.read_csv('data/spectrograms_train.csv')
    
    # Encoder
    onehotencoder = OneHotEncoder().fit(np.reshape(test_data.Sonido.values, (-1,1)))
    print(onehotencoder.categories_)
    
    validation_generator = uf.DataGenerator(data_path = data_test_path, 
                                            dataframe= test_data, 
                                            x_col_name= 'Nombre_fragmento',
                                            y_col_name= 'Sonido',
                                            onehotencoder= onehotencoder,
                                            batch_size=3,
                                            shape=(513,534,1),
                                            shuffle= False)
    # Predict
    predictions = trained_model.predict(validation_generator, verbose=1)
    pd.DataFrame(np.asarray(predictions), columns=categories).to_csv("results/accuracy/test_predictions.csv")
    
    # Confusion matrix
    true_lables = test_data.Sonido
    pred_labels = []
    for i in range(0, len(predictions)):
        lbl = np.where(predictions[i] == max(predictions[i]))[0][0]
        pred_labels.append(categories[lbl])
    while len(pred_labels) < test_data.shape[0]:
        pred_labels.append("")
    
    cm = confusion_matrix(true_lables, pred_labels, normalize = "true")
    pd.DataFrame(np.asarray(cm), columns=categories, index=categories).to_csv(
        "results/accuracy/confusion_matrix.csv")
    
    cm_display = ConfusionMatrixDisplay(cm, display_labels=categories)
    cm_display.plot(cmap = "Blues")
    cm_display.figure_.savefig("results/accuracy/confusion_matrix.png", dpi = 300)
    
    clas_report = classification_report(true_lables, pred_labels,
                                        labels = categories)
    with open("results/accuracy/classification_metrics.txt", mode = "w+") as f:
        f.write(clas_report)
    
    # Barplot of class proportion in train and test ===
    # Compute proportion
    prop_test = test_data.groupby('Sonido')['Sonido'].aggregate(func = len)
    prop_test2 = prop_test/sum(prop_test)
    prop_train = train_data.groupby('Sonido')['Sonido'].aggregate(func = len)
    prop_train2 = prop_train/sum(prop_train)
    # X positions
    r1 = np.arange(len(prop_test)) + 0.25/2
    r2 = [x - 0.25 for x in r1]
    # Bars
    plt.bar(r2, prop_train2, color='#E41A1C', width=.25, edgecolor='white', label='train')
    plt.bar(r1, prop_test2, color='#377EB8', width=.25, edgecolor='white', label='test')
    # Add xticks on the middle of the group bars
    plt.xlabel('Label', fontweight='bold')
    plt.ylabel('Proportion of classes', fontweight='bold')
    plt.xticks([r + 0.25 for r in range(len(categories))], categories)
    # Text on the top of each bar
    for i in range(len(r1)):
        plt.text(x = r1[i], y = prop_test2[i]+0.01, horizontalalignment='center',
                 s = str(prop_test[i]), size = 7)
        plt.text(x = r2[i], y = prop_train2[i]+0.01, horizontalalignment='center',
                 s = str(prop_train[i]), size = 7)
    # Create legend & Save graphic
    plt.legend()
    plt.savefig("results/accuracy/classes_train-test_proportions.png", dpi = 300)


if __name__ == '__main__':
    main()