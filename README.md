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
For a better training of the model, I have performed
a data augmentation in which I have triplicate the number
of crows vocalizations by substracting 0.5-2.45 s and
2.55-4.5 s to every carrion crow call. In this step,
I have ensure that all clips that contain the
same vocalizations (because of data augmentation
procedure) are in the same set (train or test) to
avoid over fitting in the Neural Network training.

This stage has been conducted in R
(see [1_vocalization-export.R](src/1_vocalization-export.R))
for more information.

Table 1: Number of clips and seconds per type of sound

| Sound   | Number | Seconds | N in test | N in train |
|---------|--------|---------|-----------|------------|
| Crow    |  3159  |  15755  |    948    |   2211     |
| Noise   |  2527  |  12635  |    758    |   1769     |
| Flights |  340   |   1700  |    102    |    283     |
| Chicks  |  233   |   1164  |     70    |    163     |


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
  * hop_length = 150 (=50 %)

Given those hyperparamenter, spectrograms dimensions
should be:

  * spectrogram dimensions = (513, 534, 1)


The Neural Network ResNet50_v2 has been trained with a
learining rate of 0.1 and 80 epochs, using Adam optimizer.
After several days of training in the INCIBE server,
the model has been fitted with a 96.75 % of accuracy
(see [`result history`](results/ResNet50V2_historial_de_entrenamiento.csv)).
In a first check it seems that, for crow sounds, there are
very few false negatives. The problem arrise for false positives
for crow sounds: in the first files of recording, when the crow
rubs the logger, sound produced by the rubber are detected as crow sounds.

## Stage 2 -- Use the model to recognize all crow vocalizations

In a first approach, I've decided to select manualy the crow
vocalizations as the first detection of 5s-clips is a big effect
that reduces to nearly 10% the ammount of audio to review.

----
**In process**:

|                               |                        |     |
|:------------------------------|:----------------------:|:---:|
| File IDs parsed               | 1 -- 320, 395 -- 420   | 346 |
| File IDs uploaded to server   | --                     | 0   |
| File IDs waiting to be parsed | 321 -- 394, 421 -- 723 | 377 |
| File IDs corrupted            | 202                    | 1   |
| File IDs too short            | 216 -- 218             | 3   |
| Total files                   |     --                 | 723 |

-----

## Stage 3 -- Manual selection of vocalizations recognized by ResNet

  * How to differenciate tagged crow from others
  * How many time does it saves
  * Process description (R; `src/5_select-vocalizations.R`)

----
**In process**:

|                               |                                          |          |
|:------------------------------|:----------------------------------------:|:--------:|
| File IDs parsed               | 1 -- 3, 10 -- 36, 100 -- 112             | 43       |
| File IDs recognized by NN     | 4 -- 9, 37 -- 99, 113 -- 320, 395 -- 420 | 303      |
| File IDs waiting to be parsed | 321 -- 394, 421 -- 723                   | 377      |
| Total files                   |        --                                | 723      |
| Vocalizations                 |        --                                | 2949     |
| Spent time                    | 8349 s / 8 files                         | 1043 s/f |

-----
## Stage 3 -- Classify crow vocalizations
