////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMQueryUtil.h"
#import "RLMUtil.h"
#import "RLMProperty_Private.h"

NSString *const RLMPropertiesComparisonTypeMismatchException = @"RLMPropertiesComparisonTypeMismatchException";
NSString *const RLMUnsupportedTypesFoundInPropertyComparisonException = @"RLMUnsupportedTypesFoundInPropertyComparisonException";

NSString *const RLMPropertiesComparisonTypeMismatchReason = @"Property type mismatch between %@ and %@";
NSString *const RLMUnsupportedTypesFoundInPropertyComparisonReason = @"Comparison between %@ and %@";

// small helper to create the many exceptions thrown when parsing predicates
NSException *RLMPredicateException(NSString *name, NSString *reason) {
    return [NSException exceptionWithName:[NSString stringWithFormat:@"filterWithPredicate:orderedBy: - %@", name] reason:reason userInfo:nil];
}

// return the column index for a validated column name
NSUInteger RLMValidatedColumnIndex(RLMObjectSchema *desc, NSString *columnName) {
    RLMProperty *prop = desc[columnName];
    if (!prop) {
        @throw RLMPredicateException(@"Invalid column name",
                                       [NSString stringWithFormat:@"Column name %@ not found in table", columnName]);
    }
    return prop.column;
}

namespace {

// validate that we support the passed in expression type
NSExpressionType validated_expression_type(NSExpression *expression) {
    if (expression.expressionType != NSConstantValueExpressionType &&
        expression.expressionType != NSKeyPathExpressionType) {
        @throw RLMPredicateException(@"Invalid expression type",
                                       @"Only support NSConstantValueExpressionType and NSKeyPathExpressionType");
    }
    return expression.expressionType;
}

//// apply an expression between two columns to a query
//void update_query_with_column_expression(RLMTable * table, tightdb::Query & query,
//                                         NSString * col1, NSString * col2, NSPredicateOperatorType operatorType) {
//    
//    // only support equality for now
//    if (operatorType != NSEqualToPredicateOperatorType) {
//        @throw RLM_predicate_exception(@"Invalid predicate comparison type",
//                                       @"only support equality comparison type");
//    }
//    
//    // validate column names
//    NSUInteger index1 = RLMValidatedColumnIndex(table, col1);
//    NSUInteger index2 = RLMValidatedColumnIndex(table, col2);
//    
//    // make sure they are the same type
//    tightdb::DataType type1 = table->m_table->get_column_type(index1);
//    tightdb::DataType type2 = table->m_table->get_column_type(index2);
//    
//    if (type1 == type2) {
//        @throw RLM_predicate_exception(@"Invalid predicate expression",
//                                       @"Columns must be the same type");
//    }
//    
//    // not suppoting for now - if we changed names for column comparisons so that we could
//    // use templated function for all numeric types this would be much easier
//    @throw RLM_predicate_exception(@"Unsupported predicate",
//                                   @"Not suppoting column comparison for now");
//}

// add a clause for numeric constraints based on operator type
template <typename T>
void add_numeric_constraint_to_query(tightdb::Query & query,
                                     RLMPropertyType datatype,
                                     NSPredicateOperatorType operatorType,
                                     NSUInteger index,
                                     T value) {
    switch (operatorType) {
        case NSLessThanPredicateOperatorType:
            query.less(index, value);
            break;
        case NSLessThanOrEqualToPredicateOperatorType:
            query.less_equal(index, value);
            break;
        case NSGreaterThanPredicateOperatorType:
            query.greater(index, value);
            break;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            query.greater_equal(index, value);
            break;
        case NSEqualToPredicateOperatorType:
            query.equal(index, value);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.not_equal(index, value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                           [NSString stringWithFormat:@"Operator type %lu not supported for type %@", (unsigned long)operatorType, RLMTypeToString(datatype)]);
            break;
    }
}

void add_bool_constraint_to_query(tightdb::Query & query,
                                  NSPredicateOperatorType operatorType,
                                  NSUInteger index,
                                  bool value) {
    switch (operatorType) {
        case NSEqualToPredicateOperatorType:
            query.equal(index, value);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.not_equal(index, value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                           [NSString stringWithFormat:@"Operator type %lu not supported for bool type", (unsigned long)operatorType]);
            break;
    }
}

void add_string_constraint_to_query(tightdb::Query & query,
                                    NSPredicateOperatorType operatorType,
                                    NSComparisonPredicateOptions predicateOptions,
                                    NSUInteger index,
                                    NSString * value) {
    bool caseSensitive = !(predicateOptions & NSCaseInsensitivePredicateOption);
    bool diacriticInsensitive = (predicateOptions & NSDiacriticInsensitivePredicateOption);
    
    if (diacriticInsensitive) {
        @throw RLMPredicateException(@"Invalid predicate option",
                                       @"NSDiacriticInsensitivePredicateOption not supported for string type");
    }
    
    tightdb::StringData sd([(NSString *)value UTF8String]);
    switch (operatorType) {
        case NSBeginsWithPredicateOperatorType:
            query.begins_with(index, sd, caseSensitive);
            break;
        case NSEndsWithPredicateOperatorType:
            query.ends_with(index, sd, caseSensitive);
            break;
        case NSContainsPredicateOperatorType:
            query.contains(index, sd, caseSensitive);
            break;
        case NSEqualToPredicateOperatorType:
            query.equal(index, sd, caseSensitive);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.not_equal(index, sd, caseSensitive);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                           [NSString stringWithFormat:@"Operator type %lu not supported for string type", (unsigned long)operatorType]);
            break;
    }
}

