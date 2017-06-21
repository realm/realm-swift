import os, re

types = [
  ['AllPrimitiveArrays', 'unmanaged', 'boolObj', ['@NO', '@YES'], ['r', 'nominmax', 'nosum', 'noavg', 'unman']],
  ['AllPrimitiveArrays', 'unmanaged', 'intObj', ['@2', '@3'], ['r', 'minmax', 'sum', 'avg', 'unman']],
  ['AllPrimitiveArrays', 'unmanaged', 'floatObj', ['@2.2f', '@3.3f'], ['r', 'minmax', 'sum', 'avg', 'unman']],
  ['AllPrimitiveArrays', 'unmanaged', 'doubleObj', ['@2.2', '@3.3'], ['r', 'minmax', 'sum', 'avg', 'unman']],
  ['AllPrimitiveArrays', 'unmanaged', 'stringObj', ['@"a"', '@"b"'], ['r', 'nominmax', 'nosum', 'noavg', 'unman']],
  ['AllPrimitiveArrays', 'unmanaged', 'dataObj', ['data(1)', 'data(2)'], ['r', 'nominmax', 'nosum', 'noavg', 'unman']],
  ['AllPrimitiveArrays', 'unmanaged', 'dateObj', ['date(1)', 'date(2)'], ['r', 'minmax', 'nosum', 'noavg', 'unman']],
  ['AllOptionalPrimitiveArrays', 'optUnmanaged', 'boolObj', ['@NO', '@YES', 'NSNull.null'], ['o', 'nominmax', 'nosum', 'noavg', 'unman']],
  ['AllOptionalPrimitiveArrays', 'optUnmanaged', 'intObj', ['@2', '@3', 'NSNull.null'], ['o', 'minmax', 'sum', 'avg', 'unman']],
  ['AllOptionalPrimitiveArrays', 'optUnmanaged', 'floatObj', ['@2.2f', '@3.3f', 'NSNull.null'], ['o', 'minmax', 'sum', 'avg', 'unman']],
  ['AllOptionalPrimitiveArrays', 'optUnmanaged', 'doubleObj', ['@2.2', '@3.3', 'NSNull.null'], ['o', 'minmax', 'sum', 'avg', 'unman']],
  ['AllOptionalPrimitiveArrays', 'optUnmanaged', 'stringObj', ['@"a"', '@"b"', 'NSNull.null'], ['o', 'nominmax', 'nosum', 'noavg', 'unman']],
  ['AllOptionalPrimitiveArrays', 'optUnmanaged', 'dataObj', ['data(1)', 'data(2)', 'NSNull.null'], ['o', 'nominmax', 'nosum', 'noavg', 'unman']],
  ['AllOptionalPrimitiveArrays', 'optUnmanaged', 'dateObj', ['date(1)', 'date(2)', 'NSNull.null'], ['o', 'minmax', 'nosum', 'noavg', 'unman']],
  ['AllPrimitiveArrays', 'managed', 'boolObj', ['@NO', '@YES'], ['r', 'nominmax', 'nosum', 'noavg', 'man']],
  ['AllPrimitiveArrays', 'managed', 'intObj', ['@2', '@3'], ['r', 'minmax', 'sum', 'avg', 'man']],
  ['AllPrimitiveArrays', 'managed', 'floatObj', ['@2.2f', '@3.3f'], ['r', 'minmax', 'sum', 'avg', 'man']],
  ['AllPrimitiveArrays', 'managed', 'doubleObj', ['@2.2', '@3.3'], ['r', 'minmax', 'sum', 'avg', 'man']],
  ['AllPrimitiveArrays', 'managed', 'stringObj', ['@"a"', '@"b"'], ['r', 'nominmax', 'nosum', 'noavg', 'man']],
  ['AllPrimitiveArrays', 'managed', 'dataObj', ['data(1)', 'data(2)'], ['r', 'nominmax', 'nosum', 'noavg', 'man']],
  ['AllPrimitiveArrays', 'managed', 'dateObj', ['date(1)', 'date(2)'], ['r', 'minmax', 'nosum', 'noavg', 'man']],
  ['AllOptionalPrimitiveArrays', 'optManaged', 'boolObj', ['@NO', '@YES', 'NSNull.null'], ['o', 'nominmax', 'nosum', 'noavg', 'man']],
  ['AllOptionalPrimitiveArrays', 'optManaged', 'intObj', ['@2', '@3', 'NSNull.null'], ['o', 'minmax', 'sum', 'avg', 'man']],
  ['AllOptionalPrimitiveArrays', 'optManaged', 'floatObj', ['@2.2f', '@3.3f', 'NSNull.null'], ['o', 'minmax', 'sum', 'avg', 'man']],
  ['AllOptionalPrimitiveArrays', 'optManaged', 'doubleObj', ['@2.2', '@3.3', 'NSNull.null'], ['o', 'minmax', 'sum', 'avg', 'man']],
  ['AllOptionalPrimitiveArrays', 'optManaged', 'stringObj', ['@"a"', '@"b"', 'NSNull.null'], ['o', 'nominmax', 'nosum', 'noavg', 'man']],
  ['AllOptionalPrimitiveArrays', 'optManaged', 'dataObj', ['data(1)', 'data(2)', 'NSNull.null'], ['o', 'nominmax', 'nosum', 'noavg', 'man']],
  ['AllOptionalPrimitiveArrays', 'optManaged', 'dateObj', ['date(1)', 'date(2)', 'NSNull.null'], ['o', 'minmax', 'nosum', 'noavg', 'man']],
]
types = [{'class': t[0], 'obj': t[1], 'prop': t[2], 'v0': t[3][0], 'v1': t[3][1],
          'array': t[1] + '.' + t[2],
          'values2': '@[' + ', '.join(t[3] * 2) + ']',
          'values': '@[' + ', '.join(t[3]) + ']',
          'first': t[3][0], 'last': t[3][2] if len(t[3]) == 3 else t[3][1],
          's0': t[3][0][1:], 's1': t[3][1][1:],
          'wrong': '@"a"', 'wdesc': 'a', 'wtype': '__NSCFConstantString',
          'type': t[2].replace('Obj', '') + ('?' if 'opt' in t[1] else ''),
          'tags': t[4],
          }
         for t in types]
types[4]['wrong'] = '@2'
types[4]['wdesc'] = '2'
types[4]['wtype'] = '__NSCFNumber'
types[11]['wrong'] = '@2'
types[11]['wdesc'] = '2'
types[11]['wtype'] = '__NSCFNumber'
types[18]['wrong'] = '@2'
types[18]['wdesc'] = '2'
types[18]['wtype'] = '__NSCFNumber'
types[25]['wrong'] = '@2'
types[25]['wdesc'] = '2'
types[25]['wtype'] = '__NSCFNumber'

file = open(os.path.dirname(__file__) + '/PrimitiveArrayPropertyTests.tpl.m', 'rt')
for line in file:
    if not '$' in line:
        print line,
        continue

    filtered_types = types

    start = 0
    end = len(types)
    for tag in re.findall(r'\%([a-z]+)', line):
        filtered_types = [t for t in filtered_types if tag in t['tags']]
        line = line.replace('%' + tag + ' ', '')

    line = line.replace(' ^nl ', '\n    ')
    line = line.replace(' ^n', '\n' + ' ' * line.find('('))

    for t in filtered_types:
        l = line
        for k, v in t.iteritems():
            if k in l:
                l = l.replace('$' + k, v)
        print l,
