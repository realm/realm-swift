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

#import "NSFileManager+GlobAdditions.h"

@implementation NSFileManager (GlobAdditions)

- (NSArray *)globFilesAtDirectoryURL:(NSURL *)directoryURL fileExtension:(NSString *)extension errorHandler:(BOOL (^)(NSURL *URL, NSError *error))handler {
    return [self globFilesAtDirectoryURL:directoryURL predicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"pathExtension == '%@'", extension]] errorHandler:handler];
}

- (NSArray *)globFilesAtDirectoryURL:(NSURL *)directoryURL predicate:(NSPredicate *)filteredPredicate errorHandler:(BOOL (^)(NSURL *URL, NSError *error))handler {
    NSDirectoryEnumerator *directoryEnumerator = [self enumeratorAtURL:directoryURL
                                            includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                               options:NSDirectoryEnumerationSkipsHiddenFiles
                                                          errorHandler:handler];
    NSMutableArray *fileURLs = [NSMutableArray array];
    for (NSURL *fileURL in directoryEnumerator) {
        NSString *fileName;
        [fileURL getResourceValue:&fileName forKey:NSURLNameKey error:nil];
        
        NSString *isDirectory;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        
        //check it is not a directory
        if (![isDirectory boolValue]) {
            [fileURLs addObject:fileURL];
        }
    }
    
    return [fileURLs filteredArrayUsingPredicate:filteredPredicate];
}

@end