void add_datetime_constraint_to_query(tightdb::Query & query,
                                      NSPredicateOperatorType operatorType,
                                      NSUInteger index,
                                      double value) {
    switch (operatorType) {
        case NSLessThanPredicateOperatorType:
            query.less_datetime(index, value);
            break;
        case NSLessThanOrEqualToPredicateOperatorType:
            query.less_equal_datetime(index, value);
            break;
        case NSGreaterThanPredicateOperatorType:
            query.greater_datetime(index, value);
            break;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            query.greater_equal_datetime(index, value);
            break;
        case NSEqualToPredicateOperatorType:
            query.equal_datetime(index, value);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.not_equal_datetime(index, value);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                           [NSString stringWithFormat:@"Operator type %lu not supported for type NSDate", (unsigned long)operatorType]);
            break;
    }
}

void add_between_constraint_to_query(tightdb::Query & query,
                                     RLMPropertyType dataType,
                                     NSUInteger index,
                                     NSArray *array) {
    id from = array.firstObject;
    id to = array.lastObject;
    switch (dataType) {
        case tightdb::type_DateTime:
            query.between_datetime(index,
                                   double([(NSDate *)from timeIntervalSince1970]),
                                   double([(NSDate *)to timeIntervalSince1970]));
            break;
        case tightdb::type_Double:
        {
            double fromDouble = [(NSNumber *)from doubleValue];
            double toDouble = [(NSNumber *)to doubleValue];
            query.between(index, fromDouble, toDouble);
            break;
        }
        case tightdb::type_Float:
        {
            float fromFloat = [(NSNumber *)from floatValue];
            float toFloat = [(NSNumber *)to floatValue];
            query.between(index, fromFloat, toFloat);
            break;
        }
        case tightdb::type_Int:
        {
            int fromInt = [(NSNumber *)from intValue];
            int toInt = [(NSNumber *)to intValue];
            query.between(index, fromInt, toInt);
            break;
        }
        default:
            @throw RLMPredicateException(@"Unsupported predicate value type",
                                           [NSString stringWithFormat:@"Object type %@ not supported for BETWEEN operations", RLMTypeToString(dataType)]);
    }
}

