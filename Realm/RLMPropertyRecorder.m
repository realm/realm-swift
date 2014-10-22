//
//  RLMPropertyRecorder.m
//  Realm
//
//  Created by Thomas Goyne on 10/22/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMPropertyRecorder.h"

@implementation RLMPropertyRecorder {
    NSString *propertyName;
    id obj;
}

+ (id)recorderForClass:(Class)cls {
    RLMPropertyRecorder *recorder = [RLMPropertyRecorder alloc];
    recorder->obj = [[cls alloc] init];
    return recorder;

}

+ (NSString *)propertyNameFromRecorder:(id)recorder {
    return ((RLMPropertyRecorder *)recorder)->propertyName;
}

- (id)forwardingTargetForSelector:(SEL)sel {
    propertyName = NSStringFromSelector(sel);
    return obj;
}
@end
