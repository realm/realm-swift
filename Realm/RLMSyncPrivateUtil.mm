////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import "RLMSyncPrivateUtil.h"

NSURL *RLMAuthURLForSyncURL(NSURL *syncURL, NSNumber *customPort) {
    BOOL isSSL = [syncURL.scheme isEqualToString:@"realms"];
    NSString *scheme = (isSSL ? @"https" : @"http");
    NSInteger port = customPort ? [customPort integerValue] : (isSSL ? 8081 : 8080);
    NSString *raw = [NSString stringWithFormat:@"%@://%@:%@", scheme, syncURL.host, @(port)];
    return [NSURL URLWithString:raw];
}
