#!/usr/bin/python
# Parse no arquivo de redes do lacnic
# thiagojlucas@gmail.com

import os
import sys

try:
    location = (sys.argv[2])
except:
    location = "BR"

for tmp in open(sys.argv[1]):
    tmp = tmp[:-2].split("|")
    x = 1
    i = 32
    if tmp[1]==location and tmp[2]=="ipv4":
        while not x == int(tmp[4]):
            x = x*2
            i = i-1
            if i==0:
                break
        if i != 0:
            print tmp[3]+"/%d" % (i)
        else:
            print tmp[3]+"/%d" % 16
