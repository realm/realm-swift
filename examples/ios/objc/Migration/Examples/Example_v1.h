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

#ifndef SCHEMA_VERSION_1
#define SCHEMA_VERSION_1 0
#endif

#if SCHEMA_VERSION_1

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

#pragma mark - Schema

NSInteger schemaVersion = 1;

// Changes from previous version:
// - combine `firstName` and `lastName` into `fullName`

@interface Person : RLMObject
@property NSString *fullName;
@property NSInteger age;
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
            if (oldSchemaVersion < 1) {
                // combine name fields into a single field
                newObject[@"fullName"] = [NSString stringWithFormat:@"%@ %@", oldObject[@"firstName"], oldObject[@"lastName"]];
            }
        }];
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
    assert([persons[1].fullName isEqualToString:@"Jane Doe"]);
    assert(persons[1].age == 43);
    assert([persons[2].fullName isEqualToString:@"John Smith"]);
    assert(persons[2].age == 44);
};

#pragma mark - Example data

// Example data for this schema version.
typedef void (^ExampleData) (RLMRealm *realm);
ExampleData exampleData = ^(RLMRealm *realm) {
    Person *person1 = [Person personWithFullName:@"John Doe" age: 42];
    Person *person2 = [Person personWithFullName:@"Jane Doe" age: 43];
    Person *person3 = [Person personWithFullName:@"John Smith" age: 44];
    [realm addObjects:@[person1, person2, person3]];
};

#endif
