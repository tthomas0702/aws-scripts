#!/bin/bash

# used to format the credentials file annd make easier to read
# usage:
# format_credentials_csv.sh <file.csv> 

 column -t -s ',' $1
