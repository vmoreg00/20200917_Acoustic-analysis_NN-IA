#!/bin/bash
while getopts 1:2:3: option
do
  case "${option}"
    in
    1) ID1=${OPTARG};;
    2) ID2=${OPTARG};;
    3) CROW=${OPTARG};;
    *) echo "wrong arguments"; exit 1;;
  esac
done

# Compute lines of files.csv to be read
ID1=$(grep -n ^$ID1 ../00_CarrionCrow_DB/data/files.csv | cut -f 1 -d ":")
ID2=$(grep -n ^$ID2 ../00_CarrionCrow_DB/data/files.csv | cut -f 1 -d ":")
ID2=$(($ID2 - $ID1 + 1))

# Create the new directory
if [ ! -d ./tmp ]; then
    mkdir ./tmp;
fi;

# Downsample and rename wav files
tail -n +$ID1 ../00_CarrionCrow_DB/data/files.csv | head -n $ID2 \
  | sed 's/\ /\\ /g' \
  | awk ' \
    BEGIN{FS=";"}
    {
      print "sox "$5".wav ./tmp/"$1".wav rate 22000"
    }' \
  | sh;

# Compress them
tar -czf ./tmp/$CROW.tar.gz ./tmp/*wav;

# Upload zip file
sshpass -f "pswd.txt" scp -P 50055 ./tmp/$CROW.tar.gz \
    victorm@vision.unileon.es:~/crow/selector/data/audios/$CROW.tar.gz;

# Remove temporary files (zip and downsampled wavs)
rm -r ./tmp
