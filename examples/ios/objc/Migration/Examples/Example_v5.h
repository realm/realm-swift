////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

#ifndef SCHEMA_VERSION_5
#define SCHEMA_VERSION_5 1
#endif

#if SCHEMA_VERSION_5 && !SCHEMA_VERSION_4 && !SCHEMA_VERSION_3 && !SCHEMA_VERSION_2 && !SCHEMA_VERSION_1 && !SCHEMA_VERSION_0

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

#pragma mark - Schema

NSInteger schemaVersion = 5;

// Changes from previous version:
// - Change the `Address` from `Object` to `EmbeddedObject`.
//
// Be aware that this only works if there is only one `LinkingObject` per `Address`.
// See https://github.com/realm/realm-cocoa/issues/7060

@interface Pet : RLMObject
typedef NS_ENUM(int, Kind) {
    unspecified,
    dog,
    chicken,
    cow
};
@property NSString *name;
@property NSInteger kindValue;
@property enum Kind kind;
+ (Pet *)petWithName:(NSString *)name kind:(enum Kind)kind;
@end
RLM_ARRAY_TYPE(Pet)

@implementation Pet
+ (Pet *)petWithName:(NSString *)name kind:(enum Kind)kind {
    Pet *pet = [[self alloc] init];
    pet.name = name;
    pet.kind = kind;
    return pet;
}
- (enum Kind)kind {
    return (Kind)_kindValue;
}
- (void)setKind:(enum Kind)kind {
    _kindValue = kind;
}
+ (NSArray *)requiredProperties {
    return @[@"name", @"kindValue"];
}
+ (NSArray *)ignoredProperties {
    return @[@"kind"];
}
@end

@class Address;
@interface Person : RLMObject
@property NSString *fullName;
@property NSInteger age;
@property Address *address;
@property RLMArray<Pet *><Pet> *pets;
+ (Person *)personWithFullName:(NSString *)fullName age:(int)age;
@end

@implementation Person
+ (Person *)personWithFullName:(NSString *)fullName age:(int)age {
    Person *person = [[self alloc] init];
    person.fullName = fullName;
    person.age = age;
    return person;
}
+ (NSArray *)requiredProperties {
    return @[@"fullName", @"age"];
}
@end

@interface Address : RLMEmbeddedObject
@property NSString *street;
@property NSString *city;
@property (readonly) RLMLinkingObjects *residents;
+ (Address *)addressWithStreet:(NSString *)street city:(NSString *)city;
@end

@implementation Address
+ (Address *)addressWithStreet:(NSString *)street city:(NSString *)city {
    Address *address = [[self alloc] init];
    address.street = street;
    address.city = city;
    return address;
}
+ (NSArray *)requiredProperties {
    return @[@"street", @"city"];
}
+ (NSDictionary *)linkingObjectsProperties {
    return @{
        @"residents": [RLMPropertyDescriptor descriptorWithClass:Person.class propertyName:@"address"],
    };
}
@end

#pragma mark - Migration

