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

#import <Foundation/Foundation.h>


#define GROUP_LOG 0
#define GROUP_RUN 1
#define GROUP_DIFF 2
#define GROUP_SIZE 3

@interface Utils : NSObject

-(id)initWithView:(UIScrollView *)view;

- (NSString *) pathForDataFile:(NSString *)filename;

-(void)Eval:(BOOL)good msg:(NSString *)msg;
-(void)OutGroup:(int)group msg:(NSString *)msg;
@end
