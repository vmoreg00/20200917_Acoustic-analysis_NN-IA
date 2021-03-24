#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jan 22 11:59:10 2021

@author: msi
"""

import sqlite3
import joblib
import pandas as pd
import numpy as np
import librosa
import os
import sys
import re
import gc
from sklearn.preprocessing import OneHotEncoder
from tensorflow.keras.applications.resnet_v2 import ResNet50V2

# Cargar funciones
sys.path.insert(0, "./src/")
import utility_functions as uf

def main():
    # Create results directory
    if not os.path.exists("./results/resnet_selections/"):
        print("Creating results directory ('./results/resnet_selections/')")
        os.mkdir("./results/resnet_selections/")

    # Load files list from DB
    print("Retrieving files list")
    conn = sqlite3.connect('./data/CarrionCrow_DB.sqlite')
    cur = conn.cursor()
    cur.execute("SELECT * FROM files")
    files = pd.DataFrame(cur.fetchall(),
                         columns=['fileID','loggerID','fileStart','fileEnd',
                                  'location'])
    conn.close(); del(cur)

    # Load trained model
    print("Loading trained model (ResNet50V2)")
    trained_model = ResNet50V2(weights='results/ResNet50V2_best_model.h5',
                               input_shape=(513,534,1), classes=4)
    categories = ('chicks', 'crow', 'flight', 'noise')

    # Iterate through files
    for idx, row in files.iterrows():
        if not os.path.exists("data/audios/" + str(int(row['fileID'])) + ".wav"):
            continue
        if re.search('1001$', row['location']):
            continue
        print("Reading file " + str(int(row['fileID'])) + ".wav ...")
        if row['fileEnd'] - row['fileStart'] < 15:
            print("\tW: file too short (less than 15 seconds). SKIPPED!")
            continue
        hist_csv_file = 'results/resnet_selections/file_' + \
            str(int(row['fileID'])) +'.csv'
        if not os.path.exists(hist_csv_file):
            # Generate 5s spectrograms
            audio_df = uf.get_windows_table("data/audios/" + str(int(row['fileID'])) + ".wav",
                                            int(row['fileID']), 5)
            try:
                esp = uf.crear_espectrogramas(audio_df, "tmp.h5",
                                              win_length=300, hop_length=150,
                                              spectrogram_dimensiones=(513,534,1))
            except:
                print("\tWARNING: Unable to parse this file")
                os.remove('tmp.h5')
                gc.collect()
                continue
            # Generate dataset
            onehotencoder = OneHotEncoder().fit(np.reshape(esp.Sonido.values,
                                                           (-1,1)))
            new_data = uf.DataGenerator(data_path="tmp.h5",
                                        dataframe=esp,
                                        x_col_name='Nombre_fragmento',
                                        y_col_name='Sonido',
                                        onehotencoder=onehotencoder,
                                        batch_size=3,
                                        shape=(513,534,1),
                                        shuffle= False)
            # Predict
            predictions = trained_model.predict(new_data, verbose=1)
            # Get labels
            labels = []
            for i in range(0, len(predictions)):
                lbl = np.where(predictions[i] == max(predictions[i]))[0][0]
                labels.append(categories[lbl])
            while len(labels) < esp.shape[0]:
                labels.append("")
            esp['Sonido'] = labels
            # Write
            with open(hist_csv_file, mode='w+') as f:
                esp.to_csv(f)
            # Remove tmp files
            os.remove('tmp.h5')
            gc.collect()
        print("\tDONE!")
if __name__ == '__main__':
    main()
