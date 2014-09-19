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

#import "RLMModelExporter.h"
#import <Realm/Realm.h>

@implementation RLMModelExporter

+(NSString *)stringWithJavaModelOfSchema:(RLMObjectSchema *)schema
{
    NSMutableString *string = [NSMutableString string];
    [string appendFormat:@"public class %@ extends RealmObject {\n", schema.className];
    
    for (RLMProperty *property in schema.properties) {
        [string appendFormat:@"    private %@ %@;\n", [self javaNameForProperty:property], property.name];
    }
    
    [string appendFormat:@"}"];
    
    return string;
}

+(NSString *)javaNameForProperty:(RLMProperty *)property
{
    switch (property.type) {
        case RLMPropertyTypeBool:
            return @"boolean";
        case RLMPropertyTypeInt:
            return @"int";
        case RLMPropertyTypeFloat:
            return @"float";
        case RLMPropertyTypeDouble:
            return @"double";
        case RLMPropertyTypeString:
            return @"String";
        case RLMPropertyTypeData:
            return @"byte[]";
        case RLMPropertyTypeAny:
            return @"Any";
        case RLMPropertyTypeDate:
            return @"Date";
        case RLMPropertyTypeArray:
            return [NSString stringWithFormat:@"RealmList<%@>", property.objectClassName];
        case RLMPropertyTypeObject:
            return [NSString stringWithFormat:@"%@", property.objectClassName];
    }
}

@end

/*
 
 private byte aByte;
 private short aShort;
 private long aLong;
 
 */