#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Nov 18 11:34:26 2020

@author: msi
"""
import joblib
import pandas as pd
import librosa
import h5py
import os
from sklearn.preprocessing import OneHotEncoder
from tensorflow.keras.utils import Sequence
from tensorflow.keras.optimizers import Adam
import numpy as np
from tensorflow.keras.applications.resnet_v2 import ResNet50V2
from tensorflow.keras import Input
from tensorflow.keras.callbacks import ModelCheckpoint, LearningRateScheduler

##############################################################################
###                             CLASSES                                    ###
##############################################################################
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

##############################################################################
###                                  MAIN                                  ###
##############################################################################
def main():
    if not os.path.isdir('results'):
        os.mkdir('results')

    #Lee los datos de los conjuntos test y train
    train_data = pd.read_csv('data/spectrograms_train.csv')
    test_data = pd.read_csv('data/spectrograms_test.csv')
    
    #Dirección de los archivos con los espectrogramas
    data_train_path = 'data/train_db.h5'
    data_test_path = 'data/test_db.h5'
    
    #Número de espectrogramas que se usarán para alimentar al modelo en cada epoch.
    batch_size = 3
    
    onehotencoder = OneHotEncoder().fit(np.reshape(train_data.Sonido.values, (-1,1)))
    
    print(onehotencoder.categories_)
    
    shape = (513,534,1)
    
    training_generator = DataGenerator(data_path= data_train_path, 
                                       dataframe= train_data, 
                                       x_col_name= 'Nombre_fragmento',
                                       y_col_name= 'Sonido', 
                                       onehotencoder= onehotencoder,
                                       batch_size=batch_size,
                                       shape=shape, 
                                       shuffle= True)
    validation_generator = DataGenerator(data_path = data_test_path, 
                                         dataframe= test_data, 
                                         x_col_name= 'Nombre_fragmento',
                                         y_col_name= 'Sonido',
                                         onehotencoder= onehotencoder,
                                         batch_size=batch_size,
                                         shape=shape,
                                         shuffle= False)
    
    classes=len(np.unique(train_data.Sonido.values))
    
    input_tensor = Input(shape=shape)
    
    # Metodo que cada 15 epoch divide el learning por 10 para poderse acercar al error optimo.
    def decay_schedule(epoch, lr):
        if (epoch % 15 == 0) and (epoch != 0):
            lr = lr * 0.1
        return lr
    
    lr_scheduler = LearningRateScheduler(decay_schedule)
    
    # En el ResNet50V2_best_model.h5 se almacena el mejor modelo de entre todos los epoch de entrenamiento
    checkpoint = ModelCheckpoint('results/ResNet50V2_best_model.h5',
                                 monitor='val_accuracy',
                                 save_best_only=True,
                                 mode='auto')
    #csv_logger = CSVLogger("Results_one_file/Effnet_relative_history_log.csv", append=True)
    
    # Definición de la red neuronal ResNet50
    model = ResNet50V2(weights=None, classes=classes,
                       input_tensor=input_tensor)
    
    # Se usa el optimizador Adam, y se iniciará por un learning_rate de 0.1
    adam_optimizer = Adam(learning_rate=0.1) #0.00005
    
    model.compile(adam_optimizer, "categorical_crossentropy", ["accuracy"])
    
    # Entrenamiento del modelo
    history = model.fit(training_generator,
                        validation_data=validation_generator,
                        epochs=50,
                        callbacks=[checkpoint, lr_scheduler])
    
    # Almacenar el historial de entrenamiento
    hist_df = pd.DataFrame(history.history) 
    hist_csv_file = 'results/ResNet50V2_historial_de_entrenamiento.csv'
    with open(hist_csv_file, mode='w') as f:
        hist_df.to_csv(f)

if __name__ == "__main__":
    main()