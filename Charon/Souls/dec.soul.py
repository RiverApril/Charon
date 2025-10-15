#!/usr/bin/env python3

import sys
import calc

input = " ".join(sys.argv[1:])

calculated = calc.evaluate(input)

print(calculated, end="", flush=True)
