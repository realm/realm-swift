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

#import "RLMPrivate.hpp"
#import "RLMObject.h"
#import "RLMObjectDescriptor.h"
#import "RLMObjectStore.h"

NSString *const RLMPropertyAttributeUnique = @"RLMPropertyAttributeUnique";
NSString *const RLMPropertyAttributeIndexed = @"RLMPropertyAttributeIndexed";
NSString *const RLMPropertyAttributeInlined = @"RLMPropertyAttributeInlined";
NSString *const RLMPropertyAttributeRequired = @"RLMPropertyAttributeRequired";

@implementation RLMObject

@synthesize realm = _realm;
@synthesize objectIndex = _objectIndex;
@synthesize backingTableIndex = _backingTableIndex;
@synthesize backingTable = _backingTable;
@synthesize writable = _writable;

-(instancetype)init {
    self = [super init];
    return self;
}

+(instancetype)createInRealm:(RLMRealm *)realm withObject:(id)values {
    id obj = [[self alloc] init];
    
    // FIXME - this can be optimized by inserting directly into the table
    //  after validation, rather than populating the object first
    if ([values isKindOfClass:NSDictionary.class]) {
        // if a dictionary, use key value coding to populate our object
        for (NSString *key in values) {
            [obj setValue:values[key] forKeyPath:key];
        }
    }
    else if ([values isKindOfClass:NSArray.class]) {
        // for arrays use property names as keys
        NSArray *array = values;
        RLMObjectDescriptor *desc = [RLMObjectDescriptor descriptorForObjectClass:self];
        NSArray *properties = desc.properties;
        if (array.count != desc.properties.count) {
            @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid array input. Number of array elements does not match number of properties." userInfo:nil];
        }
        // FIXME - more validation for each property type
        
        for (int i = 0; i < array.count; i++) {
            [obj setValue:array[i] forKeyPath:[properties[i] name]];
        }
    }
    
    // insert populated object into store
    RLMAddObjectToRealm(obj, realm);

    return obj;
}

+(instancetype)createInRealm:(RLMRealm *)realm withJSONString:(NSString *)JSONString {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

-(id)objectForKeyedSubscript:(NSString *)key {
    return [self valueForKey:key];
}

-(void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    [self setValue:obj forKeyPath:key];
}

- (NSString *)JSONString {
    @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                   reason:@"Not yet implemented" userInfo:nil];
}

@end