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

typedef NS_ENUM(NSInteger, RLMObjectTransformInput) {
    RLMObjectTransformInputDefault = 0, // default is a mapped value
    RLMObjectTransformInputMappedValue = RLMObjectTransformInputDefault,
    RLMObjectTransformInputAttributes
};

/**
 * @description This protocol defines how objects should be created
 * from a given input source. You could use this when creating objects
 * from the response of an API call where the response structure does
 * not match the RLMObject property structure. This protocol also defines
 * how input data is transformed during initialization. For example, you
 * may need to format dates, or combine two remote attributes to form a
 * single local property value.
 
 * @see RLMTransformer
 * @see [RLMObject defaultTranslation]
 */
@protocol RLMObjectTranslationProtocol <NSObject>
@required

/**
 * @brief The mapped source for a given property from the input object
 * @param property The current property being evaluated
 * @return The key path within the source to map for the give property
 */
- (NSString *)sourceKeyPathMappingForProperty:(NSString *)property;

/**
 * @brief The input type expected for a given property
 * @param property  The current property being evaluated
 * @return An RLMObjectTransformInput value representing the
 * type of data the corresponding transform expects
 * @see transformObject:forProperty:
 */
- (RLMObjectTransformInput)transformInputForProperty:(NSString *)property;

/**
 * @brief Transform a given object for a given property
 * @param object    The object that should be transformed
 * @param property  The property for which the object is being transformed
 * @return The transformed object
 */
- (id)transformObject:(id)object forProperty:(NSString *)property;

@end
