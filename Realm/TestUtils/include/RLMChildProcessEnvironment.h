////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

@interface RLMChildProcessEnvironment : NSObject 

/// A single app identifier provided by the parent process.
@property (nonatomic, readonly, nullable) NSString *appId;
/// A list of app identifiers provided by the parent process.
@property (nonatomic, readonly, nonnull) NSArray<NSString *> *appIds;
/// An email credential provided by the parent process.
@property (nonatomic, readonly, nullable) NSString *email;
/// A password credential provided by the parent process.
@property (nonatomic, readonly, nullable) NSString *password;
/// A unique identifier set by the user (this differs from the PID).
@property (nonatomic, readonly) NSInteger identifier;
/// Whether or not the child process should delete the client root and reset the sync manager. True by default.
@property (nonatomic, readonly) BOOL shouldCleanUpOnTermination;

- (nonnull instancetype)init;

- (nonnull instancetype)initWithAppIds:(NSArray<NSString *> * _Nullable)appIds
                                 email:(NSString * _Nullable)email
                              password:(NSString * _Nullable)password
                             identifer:(NSInteger)identifier
            shouldCleanUpOnTermination:(BOOL)shouldCleanUpOnTermination;

- (NSDictionary<NSString *, NSString *> * _Nonnull)dictionaryValue;

+ (instancetype _Nonnull)current;

@end
