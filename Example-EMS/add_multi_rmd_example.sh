#!/bin/bash
for ((i=24;i<33;i++)); do 
 echo "${i}"
 ./add_rmd_example.sh $i
done
