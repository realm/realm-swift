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

#import "RLMTestObjects.h"

#pragma mark - Abstract Objects
#pragma mark -

#pragma mark OneTypeObjects

@implementation StringObject
@end

@implementation IntObject
@end

@implementation AllIntSizesObject
@end

@implementation FloatObject
@end

@implementation DoubleObject
@end

@implementation BoolObject
@end

@implementation DateObject
@end

@implementation BinaryObject
@end

@implementation UTF8Object
@end

#pragma mark AllTypesObject

@implementation AllTypesObject
@end

@implementation ArrayOfAllTypesObject
@end

@implementation LinkToAllTypesObject
@end

#pragma mark - Real Life Objects
#pragma mark -

#pragma mark EmployeeObject

@implementation EmployeeObject
@end

#pragma mark CompanyObject

@implementation CompanyObject
@end

#pragma mark DogObject

@implementation DogObject
@end

#pragma mark OwnerObject

@implementation OwnerObject
@end

#pragma mark - Specific Use Objects
#pragma mark -

#pragma mark MixedObject

@implementation MixedObject
@end

#pragma mark CustomAccessorsObject

@implementation CustomAccessorsObject
@end

#pragma mark BaseClassStringObject

@implementation BaseClassStringObject
@end

#pragma mark CircleObject

@implementation CircleObject
@end

#pragma mark CircleArrayObject

@implementation CircleArrayObject
@end

#pragma mark ArrayPropertyObject

@implementation ArrayPropertyObject
@end

#pragma mark DynamicObject

@implementation DynamicObject
@end

#pragma mark AggregateObject

@implementation AggregateObject
@end


@implementation PrimaryStringObject
+ (NSString *)primaryKey {
    return @"stringCol";
}
@end

@interface ReadOnlyPropertyObject ()
@property (readwrite) int readOnlyPropertyMadeReadWriteInClassExtension;
@end

@implementation ReadOnlyPropertyObject
- (NSNumber *)readOnlyUnsupportedProperty {
    return nil;
}
@end

@implementation UserTranslationObject
+ (id<RLMObjectTranslationProtocol>)defaultTranslation {
    return [UserAPITranslation new];
}
@end

@interface UserAPITranslation()
@property(nonatomic, strong) NSDictionary *mapping;
@property(nonatomic, strong) NSDictionary *transforms;
@end

@implementation UserAPITranslation
- (instancetype)init {
    self = [super init];
    
    // Specify our property to attribute mapping
    _mapping =  @{@"userId": @"id",
                  @"first": @"user.first",
                  @"last": @"user.last",
                  @"joined": @"started"};
    
    // Specify our transforms
    RLMTransformer *greetingTransformer = [RLMTransformer transformerWithBlock:^id(id attributes) {
        if ([attributes isKindOfClass:NSDictionary.class]) {
            NSString *prefix = [attributes valueForKeyPath:@"user.prefix"];
            NSString *last = [attributes valueForKeyPath:@"user.last"];
            return [NSString stringWithFormat:@"%@ %@", prefix, last];
        }
        return nil;
    }];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
    RLMTransformer *joinedTransformer = [RLMTransformer transformerWithDateFormatter:dateFormatter];
    
    // Active transform - block set as local variable before creating transformer
    RLMTransformBlock activeBlock = ^id(id attributes) {
        if ([attributes isKindOfClass:NSDictionary.class]) {
            
            // Get the date from our payload
            NSString *expirationDateString = attributes[@"expirationDate"];
            NSString *todayDateString = attributes[@"today"];
            
            // Get the date objects
            NSDateFormatter *formatter = [NSDateFormatter new];
            [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
            NSDate *expiryDate = [formatter dateFromString:expirationDateString];
            NSDate *today = [formatter dateFromString:todayDateString];
            
            // Expiration comparison
            return @([expiryDate compare:today] == NSOrderedDescending);
        }
        return [NSNumber numberWithBool:NO];
    };
    RLMTransformer *activeTransformer = [RLMTransformer transformerWithBlock:activeBlock];
    
    _transforms = @{@"greeting": greetingTransformer,
                    @"joined": joinedTransformer,
                    @"active": activeTransformer};
    
    return self;
}

- (NSString *)sourceKeyPathMappingForProperty:(NSString *)property {
    if ([self.mapping.allKeys containsObject:property]) {
        return self.mapping[property];
    }
    
    // by default, return the property name passed in
    return property;
}

- (RLMObjectTransformInput)transformInputForProperty:(NSString *)property {
    if ([property.lowercaseString isEqualToString:@"greeting"] || [property.lowercaseString isEqualToString:@"active"]) {
        return RLMObjectTransformInputAttributes;
    }
    
    return RLMObjectTransformInputDefault;
}

- (id)transformObject:(id)object forProperty:(NSString *)property {
    RLMTransformer *transform = self.transforms[property];
    if (transform) {
        return [transform transformObject:object];
    }
    
    // by default, return the original input
    return object;
}
@end
