# Classification of corvid sound
  * **Author**: Víctor Moreno-González <vmorg@unileon.es>
  * **Date**: 2020-09-17

Automatic crow vocalization recognition has been a tough task 
since it is very difficult to differenciate correctly those 
vocalizations from the background noise. 
Thus, with the help of the GVIS group from the University of
León, we will use a new methodology for automatic selection
of crow vocalizations in the whole dataset (up to 3000 H).
Then, we will use this dataset to perform an objective
classification of crow vocalizations.

To do this, we will use a subset in of XXX vocalizations
recorded from YYY hours

## Stage 0 -- Vocalization extraction
In past analysis, I have extracted some vocalizations as well
as environment, flight and chick noises. In this dataset,
I have 1053 crow calls, 2527 environment noises,
340 flight noises and 233 chick noises. Having in to
account that the classification is going to be trained
with 5s clips, the dataset is composed by 5265, 12635, 1700
and 1164 seconds, respectively.

In order to create a better model, the start of crow calls
have been randomly reduced from 0 to 4.5 seconds. In this way
the crow calls clips will contain entire and non-entire calls.

## Stage 1 -- Train a model for crow recognition

## Stage 2 -- Use the model to recognize all crow vocalizations

## Stage 3 -- Classify crow vocalizations
