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

#import "query_util.h"

#import "RLMView_noinst.h"
#import "NSData+RLMGetBinaryData.h"

@interface RLMTable () {
@public;
    tightdb::TableRef m_table;
}

@end

// small helper to create the many exceptions thrown when parsing predicates
NSException *RLM_predicate_exception(NSString *name, NSString *reason) {
    return [NSException exceptionWithName:[NSString stringWithFormat:@"filterWithPredicate:orderedBy: - %@", name] reason:reason userInfo:nil];
}

// return the column index for a validated column name
NSUInteger RLM_validated_column_index(RLMTable *table, NSString *columnName) {
    NSUInteger index = [table indexOfColumnWithName:columnName];
    if (index == NSNotFound) {
        @throw RLM_predicate_exception(@"Invalid column name",
                                       [NSString stringWithFormat:@"Column name %@ not found in table", columnName]);
    }
    return index;
}

namespace {

// validate that we support the passed in expression type
NSExpressionType validated_expression_type(NSExpression *expression) {
    if (expression.expressionType != NSConstantValueExpressionType &&
        expression.expressionType != NSKeyPathExpressionType) {
        @throw RLM_predicate_exception(@"Invalid expression type",
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
//    NSUInteger index1 = RLM_validated_column_index(table, col1);
//    NSUInteger index2 = RLM_validated_column_index(table, col2);
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
                                     tightdb::DataType datatype,
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
            @throw RLM_predicate_exception(@"Invalid operator type",
                                           [NSString stringWithFormat:@"Operator type %lu not supported for type %u", (unsigned long)operatorType, datatype]);
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
            @throw RLM_predicate_exception(@"Invalid operator type",
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
        @throw RLM_predicate_exception(@"Invalid predicate option",
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
            @throw RLM_predicate_exception(@"Invalid operator type",
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
            @throw RLM_predicate_exception(@"Invalid operator type",
                                           [NSString stringWithFormat:@"Operator type %lu not supported for type NSDate", (unsigned long)operatorType]);
            break;
    }
}

void add_between_constraint_to_query(tightdb::Query & query,
                                     tightdb::DataType dataType,
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
            double fromDouble = double([(NSNumber *)from doubleValue]);
            double toDouble = double([(NSNumber *)to doubleValue]);
            query.between(index, fromDouble, toDouble);
            break;
        }
        case tightdb::type_Float:
        {
            float fromFloat = float([(NSNumber *)from floatValue]);
            float toFloat = float([(NSNumber *)to floatValue]);
            query.between(index, fromFloat, toFloat);
            break;
        }
        case tightdb::type_Int:
        {
            int fromInt = int([(NSNumber *)from intValue]);
            int toInt = int([(NSNumber *)to intValue]);
            query.between(index, fromInt, toInt);
            break;
        }
        default:
            @throw RLM_predicate_exception(@"Unsupported predicate value type",
                                           [NSString stringWithFormat:@"Object type %i not supported for BETWEEN operations", dataType]);
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
            @throw RLM_predicate_exception(@"Invalid operator type",
                                           [NSString stringWithFormat:@"Operator type %lu not supported for binary type", (unsigned long)operatorType]);
            break;
    }
}

void validate_value_for_query(id value, tightdb::DataType type, BOOL betweenOperation) {
    if (betweenOperation) {
        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *array = value;
            if (array.count == 2) {
                if (!verify_object_is_type(array.firstObject, type) ||
                    !verify_object_is_type(array.lastObject, type)) {
                    @throw RLM_predicate_exception(@"Invalid value",
                                                   [NSString stringWithFormat:@"NSArray objects must be of type %i for BETWEEN operations", type]);
                }
            } else {
                @throw RLM_predicate_exception(@"Invalid value",
                                               @"NSArray object must contain exactly two objects for BETWEEN operations");
            }
        } else {
            @throw RLM_predicate_exception(@"Invalid value",
                                           @"object must be of type NSArray for BETWEEN operations");
        }
    } else {
        if (!verify_object_is_type(value, type)) {
            @throw RLM_predicate_exception(@"Invalid value",
                                           [NSString stringWithFormat:@"object must be of type %i", type]);
        }
    }
}

void update_query_with_value_expression(RLMTable * table, tightdb::Query & query,
                                        NSString * columnName, id value, NSPredicateOperatorType operatorType,
                                        NSComparisonPredicateOptions predicateOptions) {
    
    // validate object type
    NSUInteger index = RLM_validated_column_index(table, columnName);
    tightdb::DataType type = table->m_table->get_column_type(index);
    
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
                                            index, double([(NSNumber *)value doubleValue]));
            break;
        case tightdb::type_Float:
            add_numeric_constraint_to_query(query, type, operatorType,
                                            index, float([(NSNumber *)value floatValue]));
            break;
        case tightdb::type_Int:
            add_numeric_constraint_to_query(query, type, operatorType,
                                            index, int([(NSNumber *)value intValue]));
            break;
        case tightdb::type_String:
            add_string_constraint_to_query(query, operatorType, predicateOptions, index, value);
            break;
        case tightdb::type_Binary:
            add_binary_constraint_to_query(query, operatorType, index, value);
            break;
        default:
            @throw RLM_predicate_exception(@"Unsupported predicate value type",
                                           [NSString stringWithFormat:@"Object type %i not supported", type]);
    }
}

