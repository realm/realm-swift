import os, re

# Tags:
# (un)minmax: Type supports min() and max()
# (un)sum: Type supports sum()
# (un)avg: Type supports average()
# r/o: Type is Required or Optional
# (un)man: Type is Managed or Unmanaged
# maxtwovalues: Type that can contain only 2 values, e.g non-optional bool
# nomaxvalues: Type that can contain any amount of values
# (no)any: Can accept any type
# (no)date: Stores dates

types = [
  # Class, Object, Property, Values, Values2, Tags
  ['AllPrimitiveSets', 'unmanaged', 'boolObj', ['@NO', '@YES'], ['@NO', '@YES'], ['r', 'unman', 'maxtwovalues']],
  ['AllPrimitiveSets', 'unmanaged', 'intObj', ['@2', '@3'], ['@2', '@4'], ['r', 'minmax', 'sum', 'avg', 'unman']],
  ['AllPrimitiveSets', 'unmanaged', 'floatObj', ['@2.2f', '@3.3f'], ['@2.2f', '@4.4f'], ['r', 'minmax', 'sum', 'avg', 'unman']],
  ['AllPrimitiveSets', 'unmanaged', 'doubleObj', ['@2.2', '@3.3'], ['@2.2', '@4.4'], ['r', 'minmax', 'sum', 'avg', 'unman']],
  ['AllPrimitiveSets', 'unmanaged', 'stringObj', ['@"a"', '@"bc"'], ['@"a"', '@"de"'], ['r', 'unman', 'string']],
  ['AllPrimitiveSets', 'unmanaged', 'dataObj', ['data(1)', 'data(2)'], ['data(1)', 'data(3)'], ['r', 'unman']],
  ['AllPrimitiveSets', 'unmanaged', 'dateObj', ['date(1)', 'date(2)'], ['date(1)', 'date(3)'], ['r', 'minmax', 'unman', 'date']],
  ['AllPrimitiveSets', 'unmanaged', 'decimalObj', ['decimal128(1)', 'decimal128(2)'], ['decimal128(1)', 'decimal128(3)'], ['r', 'minmax', 'sum', 'avg', 'unman']],
  ['AllPrimitiveSets', 'unmanaged', 'objectIdObj', ['objectId(1)', 'objectId(2)'], ['objectId(1)', 'objectId(3)'], ['r', 'unman']],
  ['AllPrimitiveSets', 'unmanaged', 'uuidObj', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")'], ['r', 'unman']],

  ['AllPrimitiveSets', 'unmanaged', 'anyBoolObj', ['@NO', '@YES'], ['@NO', '@YES'], {'r', 'any', 'unman'}],
  ['AllPrimitiveSets', 'unmanaged', 'anyIntObj', ['@2', '@3'], ['@2', '@4'], {'r', 'any', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveSets', 'unmanaged', 'anyFloatObj', ['@2.2f', '@3.3f'], ['@4.4f', '@3.3f'], {'r', 'any', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveSets', 'unmanaged', 'anyDoubleObj', ['@2.2', '@3.3'], ['@2.2', '@4.4'], {'r', 'any', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveSets', 'unmanaged', 'anyStringObj', ['@"a"', '@"b"'], ['@"a"', '@"d"'], {'r', 'any', 'unman', 'string'}],
  ['AllPrimitiveSets', 'unmanaged', 'anyDataObj', ['data(1)', 'data(2)'], ['data(1)', 'data(3)'], {'r', 'any', 'unman'}],
  ['AllPrimitiveSets', 'unmanaged', 'anyDateObj', ['date(1)', 'date(2)'], ['date(1)', 'date(4)'], {'r', 'any', 'minmax', 'unman', 'date'}],
  ['AllPrimitiveSets', 'unmanaged', 'anyDecimalObj', ['decimal128(1)', 'decimal128(2)'], ['decimal128(1)', 'decimal128(3)'], {'r', 'any', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveSets', 'unmanaged', 'anyObjectIdObj', ['objectId(1)', 'objectId(2)'], ['objectId(1)', 'objectId(3)'], {'r', 'any', 'unman'}],
  ['AllPrimitiveSets', 'unmanaged', 'anyUUIDObj', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")'], ['r', 'any','unman']],

  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'boolObj', ['NSNull.null', '@NO', '@YES'], ['@YES', '@NO'], ['o' 'unman', 'maxtwovalues']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'intObj', ['NSNull.null', '@2', '@3'], ['@3', '@4'], ['o', 'minmax', 'sum', 'avg', 'unman']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'floatObj', ['NSNull.null', '@2.2f', '@3.3f'], ['@3.3f', '@4.4f'], ['o', 'minmax', 'sum', 'avg', 'unman']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'doubleObj', ['NSNull.null', '@2.2', '@3.3'], ['@3.3', '@4.4'], ['o', 'minmax', 'sum', 'avg', 'unman']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'stringObj', ['NSNull.null', '@"a"', '@"bc"'], ['@"bc"', '@"de"'], ['o', 'unman', 'string']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'dataObj', ['NSNull.null', 'data(1)', 'data(2)'], ['data(2)', 'data(3)'], ['o', 'unman']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'dateObj', ['NSNull.null', 'date(1)', 'date(2)'], ['date(2)', 'date(3)'], ['o', 'minmax', 'unman', 'date']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'decimalObj', ['NSNull.null', 'decimal128(1)', 'decimal128(2)'], ['decimal128(2)', 'decimal128(4)'], ['o', 'minmax', 'sum', 'avg', 'unman']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'objectIdObj', ['NSNull.null', 'objectId(1)', 'objectId(2)'], ['objectId(2)', 'objectId(4)'], ['o', 'unman']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'uuidObj', ['NSNull.null','uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")', 'uuid(@"00000000-0000-0000-0000-000000000000")'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")'], ['o', 'unman']],

  ['AllPrimitiveSets', 'managed', 'boolObj', ['@NO', '@YES'], ['@YES', '@NO'], ['r', 'man', 'maxtwovalues']],
  ['AllPrimitiveSets', 'managed', 'intObj', ['@2', '@3'], ['@3', '@4'], ['r', 'minmax', 'sum', 'avg', 'man']],
  ['AllPrimitiveSets', 'managed', 'floatObj', ['@2.2f', '@3.3f'], ['@3.3f', '@4.4f'], ['r', 'minmax', 'sum', 'avg', 'man']],
  ['AllPrimitiveSets', 'managed', 'doubleObj', ['@2.2', '@3.3'], ['@3.3', '@4.4'], ['r', 'minmax', 'sum', 'avg', 'man']],
  ['AllPrimitiveSets', 'managed', 'stringObj', ['@"a"', '@"bc"'], ['@"bc"', '@"de"'], ['r', 'nominmax', 'man', 'string']],
  ['AllPrimitiveSets', 'managed', 'dataObj', ['data(1)', 'data(2)'], ['data(2)', 'data(3)'], ['r', 'man']],
  ['AllPrimitiveSets', 'managed', 'dateObj', ['date(1)', 'date(2)'], ['date(2)', 'date(3)'], ['r', 'minmax', 'man', 'date']],
  ['AllPrimitiveSets', 'managed', 'decimalObj', ['decimal128(1)', 'decimal128(2)'], ['decimal128(2)', 'decimal128(3)'], ['r', 'minmax', 'sum', 'avg', 'man']],
  ['AllPrimitiveSets', 'managed', 'objectIdObj', ['objectId(1)', 'objectId(2)'], ['objectId(2)', 'objectId(3)'], ['r', 'nominmax', 'man']],
  ['AllPrimitiveSets', 'managed', 'uuidObj', ['uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")', 'uuid(@"00000000-0000-0000-0000-000000000000")'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")'], ['r', 'man']],

  ['AllPrimitiveSets', 'managed', 'anyBoolObj', ['@NO', '@YES'], ['@NO', '@YES'], {'r', 'any', 'man'}],
  ['AllPrimitiveSets', 'managed', 'anyIntObj', ['@2', '@3'], ['@2', '@4'], {'r', 'any', 'minmax', 'sum', 'avg', 'man'}],
  ['AllPrimitiveSets', 'managed', 'anyFloatObj', ['@2.2f', '@3.3f'], ['@2.2f', '@4.4f'], {'r', 'any', 'minmax', 'sum', 'avg', 'man'}],
  ['AllPrimitiveSets', 'managed', 'anyDoubleObj', ['@2.2', '@3.3'], ['@2.2', '@4.4'], {'r', 'any', 'minmax', 'sum', 'avg', 'man'}],
  ['AllPrimitiveSets', 'managed', 'anyStringObj', ['@"a"', '@"b"'], ['@"a"', '@"d"'], {'r', 'any', 'man', 'string'}],
  ['AllPrimitiveSets', 'managed', 'anyDataObj', ['data(1)', 'data(2)'], ['data(1)', 'data(3)'], {'r', 'any', 'man'}],
  ['AllPrimitiveSets', 'managed', 'anyDateObj', ['date(1)', 'date(2)'], ['date(1)', 'date(3)'], {'r', 'any', 'minmax', 'man', 'date'}],
  ['AllPrimitiveSets', 'managed', 'anyDecimalObj', ['decimal128(1)', 'decimal128(2)'], ['decimal128(1)', 'decimal128(3)'], {'r', 'any', 'minmax', 'sum', 'avg', 'man'}],
  ['AllPrimitiveSets', 'managed', 'anyObjectIdObj', ['objectId(1)', 'objectId(2)'], ['objectId(1)', 'objectId(3)'], {'r', 'any', 'man'}],
  ['AllPrimitiveSets', 'managed', 'anyUUIDObj', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")'], ['r', 'any', 'man']],

  ['AllOptionalPrimitiveSets', 'optManaged', 'boolObj', ['NSNull.null', '@NO', '@YES'], ['@YES', '@NO'], ['o', 'nominmax', 'nosum', 'noavg', 'man', 'maxtwovalues']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'intObj', ['NSNull.null', '@2', '@3'], ['@3', '@4'], ['o', 'minmax', 'sum', 'avg', 'man']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'floatObj', ['NSNull.null', '@2.2f', '@3.3f'], ['@3.3f', '@4.4f'], ['o', 'minmax', 'sum', 'avg', 'man']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'doubleObj', ['NSNull.null', '@2.2', '@3.3'], ['@3.3', '@4.4'], ['o', 'minmax', 'sum', 'avg', 'man']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'stringObj', ['NSNull.null', '@"a"', '@"bc"'], ['@"bc"', '@"de"'], ['o', 'man', 'string']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'dataObj', ['NSNull.null', 'data(1)', 'data(2)'], ['data(2)', 'data(3)'], ['o', 'man']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'dateObj', ['NSNull.null', 'date(1)', 'date(2)'], ['date(2)', 'date(3)'], ['o', 'minmax', 'man', 'date']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'decimalObj', ['NSNull.null', 'decimal128(1)', 'decimal128(2)'], ['decimal128(2)', 'decimal128(3)'], ['o', 'minmax', 'sum', 'avg', 'man']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'objectIdObj', ['NSNull.null', 'objectId(1)', 'objectId(2)'], ['objectId(2)', 'objectId(3)'], ['o', 'man']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'uuidObj', ['NSNull.null', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")', 'uuid(@"00000000-0000-0000-0000-000000000000")'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")'], ['o', 'man']],
]

def type_name(propertyName, optional):
    if 'any' in propertyName:
        return 'mixed'
    else:
        return propertyName.replace('Obj', '') + ('?' if 'opt' in optional else '')

types = [{'class': t[0],
          'obj': t[1],
          'prop': t[2],
          'v0': t[3][0],
          'v1': t[3][1],
          'v2': len(t[3])>2 and t[3][2] or 'NSNull.null',
          'v3': t[4][0],
          'v4': t[4][1],
          'set': t[1] + '.' + t[2],
          'set2': t[1] + '.' + t[2],
          'values': '@[' + ', '.join(t[3]) + ']',
          'values2': '@[' + ', '.join(t[4]) + ']',
          'first': t[3][0], 'last': t[3][2] if len(t[3]) == 3 else t[3][1],
          'wrong': '@"a"', 'wdesc': 'a', 'wtype': 'RLMConstantString',
          'type': type_name(t[2], t[1]),
          'tags': set(t[5])
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

file = open(os.path.dirname(__file__) + '/PrimitiveSetPropertyTests.tpl.m', 'rt')
for line in file:
    if not '$' in line:
        print line,
        continue
    if '$allSets' in line:
        line = line.replace(' ^n', '\n' + ' ' * (line.find('(') + 4))
        print '    for (RLMSet *set in allSets) {\n    ' + line.replace('$allSets', 'set') + '    }'
        continue

    filtered_types = types

    start = 0
    end = len(types)
    for tag in re.findall(r'\%([a-z]+)', line):
        filtered_types = [t for t in filtered_types if tag in t['tags']]
        line = line.replace('%' + tag + ' ', '')


    line = line.replace('^nl', '\n    ')
    line = line.replace('^n', '\n' + ' ' * line.find('('))

    for t in filtered_types:
        l = line
        for k, v in t.iteritems():
            if k in l:
                l = l.replace('$' + k, v)
        print l,
