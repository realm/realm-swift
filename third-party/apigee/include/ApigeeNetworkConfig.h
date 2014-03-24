//
//  ApigeeNetworkConfig.h
//  ApigeeAppMonitor
//
//  Copyright (c) 2012 Apigee. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ApigeeNetworkConfig : NSObject

@property (assign, nonatomic) NSInteger configId;
@property (assign, nonatomic) BOOL heuristicCachingEnabled;
@property (assign, nonatomic) float heuristicCoefficient;
@property (assign, nonatomic) NSInteger heuristicDefaultLifetime;
@property (assign, nonatomic) BOOL isSharedCache;
@property (assign, nonatomic) NSInteger maxCacheEntries;
@property (assign, nonatomic) NSInteger maxObjectSizeBytes;
@property (assign, nonatomic) NSInteger maxUpdateRetries;

@end
