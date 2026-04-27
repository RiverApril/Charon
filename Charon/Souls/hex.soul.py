#!/usr/bin/env python3

import sys
import calc as calc

user_input = " ".join(sys.argv[1:])

print(calc.to_hex(calc.evaluate(user_input)), end="", flush=True)
