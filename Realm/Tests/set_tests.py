import os, re

# Tags:
# (un)minmax: Type supports min() and max()
# (un)sum: Type supports sum()
# (un)avg: Type supports average()
# r/o: Type is Required or Optional
# (un)man: Type is Managed or Unmanaged

types = [
  # Class, Object, Property, Values, Tags
  ['AllPrimitiveSets', 'unmanaged', 'boolObj', ['@NO', '@YES'], ['r', 'nominmax', 'nosum', 'noavg', 'unman']],
  ['AllPrimitiveSets', 'unmanaged', 'intObj', ['@2', '@3'], ['r', 'minmax', 'sum', 'avg', 'unman']],
  ['AllPrimitiveSets', 'unmanaged', 'floatObj', ['@2.2f', '@3.3f'], ['r', 'minmax', 'sum', 'avg', 'unman']],
  ['AllPrimitiveSets', 'unmanaged', 'doubleObj', ['@2.2', '@3.3'], ['r', 'minmax', 'sum', 'avg', 'unman']],
  ['AllPrimitiveSets', 'unmanaged', 'stringObj', ['@"a"', '@"bc"'], ['r', 'nominmax', 'nosum', 'noavg', 'unman', 'string']],
  ['AllPrimitiveSets', 'unmanaged', 'dataObj', ['data(1)', 'data(2)'], ['r', 'nominmax', 'nosum', 'noavg', 'unman']],
  ['AllPrimitiveSets', 'unmanaged', 'dateObj', ['date(1)', 'date(2)'], ['r', 'minmax', 'nosum', 'noavg', 'unman']],
  ['AllPrimitiveSets', 'unmanaged', 'decimalObj', ['decimal128(1)', 'decimal128(2)'], ['r', 'minmax', 'sum', 'avg', 'unman']],
  ['AllPrimitiveSets', 'unmanaged', 'objectIdObj', ['objectId(1)', 'objectId(2)'], ['r', 'nominmax', 'nosum', 'noavg', 'unman']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'boolObj', ['NSNull.null', '@NO', '@YES'], ['o', 'nominmax', 'nosum', 'noavg', 'unman']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'intObj', ['NSNull.null', '@2', '@3'], ['o', 'minmax', 'sum', 'avg', 'unman']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'floatObj', ['NSNull.null', '@2.2f', '@3.3f'], ['o', 'minmax', 'sum', 'avg', 'unman']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'doubleObj', ['NSNull.null', '@2.2', '@3.3'], ['o', 'minmax', 'sum', 'avg', 'unman']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'stringObj', ['NSNull.null', '@"a"', '@"bc"',], ['o', 'nominmax', 'nosum', 'noavg', 'unman', 'string']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'dataObj', ['NSNull.null', 'data(1)', 'data(2)'], ['o', 'nominmax', 'nosum', 'noavg', 'unman']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'dateObj', ['NSNull.null', 'date(1)', 'date(2)'], ['o', 'minmax', 'nosum', 'noavg', 'unman']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'decimalObj', ['NSNull.null', 'decimal128(1)', 'decimal128(2)'], ['o', 'minmax', 'sum', 'avg', 'unman']],
  ['AllOptionalPrimitiveSets', 'optUnmanaged', 'objectIdObj', ['NSNull.null', 'objectId(1)', 'objectId(2)'], ['o', 'nominmax', 'nosum', 'noavg', 'unman']],
  ['AllPrimitiveSets', 'managed', 'boolObj', ['@NO', '@YES'], ['r', 'nominmax', 'nosum', 'noavg', 'man']],
  ['AllPrimitiveSets', 'managed', 'intObj', ['@2', '@3'], ['r', 'minmax', 'sum', 'avg', 'man']],
  ['AllPrimitiveSets', 'managed', 'floatObj', ['@2.2f', '@3.3f'], ['r', 'minmax', 'sum', 'avg', 'man']],
  ['AllPrimitiveSets', 'managed', 'doubleObj', ['@2.2', '@3.3'], ['r', 'minmax', 'sum', 'avg', 'man']],
  ['AllPrimitiveSets', 'managed', 'stringObj', ['@"a"', '@"bc"'], ['r', 'nominmax', 'nosum', 'noavg', 'man', 'string']],
  ['AllPrimitiveSets', 'managed', 'dataObj', ['data(1)', 'data(2)'], ['r', 'nominmax', 'nosum', 'noavg', 'man']],
  ['AllPrimitiveSets', 'managed', 'dateObj', ['date(1)', 'date(2)'], ['r', 'minmax', 'nosum', 'noavg', 'man']],
  ['AllPrimitiveSets', 'managed', 'decimalObj', ['decimal128(1)', 'decimal128(2)'], ['r', 'minmax', 'sum', 'avg', 'man']],
  ['AllPrimitiveSets', 'managed', 'objectIdObj', ['objectId(1)', 'objectId(2)'], ['r', 'nominmax', 'nosum', 'noavg', 'man']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'boolObj', ['NSNull.null', '@NO', '@YES'], ['o', 'nominmax', 'nosum', 'noavg', 'man']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'intObj', ['NSNull.null', '@2', '@3'], ['o', 'minmax', 'sum', 'avg', 'man']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'floatObj', ['NSNull.null', '@2.2f', '@3.3f'], ['o', 'minmax', 'sum', 'avg', 'man']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'doubleObj', ['NSNull.null', '@2.2', '@3.3'], ['o', 'minmax', 'sum', 'avg', 'man']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'stringObj', ['NSNull.null', '@"a"', '@"bc"'], ['o', 'nominmax', 'nosum', 'noavg', 'man', 'string']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'dataObj', ['NSNull.null', 'data(1)', 'data(2)'], ['o', 'nominmax', 'nosum', 'noavg', 'man']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'dateObj', ['NSNull.null', 'date(1)', 'date(2)'], ['o', 'minmax', 'nosum', 'noavg', 'man']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'decimalObj', ['NSNull.null', 'decimal128(1)', 'decimal128(2)'], ['o', 'minmax', 'sum', 'avg', 'man']],
  ['AllOptionalPrimitiveSets', 'optManaged', 'objectIdObj', ['NSNull.null', 'objectId(1)', 'objectId(2)'], ['o', 'nominmax', 'nosum', 'noavg', 'man']],
]
types = [{'class': t[0], 'obj': t[1], 'prop': t[2], 'v0': t[3][0], 'v1': t[3][1], 'v2': len(t[3])>2 and t[3][2] or 'NSNull.null',
          'set': t[1] + '.' + t[2],
          'values2': '@[' + ', '.join(t[3] * 2) + ']',
          'values': '@[' + ', '.join(t[3]) + ']',
          'first': t[3][0], 'last': t[3][2] if len(t[3]) == 3 else t[3][1],
          'wrong': '@"a"', 'wdesc': 'a', 'wtype': '__NSCFConstantString',
          'type': t[2].replace('Obj', '') + ('?' if 'opt' in t[1] else ''),
          'tags': t[4],
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