void add_binary_constraint_to_query(tightdb::Query & query,
                                    NSPredicateOperatorType operatorType,
                                    NSUInteger index,
                                    NSData *value) {
    tightdb::BinaryData binData = RLMBinaryDataForNSData(value);
    switch (operatorType) {
        case NSBeginsWithPredicateOperatorType:
            query.begins_with(index, binData);
            break;
        case NSEndsWithPredicateOperatorType:
            query.ends_with(index, binData);
            break;
        case NSContainsPredicateOperatorType:
            query.contains(index, binData);
            break;
        case NSEqualToPredicateOperatorType:
            query.equal(index, binData);
            break;
        case NSNotEqualToPredicateOperatorType:
            query.not_equal(index, binData);
            break;
        default:
            @throw RLMPredicateException(@"Invalid operator type",
                                           [NSString stringWithFormat:@"Operator type %lu not supported for binary type", (unsigned long)operatorType]);
            break;
    }
}

void validate_value_for_query(id value, RLMProperty *prop, BOOL betweenOperation) {
    if (betweenOperation) {
        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *array = value;
            if (array.count == 2) {
                if (!RLMIsObjectValidForProperty(array.firstObject, prop) ||
                    !RLMIsObjectValidForProperty(array.lastObject, prop)) {
                    @throw RLMPredicateException(@"Invalid value",
                                                [NSString stringWithFormat:@"NSArray objects must be of type %@ for BETWEEN operations", RLMTypeToString(prop.type)]);
                }
            } else {
                @throw RLMPredicateException(@"Invalid value", @"NSArray object must contain exactly two objects for BETWEEN operations");
            }
        } else {
            @throw RLMPredicateException(@"Invalid value", @"object must be of type NSArray for BETWEEN operations");
        }
    } else {
        if (!RLMIsObjectValidForProperty(value, prop)) {
            @throw RLMPredicateException(@"Invalid value", [NSString stringWithFormat:@"object must be of type %@", RLMTypeToString(prop.type)]);
        }
    }
}

void update_query_with_value_expression(RLMObjectSchema * desc, tightdb::Query & query,
                                        NSString * columnName, id value, NSPredicateOperatorType operatorType,
                                        NSComparisonPredicateOptions predicateOptions)
{
    // validate object type
    NSUInteger index = RLMValidatedColumnIndex(desc, columnName);
    RLMProperty *prop = desc[columnName];
    
    BOOL betweenOperation = (operatorType == NSBetweenPredicateOperatorType);
    validate_value_for_query(value, prop, betweenOperation);
    
    if (betweenOperation) {
        add_between_constraint_to_query(query, prop.type, index, value);
        return;
    }
    
    // finally cast to native types and add query clause
    RLMPropertyType type = prop.type;
    switch (type) {
        case tightdb::type_Bool:
            add_bool_constraint_to_query(query, operatorType, index,
                                         bool([(NSNumber *)value boolValue]));
            break;
        case tightdb::type_DateTime:
            add_datetime_constraint_to_query(query, operatorType, index,
                                             double([(NSDate *)value timeIntervalSince1970]));
            break;
        case tightdb::type_Double:
            add_numeric_constraint_to_query(query, type, operatorType,
                                            index, [(NSNumber *)value doubleValue]);
            break;
        case tightdb::type_Float:
            add_numeric_constraint_to_query(query, type, operatorType,
                                            index, [(NSNumber *)value floatValue]);
            break;
        case tightdb::type_Int:
            add_numeric_constraint_to_query(query, type, operatorType,
                                            index, [(NSNumber *)value intValue]);
            break;
        case tightdb::type_String:
            add_string_constraint_to_query(query, operatorType, predicateOptions, index, value);
            break;
        case tightdb::type_Binary:
            add_binary_constraint_to_query(query, operatorType, index, value);
            break;
        default:
            @throw RLMPredicateException(@"Unsupported predicate value type",
                                           [NSString stringWithFormat:@"Object type %@ not supported", RLMTypeToString(type)]);
    }
}