void update_query_with_predicate(NSPredicate * predicate,
                                 RLMTable * table, tightdb::Query & query) {
    
    // compound predicates
    if ([predicate isMemberOfClass:[NSCompoundPredicate class]]) {
        NSCompoundPredicate * comp = (NSCompoundPredicate *)predicate;
        if ([comp compoundPredicateType] == NSAndPredicateType) {
            // add all of the subprediates
            query.group();
            for (NSPredicate * subp in comp.subpredicates) {
                update_query_with_predicate(subp, table, query);
            }
            query.end_group();
        }
        else if ([comp compoundPredicateType] == NSOrPredicateType) {
            // add all of the subprediates with ors inbetween
            query.group();
            for (NSUInteger i = 0; i < comp.subpredicates.count; i++) {
                NSPredicate * subp = comp.subpredicates[i];
                if (i > 0) {
                    query.Or();
                }
                update_query_with_predicate(subp, table, query);
            }
            query.end_group();
        }
        else {
            @throw RLM_predicate_exception(@"Invalid compound predicate type",
                                           @"Only support AND and OR predicate types");
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
                @throw RLM_predicate_exception(@"Unsupported predicate",
                                               @"Not suppoting column comparison for now");
                //                update_query_with_column_expression(table, query, compp.leftExpression.keyPath,
                //                    compp.rightExpression.keyPath, compp.predicateOperatorType);
            }
            else {
                update_query_with_value_expression(table, query, compp.leftExpression.keyPath, compp.rightExpression.constantValue, compp.predicateOperatorType, compp.options);
            }
        }
        else {
            if (exp2Type == NSKeyPathExpressionType) {
                update_query_with_value_expression(table, query, compp.rightExpression.keyPath, compp.leftExpression.constantValue, compp.predicateOperatorType, compp.options);
            }
            else {
                @throw RLM_predicate_exception(@"Invalid predicate expressions",
                                               @"Tring to compare two constant values");
            }
        }
    }
    else {
        // invalid predicate type
        @throw RLM_predicate_exception(@"Invalid predicate",
                                       @"Only support compound and comparison predicates");
    }
}

} // namespace

tightdb::Query queryFromPredicate(RLMTable *table, id predicate)
{
    tightdb::Query query = table->m_table->where();
    
    // parse and apply predicate tree
    if (predicate) {
        if ([predicate isKindOfClass:[NSString class]]) {
            update_query_with_predicate([NSPredicate predicateWithFormat:predicate],
                                        table,
                                        query);
        }
        else if ([predicate isKindOfClass:[NSPredicate class]]) {
            update_query_with_predicate(predicate, table, query);
        }
        else {
            @throw RLM_predicate_exception(@"Invalid argument",
                                           @"Condition should be predicate as string or NSPredicate object");
        }
    }
    
    return query;
}
