from collections import Counter
from itertools import zip_longest
import re
from math import log, floor, sqrt

class AddMultiplyAdd:
    def __init__(self, a_add, b_multiply=1.0, c_add=0.0):
        self.a_add = a_add
        self.b_multiply = b_multiply
        self.c_add = c_add
    def apply(self, value):
        return ((value + self.a_add) * self.b_multiply) + self.c_add
    def invert(self):
        return AddMultiplyAdd(-self.c_add, 1.0 / self.b_multiply, -self.a_add)

def apply(to_other, value):
    if isinstance(to_other, float):
        return value * to_other
    elif isinstance(to_other, AddMultiplyAdd):
        return to_other.apply(value)
    else:
        return None

def invert(to_other):
    if isinstance(to_other, float):
        return 1.0 / to_other
    elif isinstance(to_other, AddMultiplyAdd):
        return to_other.invert()
    else:
        return None

def combine(a_to_b, b_to_c):
    if isinstance(a_to_b, float) and isinstance(b_to_c, float):
        return a_to_b * b_to_c
    elif isinstance(a_to_b, AddMultiplyAdd) and isinstance(b_to_c, AddMultiplyAdd):
        return AddMultiplyAdd(
            0, 
            a_to_b.b_multiply * b_to_c.b_multiply, 
            (a_to_b.a_add * a_to_b.b_multiply + a_to_b.c_add + b_to_c.a_add) * b_to_c.b_multiply + b_to_c.c_add
        )
    elif isinstance(a_to_b, float) and isinstance(b_to_c, AddMultiplyAdd):
        return combine(AddMultiplyAdd(0, a_to_b, 0), b_to_c)
    elif isinstance(a_to_b, AddMultiplyAdd) and isinstance(b_to_c, float):
        return combine(a_to_b, AddMultiplyAdd(0, b_to_c, 0))
    else:
        return None


class Unit:
    def __init__(self, dimension, symbols):
        self.dimension = dimension
        self.symbols = symbols
        if not isinstance(self.symbols, list):
            self.symbols = [self.symbols]
    def __str__(self):
        return "(" + self.symbols[-1] + ")[" + self.dimension.name + "]"

class UnitNode:
    def __init__(self, unit):
        self.unit = unit
        self.connections = {}
    def add_both_connections(self, other_node, to_other_unit):
        self.connections[other_node] = to_other_unit
        other_node.connections[self] = invert(to_other_unit)

class Dimension:
    def __init__(self, name):
        self.name = name

class UnitGraph:
    def __init__(self, dimension):
        self.dimension = dimension
        self.nodes = {}
        self.symbol_to_unit = {}
        
    def add_unit(self, unit):
        self.nodes[unit] = UnitNode(unit)
        for symbol in unit.symbols:
            self.symbol_to_unit[symbol] = unit

    def get_unit_from_symbol(self, symbol):
        return self.symbol_to_unit[symbol]

    def add_multiply_connection(self, unit_a, unit_a_qty, unit_b, unit_b_qty=1):
        node_a = self.nodes[unit_a]
        node_b = self.nodes[unit_b]
        node_b.add_both_connections(node_a, unit_a_qty / unit_b_qty)
    def add_generic_connection(self, unit_a, unit_b, unit_a_to_b):
        node_a = self.nodes[unit_a]
        node_b = self.nodes[unit_b]
        node_a.add_both_connections(node_b, unit_a_to_b)

    def fill_in_all_connections(self):
        has_made_a_new_connection = True
        while has_made_a_new_connection:
            has_made_a_new_connection = False
            for node in self.nodes.values():
                present_keys_1 = list(node.connections.keys())
                for other_node in present_keys_1:
                    present_keys_2 = list(other_node.connections.keys())
                    for other_other_node in present_keys_2:
                        if node == other_other_node:
                            continue
                        if other_other_node in node.connections:
                            continue
                        to_other_other = combine(node.connections[other_node], other_node.connections[other_other_node])
                        node.add_both_connections(other_other_node, to_other_other)
                        has_made_a_new_connection = True
    

class UnitPrefix:
    def __init__(self, short_symbol, long_symbol, multiplier):
        self.short_symbol = short_symbol
        self.long_symbol = long_symbol
        self.multiplier = multiplier

prefixes_metric_standard_big = [
    UnitPrefix("T", "tera", 1e12),
    UnitPrefix("G", "giga", 1e9),
    UnitPrefix("M", "mega", 1e6),
    UnitPrefix("k", "kilo", 1e3),
]
prefixes_metric_standard_small = [
    UnitPrefix("m", "milli", 1e-3),
    UnitPrefix("u", "micro", 1e-6),
    UnitPrefix("μ", "micro", 1e-6),
    UnitPrefix("n", "nano", 1e-9),
    UnitPrefix("p", "pico", 1e-12),
    UnitPrefix("f", "femto", 1e-15),
]

