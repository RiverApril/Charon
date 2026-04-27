#!/usr/bin/env python3

import sys
import calc as calc

user_input = " ".join(sys.argv[1:])

calculated = calc.evaluate(user_input)

print(calculated, end="", flush=True)
