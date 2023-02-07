#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Apr  6 11:31:11 2022

@author: msi
"""

import sqlite3
import pandas as pd
import numpy as np
import librosa
import soundfile as sf
import os
import sys
import re
import gc
from random import sample
from random import seed

sys.path.insert(0, "./src/")
import utility_functions as uf
seed(123)

def main():
    # Create results directory
    if not os.path.exists("./results/accuracy/"):
        print("Creating results directory ('./results/accuracy/')")
        os.mkdir("./results/accuracy/")
    # Retrieving files info
    print("Retrieving files info")
    conn = sqlite3.connect('../00_CarrionCrow_DB/data/CarrionCrow_DB.sqlite')
    cur = conn.cursor()
    cur.execute("SELECT * FROM files")
    files = pd.DataFrame(cur.fetchall(),
                         columns=['fileID','loggerID','fileStart','fileEnd',
                                  'location','comments'])
    conn.close(); del(cur)
    # Retrieve info
    print("Retrieving selections")
    filesRN = [f for f in os.listdir("results/resnet_selections") if 
               f.startswith("file")]
    # Select random windows
    rwinds = list()
    print("Selecting random windows")
    for i in range(445, len(filesRN)):
        filename = "results/resnet_selections/" + filesRN[i]
        fid = int(filesRN[i].split(".")[0].split("_")[1])
        wavname = list(files.iloc[:,4])[np.where(files.fileID == fid)[0][0]] + ".wav"
        sels = pd.read_csv(filename, index_col = 0)
        if(len(sels.index) < 10):
            continue
        idx = sample(range(len(sels.index)-3), 5)
        for j in idx:
            try:
                audio, sample_rate = librosa.load(wavname, 
                                                  offset = sels.Segundo[j],
                                                  duration = 5,
                                                  res_type='kaiser_fast', 
                                                  sr=16000)
            except:
                print("audio " + wavname, " skipped")
                continue
            else:
                sf.write("results/accuracy/" + filesRN[i].split(".")[0] + "_" + \
                         str(j) + "_" + sels.Sonido[j] + ".wav",
                         audio, sample_rate)
                rwinds.append([fid, j, sels.Sonido[j], ""])
    rwinds = pd.DataFrame(rwinds, columns = ["fileID", "window", "ResNet_label",
                                             "checked_label"])
    rwinds.to_csv("./results/accuracy/00_labels.csv")

if __name__ == '__main__':
    main()