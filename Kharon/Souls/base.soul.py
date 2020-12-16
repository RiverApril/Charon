#!/usr/bin/env python3

import sys

input = " ".join(sys.argv[1:])

evaluated = eval(input)

decStr = evaluated
hexStr = hex(evaluated)
binStr = bin(evaluated)

print(decStr, hexStr, binStr, sep="\n", end="")

exit(0)
