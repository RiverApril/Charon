import re
from math import *

def log16(x):
    return log2(x) / 4

def preprocess(raw):
    
    input = raw
    
    # Add implicit multiplication like '42(' -> '42*('
    anynum_pattern = r"([0-9]+\.?[0-9]*|0b[01]+\.?[01]*|0x[0-9a-f]+\.?[0-9a-f]+)"
    input = re.sub(anynum_pattern + r"(\()", r"\1*\2", input) # prefix 42( -> 42*(
    input = re.sub(r"(\))" + anynum_pattern, r"\1*\2", input) # suffix )42 -> )*42
    input = re.sub(r"(\))(\()", r"\1*\2", input) # two parenthesis groups )( -> )*(
    #

    # Fix missing ( and ) on edges
    extra_open = 0
    level = 0
    for c in input:
        if c == "(":
            level += 1
        elif c == ")":
            level -= 1
        
        if level < 0:
            extra_open += 1
            level += 1
            
    extra_close = level
    
    input = ("(" * extra_open) + input + (")" * extra_close)
    #
    
    return input


def evaluate(raw):
    if len(raw) == 0:
        return ""
    
    input = preprocess(raw)
    result = eval(input)
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
