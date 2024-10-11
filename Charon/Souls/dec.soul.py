#!/usr/bin/env python3

import sys
import calc

input = " ".join(sys.argv[1:])

print(calc.evaluate(input), end="", flush=True)
