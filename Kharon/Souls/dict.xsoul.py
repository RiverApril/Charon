#!/usr/bin/env python3

import sys
import os
import re

word = "".join(sys.argv[1:])

command = "curl dict://dict.org/d:\"%s\"" % word

stream = os.popen(command)

stage = 0

for line in stream.readlines():
    if stage == 0:
        if line.startswith("250 ok"):
            stage = 1
    elif stage == 1:
        if line.startswith("150"):
            m = re.search("150 ([0-9]*) definitions retrieved", line)
            if m is not None:
                if m.group(1) != "1":
                    print("Found %s definitions\n" % m.group(1))
        elif line.startswith("151"):
            stage = 2
        elif line.startswith("552 no match"):
            print("no match")
            stage = -1
            break
    elif stage == 2:
        if line.startswith("250 ok"):
            stage = 3
            break
        elif line.startswith("151"):
            pass
        elif line.startswith("."):
            print("")
        else:
            line = re.sub(r"(\[.*\])", r"", line)
            line = re.sub(r"--[A-Z][a-z]+\.", r"", line)
            if len(line.strip()) > 0:
                print(line, end="")
    else:
        break
        
if stage == -1:
    exit(-1)
            

