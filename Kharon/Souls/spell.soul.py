#!/usr/bin/env python3

import sys
from spellchecker import SpellChecker


input = " ".join(sys.argv[1:])

if any(c.isnumeric() for c in input):
    exit(0) # it's got numbers, probably not meant for spell checking


spell = SpellChecker()

words = spell.split_words(input)

correction_pairs = [(word, spell.correction(word)) for word in words]

display = ["?" if not spell.known([word]) and word == correction else correction for word, correction in correction_pairs]

print(" ".join(display), end="")
