#!/bin/bash
tail -n +2 ../00_CarrionCrow_DB/data/files.csv | \
  sed 's/\ /\\ /g' | \
  awk '
  BEGIN{FS=";"}
  {
    print "sshpass -f \"pswd.txt\" scp -P 50055 "$5".wav victorm@vision.unileon.es:~/crow/selector/data/audios/"$1".wav"
  }' | sh;

declare -a LOCATIONS=($(
  tail -n +2 ../00_CarrionCrow_DB/data/files.csv | \
    sed 's/\ /\\ /g' | \
    awk '
    BEGIN{FS=";"}
    {
      print "sshpass -f \"pswd.txt\" scp -P 50055 "$5".wav victorm@vision.unileon.es:~/crow/selector/data/audios/"$1".wav;"
    }'
  ))
IFS=";"
for exp in ${LOCATIONS[@]}; do
    sh $exp &
done
