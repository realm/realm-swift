//
//  DataModels.h
//  RealmMigrationExample
//
//  Created by Ari Lazier on 6/26/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

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
@property NSString *fullName;
@property int age;
@end
*/

/* V2
@interface Pet : RLMObject
@property NSString *name;
@property NSString *type;
@end
RLM_ARRAY_TYPE(Pet)

@interface Person : RLMObject
@property NSString *fullName;
@property RLMArray<Pet> *pets;
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
@property AnimalType type;

+ (AnimalType)animalTypeForString:(NSString *)typeString;

@end
RLM_ARRAY_TYPE(Pet)

@interface Person : RLMObject
@property NSString *fullName;
@property int age;
@property RLMArray<Pet> *pets;
@end


