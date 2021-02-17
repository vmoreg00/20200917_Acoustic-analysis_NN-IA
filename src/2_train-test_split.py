#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Nov  5 16:41:32 2020

@name: 2_train-test_split.py
@author: Andrés Vasco
@modified: Víctor Moreno González <vmorg@unileon.es>
@description: Split the dataset into train (70%) and test (30%) and construct
              the spectrograms, which are stored in *.h5 files.
@run: python 2_train-test_split.py
"""

import joblib
import h5py
import os
import sys
import pandas as pd
from tqdm import tqdm
import numpy as np
import gc
import librosa
from sklearn.model_selection import train_test_split

# Cargar funciones
sys.path.insert(0, "./src/")
import utility_functions as uf

##############################################################################
###                                  MAIN                                  ###
##############################################################################
def main():
    # Read dataset
    datos = pd.read_csv('data/calls_dataset.csv')
    split = datos['train_test_split']
    datos.drop('train_test_split', inplace=True, axis=1)
    datos = datos.rename(columns={'callID':'ID', 'location':'Archivo', 
                                  'start':'Segundo', 'label':'Sonido'})
    # Train-test split; train = 70%; test = 30%
    train = datos[split=="train"]
    test = datos[split=="test"]
    # Train spectrograms database
    print('Creando espectrogramas del conjunto de train...')
    train_table = uf.crear_espectrogramas(train, 'data/train_db.h5',
                                          win_length = 300, hop_length=150,
                                          spectrogram_dimensiones=(513,534,1))
    #Guardar tabla resultante
    train_table.to_csv('data/spectrograms_train.csv')
    gc.collect()
    
    # Test spectrograms database
    print('Creando espectrogramas del conjunto de test...')
    test_table = uf.crear_espectrogramas(test, 'data/test_db.h5',
                                         win_length = 300, hop_length=150,
                                         spectrogram_dimensiones=(513,534,1))
    #Guardar tabla resultante
    test_table.to_csv('data/spectrograms_test.csv')
    gc.collect()
    
    
if __name__ == '__main__':
    main()
