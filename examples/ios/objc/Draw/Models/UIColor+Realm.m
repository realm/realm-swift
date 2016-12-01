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

#import "UIColor+Realm.h"

@implementation UIColor (Realm)
+ (NSDictionary<NSString *, UIColor*> *)realmColors {
    static NSDictionary<NSString *, UIColor*> *realmColors;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        realmColors =
        @{
          @"Charcoal": [UIColor colorWithRed:28.0f/255.0f green:35.0f/255.0f blue:63.0f/255.0f alpha:1.0f],
          @"Elephant": [UIColor colorWithRed:154.0f/255.0f green:155.0f/255.0f blue:165.0f/255.0f alpha:1.0f],
          @"Dove": [UIColor colorWithRed:235.0f/255.0f green:235.0f/255.0f blue:242.0f/255.0f alpha:1.0f],
          @"Ultramarine": [UIColor colorWithRed:57.0f/255.0f green:71.0f/255.0f blue:127.0f/255.0f alpha:1.0f],
          @"Indigo": [UIColor colorWithRed:89.0f/255.0f green:86.0f/255.0f blue:158.0f/255.0f alpha:1.0f],
          @"GrapeJelly": [UIColor colorWithRed:154.0f/255.0f green:80.0f/255.0f blue:165.0f/255.0f alpha:1.0f],
          @"Mulberry": [UIColor colorWithRed:211.0f/255.0f green:76.0f/255.0f blue:163.0f/255.0f alpha:1.0f],
          @"Flamingo": [UIColor colorWithRed:242.0f/255.0f green:81.0f/255.0f blue:146.0f/255.0f alpha:1.0f],
          @"SexySalmon": [UIColor colorWithRed:247.0f/255.0f green:124.0f/255.0f blue:136.0f/255.0f alpha:1.0f],
          @"Peach": [UIColor colorWithRed:252.0f/255.0f green:159.0f/255.0f blue:149.0f/255.0f alpha:1.0f],
          @"Melon": [UIColor colorWithRed:252.0f/255.0f green:195.0f/255.0f blue:151.0f/255.0f alpha:1.0f]
        };
    });
    return realmColors;
}
@end
