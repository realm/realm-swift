import os, re

# Tags:
# (un)minmax: Type supports min() and max()
# (un)sum: Type supports sum()
# (un)avg: Type supports average()
# r/o: Type is Required or Optional
# (un)man: Type is Managed or Unmanaged
# maxtwovalues: Type that can contain only 2 values, e.g non-optional bool
# nomaxvalues: Type that can contain any amount of values

types = [
  # Class, Object, Property, Values, Values2, Tags
  ['AllPrimitiveSets', 'unmanaged', 'boolObj', ['@NO', '@YES'], ['@NO', '@YES'], ['r', 'nominmax', 'nosum', 'noavg', 'unman', 'maxtwovalues']],
  ['AllPrimitiveSets', 'unmanaged', 'intObj', ['@2', '@3'], ['@2', '@4'], ['r', 'minmax', 'sum', 'avg', 'unman', 'nomaxvalues']],
  ['AllPrimitiveSets', 'unmanaged', 'floatObj', ['@2.2f', '@3.3f'], ['@2.2f', '@4.4f'], ['r', 'minmax', 'sum', 'avg', 'unman', 'nomaxvalues']],
  ['AllPrimitiveSets', 'unmanaged', 'doubleObj', ['@2.2', '@3.3'], ['@2.2', '@4.4'], ['r', 'minmax', 'sum', 'avg', 'unman', 'nomaxvalues']],
  ['AllPrimitiveSets', 'unmanaged', 'stringObj', ['@"a"', '@"bc"'], ['@"a"', '@"de"'], ['r', 'nominmax', 'nosum', 'noavg', 'unman', 'string', 'nomaxvalues']],
  ['AllPrimitiveSets', 'unmanaged', 'dataObj', ['data(1)', 'data(2)'], ['data(1)', 'data(3)'], ['r', 'nominmax', 'nosum', 'noavg', 'unman', 'nomaxvalues']],
  ['AllPrimitiveSets', 'unmanaged', 'dateObj', ['date(1)', 'date(2)'], ['date(1)', 'date(3)'], ['r', 'minmax', 'nosum', 'noavg', 'unman', 'nomaxvalues']],
  ['AllPrimitiveSets', 'unmanaged', 'decimalObj', ['decimal128(1)', 'decimal128(2)'], ['decimal128(1)', 'decimal128(3)'], ['r', 'minmax', 'sum', 'avg', 'unman', 'nomaxvalues']],
  ['AllPrimitiveSets', 'unmanaged', 'objectIdObj', ['objectId(1)', 'objectId(2)'], ['objectId(1)', 'objectId(3)'], ['r', 'nominmax', 'nosum', 'noavg', 'unman', 'nomaxvalues']],
  ['AllPrimitiveSets', 'unmanaged', 'uuidObj', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")'], ['r', 'nominmax', 'nosum', 'noavg', 'unman', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'boolObj', ['NSNull.null', '@NO', '@YES'], ['@YES', '@NO'], ['o', 'nominmax', 'nosum', 'noavg', 'unman', 'maxtwovalues']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'intObj', ['NSNull.null', '@2', '@3'], ['@3', '@4'], ['o', 'minmax', 'sum', 'avg', 'unman', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'floatObj', ['NSNull.null', '@2.2f', '@3.3f'], ['@3.3f', '@4.4f'], ['o', 'minmax', 'sum', 'avg', 'unman', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'doubleObj', ['NSNull.null', '@2.2', '@3.3'], ['@3.3', '@4.4'], ['o', 'minmax', 'sum', 'avg', 'unman', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'stringObj', ['NSNull.null', '@"a"', '@"bc"'], ['@"bc"', '@"de"'], ['o', 'nominmax', 'nosum', 'noavg', 'unman', 'string', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'dataObj', ['NSNull.null', 'data(1)', 'data(2)'], ['data(2)', 'data(3)'], ['o', 'nominmax', 'nosum', 'noavg', 'unman', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'dateObj', ['NSNull.null', 'date(1)', 'date(2)'], ['date(2)', 'date(3)'], ['o', 'minmax', 'nosum', 'noavg', 'unman', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'decimalObj', ['NSNull.null', 'decimal128(1)', 'decimal128(2)'], ['decimal128(2)', 'decimal128(4)'], ['o', 'minmax', 'sum', 'avg', 'unman', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'objectIdObj', ['NSNull.null', 'objectId(1)', 'objectId(2)'], ['objectId(2)', 'objectId(4)'], ['o', 'nominmax', 'nosum', 'noavg', 'unman', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'uuidObj', ['NSNull.null','uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")', 'uuid(@"00000000-0000-0000-0000-000000000000")'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")'], ['o', 'nominmax', 'nosum', 'noavg', 'unman', 'nomaxvalues']],
  ['AllPrimitiveSets', 'managed', 'boolObj', ['@NO', '@YES'], ['@YES', '@NO'], ['r', 'nominmax', 'nosum', 'noavg', 'man', 'maxtwovalues']],
  ['AllPrimitiveSets', 'managed', 'intObj', ['@2', '@3'], ['@3', '@4'], ['r', 'minmax', 'sum', 'avg', 'man', 'nomaxvalues']],
  ['AllPrimitiveSets', 'managed', 'floatObj', ['@2.2f', '@3.3f'], ['@3.3f', '@4.4f'], ['r', 'minmax', 'sum', 'avg', 'man', 'nomaxvalues']],
  ['AllPrimitiveSets', 'managed', 'doubleObj', ['@2.2', '@3.3'], ['@3.3', '@4.4'], ['r', 'minmax', 'sum', 'avg', 'man', 'nomaxvalues']],
  ['AllPrimitiveSets', 'managed', 'stringObj', ['@"a"', '@"bc"'], ['@"bc"', '@"de"'], ['r', 'nominmax', 'nosum', 'noavg', 'man', 'string', 'nomaxvalues']],
  ['AllPrimitiveSets', 'managed', 'dataObj', ['data(1)', 'data(2)'], ['data(2)', 'data(3)'], ['r', 'nominmax', 'nosum', 'noavg', 'man', 'nomaxvalues']],
  ['AllPrimitiveSets', 'managed', 'dateObj', ['date(1)', 'date(2)'], ['date(2)', 'date(3)'], ['r', 'minmax', 'nosum', 'noavg', 'man', 'nomaxvalues']],
  ['AllPrimitiveSets', 'managed', 'decimalObj', ['decimal128(1)', 'decimal128(2)'], ['decimal128(2)', 'decimal128(3)'], ['r', 'minmax', 'sum', 'avg', 'man', 'nomaxvalues']],
  ['AllPrimitiveSets', 'managed', 'objectIdObj', ['objectId(1)', 'objectId(2)'], ['objectId(2)', 'objectId(3)'], ['r', 'nominmax', 'nosum', 'noavg', 'man', 'nomaxvalues']],
  ['AllPrimitiveSets', 'managed', 'uuidObj', ['uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")', 'uuid(@"00000000-0000-0000-0000-000000000000")'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")'], ['r', 'nominmax', 'nosum', 'noavg', 'man', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'boolObj', ['NSNull.null', '@NO', '@YES'], ['@YES', '@NO'], ['o', 'nominmax', 'nosum', 'noavg', 'man', 'maxtwovalues']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'intObj', ['NSNull.null', '@2', '@3'], ['@3', '@4'], ['o', 'minmax', 'sum', 'avg', 'man', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'floatObj', ['NSNull.null', '@2.2f', '@3.3f'], ['@3.3f', '@4.4f'], ['o', 'minmax', 'sum', 'avg', 'man', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'doubleObj', ['NSNull.null', '@2.2', '@3.3'], ['@3.3', '@4.4'], ['o', 'minmax', 'sum', 'avg', 'man', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'stringObj', ['NSNull.null', '@"a"', '@"bc"'], ['@"bc"', '@"de"'], ['o', 'nominmax', 'nosum', 'noavg', 'man', 'string', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'dataObj', ['NSNull.null', 'data(1)', 'data(2)'], ['data(2)', 'data(3)'], ['o', 'nominmax', 'nosum', 'noavg', 'man', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'dateObj', ['NSNull.null', 'date(1)', 'date(2)'], ['date(2)', 'date(3)'], ['o', 'minmax', 'nosum', 'noavg', 'man', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'decimalObj', ['NSNull.null', 'decimal128(1)', 'decimal128(2)'], ['decimal128(2)', 'decimal128(3)'], ['o', 'minmax', 'sum', 'avg', 'man', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'objectIdObj', ['NSNull.null', 'objectId(1)', 'objectId(2)'], ['objectId(2)', 'objectId(3)'], ['o', 'nominmax', 'nosum', 'noavg', 'man', 'nomaxvalues']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'uuidObj', ['NSNull.null', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")', 'uuid(@"00000000-0000-0000-0000-000000000000")'], ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"123DECC8-B300-4954-A233-F89909F4FD89")'], ['o', 'nominmax', 'nosum', 'noavg', 'man', 'nomaxvalues']],
]
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
          'wrong': '@"a"', 'wdesc': 'a', 'wtype': '__NSCFConstantString',
          'type': t[2].replace('Obj', '') + ('?' if 'opt' in t[1] else ''),
          'tags': t[5]
          }
         for t in types]

for string_type in (t for t in types if 'string' in t['tags']):
    string_type['wrong'] = '@2'
    string_type['wdesc'] = '2'
    string_type['wtype'] = '__NSCFNumber'

for type in types:
    type['type'] = type['type'].replace('objectId', 'object id').replace('decimal', 'decimal128')

file = open(os.path.dirname(__file__) or '.' + '/PrimitiveSetPropertyTests.tpl.m', 'rt')
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
