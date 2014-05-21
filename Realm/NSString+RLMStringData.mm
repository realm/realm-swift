//
//  NSString+RLMStringData.m
//  Realm
//
//  Created by Ari Lazier on 5/21/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "NSString+RLMStringData.h"
#import <tightdb/util/safe_int_ops.hpp>

@implementation NSString (RLMStringData)

+(NSString *)stringWithRLMStringData:(tightdb::StringData)stringData {
    if (tightdb::util::int_cast_has_overflow<NSUInteger>(stringData.size())) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"String size overflow" userInfo:nil];
        
    }
    return [[NSString alloc] initWithBytes:stringData.data()
                                    length:stringData.size()
                                  encoding:NSUTF8StringEncoding];
}

-(tightdb::StringData)RLMStringData {
    if (tightdb::util::int_cast_has_overflow<size_t>(self.length)) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"String size overflow" userInfo:nil];
        
    }
    return tightdb::StringData(self.UTF8String, self.length);
}

@end
