//
//  NSString+RLMStringData.h
//  Realm
//
//  Created by Ari Lazier on 5/21/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <tightdb/string_data.hpp>

@interface NSString (RLMStringData)

// create NSString from StringData (copies data)
+ (NSString *)stringWithRLMStringData:(tightdb::StringData)stringData;

// create StringData from NSString (StringData constructor does not copy)
- (tightdb::StringData)RLMStringData;

@end
