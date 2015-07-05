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

#import "NSTask+LaunchAdditions.h"

@implementation NSTask (LaunchAdditions)

+ (NSTask *)launchedTaskSynchonouslyWithPath:(NSString *)path arguments:(NSArray *)args inCurrentDirectoryPath:(NSString*)directoryPath standardOutput:(NSString* __autoreleasing *)output
{
    // Setup task with given parameters
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = path;
    task.arguments = args;
    
    if (directoryPath) {
        task.currentDirectoryPath = directoryPath;
    }
    
    // Setup output Pipe to created Task
    NSPipe *outputPipe = [NSPipe pipe];
    task.standardOutput = outputPipe;
    
    [task launch];
    [task waitUntilExit];
    
    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    
    *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    return task;
}

@end
