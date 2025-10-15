#!/usr/bin/env python3

import sys
import calc
from math import floor

# https://stackoverflow.com/questions/5124743/algorithm-for-simplifying-decimal-to-fractions
def pos_real_to_frac(x, error = 0.000001):
    n = int(floor(x))
    x -= n
    if x < error:
        return (n, 1)
    elif 1 - error < x:
        return (n+1, 1)
    
    # lower fraction: 0/1
    lower_n = 0
    lower_d = 1
    # upper fraction: 1/1
    upper_n = 1
    upper_d = 1
    while True:
        middle_n = lower_n + upper_n
        middle_d = lower_d + upper_d
        # x + error < middle, but with safe d
        if middle_d * (x + error) < middle_n:
            upper_n = middle_n
            upper_d = middle_d
        # middle < x - error
        elif middle_n < (x - error) * middle_d:
            lower_n = middle_n
            lower_d = middle_d
        else:
            return (n * middle_d + middle_n, middle_d)


input = " ".join(sys.argv[1:])

real = calc.evaluate(input)

is_negative = real < 0

if is_negative:
    real = -real

whole = int(floor(real))
real -= whole

fraction = pos_real_to_frac(real)

error = real - fraction[0]/fraction[1]

result = ""
have_parenths = False
if is_negative and whole > 0 and fraction[0] > 0:
    have_parenths = True


if is_negative:
    result += "-"
if have_parenths:
    result += "("
if whole > 0:
    result += str(whole)
if whole > 0 and fraction[0] > 0:
    result += " + "
if whole == 0 and fraction[0] == 0:
    result += "0"
if fraction[0] > 0:
    result += str(fraction[0]) + "/" + str(fraction[1])
if error > 0:
    result += " +" + str(error)
elif error < 0:
    result += " -" + str(-error)
if have_parenths:
    result += ")"

print(result, end="", flush=True)
