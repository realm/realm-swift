import os, re

# Tags:
# (no)minmax: Type supports min() and max()
# (no)sum: Type supports sum()
# (no)avg: Type supports average()
# r/o: Type is Required or Optional
# (un)man: Type is Managed or Unmanaged

types = [
  # Class, Object, Property, Values, Tags
  ['AllPrimitiveRLMValues', 'unmanaged', 'boolVal', ['@NO', '@YES', 'NSNull.null'], {'o', 'unman'}, '(NSNumber *)', 'RLMPropertyTypeBool'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'intVal', ['@2', '@3', 'NSNull.null'], {'n', 'o', 'minmax', 'sum', 'avg', 'unman'}, '(NSNumber *)', 'RLMPropertyTypeInt'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'floatVal', ['@2.2f', '@3.3f', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'unman'}, '(NSNumber *)', 'RLMPropertyTypeFloat'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'doubleVal', ['@2.2', '@3.3', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'unman'}, '(NSNumber *)', 'RLMPropertyTypeDouble'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'stringVal', ['@"a"', '@"b"', 'NSNull.null'], {'o', 'unman', 'string'}, '(NSString *)', 'RLMPropertyTypeString'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'dataVal', ['data(1)', 'data(2)', 'NSNull.null'], {'o', 'unman'}, '(NSData *)', 'RLMPropertyTypeData'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'dateVal', ['date(1)', 'date(2)', 'NSNull.null'], {'o', 'minmax', 'unman', 'date'}, '(NSDate *)', 'RLMPropertyTypeDate'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'decimalVal', ['decimal128(2)', 'decimal128(3)', 'NSNull.null'], {'o', 'minmax', 'sum', 'avg', 'unman'}, '(RLMDecimal128 *)', 'RLMPropertyTypeDecimal128'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'objectIdVal', ['objectId(1)', 'objectId(2)', 'NSNull.null'], {'o', 'unman'}, '(RLMObjectId *)', 'RLMPropertyTypeObjectId'],
  ['AllPrimitiveRLMValues', 'unmanaged', 'uuidVal', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")', 'NSNull.null'], {'o', 'unman'}, '(NSUUID *)', 'RLMPropertyTypeUUID'],
  ['AllPrimitiveRLMValues', 'managed', 'boolVal', ['@NO', '@YES'], { 'r', 'man'}, '(NSNumber *)', 'RLMPropertyTypeBool'],
  ['AllPrimitiveRLMValues', 'managed', 'intVal', ['@2', '@3'], {'r', 'minmax', 'sum', 'avg', 'man'}, '(NSNumber *)', 'RLMPropertyTypeBool'],
  ['AllPrimitiveRLMValues', 'managed', 'floatVal', ['@2.2f', '@3.3f'], {'r', 'minmax', 'sum', 'avg', 'man'}, '(NSNumber *)', 'RLMPropertyTypeInt'],
  ['AllPrimitiveRLMValues', 'managed', 'doubleVal', ['@2.2', '@3.3'], {'r', 'minmax', 'sum', 'avg', 'man'}, '(NSNumber *)', 'RLMPropertyTypeFloat'],
  ['AllPrimitiveRLMValues', 'managed', 'stringVal', ['@"a"', '@"b"'], {'r', 'man', 'string'}, '(NSString *)', 'RLMPropertyTypeDouble'],
  ['AllPrimitiveRLMValues', 'managed', 'dataVal', ['data(1)', 'data(2)'], {'r', 'man'}, '(NSData *)', 'RLMPropertyTypeData'],
  ['AllPrimitiveRLMValues', 'managed', 'dateVal', ['date(1)', 'date(2)'], {'r', 'minmax', 'man', 'date'}, '(NSDate *)', 'RLMPropertyTypeDate'],
  ['AllPrimitiveRLMValues', 'managed', 'decimalVal', ['decimal128(2)', 'decimal128(3)'], {'r', 'minmax', 'sum', 'avg', 'man'}, '(RLMDecimal128 *)', 'RLMPropertyTypeDecimal128'],
  ['AllPrimitiveRLMValues', 'managed', 'objectIdVal', ['objectId(1)', 'objectId(2)', 'NSNull.null'], {'o', 'man'}, '(RLMObjectId *)', 'RLMPropertyTypeObjectId'],
  ['AllPrimitiveRLMValues', 'managed', 'uuidVal', ['uuid(@"00000000-0000-0000-0000-000000000000")', 'uuid(@"137DECC8-B300-4954-A233-F89909F4FD89")', 'NSNull.null'], {'o', 'man'}, '(NSUUID *)', 'RLMPropertyTypeUUID'],

]
types = [{'class': t[0], 'obj': t[1], 'prop': t[2], 'v0': t[3][0], 'v1': t[3][1],
          'member': t[2],
          'rlmValue': t[1] + '.' + t[2],
          'value0': t[3][0],
          'value1': t[3][1],
          'values': '@[' + ', '.join(t[3]) + ']',
          'cast': t[5],
          'valueType': t[6],
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
    
file = open(os.path.dirname(__file__) + '/PrimitiveRLMValuePropertyTests.tpl.m', 'rt')
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