prefixes_metric_niche = [
    UnitPrefix("h", "hecto", 1e2),
    UnitPrefix("d", "deci", 1e-1),
    UnitPrefix("c", "centi", 1e-2),
]

prefixes_metric = prefixes_metric_standard_big + prefixes_metric_standard_small + prefixes_metric_niche

prefixes_1024s = [
    UnitPrefix("Ti", "tebi", 1024*1024*1024*1024),
    UnitPrefix("Gi", "gibi", 1024*1024*1024),
    UnitPrefix("Mi", "mebi", 1024*1024),
    UnitPrefix("Ki", "kibi", 1024),

    UnitPrefix("ti", "tebi", 1024*1024*1024*1024),
    UnitPrefix("gi", "gibi", 1024*1024*1024),
    UnitPrefix("mi", "mebi", 1024*1024),
    UnitPrefix("ki", "kibi", 1024),
]
prefixes_metric_caseless_big = [
    UnitPrefix("T", "tera", 1e12),
    UnitPrefix("G", "giga", 1e9),
    UnitPrefix("M", "mega", 1e6),
    UnitPrefix("K", "kilo", 1e3),

    UnitPrefix("t", "tera", 1e12),
    UnitPrefix("g", "giga", 1e9),
    UnitPrefix("m", "mega", 1e6),
    UnitPrefix("k", "kilo", 1e3),
]

def create_prefix_symbols(base_symbols, prefixes):
    yield [base_symbol.replace("?", "") for base_symbol in base_symbols]
    for prefix in prefixes:
        combined_symbols = []
        for index in range(len(base_symbols)):
            base_symbol = base_symbols[index]
            prefix_symbol = prefix.short_symbol if len(base_symbol) <=2 else prefix.long_symbol
            if "?" in base_symbol:
                combined_symbols.append(base_symbol.replace("?", prefix_symbol))
            else:
                combined_symbols.append(prefix_symbol + base_symbol)
        yield combined_symbols
            
def create_prefix_connections(base_symbol, prefixes, power=1):
    for prefix in prefixes:
        combined_symbol = prefix.short_symbol + base_symbol
        yield [1, combined_symbol, prefix.multiplier**power, base_symbol]

def setup_dimension(name, units_symbols, unit_connections):
    dim = Dimension(name)
    graph = UnitGraph(dim)
    units = []

    for unit_symbols in units_symbols:
        unit = Unit(dim, unit_symbols)
        graph.add_unit(unit)
        units.append(unit)

    for unit_connection in unit_connections:
        unit_a_qty, unit_a_symbol, unit_b_qty, unit_b_symbol = unit_connection
        unit_a = graph.get_unit_from_symbol(unit_a_symbol)
        unit_b = graph.get_unit_from_symbol(unit_b_symbol)
        graph.add_multiply_connection(unit_a, unit_a_qty, unit_b, unit_b_qty)

    graph.fill_in_all_connections()

    return dim, graph, units

def combine_stuff(stuffs):
    all_dims = []
    unit_graphs_by_dim = {}
    all_units = []
    combined_symbol_to_unit = {}
    for dim, graph, units in stuffs:
        all_dims.append(dim)
        unit_graphs_by_dim[dim] = graph
        all_units += units
        combined_symbol_to_unit |= graph.symbol_to_unit

    return all_dims, unit_graphs_by_dim, all_units, combined_symbol_to_unit


####
#### Start of definitions
####

### Temperature
if True:
    dim_temperature = Dimension("temperature")
    graph_temperature = UnitGraph(dim_temperature)
    units_temperature = []

    units_temperature_symbols = [
        ["C", "c", "Celsius", "celsius"],
        ["F", "f", "Fahrenheit", "fahrenheit"],
        ["K", "k", "Kelvin", "kelvin"],
    ]

    for unit_symbols in units_temperature_symbols:
        unit = Unit(dim_temperature, unit_symbols)
        graph_temperature.add_unit(unit)
        units_temperature.append(unit)

    unit_temperature_c = graph_temperature.get_unit_from_symbol("C")
    unit_temperature_f = graph_temperature.get_unit_from_symbol("F")
    unit_temperature_k = graph_temperature.get_unit_from_symbol("K")

    graph_temperature.add_generic_connection(unit_temperature_c, unit_temperature_f, AddMultiplyAdd(0, 9.0/5.0, 32))
    graph_temperature.add_generic_connection(unit_temperature_c, unit_temperature_k, AddMultiplyAdd(273.15, 1, 0))

    graph_temperature.fill_in_all_connections()

    stuff_temperature = dim_temperature, graph_temperature, units_temperature
