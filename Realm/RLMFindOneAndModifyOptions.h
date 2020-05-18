//
//  RLMFindOneAndModifyOptions.h
//  Realm
//
//  Created by Lee Maguire on 15/05/2020.
//  Copyright © 2020 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol RLMBSON;

@interface RLMFindOneAndModifyOptions : NSObject

/// Limits the fields to return for all matching documents.
@property (nonatomic, nullable) id<RLMBSON> projectionBson;

/// The order in which to return matching documents.
@property (nonatomic, nullable) id<RLMBSON> sortBson;

/// Whether or not to perform an upsert, default is false
/// (only available for find_one_and_replace and find_one_and_update)
@property (nonatomic) BOOL upsert;

/// If this is true then the new document is returned,
/// Otherwise the old document is returned (default)
/// (only available for find_one_and_replace and find_one_and_update)
@property (nonatomic) BOOL returnNewDocument;

- (instancetype)initWithProjectionBson:(id<RLMBSON> _Nullable)projectionBson
                              sortBson:(id<RLMBSON> _Nullable)sortBson
                                upsert:(BOOL)upsert
                     returnNewDocument:(BOOL)returnNewDocument;

@end

NS_ASSUME_NONNULL_END
