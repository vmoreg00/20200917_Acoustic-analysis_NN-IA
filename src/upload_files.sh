#!/bin/bash
while getopts 1:2:3: option
do
  case "${option}"
    in
    1) ID1=${OPTARG};;
    2) ID2=${OPTARG};;
    3) CROW=${OPTARG};;
  esac
done

# Compute lines of files.csv to be read
ID1=$(grep -n ^$ID1 ../00_CarrionCrow_DB/data/files.csv | cut -f 1 -d ":")
ID2=$(grep -n ^$ID2 ../00_CarrionCrow_DB/data/files.csv | cut -f 1 -d ":")
ID2=$(($ID2 - $ID1 + 1))

# Create the new directory
if [ ! -d /media/msi/TOSHIBA\ EXT/$CROW ]; then
    mkdir /media/msi/TOSHIBA\ EXT/$CROW;
fi;

# Downsample and rename wav files
tail -n +$ID1 ../00_CarrionCrow_DB/data/files.csv | head -n $ID2 \
  | sed 's/\ /\\ /g' \
  | awk -v cr=$CROW ' \
    BEGIN{FS=";"}
    {
      print "sox "$5".wav /media/msi/TOSHIBA\\ EXT/"cr"/"$1".wav rate 22000"
    }' \
  | sh;

# Compress them
zip /media/msi/TOSHIBA\ EXT/$CROW.zip /media/msi/TOSHIBA\ EXT/$CROW/*;

# Upload zip file
sshpass -f "pswd.txt" scp -P 50055 /media/msi/TOSHIBA\ EXT/$CROW.zip \
    victorm@vision.unileon.es:~/crow/selector/data/audios/$CROW.zip;

# Remove temporary files (zip and downsampled wavs)
rm /media/msi/TOSHIBA\ EXT/$CROW.zip
rm /media/msi/TOSHIBA\ EXT/$CROW/*
rmdir /media/msi/TOSHIBA\ EXT/$CROW
