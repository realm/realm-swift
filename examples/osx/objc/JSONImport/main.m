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
#import "Person.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        // Import JSON
        NSString *jsonFilePath = [[NSBundle mainBundle] pathForResource:@"persons" ofType:@"json"];
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonFilePath];
        NSError *error = nil;
        NSArray *personDicts = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:0
                                                                 error:&error];
        if (error) {
            NSLog(@"There was an error reading the JSON file: %@", error.localizedDescription);
            return 1;
        }

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.dateFormat = @"MMMM dd, yyyy";
        dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

        [[NSFileManager defaultManager] removeItemAtURL:[RLMRealmConfiguration defaultConfiguration].fileURL
                                                   error:nil];

        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];

        // Add Person objects in realm for every person dictionary in JSON array
        for (NSDictionary *personDict in personDicts) {
            Person *person = [[Person alloc] init];
            person.fullName = personDict[@"name"];
            person.birthdate = [dateFormatter dateFromString:personDict[@"birthdate"]];
            person.numberOfFriends = [(NSNumber *)personDict[@"friendCount"] integerValue];
            [realm addObject:person];
        }
        [realm commitWriteTransaction];

        // Print all persons from realm
        for (Person *person in [Person allObjects]) {
            NSLog(@"person persisted to realm: %@", person);
        }

        // Realm file saved at default path (~/Documents/default.realm)
    }
    return 0;
}