// Migration block to migrate from *any* previous version to this version.
RLMMigrationBlock migrationBlock = ^(RLMMigration *migration, uint64_t oldSchemaVersion) {
    if (oldSchemaVersion < 1) {
        [migration enumerateObjects:Person.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            // combine name fields into a single field
            newObject[@"fullName"] = [NSString stringWithFormat:@"%@ %@", oldObject[@"firstName"], oldObject[@"lastName"]];
        }];
    }
    if (oldSchemaVersion < 2) {
        [migration enumerateObjects:Person.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            // Add a pet to a specific person
            if ([newObject[@"fullName"] isEqualToString:@"John Doe"]) {
                // `Dog` was changed to `Pet` in v2 already, but we still need to account for this
                // if upgrading from pre v2 to v3.
                Pet *marley = [Pet petWithName:@"Marley" kind:dog];
                Pet *lassie = [Pet petWithName:@"Lassie" kind:dog];
                RLMArray<Pet *><Pet> *pets = newObject[@"pets"];
                [pets addObject:marley];
                [pets addObject:lassie];
            } else if ([newObject[@"fullName"] isEqualToString:@"Jane Doe"]) {
                Pet *toto = [Pet petWithName:@"Toto" kind:dog];
                RLMArray<Pet *><Pet> *pets = newObject[@"pets"];
                [pets addObject:toto];
            }
        }];
        [migration createObject:Pet.className withValue:@[@"Slinkey", @1]];
    }
    if (oldSchemaVersion == 2) {
        // This branch is only relevant for version 2. If we are migration from a previous
        // version, we would not be able to access `dogs` since they did not exist back there.
        // Migration from v0 and v1 to v3 is done in the previous blocks.
        // Related issue: https://github.com/realm/realm-cocoa/issues/6263
        [migration enumerateObjects:Person.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            RLMArray<Pet *><Pet> *pets = newObject[@"pets"];
            for (RLMObject *dog in oldObject[@"dogs"]) {
                Pet *pet = (Pet *)[migration createObject:Pet.className withValue:@[dog[@"name"], @1]];
                [pets addObject:pet];
            }
        }];
        // We migrate over the old dog list to make sure all dogs get added, even those without
        // an owner.
        // Related issue: https://github.com/realm/realm-cocoa/issues/6734
        [migration enumerateObjects:@"Dog" block:^(RLMObject *oldDogObject, RLMObject *newDogObject) {
            __block bool dogFound = false;
            [migration enumerateObjects:Person.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                for (Pet *pet in newObject[@"pets"]) {
                    if ([pet[@"name"] isEqualToString:oldDogObject[@"name"]]) {
                        dogFound = true;
                        break;
                    }
                }
            }];
            if (!dogFound) {
                [migration createObject:Pet.className withValue:@[oldDogObject[@"name"], @1]];
            }
        }];
        // The data cannot be deleted just yet since the table is target of cross-table link columns.
        // See https://github.com/realm/realm-cocoa/issues/3686
        // [migration deleteDataForClassName:@"Dog"];
    }
    if (oldSchemaVersion < 4) {
        [migration enumerateObjects:Person.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            if ([newObject[@"fullName"] isEqualToString:@"John Doe"]) {
                Address *address = [Address addressWithStreet:@"Broadway" city:@"New York"];
                newObject[@"address"] = address;
            }
        }];
    }
    if (oldSchemaVersion < 5) {
        // Nothing to do here. The `Address` gets migrated to a `RLMEmbeddedObject` automatically if
        // it is only referenced by one other object.
        // See https://github.com/realm/realm-cocoa/issues/7060
    }
};

// This block checks if the migration led to the expected result.
// All older versions should have been migrated to the below stated `exampleData`.
typedef void (^MigrationCheck) (RLMRealm *realm);
MigrationCheck migrationCheck = ^(RLMRealm *realm) {
    RLMResults<Person *> *persons = [Person allObjects];
    assert(persons.count == 3);
    assert([persons[0].fullName isEqualToString:@"John Doe"]);
    assert(persons[0].age == 42);
    assert(persons[0].address != nil);
    assert([persons[0].address.city isEqualToString:@"New York"]);
    assert([persons[0].address.street isEqualToString:@"Broadway"]);
    assert(persons[0].pets.count == 2);
    assert([persons[0].pets[0].name isEqualToString:@"Marley"]);
    assert([persons[0].pets[1].name isEqualToString:@"Lassie"]);
    assert([persons[1].fullName isEqualToString:@"Jane Doe"]);
    assert(persons[1].age == 43);
    assert(persons[1].address == nil);
    assert(persons[1].pets.count == 1);
    assert([persons[1].pets[0].name isEqualToString:@"Toto"]);
    assert([persons[2].fullName isEqualToString:@"John Smith"]);
    assert(persons[2].age == 44);
    assert(persons[2].address == nil);
    RLMResults *pets = [Pet allObjects];
    assert(pets.count == 4);
    assert([pets objectsWithPredicate:[NSPredicate predicateWithFormat:@"name == 'Slinkey'"]].count == 1);
};

#pragma mark - Example data

// Example data for this schema version.
typedef void (^ExampleData) (RLMRealm *realm);
ExampleData exampleData = ^(RLMRealm *realm) {
    Person *person1 = [Person personWithFullName:@"John Doe" age: 42];
    Person *person2 = [Person personWithFullName:@"Jane Doe" age: 43];
    Person *person3 = [Person personWithFullName:@"John Smith" age: 44];
    Pet *pet1 = [Pet petWithName:@"Marley" kind:dog];
    Pet *pet2 = [Pet petWithName:@"Lassie" kind:dog];
    Pet *pet3 = [Pet petWithName:@"Toto" kind:dog];
    Pet *pet4 = [Pet petWithName:@"Slinkey" kind:dog];
    [realm addObjects:@[person1, person2, person3]];
    // pet1, pet2 and pet3 get added automatically by adding them to a list.
    // pet4 has to be added manually though since it's not attached to a person yet.
    [realm addObject:pet4];
    [person1.pets addObject:pet1];
    [person1.pets addObject:pet2];
    [person2.pets addObject:pet3];
};

#endif
