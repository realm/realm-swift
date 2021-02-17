import os, re

# Tags:
# (no)minmax: Type supports min() and max()
# (no)sum: Type supports sum()
# (no)avg: Type supports average()
# r/o: Type is Required or Optional
# (un)man: Type is Managed or Unmanaged

types = [
  # Class, Object, Property, Values, Tags
  ['AllPrimitiveValues', 'unmanaged', 'boolObj', '@YES', {'r', 'unman'}],
  ['AllPrimitiveValues', 'unmanaged', 'intObj', '@2', {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveValues', 'unmanaged', 'floatObj', '@2.2f', {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveValues', 'unmanaged', 'doubleObj', '@2.2', {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveValues', 'unmanaged', 'stringObj', '@"a"', {'r', 'unman', 'string'}],
  ['AllPrimitiveValues', 'unmanaged', 'dataObj', 'data(1)', {'r', 'unman'}],
  ['AllPrimitiveValues', 'unmanaged', 'dateObj', 'date(1)', {'r', 'minmax', 'unman', 'date'}],
  ['AllPrimitiveValues', 'unmanaged', 'decimalObj', 'decimal128(2)', {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveValues', 'unmanaged', 'objectIdObj', 'objectId(1)', {'r', 'unman'}],
  #
  # Add UUID do not merge without them
  ['AllOptionalPrimitiveValues', 'optUnmanaged', 'boolObj', '@YES', {'o', 'unman'}],
  ['AllOptionalPrimitiveValues', 'optUnmanaged', 'intObj', '@2', {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveValues', 'optUnmanaged', 'floatObj', '@2.2f', {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveValues', 'optUnmanaged', 'doubleObj', '@2.2', {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveValues', 'optUnmanaged', 'stringObj', '@"a"', {'o', 'unman', 'string'}],
  ['AllOptionalPrimitiveValues', 'optUnmanaged', 'dataObj', 'data(1)', {'o', 'unman'}],
  ['AllOptionalPrimitiveValues', 'optUnmanaged', 'dateObj', 'date(1)', {'o', 'minmax', 'unman', 'date'}],
  ['AllOptionalPrimitiveValues', 'optUnmanaged', 'decimalObj', 'decimal128(2)', {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveValues', 'optUnmanaged', 'objectIdObj', 'objectId(1)', {'o', 'unman'}],
  ['AllPrimitiveValues', 'managed', 'boolObj', '@YES', {'r', 'unman'}],
  ['AllPrimitiveValues', 'managed', 'intObj', '@2', {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveValues', 'managed', 'floatObj', '@2.2f', {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveValues', 'managed', 'doubleObj', '@2.2', {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveValues', 'managed', 'stringObj', '@"a"', {'r', 'unman', 'string'}],
  ['AllPrimitiveValues', 'managed', 'dataObj', 'data(1)', {'r', 'unman'}],
  ['AllPrimitiveValues', 'managed', 'dateObj', 'date(1)', {'r', 'minmax', 'unman', 'date'}],
  ['AllPrimitiveValues', 'managed', 'decimalObj', 'decimal128(2)', {'r', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllPrimitiveValues', 'managed', 'objectIdObj', 'objectId(1)', {'r', 'unman'}],
  ['AllOptionalPrimitiveValues', 'optmanaged', 'boolObj', '@YES', {'o', 'unman'}],
  ['AllOptionalPrimitiveValues', 'optmanaged', 'intObj', '@2', {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveValues', 'optmanaged', 'floatObj', '@2.2f', {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveValues', 'optmanaged', 'doubleObj', '@2.2', {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveValues', 'optmanaged', 'stringObj', '@"a"', {'o', 'unman', 'string'}],
  ['AllOptionalPrimitiveValues', 'optmanaged', 'dataObj', 'data(1)', {'o', 'unman'}],
  ['AllOptionalPrimitiveValues', 'optmanaged', 'dateObj', 'date(1)', {'o', 'minmax', 'unman', 'date'}],
  ['AllOptionalPrimitiveValues', 'optmanaged', 'decimalObj', 'decimal128(2)', {'o', 'minmax', 'sum', 'avg', 'unman'}],
  ['AllOptionalPrimitiveValues', 'optmanaged', 'objectIdObj', 'objectId(1)', {'o', 'unman'}],
]
types = [{'class': t[0], 'obj': t[1], 'prop': t[2], 'v0': t[3][0], 'v1': t[3][1],
          'rlmValue': t[1] + '.' + t[2],
#          'values2': '@[' + ', '.join(t[3] * 2) + ']',
          'values': '@[' + ', '.join(t[3]) + ']',
          'first': t[3][0], 'last': t[3][2] if len(t[3]) == 3 else t[3][1],
          'wrong': '@"a"', 'wdesc': 'a', 'wtype': '__NSCFConstantString',
          'type': t[2].replace('Obj', '') + ('?' if 'opt' in t[1] else ''),
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
