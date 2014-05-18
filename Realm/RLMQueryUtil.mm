////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMQueryUtil.h"
#import "RLMUtil.h"
#import "NSData+RLMGetBinaryData.h"

// small helper to create the many exceptions thrown when parsing predicates
NSException *RLMPredicateException(NSString *name, NSString *reason) {
    return [NSException exceptionWithName:[NSString stringWithFormat:@"filterWithPredicate:orderedBy: - %@", name] reason:reason userInfo:nil];
}

// return the column index for a validated column name
NSUInteger RLMValidatedColumnIndex(RLMObjectDescriptor *desc, NSString *columnName) {
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
                                           [NSString stringWithFormat:@"Operator type %lu not supported for type %d", (unsigned long)operatorType, datatype]);
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
                                           [NSString stringWithFormat:@"Object type %inot supported for BETWEEN operations", dataType]);
    }
}

void add_binary_constraint_to_query(tightdb::Query & query,
                                    NSPredicateOperatorType operatorType,
                                    NSUInteger index,
                                    NSData *value) {
    tightdb::BinaryData binData = [value rlmBinaryData];
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

void validate_value_for_query(id value, RLMPropertyType type, BOOL betweenOperation) {
    if (betweenOperation) {
        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *array = value;
            if (array.count == 2) {
                if (!RLMIsObjectOfType(array.firstObject, type) ||
                    !RLMIsObjectOfType(array.lastObject, type)) {
                    @throw RLMPredicateException(@"Invalid value",
                                                [NSString stringWithFormat:@"NSArray objects must be of type %i for BETWEEN operations", type]);
                }
            } else {
                @throw RLMPredicateException(@"Invalid value", @"NSArray object must contain exactly two objects for BETWEEN operations");
            }
        } else {
            @throw RLMPredicateException(@"Invalid value", @"object must be of type NSArray for BETWEEN operations");
        }
    } else {
        if (!RLMIsObjectOfType(value, type)) {
            @throw RLMPredicateException(@"Invalid value", [NSString stringWithFormat:@"object must be of type %i", type]);
        }
    }
}

void update_query_with_value_expression(RLMObjectDescriptor * desc, tightdb::Query & query,
                                        NSString * columnName, id value, NSPredicateOperatorType operatorType,
                                        NSComparisonPredicateOptions predicateOptions)
{
    // validate object type
    NSUInteger index = RLMValidatedColumnIndex(desc, columnName);
    RLMPropertyType type = [desc[columnName] type];
    
    BOOL betweenOperation = (operatorType == NSBetweenPredicateOperatorType);
    validate_value_for_query(value, type, betweenOperation);
    
    if (betweenOperation) {
        add_between_constraint_to_query(query, type, index, value);
        return;
    }
    
    // finally cast to native types and add query clause
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
                                           [NSString stringWithFormat:@"Object type %i not supported", type]);
    }
}

void update_query_with_column_expression(RLMObjectDescriptor *desc, tightdb::Query &query, NSString * leftColumnName, NSString * rightColumnName, NSComparisonPredicateOptions predicateOptions)
{
    // validate object types
    NSUInteger leftIndex = RLMValidatedColumnIndex(desc, leftColumnName);
    RLMPropertyType leftType = [desc[leftColumnName] type];

    NSUInteger rightIndex = RLMValidatedColumnIndex(desc, rightColumnName);
    RLMPropertyType rightType = [desc[leftColumnName] type];

    // TODO: Should we handle special case where left row is the same as right row (a tautologi)
    // NOTE: tightdb::Query current only supports column comparison for columns of type int, float
    //       and double. However, type conversion between float and double is assumed.
    // NOTE: It's assumed that column type must match and no automatic type coversion is supported.
    switch (leftType) {
        case tightdb::type_Int:
            if(rightType == RLMPropertyTypeInt) {
                query.equal_int(leftIndex, rightIndex);
            }
            else {
                @throw RLMPredicateException(@"Type mismatch between compared properties",
                                             [NSString stringWithFormat:@"Property type mismatch between %i and %i", leftType, rightType]);
            }
            
            break;

        case tightdb::type_Float:
            if(rightType == RLMPropertyTypeFloat) {
                query.equal_float(leftIndex, rightIndex);
            }
            else {
                @throw RLMPredicateException(@"Type mismatch between compared properties",
                                             [NSString stringWithFormat:@"Property type mismatch between %i and %i", leftType, rightType]);
            }
            
            break;

        case tightdb::type_Double:
            if(rightType == RLMPropertyTypeDouble) {
                query.equal_double(leftIndex, rightIndex);
            }
            else {
                @throw RLMPredicateException(@"Type mismatch between compared properties",
                                             [NSString stringWithFormat:@"Property type mismatch between %i and %i", leftType, rightType]);
            }
            
            break;

        default:
            @throw RLMPredicateException(@"Unsupported types found in property comparison",
                                         [NSString stringWithFormat:@"Comparison between %i and %i", leftType, rightType]);
            
            break;
    }
}
    
