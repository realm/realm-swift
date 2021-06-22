import os, re

# Tags:
# (no)minmax: Type supports min() and max()
# (no)sum: Type supports sum()
# (no)avg: Type supports average()
# r/o: Type is Required or Optional
# (un)man: Type is Managed or Unmanaged

types = [
  # Class, Object, Property, Keys, Values, Tags
  # Bool
  ['AllPrimitiveDictionaries', 'unmanaged', 'boolObj', ['@"key1"', '@"key2"'], ['@NO', '@YES'], {'r', 'unman'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'boolObj', ['@"key1"', '@"key2"'], ['@NO', 'NSNull.null'], {'o', 'unman'}],
  ['AllPrimitiveDictionaries', 'managed', 'boolObj', ['@"key1"', '@"key2"'], ['@NO', '@YES'], {'r', 'man'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'boolObj', ['@"key1"', '@"key2"'], ['@NO', 'NSNull.null'], {'o', 'man'}],
  # Int
  ['AllPrimitiveDictionaries', 'unmanaged', 'intObj', ['@"key1"', '@"key2"'], ['@2', '@3'], {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'intObj', ['@"key1"', '@"key2"'], ['@2', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveDictionaries', 'managed', 'intObj', ['@"key1"', '@"key2"'], ['@2', '@3'], {'r', 'minmax', 'sum', 'avg', 'man'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'intObj', ['@"key1"', '@"key2"'], ['@2', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'man'}],
  # String
  ['AllPrimitiveDictionaries', 'unmanaged', 'stringObj', ['@"key1"', '@"key2"'], ['@"bar"', '@"foo"'], {'r', 'unman', 'string'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'stringObj', ['@"key1"', '@"key2"'], ['@"bar"', 'NSNull.null'], {'o', 'unman', 'string'}],
  ['AllPrimitiveDictionaries', 'managed', 'stringObj', ['@"key1"', '@"key2"'], ['@"bar"', '@"foo"'], {'r', 'man', 'string'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'stringObj', ['@"key1"', '@"key2"'], ['@"bar"', 'NSNull.null'], {'o', 'man', 'string'}],
  # Date
  ['AllPrimitiveDictionaries', 'unmanaged', 'dateObj', ['@"key1"', '@"key2"'], ['date(1)', 'date(2)'], {'r', 'minmax', 'unman', 'date'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'dateObj', ['@"key1"', '@"key2"'], ['date(1)', 'NSNull.null'], {'o', 'minmax', 'unman', 'date'}],
  ['AllPrimitiveDictionaries', 'managed', 'dateObj', ['@"key1"', '@"key2"'], ['date(1)', 'date(2)'], {'r', 'minmax', 'man', 'date'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'dateObj', ['@"key1"', '@"key2"'], ['date(1)', 'NSNull.null'], {'o', 'minmax', 'man', 'date'}],
  # Float
  ['AllPrimitiveDictionaries', 'unmanaged', 'floatObj', ['@"key1"', '@"key2"'], ['@2.2f', '@3.3f'], {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'floatObj', ['@"key1"', '@"key2"'], ['@2.2f', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveDictionaries', 'managed', 'floatObj', ['@"key1"', '@"key2"'], ['@2.2f', '@3.3f'], {'r', 'minmax', 'sum', 'avg'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'floatObj', ['@"key1"', '@"key2"'], ['@2.2f', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg'}],
  # Double
  ['AllPrimitiveDictionaries', 'unmanaged', 'doubleObj', ['@"key1"', '@"key2"'], ['@2.2', '@3.3'], {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'doubleObj', ['@"key1"', '@"key2"'], ['@2.2', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveDictionaries', 'managed', 'doubleObj', ['@"key1"', '@"key2"'], ['@2.2', '@3.3'], {'r', 'minmax', 'sum', 'avg'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'doubleObj', ['@"key1"', '@"key2"'], ['@2.2', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg'}],
  # Data
  ['AllPrimitiveDictionaries', 'unmanaged', 'dataObj', ['@"key1"', '@"key2"'], ['data(1)', 'data(2)'], {'r', 'unman'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'dataObj', ['@"key1"', '@"key2"'], ['data(1)', 'NSNull.null'], {'o', 'unman'}],
  ['AllPrimitiveDictionaries', 'managed', 'dataObj', ['@"key1"', '@"key2"'], ['data(1)', 'data(2)'], {'r'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'dataObj', ['@"key1"', '@"key2"'], ['data(1)', 'NSNull.null'], {'o'}],
  # Double
  ['AllPrimitiveDictionaries', 'unmanaged', 'decimalObj', ['@"key1"', '@"key2"'], ['decimal128(2)', 'decimal128(3)'], {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'decimalObj', ['@"key1"', '@"key2"'], ['decimal128(2)', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveDictionaries', 'managed', 'decimalObj', ['@"key1"', '@"key2"'], ['decimal128(2)', 'decimal128(3)'], {'r', 'minmax', 'sum', 'avg'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'decimalObj', ['@"key1"', '@"key2"'], ['decimal128(2)', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg'}],
  # ObjectId
  ['AllPrimitiveDictionaries', 'unmanaged', 'objectIdObj', ['@"key1"', '@"key2"'], ['objectId(1)', 'objectId(2)'], {'r', 'unman'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'objectIdObj', ['@"key1"', '@"key2"'], ['objectId(1)', 'NSNull.null'], {'o', 'unman'}],
  ['AllPrimitiveDictionaries', 'managed', 'objectIdObj', ['@"key1"', '@"key2"'], ['objectId(1)', 'objectId(2)'], {'r'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'objectIdObj', ['@"key1"', '@"key2"'], ['objectId(1)', 'NSNull.null'], {'o'}],
  # UUID
  ['AllPrimitiveDictionaries', 'unmanaged', 'uuidObj', ['@"key1"', '@"key2"'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")'], {'r', 'unman'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'uuidObj', ['@"key1"', '@"key2"'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'NSNull.null'], {'o', 'unman'}],
  ['AllPrimitiveDictionaries', 'managed', 'uuidObj', ['@"key1"', '@"key2"'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")'], {'r'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'uuidObj', ['@"key1"', '@"key2"'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'NSNull.null'], {'o'}],
  # Mixed
  ['AllPrimitiveDictionaries', 'unmanaged', 'anyBoolObj', ['@"key1"', '@"key2"'], ['@NO', '@YES'], {'r', 'any', 'unman'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'anyIntObj', ['@"key1"', '@"key2"'], ['@2', '@3'], {'r', 'any', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'anyFloatObj', ['@"key1"', '@"key2"'], ['@2.2f', '@3.3f'], {'r', 'any', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'anyDoubleObj', ['@"key1"', '@"key2"'], ['@2.2', '@3.3'], {'r', 'any', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'anyStringObj', ['@"key1"', '@"key2"'], ['@"a"', '@"b"'], {'r', 'any', 'unman', 'string'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'anyDataObj', ['@"key1"', '@"key2"'], ['data(1)', 'data(2)'], {'r', 'any', 'unman'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'anyDateObj', ['@"key1"', '@"key2"'], ['date(1)', 'date(2)'], {'r', 'any', 'minmax', 'unman', 'date'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'anyDecimalObj', ['@"key1"', '@"key2"'], ['decimal128(2)', 'decimal128(3)'], {'r', 'any', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'anyObjectIdObj', ['@"key1"', '@"key2"'], ['objectId(1)', 'objectId(2)'], {'r', 'any', 'unman'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'anyUUIDObj', ['@"key1"', '@"key2"'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")'], {'r', 'any','unman'}],

  ['AllPrimitiveDictionaries', 'managed', 'anyBoolObj', ['@"key1"', '@"key2"'], ['@NO', '@YES'], {'r', 'any', 'man'}],
  ['AllPrimitiveDictionaries', 'managed', 'anyIntObj', ['@"key1"', '@"key2"'], ['@2', '@3'], {'r', 'any', 'sum', 'avg', 'man'}],
  ['AllPrimitiveDictionaries', 'managed', 'anyFloatObj', ['@"key1"', '@"key2"'], ['@2.2f', '@3.3f'], {'r', 'any', 'minmax', 'sum', 'avg', 'man'}],
  ['AllPrimitiveDictionaries', 'managed', 'anyDoubleObj', ['@"key1"', '@"key2"'], ['@2.2', '@3.3'], {'r', 'any', 'minmax', 'sum', 'avg', 'man'}],
  ['AllPrimitiveDictionaries', 'managed', 'anyStringObj', ['@"key1"', '@"key2"'], ['@"a"', '@"b"'], {'r', 'any', 'string', 'man'}],
  ['AllPrimitiveDictionaries', 'managed', 'anyDataObj', ['@"key1"', '@"key2"'], ['data(1)', 'data(2)'], {'r', 'any', 'man'}],
  ['AllPrimitiveDictionaries', 'managed', 'anyDateObj', ['@"key1"', '@"key2"'], ['date(1)', 'date(2)'], {'r', 'any', 'minmax' 'date', 'man'}],
  ['AllPrimitiveDictionaries', 'managed', 'anyDecimalObj', ['@"key1"', '@"key2"'], ['decimal128(2)', 'decimal128(3)'], {'r', 'any', 'minmax', 'sum', 'avg', 'man'}],
  ['AllPrimitiveDictionaries', 'managed', 'anyObjectIdObj', ['@"key1"', '@"key2"'], ['objectId(1)', 'objectId(2)'], {'r', 'any'}],
  ['AllPrimitiveDictionaries', 'managed', 'anyUUIDObj', ['@"key1"', '@"key2"'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")'], {'r', 'any', 'man'}],
]

def type_name(propertyName, optional):
    if 'any' in propertyName:
        return 'mixed'
    return propertyName.replace('Obj', '') + ('?' if 'opt' in optional else '')

types = [{'class': t[0],
          'obj': t[1],
          'prop': t[2],
          'k0': t[3][0],
          'k1': t[3][1],
          'v0': t[4][0],
          'v1': t[4][1],
          'dictionary': t[1] + '.' + t[2],
          'values': '@{ ' + ', '.join('{}: {}'.format(pair[0], pair[1]) for pair in zip(t[3], t[4])) + ' }',
          'firstKey': t[3][0],
          'firstValue': t[4][0],
          'last': t[4][2] if len(t[4]) == 3 else t[4][1],
          'wrong': '@"a"', 'wdesc': 'a', 'wtype': 'RLMConstantString',
          'type': type_name(t[2], t[1]),
          'tags': set(t[5]),
         }
         for t in types]

# Add negative tags to all types
all_tags = set()
for t in types:
    all_tags |= t['tags']
for t in types:
    for missing in all_tags - t['tags']:
        t['tags'].add('no' + missing)

# For testing error handling we need a value of the wrong type. By default this
# is a string, so for string types we need to set it to a number instead
for string_type in (t for t in types if 'string' in t['tags']):
    string_type['wrong'] = '@2'
    string_type['wdesc'] = '2'
    string_type['wtype'] = 'RLMConstantInt'

# We extract the type name from the property name, but object id and decimal128
# don't have names that work for this
for type in types:
    type['type'] = type['type'].replace('objectId', 'object id').replace('decimal', 'decimal128')
    type['basetype'] = type['type'].replace('?', '')

file = open(os.path.dirname(__file__) + '/PrimitiveDictionaryPropertyTests.tpl.m', 'rt')
for line in file:
    # Lines without anything to expand just appear as-is
    if not '$' in line:
        print line,
        continue

    if '$allDictionaries' in line:
        line = line.replace(' ^n', '\n' + ' ' * (line.find('(') + 4))
        line = line.replace('$allDictionaries', 'dictionary')
        print '    for (RLMDictionary *dictionary in allDictionaries) {\n    ' + line + '    }'
        continue

    filtered_types = types
    start = 0
    end = len(types)
    # Limit the types to the ones which match all of the tags present in the
    # line, then remove the tags from the line
    for tag in re.findall(r'\%([a-z]+)', line):
        filtered_types = [t for t in filtered_types if tag in t['tags']]
        line = line.replace('%' + tag + ' ', '')

    # Places where we want multiple output lines from one input line use ^nl
    # for subsequent statements and ^n for things which should be indented within
    # parentheses. This is a pretty half-hearted attempt at producing properly
    # indented output.
    line = line.replace(' ^nl ', '\n    ')
    line = line.replace(' ^n', '\n' + ' ' * line.find('('))

    # Repeat each line for each type, replacing variables with values from the dictionary
    for t in filtered_types:
        l = line
        for k, v in t.iteritems():
            if k in l:
                l = l.replace('$' + k, v)
        print l,
