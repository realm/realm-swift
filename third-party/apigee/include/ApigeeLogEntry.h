//
//  LogEntry.h
//  ApigeeAppMonitoring
//
//  Copyright (c) 2012 Apigee. All rights reserved.
//


@interface ApigeeLogEntry : NSObject

@property (strong, nonatomic) NSString *tag;
@property (strong, nonatomic) NSString *logLevel;
@property (strong, nonatomic) NSString *logMessage;
@property (strong, nonatomic) NSString *timeStamp;

- (NSDictionary*) asDictionary;

@end
