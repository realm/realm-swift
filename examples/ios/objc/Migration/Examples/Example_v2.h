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

#ifndef SCHEMA_VERSION_2
#define SCHEMA_VERSION_2 0
#endif

#if SCHEMA_VERSION_2

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

#pragma mark - Schema

NSInteger schemaVersion = 2;

// Changes from previous version:
// add a `Dog` object
// add a list of `dogs` to the `Person` object

@interface Dog : RLMObject
@property NSString *name;
+ (Dog *)dogWithName:(NSString *)name;
@end
RLM_ARRAY_TYPE(Dog)

@implementation Dog
+ (Dog *)dogWithName:(NSString *)name {
    Dog *dog = [[self alloc] init];
    dog.name = name;
    return dog;
}
+ (NSArray *)requiredProperties {
    return @[@"name"];
}
@end

@interface Person : RLMObject
@property NSString *fullName;
@property NSInteger age;
@property RLMArray<Dog *><Dog> *dogs;
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
                Dog *marley = [Dog dogWithName:@"Marley"];
                Dog *lassie = [Dog dogWithName:@"Lassie"];
                RLMArray<Dog *><Dog> *dogs = newObject[@"dogs"];
                [dogs addObject:marley];
                [dogs addObject:lassie];
            } else if ([newObject[@"fullName"] isEqualToString:@"Jane Doe"]) {
                Dog *toto = [Dog dogWithName:@"Toto"];
                RLMArray<Dog *><Dog> *dogs = newObject[@"dogs"];
                [dogs addObject:toto];
            }
        }];
        [migration createObject:Dog.className withValue:@[@"Slinkey"]];
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
    assert(persons[0].dogs.count == 2);
    assert([persons[0].dogs[0].name isEqualToString:@"Marley"]);
    assert([persons[0].dogs[1].name isEqualToString:@"Lassie"]);
    assert([persons[1].fullName isEqualToString:@"Jane Doe"]);
    assert(persons[1].age == 43);
    assert(persons[1].dogs.count == 1);
    assert([persons[1].dogs[0].name isEqualToString:@"Toto"]);
    assert([persons[2].fullName isEqualToString:@"John Smith"]);
    assert(persons[2].age == 44);
    RLMResults *dogs = [Dog allObjects];
    assert(dogs.count == 4);
    assert([dogs objectsWithPredicate:[NSPredicate predicateWithFormat:@"name == 'Slinkey'"]].count == 1);
};

#pragma mark - Example data

// Example data for this schema version.
typedef void (^ExampleData) (RLMRealm *realm);
ExampleData exampleData = ^(RLMRealm *realm) {
    Person *person1 = [Person personWithFullName:@"John Doe" age: 42];
    Person *person2 = [Person personWithFullName:@"Jane Doe" age: 43];
    Person *person3 = [Person personWithFullName:@"John Smith" age: 44];
    Dog *pet1 = [Dog dogWithName:@"Marley"];
    Dog *pet2 = [Dog dogWithName:@"Lassie"];
    Dog *pet3 = [Dog dogWithName:@"Toto"];
    Dog *pet4 = [Dog dogWithName:@"Slinkey"];
    [realm addObjects:@[person1, person2, person3]];
    // pet1, pet2 and pet3 get added automatically by adding them to a list.
    // pet4 has to be added manually though since it's not attached to a person yet.
    [realm addObject:pet4];
    [person1.dogs addObject:pet1];
    [person1.dogs addObject:pet2];
    [person2.dogs addObject:pet3];
};

#endif