void update_query_with_column_expression(RLMObjectSchema *scheme, tightdb::Query &query, NSString * leftColumnName, NSString * rightColumnName, NSComparisonPredicateOptions predicateOptions)
{
    // Validate object types
    NSUInteger leftIndex = RLMValidatedColumnIndex(scheme, leftColumnName);
    RLMPropertyType leftType = [scheme[leftColumnName] type];
    
    NSUInteger rightIndex = RLMValidatedColumnIndex(scheme, rightColumnName);
    RLMPropertyType rightType = [scheme[rightColumnName] type];
    
    // TODO: Should we handle special case where left row is the same as right row (tautology)
    // NOTE: It's assumed that column type must match and no automatic type conversion is supported.
    if (leftType == rightType) {
        switch (leftType) {
            case tightdb::type_Int:
                switch (predicateOptions) {
                    case NSEqualToPredicateOperatorType:
                        query.equal_int(leftIndex, rightIndex);
                        break;
                    case NSNotEqualToPredicateOperatorType:
                        query.not_equal_int(leftIndex, rightIndex);
                        break;
                    case NSLessThanPredicateOperatorType:
                        query.less_int(leftIndex, rightIndex);
                        break;
                    case NSGreaterThanPredicateOperatorType:
                        query.greater_int(leftIndex, rightIndex);
                        break;
                    case NSLessThanOrEqualToPredicateOperatorType:
                        query.less_equal_int(leftIndex, rightIndex);
                        break;
                    case NSGreaterThanOrEqualToPredicateOperatorType:
                        query.greater_equal_int(leftIndex, rightIndex);
                        break;
                    default:
                        break;
                }
                break;
                
            case tightdb::type_Float:
                switch (predicateOptions) {
                    case NSEqualToPredicateOperatorType:
                        query.equal_float(leftIndex, rightIndex);
                        break;
                    case NSNotEqualToPredicateOperatorType:
                        query.not_equal_float(leftIndex, rightIndex);
                        break;
                    case NSLessThanPredicateOperatorType:
                        query.less_float(leftIndex, rightIndex);
                        break;
                    case NSGreaterThanPredicateOperatorType:
                        query.greater_float(leftIndex, rightIndex);
                        break;
                    case NSLessThanOrEqualToPredicateOperatorType:
                        query.less_equal_float(leftIndex, rightIndex);
                        break;
                    case NSGreaterThanOrEqualToPredicateOperatorType:
                        query.greater_equal_float(leftIndex, rightIndex);
                        break;
                    default:
                        break;
                }
                break;
                
            case tightdb::type_Double:
                switch (predicateOptions) {
                    case NSEqualToPredicateOperatorType:
                        query.equal_double(leftIndex, rightIndex);
                        break;
                    case NSNotEqualToPredicateOperatorType:
                        query.not_equal_double(leftIndex, rightIndex);
                        break;
                    case NSLessThanPredicateOperatorType:
                        query.less_double(leftIndex, rightIndex);
                        break;
                    case NSGreaterThanPredicateOperatorType:
                        query.greater_double(leftIndex, rightIndex);
                        break;
                    case NSLessThanOrEqualToPredicateOperatorType:
                        query.less_equal_double(leftIndex, rightIndex);
                        break;
                    case NSGreaterThanOrEqualToPredicateOperatorType:
                        query.greater_equal_double(leftIndex, rightIndex);
                        break;
                    default:
                        break;
                }
                break;
                
            default:
                @throw RLMPredicateException(RLMUnsupportedTypesFoundInPropertyComparisonException,
                                             [NSString stringWithFormat:RLMUnsupportedTypesFoundInPropertyComparisonReason,
                                              RLMTypeToString(leftType),
                                              RLMTypeToString(rightType)]);
        }
    }
    else {
        @throw RLMPredicateException(RLMPropertiesComparisonTypeMismatchException,
                                     [NSString stringWithFormat:RLMPropertiesComparisonTypeMismatchReason,
                                      RLMTypeToString(leftType),
                                      RLMTypeToString(rightType)]);
    }
}
    
