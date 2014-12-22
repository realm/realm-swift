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

#import <Foundation/Foundation.h>
#import <Realm/Realm.h> // FIXME


@class RLMBPaneViewController;
@interface RLMBViewModel : NSObject

- (NSString *)printablePropertyValue:(id)propertyValue type:(RLMPropertyType)type;
- (NSString *)printableArray:(RLMArray *)array;
- (NSString *)printableObject:(RLMObject *)object;

- (NSString *)editablePropertyValue:(id)propertyValue type:(RLMPropertyType)type;
- (id)valueForString:(NSString *)string type:(RLMPropertyType)type;

+ (NSAttributedString *)headerStringForProperty:(RLMProperty *)property;

@end
