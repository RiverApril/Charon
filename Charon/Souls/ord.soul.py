#!/usr/bin/env python3

import sys
import calc as calc

user_input = " ".join(sys.argv[1:])

output = ", ".join([hex(ord(c)) for c in user_input])

print(output, end="", flush=True)
