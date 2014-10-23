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

#import "RLMDocument.h"

#import "RLMClassNode.h"
#import "RLMArrayNode.h"
#import "RLMClassProperty.h"
#import "RLMRealmOutlineNode.h"
#import "RLMRealmBrowserWindowController.h"

@implementation RLMDocument

- (instancetype)init
{
    if (self = [super init]) {

    }
    return self;
}

- (instancetype)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    if (self = [super init]) {
        if (![[typeName lowercaseString] isEqualToString:@"documenttype"]) {
            return self;
        }
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:absoluteURL.path]) {
            return self;
        }
        NSString *lastComponent = [absoluteURL lastPathComponent];
        NSString *extension = [absoluteURL pathExtension];
        
        if (![[extension lowercaseString] isEqualToString:@"realm"]) {
            return self;
        }
        
        NSArray *fileNameComponents = [lastComponent componentsSeparatedByString:@"."];
        NSString *realmName = [fileNameComponents firstObject];
        
        RLMRealmNode *realmNode = [[RLMRealmNode alloc] initWithName:realmName url:absoluteURL.path];
        self.presentedRealm  = realmNode;
        
        NSArray *wcs = self.windowControllers;

        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            if ([realmNode connect:&error]) {
                NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
                [documentController noteNewRecentDocumentURL:absoluteURL];
                
                for (RLMRealmBrowserWindowController *windowController in wcs) {
                    [windowController realmDidLoad];
                }
            }
        });
    }
    
    return self;
}

- (id)initForURL:(NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    return nil;
}

#pragma mark - Public methods - NSDocument overrides - Creating and Managing Window Controllers

- (void)makeWindowControllers
{
    RLMRealmBrowserWindowController *windowController = [[RLMRealmBrowserWindowController alloc] initWithWindowNibName:self.windowNibName];
    windowController.modelDocument = self;
    
    [self addWindowController:windowController];
}

- (NSString *)windowNibName
{
    return @"RLMDocument";
}

#pragma mark - Public methods - NSDocument overrides - Loading Document Data

+(BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // As we do not use the usual file handling mechanism we just returns nil (but it is necessary
    // to override this method as the default implementation throws an exception.
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // As we do not use the usual file handling mechanism we just returns YES (but it is necessary
    // to override this method as the default implementation throws an exception.
    return YES;
}

#pragma mark - Public methods - NSDocument overrides - Managing Document Windows

- (NSString *)displayName
{
    if (self.presentedRealm.name != nil) {
        return self.presentedRealm.name;
    }
    
    return [super displayName];
}

@end
