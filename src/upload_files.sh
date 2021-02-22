#!/bin/bash
while getopts 1:2: option
do
  case "${option}"
    in
    1) ID1=${OPTARG};;
    2) ID2=${OPTARG};;
  esac
done
ID1=$(grep -n ^$ID1 ../00_CarrionCrow_DB/data/files.csv | cut -f 1 -d ":")
ID2=$(grep -n ^$ID2 ../00_CarrionCrow_DB/data/files.csv | cut -f 1 -d ":")
ID2=$(($ID2 - $ID1 + 1))

tail -n +$ID1 ../00_CarrionCrow_DB/data/files.csv | head -n $ID2 \
  | sed 's/\ /\\ /g' \
  | awk '
    BEGIN{FS=";"}
    {
      print "sshpass -f \"pswd.txt\" scp -P 50055 "$5".wav victorm@vision.unileon.es:~/crow/selector/data/audios/"$1".wav"
    }' \
  | sh;
