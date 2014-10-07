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

#import "RLMArray.h"
#import "RLMResults.h"

#import <tightdb/link_view.hpp>
#import <tightdb/table_view.hpp>
#import <tightdb/query.hpp>

// RLMArray private properties/ivars for all subclasses
@interface RLMArray () {
  @protected
    // accessor ivars
    RLMRealm *_realm;
    NSString *_objectClassName;
}

// initializer
- (instancetype)initWithObjectClassName:(NSString *)objectClassName standalone:(BOOL)standalone;

// deletes all objects in the RLMArray from their containing realms
- (void)deleteObjectsFromRealm;

@end


//
// LinkView backed RLMArray subclass
//
@interface RLMArrayLinkView : RLMArray
+ (instancetype)arrayWithObjectClassName:(NSString *)objectClassName
                                    view:(tightdb::LinkViewRef)view
                                   realm:(RLMRealm *)realm;
@end


//
// RLMResults private methods
//
@interface RLMResults ()
+ (instancetype)resultsWithObjectClassName:(NSString *)objectClassName
                                     query:(std::unique_ptr<tightdb::Query>)query
                                     realm:(RLMRealm *)realm;

+ (instancetype)resultsWithObjectClassName:(NSString *)objectClassName
                                     query:(std::unique_ptr<tightdb::Query>)query
                                      view:(tightdb::TableView)view
                                     realm:(RLMRealm *)realm;
- (void)deleteObjectsFromRealm;
@end

//
// RLMResults subclass used when a TableView can't be created - this is used
// for readonly realms where we can't create an underlying table class for a
// type, and we need to return a functional RLMResults instance which is always empty.
//
@interface RLMEmptyResults : RLMResults
+ (instancetype)emptyResultsWithObjectClassName:(NSString *)objectClassName
                                          realm:(RLMRealm *)realm;
@end

//
// A simple holder for a C array of ids to enable autoreleasing the array without
// the runtime overhead of a NSMutableArray
//
@interface RLMCArrayHolder : NSObject {
@public
    std::unique_ptr<id[]> array;
    NSUInteger size;
}

- (instancetype)initWithSize:(NSUInteger)size;

// Reallocate the array if it is not already the given size
- (void)resize:(NSUInteger)size;
@end
