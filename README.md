# Classification of corvid sound
  * **Author**: Víctor Moreno-González <vmorg@unileon.es>
  * **Date**: 2020-09-17

Automatic crow vocalization recognition has been a tough 
task since it is very difficult to differenciate correctly 
those vocalizations from the background noise. Thus, with 
the help of the GVIS group from the University of León, we 
will use a new methodology for automatic selection of crow 
vocalizations in the whole dataset (up to 3000 H). Then, 
we will use this dataset to perform an objective 
classification of crow vocalizations.

To do this, we will use a subset in of XXX vocalizations 
recorded from YYY hours

## Stage 0 -- Vocalization extraction
In past analysis, I have extracted some vocalizations as 
well as environment, flight and chick noises (Table 1).
Due to the large ammount of noises, I have removed
randomly 1500 of them in order to equilibrate them
with the number of 'crow' clips.

Table 1: Number of clips and seconds per type of sound
| Sound   | Number | Seconds | N in test | N in train |
|---------|--------|---------|-----------|------------|
| Crow    |  1053  |  5265   |    316    |    737     |
| Noise   |  2527  |  12635  |    308    |    719     |
| Flights |  340   |  1700   |    102    |    283     |
| Chicks  |  233   |  1164   |     70    |    163     |


In order to create a better model, the start of crow calls 
has been randomly reduced from 0 to 4.5 seconds. In this 
way the crow calls clips will contain entire and 
non-entire calls.

## Stage 1 -- Train a model for crow recognition
In order to train the neural network, it is necessary to
split the original dataset into train and test subsets.
Following the recomendations of GVIS group, the sizes
of each subset will be 70 and 30 % respectively.

After train/test split, audio clips will be read and
spectrograms will be created with the following 
hyperparameters:

  * sampling rate = 16000 Hz
  * n_fft = 1024
  * win_length = 300
  * hop_length = 160
  * spectrogram dimensions = (513, 501, 1)

## Stage 2 -- Use the model to recognize all crow vocalizations

## Stage 3 -- Classify crow vocalizations