void update_query_with_predicate(NSPredicate * predicate, RLMObjectSchema *schema, tightdb::Query & query)
{
    // Compound predicates.
    if ([predicate isMemberOfClass:[NSCompoundPredicate class]]) {
        NSCompoundPredicate * comp = (NSCompoundPredicate *)predicate;
        
        switch ([comp compoundPredicateType]) {
            case NSAndPredicateType:
                // Add all of the subpredicates.
                query.group();
                for (NSPredicate * subp in comp.subpredicates) {
                    update_query_with_predicate(subp, schema, query);
                }
                query.end_group();
                break;
                
            case NSOrPredicateType:
                // Add all of the subpredicates with ors inbetween.
                query.group();
                for (NSUInteger i = 0; i < comp.subpredicates.count; i++) {
                    NSPredicate * subp = comp.subpredicates[i];
                    if (i > 0) {
                        query.Or();
                    }
                    update_query_with_predicate(subp, schema, query);
                }
                query.end_group();
                break;
                
            case NSNotPredicateType:
                // Add the negated subpredicate
                query.Not();
                update_query_with_predicate(comp.subpredicates.firstObject, schema, query);
                break;
                
            default:
                @throw RLMPredicateException(@"Invalid compound predicate type",
                                               @"Only support AND, OR and NOT predicate types");
        }
    }
    else if ([predicate isMemberOfClass:[NSComparisonPredicate class]]) {
        NSComparisonPredicate * compp = (NSComparisonPredicate *)predicate;
        
        // validate expressions
        NSExpressionType exp1Type = validated_expression_type(compp.leftExpression);
        NSExpressionType exp2Type = validated_expression_type(compp.rightExpression);
        
        // figure out if we have column expression or value expression and update query accordingly
        // we are limited here to KeyPath expressions and constantValue expressions from validation
        if (exp1Type == NSKeyPathExpressionType) {
            if (exp2Type == NSKeyPathExpressionType) {
                update_query_with_column_expression(schema, query, compp.leftExpression.keyPath, compp.rightExpression.keyPath, compp.predicateOperatorType);
            }
            else {
                update_query_with_value_expression(schema, query, compp.leftExpression.keyPath, compp.rightExpression.constantValue, compp.predicateOperatorType, compp.options);
            }
        }
        else {
            if (exp2Type == NSKeyPathExpressionType) {
                update_query_with_value_expression(schema, query, compp.rightExpression.keyPath, compp.leftExpression.constantValue, compp.predicateOperatorType, compp.options);
            }
            else {
                @throw RLMPredicateException(@"Invalid predicate expressions",
                                               @"Tring to compare two constant values");
            }
        }
    }
    else {
        // invalid predicate type
        @throw RLMPredicateException(@"Invalid predicate",
                                       @"Only support compound and comparison predicates");
    }
}

} // namespace

void RLMUpdateQueryWithPredicate(tightdb::Query *query, id predicate, RLMObjectSchema *schema)
{
    // parse and apply predicate tree
    if (predicate) {
        if ([predicate isKindOfClass:[NSString class]]) {
            update_query_with_predicate([NSPredicate predicateWithFormat:predicate],
                                        schema,
                                        *query);
        }
        else if ([predicate isKindOfClass:[NSPredicate class]]) {
            update_query_with_predicate(predicate, schema, *query);
        }
        else {
            @throw RLMPredicateException(@"Invalid argument",
                                         @"Condition should be predicate as string or NSPredicate object");
        }
        
        // Test the constructed query in core
        std::string validateMessage = query->validate();
        if (validateMessage != "") {
            @throw RLMPredicateException(@"Invalid query",
                                        [NSString stringWithCString:validateMessage.c_str() encoding:[NSString defaultCStringEncoding]]  );
        }
    }
}

void RLMUpdateViewWithOrder(tightdb::TableView &view, RLMObjectSchema *schema, NSString *property, BOOL ascending)
{
    if (!property || property.length == 0) {
        return;
    }
    
    // validate
    RLMProperty *prop = schema[property];
    if (!prop) {
        @throw RLMPredicateException(@"Invalid sort column",
                                     [NSString stringWithFormat:@"Column named '%@' not found.", property]);
    }
    
    switch (prop.type) {
        case RLMPropertyTypeBool:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeDouble:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeInt:
        case RLMPropertyTypeString:
            view.sort(prop.column, ascending);
            break;
            
        default:
            @throw RLMPredicateException(@"Invalid sort column type",
                                         @"Sorting is only supported on Bool, Date, Double, Float, Integer and String columns.");
    }
}
