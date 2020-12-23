#!/usr/bin/env python3

import sys
import calc

input = " ".join(sys.argv[1:])

if len(input) == 0:
    exit(0)

eval_result = calc.evaluate(input)

info = ""

first_32_code_names = [
    "NUL",
    "SOH",
    "STX",
    "ETX",
    "EOT",
    "ENQ",
    "ACK",
    "BEL",
    "BS",
    "TAB",
    "LF",
    "VT",
    "FF",
    "CR",
    "SO",
    "SI",
    "DLE",
    "DC1",
    "DC2",
    "DC3",
    "DC4",
    "NAK",
    "SYN",
    "ETB",
    "CAN",
    "EM",
    "SUB",
    "ESC",
    "FS",
    "GS",
    "RS",
    "US"
]

def get_info(number):
    if isinstance(number, int) or number.is_integer():
        integer = int(number)
        if integer >= ord(" ") and integer <= ord("~"):
            return chr(integer)
        elif integer >= 0 and integer <= 31:
            return first_32_code_names[integer]
        elif integer == 127:
            return "DEL"
        else:
            return "ERR"
    else:
        exit(-1)

if type(eval_result) is list or type(eval_result) is tuple:
    info = "".join([get_info(num) for num in eval_result])
else:
    info = get_info(eval_result)
    
print(info)