void update_query_with_predicate(NSPredicate * predicate, RLMObjectDescriptor *desc, tightdb::Query & query)
{
    // Compound predicates.
    if ([predicate isMemberOfClass:[NSCompoundPredicate class]]) {
        NSCompoundPredicate * comp = (NSCompoundPredicate *)predicate;
        
        switch ([comp compoundPredicateType]) {
            case NSAndPredicateType:
                // Add all of the subpredicates.
                query.group();
                for (NSPredicate * subp in comp.subpredicates) {
                    update_query_with_predicate(subp, desc, query);
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
                    update_query_with_predicate(subp, desc, query);
                }
                query.end_group();
                break;
                
            case NSNotPredicateType:
                // Add the negated subpredicate
                query.Not();
                update_query_with_predicate(comp.subpredicates.firstObject, desc, query);
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
                update_query_with_column_expression(desc, query, compp.leftExpression.keyPath, compp.rightExpression.keyPath, compp.predicateOperatorType);
            }
            else {
                update_query_with_value_expression(desc, query, compp.leftExpression.keyPath, compp.rightExpression.constantValue, compp.predicateOperatorType, compp.options);
            }
        }
        else {
            if (exp2Type == NSKeyPathExpressionType) {
                update_query_with_value_expression(desc, query, compp.rightExpression.keyPath, compp.leftExpression.constantValue, compp.predicateOperatorType, compp.options);
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

void RLMUpdateQueryWithPredicate(tightdb::Query *query, id predicate, RLMObjectDescriptor *desc)
{
    // parse and apply predicate tree
    if (predicate) {
        if ([predicate isKindOfClass:[NSString class]]) {
            update_query_with_predicate([NSPredicate predicateWithFormat:predicate],
                                        desc,
                                        *query);
        }
        else if ([predicate isKindOfClass:[NSPredicate class]]) {
            update_query_with_predicate(predicate, desc, *query);
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

void RLMUpdateViewWithOrder(tightdb::TableView &view, id order, RLMObjectDescriptor *desc) {
    if (order) {
        NSString *propName;
        BOOL ascending = YES;
        
        // if not NSSortDescriptor or string then throw
        if ([order isKindOfClass:NSSortDescriptor.class]) {
            propName = [(NSSortDescriptor *)order key];
            ascending = [(NSSortDescriptor *)order ascending];
        }
        else if ([order isKindOfClass:NSString.class]) {
            propName = order;
        }
        else {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Invalid object for order - must use property name or NSSortDescriptor"
                                         userInfo:nil];
        }
        
        // validate
        RLMProperty *prop = desc[propName];
        if (!prop) {
            @throw RLMPredicateException(@"Invalid sort column",
                                         [NSString stringWithFormat:@"Column named '%@' not found.", propName]);
        }
        if (prop.type != RLMPropertyTypeInt && prop.type != RLMPropertyTypeBool && prop.type != RLMPropertyTypeDate) {
            @throw RLMPredicateException(@"Invalid sort column type",
                                         @"Sort only supported on Integer, Date and Boolean columns.");
        }
        view.sort(prop.column, ascending);
    }
}

