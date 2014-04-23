/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#import <Foundation/Foundation.h>


@class RLMTable;


// protocol for custom table objects
@protocol RLMObject <NSObject>
@required
// implement to indicate the object type within subtables
+(Class)subtableObjectClassForProperty:(NSString *)propertyName;
@optional
// return an array of names of transient properties which should not be persisted
+(NSArray *)ignoredPropertyNames;
// return the name of the primary key property for this object
+(NSString *)primaryKeyPropertyName;
@end


@interface RLMRow : NSObject<RLMObject>

-(id)objectAtIndexedSubscript:(NSUInteger)colIndex;
-(id)objectForKeyedSubscript:(id <NSCopying>)key;
-(void)setObject:(id)obj atIndexedSubscript:(NSUInteger)colIndex;
-(void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;

@end


// macro helper for defining custom table object with subtables
// if used
// TODO - move somewhere else
#define RLM_DEFINE_TABLE_TYPE_FOR_OBJECT_TYPE(TType, OType) \
@protocol OType <NSObject>                                  \
-(OType *)rowAtIndex:(NSUInteger)rowIndex;                  \
-(OType *)firstRow;                                         \
-(OType *)lastRow;                                          \
-(OType *)objectAtIndexedSubscript:(NSUInteger)rowIndex;    \
-(OType *)objectForKeyedSubscript:(NSString *)key;          \
@end                                                        \
@interface TType : RLMTable<OType>                          \
+(TType *)tableInRealm:(RLMTransaction *)rlm named:(NSString *)name;  \
+(Class)objectClass;                                        \
@end

#define STATIC_ASSERT(test, msg) typedef char _static_assert_ ## msg [ ((test) ? 1 : -1) ];

#define RLM_IMPLEMENT_TABLE_TYPE_FOR_OBJECT_TYPE(TType, OType)                  \
STATIC_ASSERT(__INCLUDE_LEVEL__ == 0, RLM_IMPLEMENT_TABLE_used_in_header_file_for##OType)  \
@implementation TType                                                           \
+(TType *)tableInRealm:(RLMTransaction *)rlm named:(NSString *)name {           \
    if([rlm hasTableWithName:name]) return (TType *)[rlm tableWithName:name objectClass:OType.class]; \
    return (TType *)[rlm createTableWithName:name objectClass:OType.class];}    \
+(Class)objectClass { return OType.class; }                                     \
-(instancetype)init { return [super initWithObjectClass:OType.class]; }         \
@end

#define RLM_TABLE_TYPE_FOR_OBJECT_TYPE(TType, OType)    \
RLM_DEFINE_TABLE_TYPE_FOR_OBJECT_TYPE(TType, OType)     \
RLM_IMPLEMENT_TABLE_TYPE_FOR_OBJECT_TYPE(TType, OType)


/* FIXME: This class can be (and should be) eliminated by using a
   macro switching trick for the individual column types on
   TIGHTDB_CURSOR_PROPERTY macros similar to what is done for query
   accessors. */
@interface RLMAccessor : NSObject
-(id)initWithRow:(RLMRow *)cursor columnId:(NSUInteger)columnId;
-(BOOL)getBool;
-(void)setBool:(BOOL)value;
-(int64_t)getInt;
-(void)setInt:(int64_t)value;
-(float)getFloat;
-(void)setFloat:(float)value;
-(double)getDouble;
-(void)setDouble:(double)value;
-(NSString *)getString;
-(void)setString:(NSString *)value;
-(NSData *)getBinary;
-(void)setBinary:(NSData *)value;
-(NSDate *)getDate;
-(void)setDate:(NSDate *)value;
-(void)setSubtable:(RLMTable *)value;
-(id)getSubtable:(Class)obj;
-(id)getMixed;
-(void)setMixed:(id)value;
@end
