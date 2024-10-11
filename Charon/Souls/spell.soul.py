#!/usr/bin/env python3

import sys
from spellchecker import SpellChecker


input = " ".join(sys.argv[1:])

if any(c.isnumeric() for c in input):
    exit(0) # it's got numbers, probably not meant for spell checking


spell = SpellChecker()

words = spell.split_words(input)


if len(words) == 1:
    word = words[0]
    candidates = spell.candidates(word)
    if candidates is None:
        display = ["?"]
    else:
        display = list(candidates)
else:
    corrections = [spell.correction(word) for word in words]

    display = ["?" if correction is None else correction for correction in corrections]

print(" ".join(display), end="", flush=True)
