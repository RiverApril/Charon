#!/usr/bin/env python3

import sys
import calc as calc
from unit_tree import unit_convert
import re

user_input = " ".join(sys.argv[1:])

pattern = re.compile(r"((?:[a-zA-Z_]*\/)?[a-zA-Z_]+[23]?) to ([a-zA-Z_]+[23]?)")

match = pattern.search(user_input)

if not match:
    sys.exit()

from_expression = user_input[:match.start()]
from_unit = match.group(1)
to_unit = match.group(2)

calculated_expression = calc.evaluate(from_expression)
converted_calculated = unit_convert(calculated_expression, from_unit, to_unit)
#result = str(calculated_expression) + from_unit + " = " + str(converted_calculated) + to_unit
#print(result, end="", flush=True)
if converted_calculated != None:
    print(converted_calculated, end="", flush=True)

