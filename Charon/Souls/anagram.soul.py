#!/usr/bin/env python3

import sys
from functools import cache
import pickle
import os
from spellchecker import SpellChecker
from collections import Counter


all_words_with_freq = SpellChecker().word_frequency.dictionary.items()
all_words = [k for k, v in sorted(all_words_with_freq, key=lambda item: item[1], reverse=True)]
for letter in "bcdefghjklmnopqrstuvwxyz": # removing single-letter words other than a and i
    all_words.remove(letter)

@cache
def get_words_of_length(n):
    words = []
    for word in all_words:
        if len(word) == n:
            words.append(word)
    return words

def combinations_lazy(n, smaller):
    if n <= 0:
        return
    
    yield (n,)

    if n > 1:
        for x in combinations(n-1, smaller):
            # for i in range(len(x)-1, -1, -1):
            for i in range(len(x)):
                if x[i]+1 <= x[i-1]:
                    yield (*x[0:i], x[i]+1, *x[i+1:])
            yield (*x, 1)
            if smaller:
                yield x


def combinations(n, smaller):
    have_yielded = []
    lazy_gen = combinations_lazy(n, smaller)
    for next_yield in lazy_gen:
        if next_yield not in have_yielded:
            yield next_yield
            have_yielded.append(next_yield)


@cache
def find_words(letters, length):
    okay_words = []
    words = get_words_of_length(length)
    for word in words:
        remaining_letters = letters
        word_okay = True
        for letter in word:
            # if letter in remaining_letters and remaining_letters[letter] > 0:
            #     remaining_letters[letter] -= 1
            # elif "?" in remaining_letters and remaining_letters["?"] > 0:
            #     remaining_letters["?"] -= 1
            if letter in remaining_letters:
                # remaining_letters.remove(letter)
                remaining_letters = remaining_letters.replace(letter, "", 1)
            elif "?" in remaining_letters:
                # remaining_letters.remove("?")
                remaining_letters = remaining_letters.replace("?", "", 1)
            else:
                word_okay = False
                break
        if word_okay:
            okay_words.append(word)
    return okay_words


# def subtract_from_histogram(histogram, values_to_subtract):
#     new_histogram = histogram.copy()
#     for value_to_subtract in values_to_subtract:
#         if value_to_subtract in new_histogram and new_histogram[value_to_subtract] > 0:
#             new_histogram[value_to_subtract] -= 1
#             if new_histogram[value_to_subtract] == 0:
#                 del new_histogram[value_to_subtract]
#         elif "?" in new_histogram and new_histogram["?"] > 0:
#             new_histogram["?"] -= 1
#             if new_histogram["?"] == 0:
#                 del new_histogram["?"]
#         else:
#             return None
#     return new_histogram

def subtract_lists(a, b):
    for x in b:
        a = a.replace(x, "", 1)
    return a
            

def anagrams(letters, shape):
    if len(shape) == 0:
        return
    word_length = shape[0]
    possible_words = find_words(letters, word_length)
    for word in possible_words:
        if len(shape) > 1:

            remaining_letters = subtract_lists(letters, word)

            for subgram in anagrams(remaining_letters, shape[1:]):
                yield word + " " + subgram
        else:
            yield word

def parse_and_find_anagrams(input):

    # examples:

    # elolhldwro
    # -> hello world, hell old row

    # elolh ldwro
    # -> hello world

    # helloworld ####
    # -> hell, held, wool, etc...

    # heloworld ####_###
    # -> hell old, held low, etc...

    special_chars = [
        "\\", # escape character
        "?", # any single character
        "#", # if included, it sets the expected output shape of non-space characters
        "_", # like # but for spaces
        "!", # forces no extra spaces
        "~", # allows letters to be excluded
        # if none of "#_!~" are included then spaces could be added anywhere
    ]

    # step 1
    # determine avalable characters
    # avalable_chars = "helloworld"

    # step 2
    # determine required output pattern
    # required_pattern = [10]

    # step 3
    # determine possible output patterns
    # possible_patterns = [[10], [9,1], [8,2], [7,3], ... [1,1,1,1,1,1,1,1,1,1]]

    # steo 4
    # determine possible characters for each word
    # [8,2] -> [8] -> ["hellowor", ""]

    awaiting_escape = False
    input_chars = ""
    input_shape = []
    defined_shape = []
    extra_spaces_okay = True
    leftovers_okay = False
    for c in input:
        if awaiting_escape:
            awaiting_escape = False
        else:
            if c == "\\":
                awaiting_escape = True
                continue
            elif c == "#":
                if len(defined_shape) == 0:
                    defined_shape.append(0)
                defined_shape[-1] += 1
                extra_spaces_okay = False
                continue
            elif c == "_":
                defined_shape.append(0)
                continue
            elif c == "!":
                extra_spaces_okay = False
                continue
            elif c == "~":
                leftovers_okay = True
                continue
            
        

        if c == " ":
            input_shape.append(0)
        else:
            if len(input_shape) == 0:
                    input_shape.append(0)
            input_shape[-1] += 1

            input_chars += c


    possible_shapes = []

    if len(defined_shape) > 0:
        defined_shape = list(filter(lambda a: a != 0, defined_shape))
        possible_shapes = [defined_shape]
    else:
        input_shape = list(filter(lambda a: a != 0, input_shape))
        if extra_spaces_okay:
            total_chars = sum(input_shape)
            if leftovers_okay:
                possible_shapes = combinations(total_chars, True)
            else:
                possible_shapes = combinations(total_chars, False)
        else:
            possible_shapes = [input_shape]


    # print(list(possible_shapes))
    # print(input_histogram)

    display = []

    anagrams_shown_counters = []
    is_first = True

    for shape in possible_shapes:
        # print(shape)
        for anagram in anagrams(input_chars, shape):
            counter = Counter(anagram.split(" "))
            if counter not in anagrams_shown_counters:
                anagrams_shown_counters.append(counter)
                if is_first:
                    is_first = False
                else:
                    print(", ", end="")
                print(anagram, end="", flush=True)


input = " ".join(sys.argv[1:])

if any(c.isnumeric() for c in input):
    exit(0) # it's got numbers, probably not meant for spell checking

parse_and_find_anagrams(input.lower())

