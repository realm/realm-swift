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

#ifndef SCHEMA_VERSION_0
#define SCHEMA_VERSION_0 0
#endif

#if SCHEMA_VERSION_0

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

#pragma mark - Schema

NSInteger schemaVersion = 0;

@interface Person : RLMObject
@property NSString *firstName;
@property NSString *lastName;
@property NSInteger age;
+ (Person *)personWithFirstName:(NSString *)firstName lastName:(NSString *)lastName age:(int)age;
@end

@implementation Person
+ (Person *)personWithFirstName:(NSString *)firstName lastName:(NSString *)lastName age:(int)age {
    Person *person = [[self alloc] init];
    person.firstName = firstName;
    person.lastName = lastName;
    person.age = age;
    return person;
}
+ (NSArray *)requiredProperties {
    return @[@"firstName", @"lastName", @"age"];
}
@end

#pragma mark - Migration

// Migration block to migrate from *any* previous version to this version.
RLMMigrationBlock migrationBlock = ^(RLMMigration* migration, uint64_t schemaVersion) {};

// This block checks if the migration led to the expected result.
// All older versions should have been migrated to the below stated `exampleData`.
typedef void (^MigrationCheck) (RLMRealm *realm);
MigrationCheck migrationCheck = ^(RLMRealm *realm) {
    RLMResults<Person *> *persons = [Person allObjects];
    assert(persons.count == 3);
    assert([persons[0].firstName isEqualToString:@"John"]);
    assert([persons[0].lastName isEqualToString:@"Doe"]);
    assert(persons[0].age == 42);
    assert([persons[1].firstName isEqualToString:@"Jane"]);
    assert([persons[1].lastName isEqualToString:@"Doe"]);
    assert(persons[1].age == 43);
    assert([persons[2].firstName isEqualToString:@"John"]);
    assert([persons[2].lastName isEqualToString:@"Smith"]);
    assert(persons[2].age == 44);
};

#pragma mark - Example data

// Example data for this schema version.
typedef void (^ExampleData) (RLMRealm *realm);
ExampleData exampleData = ^(RLMRealm *realm) {
    Person *person1 = [Person personWithFirstName:@"John" lastName:@"Doe" age:42];
    Person *person2 = [Person personWithFirstName:@"Jane" lastName:@"Doe" age: 43];
    Person *person3 = [Person personWithFirstName:@"John" lastName:@"Smith" age: 44];
    [realm addObjects:@[person1, person2, person3]];
};

#endif
