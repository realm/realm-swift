//
//  DataModels.m
//  RealmMigrationExample
//
//  Created by Ari Lazier on 6/26/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "DataModels.h"

@implementation Pet

+ (AnimalType)animalTypeForString:(NSString *)typeString {
    if ([typeString isEqualToString:@"dog"]) {
        return AnimalTypeDog;
    }
    if ([typeString isEqualToString:@"cat"]) {
        return AnimalTypeCat;
    }
    if ([typeString isEqualToString:@"hamster"]) {
        return AnimalTypeHamster;
    }
    @throw [NSException exceptionWithName:@"InvalidAnimalException" reason:@"typeString is not a valid animal type" userInfo:nil];
}

@end

@implementation Person
@end