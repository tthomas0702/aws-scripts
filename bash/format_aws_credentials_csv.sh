#!/bin/bash

# used to format the credentials CSV file that is downloaded from the AWS console and make easier to read
# usage:
# format_credentials_csv.sh <file.csv> 

 column -t -s ',' $1
