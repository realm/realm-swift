//
//  ApigeeUtils.h
//  ApigeeiOSSDK
//
//  Copyright (c) 2013 Apigee. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ApigeeJsonUtils : NSObject

+ (NSString*)encode:(id)object;
+ (NSString*)encode:(id)object error:(NSError**)error;
+ (NSData*)encodeAsData:(id)object;
+ (NSData*)encodeAsData:(id)object error:(NSError**)error;

+ (id)decode:(NSString*)json;
+ (id)decode:(NSString*)json error:(NSError**)error;
+ (id)decodeData:(NSData*)jsonData;
+ (id)decodeData:(NSData*)jsonData error:(NSError**)error;


@end
