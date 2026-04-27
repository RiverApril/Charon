import re
from math import *
from random import *

import string
import secrets
from functools import reduce
from unit_tree import unit_convert
convert = unit_convert

default_alphabet = string.ascii_letters + string.digits + string.punctuation

def password(size, alphabet = default_alphabet):
    return ''.join(secrets.choice(alphabet) for i in range(size))

# https://stackoverflow.com/questions/6800193/what-is-the-most-efficient-way-of-finding-all-the-factors-of-a-number-in-python
def factors(n):
    return sorted(set(reduce(
        list.__add__,
        ([i, n//i] for i in range(1, int(n**0.5) + 1) if n % i == 0))))

def log16(x):
    return log2(x) / 4

def rslvl2xp(L):
    return floor(0.25 * sum((floor(l + 300.0 * 2.0**(l / 7.0)) for l in range(1, L))))

def preprocess(raw):
    
    user_input = raw
    
    # Add implicit multiplication like '42(' -> '42*('
    anynum_pattern = r"([0-9]+\.?[0-9]*|0b[01]+\.?[01]*|0x[0-9a-f]+\.?[0-9a-f]+)"
    user_input = re.sub(anynum_pattern + r"(\()", r"\1*\2", user_input) # prefix 42( -> 42*(
    user_input = re.sub(r"(\))" + anynum_pattern, r"\1*\2", user_input) # suffix )42 -> )*42
    user_input = re.sub(r"(\))(\()", r"\1*\2", user_input) # two parenthesis groups )( -> )*(
    #

    # Fix missing ( and ) on edges
    extra_open = 0
    level = 0
    for c in user_input:
        if c == "(":
            level += 1
        elif c == ")":
            level -= 1
        
        if level < 0:
            extra_open += 1
            level += 1
            
    extra_close = level
    
    user_input = ("(" * extra_open) + user_input + (")" * extra_close)
    #
    
    return user_input


def evaluate(raw):
    if len(raw) == 0:
        return ""
    
    user_input = preprocess(raw)
    result = eval(user_input)
    return result
    

def to_base_single(num, base, log_func, code_letter, prefix):
    anum = abs(num)
    fraction, integer_f = modf(anum)
    integer = int(integer_f)
    neg = num < 0
    neg_str = "-" if neg else ""
    
    integer_str = format(integer, "%s" % (code_letter))
    
    if fraction != 0:
        fraction_len = 100
        integer_rep = int(fraction * (base**fraction_len))
        
        base_rep = format(integer_rep, "0%d%s" % (fraction_len, code_letter)).rstrip("0")
        
        return "%s%s%s.%s" % (neg_str, prefix, integer_str, base_rep)
    else:
        return "%s%s%s" % (neg_str, prefix, integer_str)
    

def to_base(nums, base, log_func, code_letter, prefix):
    if type(nums) is list:
        return "[" + ", ".join((to_base(num, base, log_func, code_letter, prefix) for num in nums)) + "]"
    
    elif type(nums) is tuple:
        return "(" + ", ".join((to_base(num, base, log_func, code_letter, prefix) for num in nums)) + ")"
    
    elif isinstance(nums, (int, float, complex)) and not isinstance(nums, bool):
        return to_base_single(nums, base, log_func, code_letter, prefix)
    
    elif type(nums) is str:
        return nums
    
    else:
        return str(nums)
        

    
def to_hex(num):
    return to_base(num, 16, log16, "x", "0x")


def to_bin(num):
    return to_base(num, 2, log2, "b", "0b")