###


stuff_length = setup_dimension("length", 
    list(create_prefix_symbols(["m", "meter", "meters"], prefixes_metric)) + [
        ["in", "ins", "inch", "inches"], 
        ["ft", "foot", "feet"],
        ["yd", "yds", "yrd", "yrds", "yard", "yards"],
        ["mi", "mile", "miles"],
        ["ls", "lightsecond", "lightseconds"],
        ["ly", "lightyear", "lightyears"],
        ["au", "aus", "astronomicalunit", "astronomicalunits"],
        ["pc", "parsec", "parsecs"],
    ],
    list(create_prefix_connections("m", prefixes_metric)) + [
        [1, "in", 25.4, "mm"],
        [1, "foot", 12, "in"],
        [1, "yard", 3, "feet"],
        [1, "mile", 1760, "yards"],
        [1, "lightsecond", 299792458, "m"],
        [1, "ly", 9460730472580.8, "km"],
        [1, "au", 149597870700, "m"],
        [1, "parsec", 206265, "au"],
    ]
)


stuff_time = setup_dimension("time", 
    list(create_prefix_symbols(["s", "sec", "secs", "second", "seconds"], prefixes_metric)) + [
        ["min", "mins", "minute", "minutes"],
        ["hr", "hrs", "hour", "hours"],
        ["d", "day", "days"],
        ["w", "week", "weeks"],
        ["yr", "yrs", "year", "years"],
        ["m", "month", "months"],
        ["dec", "decs", "decade", "decades"],
        ["cen", "cent", "cents", "century", "centuries"],
        ["mil", "millennium", "millennia"],
    ],
    list(create_prefix_connections("s", prefixes_metric)) + [
        [1, "min", 60, "sec"],
        [1, "hr", 60, "mins"],
        [1, "day", 24, "hours"],
        [1, "week", 7, "days"],
        [1, "year", 365.2425, "days"],
        [1, "year", 12, "months"],
        [1, "decade", 10, "years"],
        [1, "century", 100, "years"],
        [1, "millennium", 1000, "years"],
    ]
)

stuff_mass = setup_dimension("mass",
    list(create_prefix_symbols(["g", "gram", "grams"], prefixes_metric)) + [
        ["lb", "lbs", "pound", "pounds"],
        ["oz", "ozs", "ounce", "ounces"],
    ],
    list(create_prefix_connections("g", prefixes_metric)) + [
        [1, "pound", 0.45359237, "kg"],
        [16, "ounce", 1, "pound"],
    ]
)

prefixes_bytes = prefixes_metric_caseless_big + prefixes_1024s
stuff_data = setup_dimension("data",
    list(create_prefix_symbols(["B", "b", "byte", "bytes"], prefixes_bytes)) + [
        ["bit", "bits"],
    ],
    list(create_prefix_connections("B", prefixes_bytes)) + [
        [8, "bits", 1, "byte"],
    ]
)

stuff_area = setup_dimension("area",
    list(create_prefix_symbols(["m2", "meter2", "meters2", "square_?meters", "metered_squared", "squared_?meters"], prefixes_metric)) + [
        ["in2", "inch2", "inches2", "square_inch", "square_inches", "squarein", "sqin"], 
        ["ft2", "foot2", "feet2", "square_feet", "square_footage", "squareft", "sqft"],
        ["yd2", "yard2", "yards2", "square_yards"],
        ["mi2", "mile2", "miles2", "square_mile", "square_miles", "sqmi"],
        ["ha", "hectare", "hectares"],
        ["acre", "acres"],
    ],
    list(create_prefix_connections("m2", prefixes_metric, 2)) + [
        [1, "in2", 25.4**2, "mm2"],
        [1, "ft2", 12**2, "in2"],
        [1, "yd2", 3**2, "ft2"],
        [1, "mi2", 1760**2, "yd2"],
        [1, "hectare", 1e4, "m2"],
        [1, "acre", 4840, "yd2"],
    ]
)

