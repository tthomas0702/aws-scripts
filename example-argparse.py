#!/usr/bin/python3

# https://pymotw.com/2/argparse/

import argparse

parser = argparse.ArgumentParser(description='Example with long option names')

parser.add_argument('-n', '--noarg', action="store_true", default=False)
parser.add_argument('-w', '--witharg', action="store", dest="witharg")
parser.add_argument('-w2', '--witharg2', action="store", dest="witharg2", type=int)

#print(parser.parse_args([ '--noarg', '--witharg', 'val', '--witharg2=3' ]))
opt = parser.parse_args()
print(opt)
