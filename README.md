# Classification of corvid sound (part 1)
  * **Author**: Víctor Moreno-González <vmorg@unileon.es>
  * **Date**: 2020-09-17

# Table of content
1. [Introduction](#introduction)
  1. [Motivation](#motivation)
  1. [Aims](#aims)
1. [Procedure](#procedure)
  1. [Stage 0 -- Vocalization extraction](#stage-0-vocalization-extraction)
  1. [Stage 1 -- Train a model for crow recognition](#stage-1-train-a-model-for-crow-recognition)
  1. [Stage 2 -- Use the model to select crow vocalizations](#stage-2-use-the-model-to-select-crow-vocalizations)
  1. [Stage 3 -- Manual selection of crow calls](#stage-3-manual-selection-of-crow-calls)
1. [What's next](#whats-next)
1. [Future Steps](#future-steps)

# Introduction
## Motivation
Automatic crow vocalization recognition has been a tough
task since it is very difficult to differenciate correctly
those vocalizations from the background noise. Thus, with
the help of the GVIS group from the University of León, we
will use a new methodology for automatic selection of crow
vocalizations in the whole dataset (up to 3000 H). Then,
we will use this dataset to perform an objective
classification of crow vocalizations.

## Aims
...

----

# Procedure

## Stage 0. Vocalization extraction
In past analysis, I have extracted some vocalizations as
well as environment, flight and chick noises (Table 1).
For a better training of the model, I have performed
a data augmentation in which I have triplicated the number
of crows vocalizations by substracting 0.5-2.45 s and
2.55-4.5 s to every carrion crow call. In this step,
I have ensure that all clips that contain the
same vocalizations (because of data augmentation
procedure) are in the same set (train or test) to
avoid over fitting in the Neural Network training.

This task has been conducted in R
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

## Stage 1. Train a model for crow recognition
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

## Stage 2. Use the model to select crow vocalizations

In a first approach, I've decided to select manualy the crow
vocalizations as the first detection of 5s-clips is a big effect
that reduces to nearly 10% the ammount of audio to review.

**In process**:

|                               |            |     |
|:------------------------------|:----------:|:---:|
| File IDs parsed               |   1 -- 509 | 509 |
| File IDs uploaded to server   |     --     | 0   |
| File IDs waiting to be parsed | 510 -- 723 | 214 |
| File IDs corrupted            | 202        | 1   |
| File IDs too short            | 216 -- 218 | 3   |
| Total files                   |     --     | 723 |


### Real accuracy of the model check

**_TO BE DONE_**

It is important to know the real accuracy value by checking some
random files. In this way, it can be addressed if this methodology
is useful for flights and nest visits prediction.

## Stage 3. Manual selection of crow calls

  * How to differenciate tagged crow from others
  * How many time does it saves
  * Process description (R; `src/5_select-vocalizations.R`)

**In process**:

|                               |                      |          |
|:------------------------------|:--------------------:|:--------:|
| File IDs parsed               | 1 -- 50, 100 -- 200  | 151      |
| File IDs recognized by NN     | 51 -- 99, 201 -- 509 | 358      |
| File IDs waiting to be parsed | 510 -- 723           | 214      |
| Total files                   |        --            | 723      |
| Vocalizations                 |        --            | 9127     |
| Spent time                    | 53070 s / 88 files   | 603 s/f  |

----

## What's next
After manual selection has been performed, another
[project](../20210217_Carrion-crow_Vocal-repertoire/README.md)
was created to classify carrion vocalizations.

-----
## Questions to be addressed -- future steps
  - How many time ResNet50v2 saves (a lot, I know...)
    (Stage 3)
  - How well the model works (stage 2):
    * "Real" accuracy of vocalizations
    * "Real" accuracy of chicks (Predictor of nest visits?)
    * "Real" accuracy of flights (Compare with WBF of accelerometer)
  - Circadian rythm of vocalizations: example with three-five crows
    (after stage 3)
  - Classification of vocalizations -- carrion crow vocal repertoire
    (new project)
    * Use PCA-tSNE-DBSCAN instead PCA-KMeans
    * Compare classifications using acoustic features vs. image classification
    * Adecuation of vocal repertoire to Zipf's Law
  - Duets: Study overlapping vocalizations (could inform on the functionality)
    (future project)
