import os, re

# Tags:
# (no)minmax: Type supports min() and max()
# (no)sum: Type supports sum()
# (no)avg: Type supports average()
# r/o: Type is Required or Optional
# (un)man: Type is Managed or Unmanaged

types = [
  # Class, Object, Property, Values, Tags
  ['AllPrimitiveDictionaries', 'unmanaged', 'boolObj', ['@NO', '@YES'], ['@NO', '@YES'], {'r', 'unman'}, '__NSCFBoolean'],
  ['AllPrimitiveDictionaries', 'unmanaged', 'intObj', ['@2', '@3'], ['@2', '@4'], {'r', 'minmax', 'sum', 'avg', 'unman'}, '__NSCFNumber'],
#  ['AllPrimitiveDictionaries', 'unmanaged', 'floatObj', ['@2.2f', '@3.3f'], ['@2.2f', '@4.4f'], {'r', 'minmax', 'sum', 'avg', 'unman'}, '__NSCFNumber'],
#  ['AllPrimitiveDictionaries', 'unmanaged', 'doubleObj', ['@2.2', '@3.3'], ['@2.2', '@4.4'], {'r', 'minmax', 'sum', 'avg', 'unman'}, '__NSCFNumber'],
  ['AllPrimitiveDictionaries', 'unmanaged', 'stringObj', ['@"a"', '@"b"'], ['@"a"', '@"de"'], {'r', 'unman', 'string'}, '__NSCFConstantString'],
#  ['AllPrimitiveDictionaries', 'unmanaged', 'dataObj', ['data(1)', 'data(2)'], ['data(1)', 'data(3)'], {'r', 'unman'}, 'NSConcreteData'],
#  ['AllPrimitiveDictionaries', 'unmanaged', 'dateObj', ['date(1)', 'date(2)'], ['date(1)', 'date(3)'], {'r', 'minmax', 'unman', 'date'}, '__NSTaggedDate'],
#  ['AllPrimitiveDictionaries', 'unmanaged', 'decimalObj', ['decimal128(2)', 'decimal128(3)'], ['decimal128(1)', 'decimal128(3)'], {'r', 'minmax', 'sum', 'avg', 'unman'}, 'RLMDecimal128'],
#  ['AllPrimitiveDictionaries', 'unmanaged', 'objectIdObj', ['objectId(1)', 'objectId(2)'], ['objectId(1)', 'objectId(3)'], {'r', 'unman'}, 'RLMObjectId'],
#  ['AllPrimitiveDictionaries', 'unmanaged', 'uuidObj', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")'], {'r','unman'}, '__NSConcreteUUID'],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'boolObj', ['@NO', '@YES', 'NSNull.null'], ['@YES', '@NO'], {'o', 'unman'}, '__NSCFBoolean'],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'intObj', ['@2', '@3', 'NSNull.null'], ['@3', '@4'], {'o', 'minmax', 'sum', 'avg', 'unman'}, '__NSCFNumber'],
#  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'floatObj', ['@2.2f', '@3.3f', 'NSNull.null'], ['@3.3f', '@4.4f'], {'o', 'minmax', 'sum', 'avg', 'unman'}, '__NSCFNumber'],
#  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'doubleObj', ['@2.2', '@3.3', 'NSNull.null'], ['@3.3', '@4.4'], {'o', 'minmax', 'sum', 'avg', 'unman'}, '__NSCFNumber'],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'stringObj', ['@"a"', '@"b"', 'NSNull.null'], ['@"bc"', '@"de"'], {'o', 'unman', 'string'}, '__NSCFConstantString'],
#  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'dataObj', ['data(1)', 'data(2)', 'NSNull.null'], ['data(2)', 'data(3)'], {'o', 'unman'}, 'NSConcreteData'],
#  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'dateObj', ['date(1)', 'date(2)', 'NSNull.null'], ['date(2)', 'date(3)'], {'o', 'minmax', 'unman', 'date'}, '__NSTaggedDate'],
#  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'decimalObj', ['decimal128(2)', 'decimal128(3)', 'NSNull.null'], ['decimal128(2)', 'decimal128(4)'], {'o', 'minmax', 'sum', 'avg', 'unman'}, 'RLMDecimal128'],
#  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'objectIdObj', ['objectId(1)', 'objectId(2)', 'NSNull.null'], ['objectId(2)', 'objectId(4)'], {'o', 'unman'}, 'RLMObjectId'],
#  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'uuidObj', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")', 'NSNull.null'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")'], {'o', 'unman'}, '__NSConcreteUUID'],
  ['AllPrimitiveDictionaries', 'managed', 'boolObj', ['@NO', '@YES'], ['@YES', '@NO'], {'r', 'man'}, '__NSCFBoolean'],
  ['AllPrimitiveDictionaries', 'managed', 'intObj', ['@2', '@3'], ['@3', '@4'], {'r', 'minmax', 'sum', 'avg', 'man'}, '__NSCFNumber'],
#  ['AllPrimitiveDictionaries', 'managed', 'floatObj', ['@2.2f', '@3.3f'], ['@3.3f', '@4.4f'], {'r', 'minmax', 'sum', 'avg', 'man'}, '__NSCFNumber'],
#  ['AllPrimitiveDictionaries', 'managed', 'doubleObj', ['@2.2', '@3.3'], ['@3.3', '@4.4'], {'r', 'minmax', 'sum', 'avg', 'man'}, '__NSCFNumber'],
  ['AllPrimitiveDictionaries', 'managed', 'stringObj', ['@"a"', '@"b"'], ['@"bc"', '@"de"'], {'r', 'man', 'string'}, '__NSCFConstantString'],
#  ['AllPrimitiveDictionaries', 'managed', 'dataObj', ['data(1)', 'data(2)'], ['data(2)', 'data(3)'], {'r', 'man'}, 'NSConcreteData'],
#  ['AllPrimitiveDictionaries', 'managed', 'dateObj', ['date(1)', 'date(2)'], ['date(2)', 'date(3)'], {'r', 'minmax', 'man', 'date'}, '__NSTaggedDate'],
#  ['AllPrimitiveDictionaries', 'managed', 'decimalObj', ['decimal128(2)', 'decimal128(3)'], ['decimal128(2)', 'decimal128(3)'], {'r', 'minmax', 'sum', 'avg', 'man'}, 'RLMDecimal128'],
#  ['AllPrimitiveDictionaries', 'managed', 'objectIdObj', ['objectId(1)', 'objectId(2)'], ['objectId(2)', 'objectId(3)'], {'r', 'man'}, 'RLMObjectId'],
#  ['AllPrimitiveDictionaries', 'managed', 'uuidObj', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")'], {'r', 'man'}, '__NSConcreteUUID'],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'boolObj', ['@NO', '@YES', 'NSNull.null'], ['@YES', '@NO'], {'o', 'man'}, '__NSCFBoolean'],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'intObj', ['@2', '@3', 'NSNull.null'], ['@3', '@4'], {'o', 'minmax', 'sum', 'avg', 'man'}, '__NSCFNumber'],
#  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'floatObj', ['@2.2f', '@3.3f', 'NSNull.null'], ['@3.3f', '@4.4f'], {'o', 'minmax', 'sum', 'avg', 'man'}, '__NSCFNumber'],
#  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'doubleObj', ['@2.2', '@3.3', 'NSNull.null'], ['@3.3', '@4.4'], {'o', 'minmax', 'sum', 'avg', 'man'}, '__NSCFNumber'],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'stringObj', ['@"a"', '@"b"', 'NSNull.null'], ['@"bc"', '@"de"'], {'o', 'man', 'string'}, '__NSCFConstantString'],
#  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'dataObj', ['data(1)', 'data(2)', 'NSNull.null'], ['data(2)', 'data(3)'], {'o', 'man'}, 'NSConcreteData'],
#  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'dateObj', ['date(1)', 'date(2)', 'NSNull.null'], ['date(2)', 'date(3)'], {'o', 'minmax', 'man', 'date'}, '__NSTaggedDate'],
#  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'decimalObj', ['decimal128(2)', 'decimal128(3)', 'NSNull.null'], ['decimal128(2)', 'decimal128(3)'], {'o', 'minmax', 'sum', 'avg', 'man'}, 'RLMDecimal128'],
#  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'objectIdObj', ['objectId(1)', 'objectId(2)', 'NSNull.null'], ['objectId(2)', 'objectId(3)'], {'o', 'man'}, 'RLMObjectId'],
#  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'uuidObj', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")', 'NSNull.null'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")'], {'o', 'man'}, '__NSConcreteUUID']
]
types = [{'class': t[0],
          'obj': t[1],
          'prop': t[2],
          'v0': t[3][0],
          'v1': t[3][1],
          'dictionary': t[1] + '.' + t[2],
          'values': '@{' + ', '.join('@"{}": {}'.format(k, v) for k, v in enumerate(t[3])) + '}',
          'values2': '@{' + ', '.join('@"{}": {}'.format(k, v) for k, v in enumerate(t[4])) + '}',
          'first': t[3][0],
          'last': t[3][2] if len(t[3]) == 3 else t[3][1],
          'wrong': '@"a"',
          'wdesc': 'a',
          'wtype': '__NSCFConstantString',
          'type': t[2].replace('Obj', '') + ('?' if 'opt' in t[1] else ''),
          'tags': set(t[5]),
          'cType': t[6],
          'cVal': t[3][0].replace('@', '').replace('"', '').replace('f', '').replace('NO', '0')
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
