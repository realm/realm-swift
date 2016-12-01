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

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>
#import "DrawPoint.h"

@interface DrawPath : RLMObject

@property BOOL completed;   // Set to YES once the user stops drawing this particular line
@property NSString *color;  // The name of the color that this path is drawn in
@property RLMArray<DrawPoint *><DrawPoint> *points; 

@property (readonly) UIBezierPath *path;

@end
