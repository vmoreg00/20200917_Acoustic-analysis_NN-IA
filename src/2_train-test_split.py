#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Nov  5 16:41:32 2020

@author: msi
"""
import joblib
import h5py
import os
import pandas as pd
from tqdm import tqdm
import numpy as np
import gc
import librosa
from sklearn.model_selection import train_test_split

def extraer_segmento_audio(audio_completo, sample_rate, segundo, longitud_segmento):
    return audio_completo[sample_rate*segundo:(sample_rate*segundo)+(longitud_segmento*sample_rate)]

def crear_espectrogramas(df_original, f_name_db, sr=16000, n_fft=1024, 
                         window='hannig', win_length=400, hop_length=160,
                         spectrogram_dimensiones=(513, 501, 1)):

    # Nueva tabla donde se guardará la información de los 
    # espectrogramas generados
    df = pd.DataFrame(columns=['Archivo', 'Nombre_fragmento', 'Sonido', 'Segundo'])
    
    #first_iteration = True
    i=0
    index = 0
    lista_nombres = []
    last_audio = ""
    
    # Recorre la tabla original fila a fila
    for indice_fila, fila in tqdm(df_original.iterrows()):

        # El nuevo fragmento se guardará con el nombre concatenado del 
        # archivo original junto al segundo del fragmento analizado.
        #
        # Por ejemplo si el archivo es audio_yellow_1 y trabajamos con el
        # segundo 22 se audio, entonces el nombre de ese fragmento
        # será audio_yellow_1_22
        segment_name = str(fila.ID) + '_' + str(int(round(fila.Segundo)))
        
        #Comprueba que el nombre no esté repetido
        if segment_name not in lista_nombres:

            lista_nombres.append(segment_name)

            # Se lee el audio original si es distinto al anterior
            if last_audio != fila.Archivo:
                audio, sample_rate = librosa.load(fila.Archivo, 
                                                  res_type='kaiser_fast', 
                                                  sr=sr)
            else:
                last_audio = fila.Archivo
                
            # Con 5 segundos se obtiene el 'spectrogram_dimensiones' 
            # si se modifica este valor tambien debe cambiarse el de 
            # spectrogram_dimensiones
            seg_audio = extraer_segmento_audio(audio, sample_rate, 
                                               fila.Segundo, 5)
            # audio=0

            df.at[index, 'Archivo'] = fila.Archivo
            df.at[index, 'Nombre_fragmento'] = segment_name
            df.at[index, 'Sonido'] = fila.Sonido
            df.at[index, 'Segundo'] = fila.Segundo
            
            # Creación de espectrogramas
            spectrogram = np.abs(librosa.stft(seg_audio, n_fft=n_fft, 
                                              window='hanning', 
                                              win_length=win_length, 
                                              hop_length=hop_length))
            spectrogram_db = librosa.power_to_db(spectrogram, ref=np.max)

            # Se agrega una dimensión extra debido a que la red neuronal
            # necesita imagenes de 3 dimensiones.
            spectrogram_db = np.expand_dims(spectrogram_db, axis=2)

            # Almacenar espectrogramas en archivo .h5.
            # El nombre de cada espectrograma en el archivo será 'segment_name'
            with h5py.File(f_name_db,'a') as f1:
                f1.create_dataset(segment_name, spectrogram_dimensiones, 
                                  dtype='f', data=spectrogram_db)

            index+=1
            i+=1
            # Cada 20 iteraciones se limpia la memoria ram 
            if i==20:
                gc.collect()
                i=0
    return df

def main():
    # Read dataset
    datos = pd.read_csv('data/calls_dataset.csv')
    datos = datos.rename(columns={'callID':'ID', 'location':'Archivo', 
                                  'start':'Segundo', 'label':'Sonido'})
    # Train-test split; train = 70%; test = 30%
    train, test = train_test_split(datos, test_size=0.3, 
                                   stratify=datos['Sonido'])
    
    # Train spectrograms database
    print('Creando espectrogramas del conjunto de train...')
    train_table = crear_espectrogramas(train, 'data/train_db.h5' )
    #Guardar tabla resultante
    train_table.to_csv('data/spectrograms_train.csv')
    gc.collect()
    
    # Test spectrograms database
    print('Creando espectrogramas del conjunto de test...')
    test_table =crear_espectrogramas(test, 'data/test_db.h5' )
    #Guardar tabla resultante
    test_table.to_csv('data/spectrograms_test.csv')
    gc.collect()
if __name__ == '__main__':
    main()