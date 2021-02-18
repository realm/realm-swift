import os, re

# Tags:
# (no)minmax: Type supports min() and max()
# (no)sum: Type supports sum()
# (no)avg: Type supports average()
# r/o: Type is Required or Optional
# (un)man: Type is Managed or Unmanaged

types = [
  # Class, Object, Property, Values, Tags
  ['AllPrimitiveDictionaries', 'unmanaged', 'boolObj', ['@NO', '@YES'], {'r', 'unman'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'intObj', ['@2', '@3'], {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'floatObj', ['@2.2f', '@3.3f'], {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'doubleObj', ['@2.2', '@3.3'], {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'stringObj', ['@"a"', '@"b"'], {'r', 'unman', 'string'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'dataObj', ['data(1)', 'data(2)'], {'r', 'unman'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'dateObj', ['date(1)', 'date(2)'], {'r', 'minmax', 'unman', 'date'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'decimalObj', ['decimal128(2)', 'decimal128(3)'], {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'objectIdObj', ['objectId(1)', 'objectId(2)'], {'r', 'unman'}],
  ['AllPrimitiveDictionaries', 'unmanaged', 'uuidObj', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")'], ['r','unman']],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'boolObj', ['@NO', '@YES', 'NSNull.null'], {'o', 'unman'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'intObj', ['@2', '@3', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'floatObj', ['@2.2f', '@3.3f', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'doubleObj', ['@2.2', '@3.3', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'stringObj', ['@"a"', '@"b"', 'NSNull.null'], {'o', 'unman', 'string'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'dataObj', ['data(1)', 'data(2)', 'NSNull.null'], {'o', 'unman'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'dateObj', ['date(1)', 'date(2)', 'NSNull.null'], {'o', 'minmax', 'unman', 'date'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'decimalObj', ['decimal128(2)', 'decimal128(3)', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'objectIdObj', ['objectId(1)', 'objectId(2)', 'NSNull.null'], {'o', 'unman'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'uuidObj', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")', 'NSNull.null'], ['o', 'unman']],
  ['AllPrimitiveDictionaries', 'managed', 'boolObj', ['@NO', '@YES'], {'r', 'man'}],
  ['AllPrimitiveDictionaries', 'managed', 'intObj', ['@2', '@3'], {'r', 'minmax', 'sum', 'avg', 'man'}],
  ['AllPrimitiveDictionaries', 'managed', 'floatObj', ['@2.2f', '@3.3f'], {'r', 'minmax', 'sum', 'avg', 'man'}],
  ['AllPrimitiveDictionaries', 'managed', 'doubleObj', ['@2.2', '@3.3'], {'r', 'minmax', 'sum', 'avg', 'man'}],
  ['AllPrimitiveDictionaries', 'managed', 'stringObj', ['@"a"', '@"b"'], {'r', 'man', 'string'}],
  ['AllPrimitiveDictionaries', 'managed', 'dataObj', ['data(1)', 'data(2)'], {'r', 'man'}],
  ['AllPrimitiveDictionaries', 'managed', 'dateObj', ['date(1)', 'date(2)'], {'r', 'minmax', 'man', 'date'}],
  ['AllPrimitiveDictionaries', 'managed', 'decimalObj', ['decimal128(2)', 'decimal128(3)'], {'r', 'minmax', 'sum', 'avg', 'man'}],
  ['AllPrimitiveDictionaries', 'managed', 'objectIdObj', ['objectId(1)', 'objectId(2)'], {'r', 'man'}],
  ['AllPrimitiveDictionaries', 'managed', 'uuidObj', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")'], ['r', 'man']],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'boolObj', ['@NO', '@YES', 'NSNull.null'], {'o', 'man'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'intObj', ['@2', '@3', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'man'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'floatObj', ['@2.2f', '@3.3f', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'man'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'doubleObj', ['@2.2', '@3.3', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'man'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'stringObj', ['@"a"', '@"b"', 'NSNull.null'], {'o', 'man', 'string'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'dataObj', ['data(1)', 'data(2)', 'NSNull.null'], {'o', 'man'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'dateObj', ['date(1)', 'date(2)', 'NSNull.null'], {'o', 'minmax', 'man', 'date'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'decimalObj', ['decimal128(2)', 'decimal128(3)', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'man'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'objectIdObj', ['objectId(1)', 'objectId(2)', 'NSNull.null'], {'o', 'man'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'uuidObj', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")', 'NSNull.null'], ['o', 'man']]
]
types = [{'class': t[0], 'obj': t[1], 'prop': t[2], 'v0': t[3][0], 'v1': t[3][1],
          'dictionary': t[1] + '.' + t[2],
          'values2': '@[' + ', '.join(t[3] * 2) + ']',
          'values': '@[' + ', '.join(t[3]) + ']',
          'first': t[3][0], 'last': t[3][2] if len(t[3]) == 3 else t[3][1],
          'wrong': '@"a"', 'wdesc': 'a', 'wtype': '__NSCFConstantString',
          'type': t[2].replace('Obj', '') + ('?' if 'opt' in t[1] else ''),
          'tags': set(t[4]),
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
    string_type['wtype'] = '__NSCFNumber'

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
        print '    for (RLMDictionary *dictionary in allDictionaries) {\n    ' + line.replace('$allDictionaries', 'dictionary') + '    }'
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