stuff_volume = setup_dimension("volume",
    list(create_prefix_symbols(["m3", "meter3", "meters3", "cubic_?meter", "cubic_?meters", "meteres_cubed"], prefixes_metric)) + 
    list(create_prefix_symbols(["l", "L", "litre", "liter", "litres", "liters"], prefixes_metric)) + [
        ["in3", "inch3", "inches3", "cubic_inch", "cubic_inches"], 
        ["ft3", "foot3", "feet3", "cubic_feet"],
        ["yd3", "yard3", "yards3", "cubic_yards"],
        ["mi3", "mile3", "miles3", "cubic_mile", "cubic_miles"],
        ["gal", "gallon", "gallons"],
        ["qt", "quart", "quarts"],
        ["pt", "pint", "pints"],
        ["cup", "cups"],
        ["floz", "fluid_oz", "fluid_ounce"],
        ["tbsp", "table_spoon"],
        ["tsp", "tea_spoon"],
    ],
    list(create_prefix_connections("m3", prefixes_metric, 3)) +
    list(create_prefix_connections("l", prefixes_metric, 1)) + [
        [1, "l", 1, "dm3"],
        [1, "in3", 25.4**3, "mm3"],
        [1, "ft3", 12**3, "in3"],
        [1, "yd3", 3**3, "ft3"],
        [1, "mi3", 1760**3, "yd3"],
        [1, "gallon", 231, "in3"],
        [4, "quarts", 1, "gallon"],
        [2, "pints", 1, "quart"],
        [2, "cups", 1, "pint"],
        [8, "floz", 1, "cup"],
        [2, "tbsp", 1, "floz"],
        [1, "tsp", 5, "ml"],
    ]
)

prefixes_hz = prefixes_metric_caseless_big
stuff_frequency = setup_dimension("frequency", 
    list(create_prefix_symbols(["Hz", "hz", "hertz"], prefixes_hz)) + [
        ["per_s", "per_sec", "per_second"],
        ["per_m", "per_min", "per_minute"],
        ["per_hr", "per_hour"],
        ["per_day", "daily"],
        ["per_week", "weekly"],
        ["per_yr", "per_year", "yearly"],
        ["per_month", "monthly"],
        ["per_decade"],
        ["per_century"],
        ["per_millennium"],
    ],
    list(create_prefix_connections("Hz", prefixes_hz)) + [
        [1, "per_sec", 1, "hz"],
        [60, "per_min", 1, "per_sec"],
        [60, "per_hr", 1, "per_min"],
        [24, "per_day", 1, "per_hr"],
        [7, "per_week", 1, "per_day"],
        [365.2425, "per_year", 1, "per_day"],
        [1, "per_month", 12, "per_year"],
        [10, "per_decade", 1, "per_year"],
        [100, "per_century", 1, "per_year"],
        [1000, "per_millennium", 1, "per_year"],
    ]
)

stuff_quantity = setup_dimension("quantity", 
    [
        ["qty", "quantity", "count"],
        ["mol", "mole", "mols", "moles"],
    ],
    [
        [1, "mol", 6.02214076e23, "qty"],
    ]
)

stuff_velocity = setup_dimension("velocity", 
    [
        ["m/s", "meters_per_second"],
        ["mph", "mi/hr", "miles_per_hour"],
        ["kph", "km/hr", "kilometers_per_hour"],
        ["kps", "km/s", "kilometers_per_second"],
        ["c", "speed_of_light", "lightspeed"],
    ],
    [
        [1000, "m/s", 1, "km/s"],
        [1, "km/hr", 60*60, "km/s"],
        [1, "c", 299792458, "m/s"],
        [1, "mph", 1.609344, "km/hr"],
    ]
)


all_stuff = combine_stuff([
    stuff_temperature,
    stuff_length,
    stuff_time,
    stuff_mass,
    stuff_data,
    stuff_area,
    stuff_volume,
    stuff_frequency,
    stuff_quantity,
    stuff_velocity,
])

all_dims, unit_graphs_by_dim, all_units, combined_symbol_to_unit = all_stuff

def unit_convert(from_value, from_unit_symbol, to_unit_symbol=None):
    if to_unit_symbol == None:
        if " to " in from_unit_symbol:
            from_unit_symbol, to_unit_symbol = from_unit_symbol.split(" to ")
        elif " " in from_unit_symbol:
            from_unit_symbol, to_unit_symbol = from_unit_symbol.split(" ")
    
    for dim in all_dims:
        graph = unit_graphs_by_dim[dim]
        symbol_to_unit = graph.symbol_to_unit
        if from_unit_symbol in symbol_to_unit and to_unit_symbol in symbol_to_unit:
            from_unit = symbol_to_unit[from_unit_symbol]
            to_unit = symbol_to_unit[to_unit_symbol]
            return apply(graph.nodes[from_unit].connections[graph.nodes[to_unit]], from_value)
    
    error_message = ""
    if from_unit_symbol in combined_symbol_to_unit and to_unit_symbol in combined_symbol_to_unit:
        dim1 = combined_symbol_to_unit[from_unit_symbol].dimension
        dim2 = combined_symbol_to_unit[to_unit_symbol].dimension
        error_message += dim1.name + " != " + dim2.name
    if from_unit_symbol not in combined_symbol_to_unit:
        error_message += from_unit_symbol + "? "
    if to_unit_symbol not in combined_symbol_to_unit:
        error_message += to_unit_symbol + "? "
    return error_message
