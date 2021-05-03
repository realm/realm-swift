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
  ['AllPrimitiveDictionaries', 'unmanaged', 'stringObj', ['@"key1"', '@"key2"'], ['@"foo"', '@"bar"'], {'r', 'unman', 'string'}],
  ['AllOptionalPrimitiveDictionaries', 'optUnmanaged', 'stringObj', ['@"key1"', '@"key2"'], ['@"foo"', 'NSNull.null'], {'o', 'unman', 'string'}],
  ['AllPrimitiveDictionaries', 'managed', 'stringObj', ['@"key1"', '@"key2"'], ['@"foo"', '@"bar"'], {'r', 'man', 'string'}],
  ['AllOptionalPrimitiveDictionaries', 'optManaged', 'stringObj', ['@"key1"', '@"key2"'], ['@"foo"', 'NSNull.null'], {'o', 'man', 'string'}],
]

def type_name(propertyName, optional):
    if 'any' in propertyName:
        return 'mixed'
    else:
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
          'wrong': '@"a"', 'wdesc': 'a', 'wtype': '__NSCFConstantString',
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
