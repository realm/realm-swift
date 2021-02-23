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
  ['AllPrimitiveRLMValues', 'unmanaged', 'boolVal', ['@NO', '@YES', 'NSNull.null'], {'n', 'o', 'unman'}, '(NSNumber *)', 'RLMPropertyTypeBool'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'intVal', ['@2', '@3', 'NSNull.null'], {'n', 'o', 'minmax', 'sum', 'avg', 'unman'}, '(NSNumber *)', 'RLMPropertyTypeInt'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'floatVal', ['@2.2f', '@3.3f', 'NSNull.null'], {'n', 'o', 'minmax', 'sum', 'avg', 'unman'}, '(NSNumber *)', 'RLMPropertyTypeFloat'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'doubleVal', ['@2.2', '@3.3', 'NSNull.null'], {'n', 'o', 'minmax', 'sum', 'avg', 'unman'}, '(NSNumber *)', 'RLMPropertyTypeDouble'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'stringVal', ['@"a"', '@"b"', 'NSNull.null'], {'s', 'o', 'unman', 'string'}, '(NSString *)', 'RLMPropertyTypeString'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'dataVal', ['data(1)', 'data(2)', 'NSNull.null'], {'da', 'o', 'unman'}, '(NSData *)', 'RLMPropertyTypeData'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'dateVal', ['date(1)', 'date(2)', 'NSNull.null'], {'dt', 'o', 'minmax', 'unman', 'date'}, '(NSDate *)', 'RLMPropertyTypeDate'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'decimalVal', ['decimal128(2)', 'decimal128(3)', 'NSNull.null'], {'dc', 'o', 'minmax', 'sum', 'avg', 'unman'}, '(RLMDecimal128 *)', 'RLMPropertyTypeDecimal128'],
#  ['AllPrimitiveRLMValues', 'unmanaged', 'objectIdObj', ['objectId(1)', 'objectId(2)', 'NSNull.null'], {'o', 'unman'}, '(RLMObjectId *)', 'RLMPropertyTypeObjectId'],
#  ['AllPrimitiveRLMValues', 'unmanaged', 'uuidObj', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")', 'NSNull.null'], {'o', 'man'}, '(UUID *)', 'RLMPropertyTypeUUID'],
  ['AllPrimitiveRLMValues', 'managed', 'boolVal', ['@NO', '@YES'], {'n', 'r', 'man'}, '(NSNumber *)', 'RLMPropertyTypeBool'],
  ['AllPrimitiveRLMValues', 'managed', 'intVal', ['@2', '@3'], {'n', 'r', 'minmax', 'sum', 'avg', 'man'}, '(NSNumber *)', 'RLMPropertyTypeBool'],
  ['AllPrimitiveRLMValues', 'managed', 'floatVal', ['@2.2f', '@3.3f'], {'n', 'r', 'minmax', 'sum', 'avg', 'man'}, '(NSNumber *)', 'RLMPropertyTypeInt'],
  ['AllPrimitiveRLMValues', 'managed', 'doubleVal', ['@2.2', '@3.3'], {'n', 'r', 'minmax', 'sum', 'avg', 'man'}, '(NSNumber *)', 'RLMPropertyTypeFloat'],
  ['AllPrimitiveRLMValues', 'managed', 'stringVal', ['@"a"', '@"b"'], {'s', 'r', 'man', 'string'}, '(NSString *)', 'RLMPropertyTypeDouble'],
  ['AllPrimitiveRLMValues', 'managed', 'dataVal', ['data(1)', 'data(2)'], {'da', 'r', 'man'}, '(NSData *)', 'RLMPropertyTypeData'],
  ['AllPrimitiveRLMValues', 'managed', 'dateVal', ['date(1)', 'date(2)'], {'dt', 'r', 'minmax', 'man', 'date'}, '(NSDate *)', 'RLMPropertyTypeDate'],
  ['AllPrimitiveRLMValues', 'managed', 'decimalVal', ['decimal128(2)', 'decimal128(3)'], {'dc', 'r', 'minmax', 'sum', 'avg', 'man'}, '(RLMDecimal128 *)', 'RLMPropertyTypeDecimal128'],
#  ['AllPrimitiveRLMValues', 'managed', 'objectIdObj', ['objectId(1)', 'objectId(2)', 'NSNull.null'], {'o', 'unman'}, '(RLMObjectId *)', 'RLMPropertyTypeObjectId'],
#  ['AllPrimitiveRLMValues', 'managed', 'uuidObj', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")', 'NSNull.null'], {'o', 'man'}, '(UUID *)', 'RLMPropertyTypeUUID'],

]
types = [{'class': t[0], 'obj': t[1], 'prop': t[2], 'v0': t[3][0], 'v1': t[3][1],
          'rlmValue': t[1] + '.' + t[2],
          'value1': t[3][1],
          'value0': t[3][0],
          'values': '@[' + ', '.join(t[3]) + ']',
          'cast': t[5],
          'valueType': t[6],
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
