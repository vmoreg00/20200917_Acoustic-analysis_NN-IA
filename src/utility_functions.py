#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jan 22 20:36:17 2021

@author: msi
"""

import librosa
import pandas as pd
import numpy as np
import h5py
import gc
from tqdm import tqdm
from tensorflow.keras.utils import Sequence

def get_windows_table(audio_file, audio_ID, wl=5):
    audio_duration = librosa.get_duration(filename = audio_file)
    audio_duration_int = int(audio_duration)
    audio_windows_start = [w for w in range(0, audio_duration_int, wl)]
    if(audio_windows_start[-1] + wl > audio_duration):
        audio_windows_start.remove(audio_windows_start[-1])
    audio_windows_ID = [audio_ID for i in audio_windows_start]
    audio_df = pd.DataFrame(data = {'ID':audio_windows_ID,
                                    'Archivo':[audio_file for i in audio_windows_start],
                                    'Segundo':audio_windows_start,
                                    'Sonido':['' for i in audio_windows_start]})
    return audio_df

def extraer_segmento_audio(audio_completo, sample_rate, segundo, longitud_segmento):
    start = int(round(sample_rate*segundo))
    end = int(round(start+(longitud_segmento*sample_rate)))
    return audio_completo[start:end]

def crear_espectrogramas(df_original, f_name_db, sr=16000, n_fft=1024, 
                         window='hannig', win_length=400, hop_length=160,
                         spectrogram_dimensiones=(513, 501, 1)):

    # Nueva tabla donde se guardará la información de los 
    # espectrogramas generados
    df = pd.DataFrame(columns=['Archivo_original', 'Nombre_fragmento', 'Sonido', 'Segundo'])
    
    #first_iteration = True
    i=0
    index = 0
    lista_nombres = []
    
    # Recorre la tabla original fila a fila
    for indice_fila, fila in tqdm(df_original.iterrows()):
        # El nuevo fragmento se guardará con el nombre concatenado del 
        # archivo original junto al segundo del fragmento analizado.
        #segment_name = os.path.splitext(fila.Archivo)[0]+'_'+str(int(round(fila.Segundo)))
        segment_name = str(fila.ID) + '_' + str(int(round(fila.Segundo)))
        
        #Comprueba que el nombre no esté repetido
        if segment_name not in lista_nombres:

            lista_nombres.append(segment_name)

            # Se lee el audio original si es distinto al anterior
            audio, sample_rate = librosa.load(fila.Archivo, 
                                              offset = fila.Segundo,
                                              duration = 5,
                                              res_type='kaiser_fast', 
                                              sr=sr)

            df.at[index, 'Archivo_original'] = fila.Archivo
            df.at[index, 'Nombre_fragmento'] = segment_name
            df.at[index, 'Sonido'] = fila.Sonido
            df.at[index, 'Segundo'] = fila.Segundo
            
            # Creación de espectrogramas
            spectrogram = np.abs(librosa.stft(audio, n_fft=n_fft, 
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

# Metodo utilizado para entrenar al modelo mediante batches
class DataGenerator(Sequence): 
    'Generates data for Keras'
    def __init__(self, data_path, dataframe, x_col_name, y_col_name, onehotencoder, batch_size=32, shape=(513,401,1),
                 shuffle=True):
        'Initialization'
        self.shape = shape
        self.batch_size = batch_size
        self.dataframe = dataframe
        self.x_col_name = x_col_name
        self.y_col_name = y_col_name
        #self.n_classes = n_classes
        self.shuffle = shuffle
        self.on_epoch_end()
        self.onehotencoder = onehotencoder
        #self.table = table
        self.data_path = data_path

    def __len__(self):
        'Denotes the number of batches per epoch'
        return int(np.floor(len(self.indexes) / self.batch_size))
    
    def __getitem__(self, index):
        'Generate one batch of data'
        
        indexes = self.indexes[index*self.batch_size:(index+1)*self.batch_size]        
        X, y = self.__data_generation(self.dataframe.loc[indexes])

        return X, y

    def on_epoch_end(self):
                   
        self.indexes = list(self.dataframe.index)
        
        'Updates indexes after each epoch'
        if self.shuffle == True:
            np.random.shuffle(self.indexes)

    def __data_generation(self, batch_df):
        'Generates data containing batch_size samples' # X : (n_samples, *dim, n_channels)
        
        # Initialization
        X = np.empty((self.batch_size, *self.shape))   #tal vez hay que reemplazar batch_size por len(batch_df)
        y = []
        
        # Generate data
        with h5py.File(self.data_path,'r') as h5f:
            for i, (r_i, row) in enumerate(batch_df.iterrows()):         
                X[i,] = h5f[row[self.x_col_name]][:]
                y.append(row[self.y_col_name])

        y = self.onehotencoder.transform(np.reshape(y, (-1,1))).toarray()
        return X, y
