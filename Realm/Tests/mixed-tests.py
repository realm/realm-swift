import os, re

# Tags:
# (no)minmax: Type supports min() and max()
# (no)sum: Type supports sum()
# (no)avg: Type supports average()
# r/o: Type is Required or Optional
# (un)man: Type is Managed or Unmanaged
# n: RLMValue is cast as NSNumber for comparison
# s: RLMValue is cast as NSString for comparison
# dc: RLMValue is cast as Decimal128 for comparison
# dt: RLMValue is cast NSDate for comparison
# da: RLMValue is cast as NString and initialized as data

types = [
  # Class, Object, Property, Values, Tags
#  ['AllPrimitiveValues', 'unmanaged', 'objectIdObj', ['objectId(1)', 'objectId(2)'], {'r', 'unman'}],
  ['AllOptionalPrimitiveValues', 'unmanaged', 'boolObj', ['@NO', '@YES', 'NSNull.null'], {'n', 'o', 'unman'}, '(NSNumber *)'],
  ['AllOptionalPrimitiveValues', 'unmanaged', 'intObj', ['@2', '@3', 'NSNull.null'], {'n', 'o', 'minmax', 'sum', 'avg', 'unman'}, '(NSNumber *)'],
  ['AllOptionalPrimitiveValues', 'unmanaged', 'floatObj', ['@2.2f', '@3.3f', 'NSNull.null'], {'n', 'o', 'minmax', 'sum', 'avg', 'unman'}, '(NSNumber *)'],
  ['AllOptionalPrimitiveValues', 'unmanaged', 'doubleObj', ['@2.2', '@3.3', 'NSNull.null'], {'n', 'o', 'minmax', 'sum', 'avg', 'unman'}, '(NSNumber *)'],
  ['AllOptionalPrimitiveValues', 'unmanaged', 'stringObj', ['@"a"', '@"b"', 'NSNull.null'], {'s', 'o', 'unman', 'string'}, '(NSString *)'],
  ['AllOptionalPrimitiveValues', 'unmanaged', 'dataObj', ['data(1)', 'data(2)', 'NSNull.null'], {'da', 'o', 'unman'}, '(NSData *)'],
  ['AllOptionalPrimitiveValues', 'unmanaged', 'dateObj', ['date(1)', 'date(2)', 'NSNull.null'], {'dt', 'o', 'minmax', 'unman', 'date'}, '(NSDate *)'],
  ['AllOptionalPrimitiveValues', 'unmanaged', 'decimalObj', ['decimal128(2)', 'decimal128(3)', 'NSNull.null'], {'dc', 'o', 'minmax', 'sum', 'avg', 'unman'}, '(RLMDecimal128 *)'],
#  ['AllOptionalPrimitiveValues', 'optUnmanaged', 'objectIdObj', ['objectId(1)', 'objectId(2)', 'NSNull.null'], {'o', 'unman'}],
  ['AllPrimitiveValues', 'managed', 'boolObj', ['@NO', '@YES'], {'n', 'r', 'man'}, '(NSNumber *)'],
  ['AllPrimitiveValues', 'managed', 'intObj', ['@2', '@3'], {'n', 'r', 'minmax', 'sum', 'avg', 'man'}, '(NSNumber *)'],
  ['AllPrimitiveValues', 'managed', 'floatObj', ['@2.2f', '@3.3f'], {'n', 'r', 'minmax', 'sum', 'avg', 'man'}, '(NSNumber *)'],
  ['AllPrimitiveValues', 'managed', 'doubleObj', ['@2.2', '@3.3'], {'n', 'r', 'minmax', 'sum', 'avg', 'man'}, '(NSNumber *)'],
  ['AllPrimitiveValues', 'managed', 'stringObj', ['@"a"', '@"b"'], {'s', 'r', 'man', 'string'}, '(NSString *)'],
  ['AllPrimitiveValues', 'managed', 'dataObj', ['data(1)', 'data(2)'], {'da', 'r', 'man'}, '(NSData *)'],
  ['AllPrimitiveValues', 'managed', 'dateObj', ['date(1)', 'date(2)'], {'dt', 'r', 'minmax', 'man', 'date'}, '(NSDate *)'],
  ['AllPrimitiveValues', 'managed', 'decimalObj', ['decimal128(2)', 'decimal128(3)'], {'dc', 'r', 'minmax', 'sum', 'avg', 'man'}, '(RLMDecimal128 *)'],
#  ['AllPrimitiveValues', 'managed', 'objectIdObj', ['objectId(1)', 'objectId(2)'], {'r', 'man'}],
#  ['AllOptionalPrimitiveValues', 'optManaged', 'objectIdObj', ['objectId(1)', 'objectId(2)', 'NSNull.null'], {'o', 'man'}],
]
types = [{'class': t[0], 'obj': t[1], 'prop': t[2], 'v0': t[3][0], 'v1': t[3][1],
          'rlmValue': t[1] + '.' + t[2],
          'value1': t[3][1],
          'value0': t[3][0],
          'values': '@[' + ', '.join(t[3]) + ']',
          'cast': t[5],
          'first': t[3][0], 'last': t[3][2] if len(t[3]) == 3 else t[3][1],
          'wrong': '@"a"', 'wdesc': 'a', 'wtype': '__NSCFConstantString',
          'type': t[2].replace('Obj', '') + ('?' if 'opt' in t[1] else ''),
          'member': t[2],
          'tags': t[4],
          }
         for t in types]
         
all_tags = set()
for t in types:
    all_tags |= t['tags']
for t in types:
    for missing in all_tags - t['tags']:
        t['tags'].add('no' + missing)
        
for string_type in (t for t in types if 'string' in t['tags']):
    string_type['wrong'] = '@2'
    string_type['wdesc'] = '2'
    string_type['wtype'] = '__NSCFNumber'
    
for type in types:
    type['type'] = type['type'].replace('objectId', 'object id').replace('decimal', 'decimal128')
    type['basetype'] = type['type'].replace('?', '')
    
### !!! see tests.py, delete this comment before merging.
file = open(os.path.dirname(__file__) + '/PrimitiveValuePropertyTests.tpl.m', 'rt')
for line in file:
    # Lines without anything to expand just appear as-is
    if not '$' in line:
        print line,
        continue

    if '$allValues' in line:
        line = line.replace(' ^n', '\n' + ' ' * (line.find('(') + 4))
        print '    for (RLMValue *value in allValues) {\n    ' + line.replace('$allValues', 'value') + '    }'
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
