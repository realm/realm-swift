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
#import <Realm/Realm.h>

// Old data models
/* V0
@interface Person : RLMObject
@property NSString *firstName;
@property NSString *lastName;
@property int age;
@end
 */

/* V1
@interface Person : RLMObject
@property NSString *fullName;   // combine firstName and lastName into single field
@property int age;
@end
*/

/* V2
@interface Pet : RLMObject      // add a new model class
@property NSString *name;
@property NSString *type;
@end
RLM_ARRAY_TYPE(Pet)

@interface Person : RLMObject
@property NSString *fullName;
@property RLMArray<Pet> *pets;  // add and array property
@property int age;
@end
*/

/* V3 */
typedef NS_ENUM(NSInteger, AnimalType) {
    AnimalTypeDog = 1,
    AnimalTypeCat,
    AnimalTypeHamster,
};

@interface Pet : RLMObject
@property NSString *name;
@property AnimalType type;      // change type from string to enum

+ (AnimalType)animalTypeForString:(NSString *)typeString;

@end
RLM_ARRAY_TYPE(Pet)

@interface Person : RLMObject
@property NSString *fullName;
@property int age;              // age and pets properties re-ordered (handled automatically)
@property RLMArray<Pet> *pets;
@end


