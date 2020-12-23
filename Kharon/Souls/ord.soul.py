#!/usr/bin/env python3

import sys
import calc

input = " ".join(sys.argv[1:])

output = ", ".join([hex(ord(c)) for c in input])

print(output)
