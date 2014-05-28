//
//  RLMApplicationDelegate.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 22/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMApplicationDelegate.h"

#import <Realm/Realm.h>

@interface RealmTestClass1 : RLMObject

@property (nonatomic, readonly) NSInteger intValue;
@property (nonatomic, readonly) NSString *stringValue;

+ (instancetype)createWithInt:(NSInteger)integer string:(NSString *)string;

@end

@implementation RealmTestClass1

+ (instancetype)createWithInt:(NSInteger)integer string:(NSString *)string
{
    RealmTestClass1 *result = [[RealmTestClass1 alloc] init];
    result->_intValue = integer;
    result->_stringValue = string;
    return result;
}

@end

@implementation RLMApplicationDelegate

-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSInteger openFileIndex = [self.fileMenu indexOfItem:self.openMenuItem];
    [self.fileMenu performActionForItemAtIndex:openFileIndex];    
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return NO;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    return NO;
}

- (IBAction)generatedTestDb:(id)sender
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directories = [fileManager URLsForDirectory:NSDocumentDirectory
                                               inDomains:NSUserDomainMask];
    NSURL *url = [directories firstObject];
    url = [url URLByAppendingPathComponent:@"test123.realm"];
    NSString *path = url.path;
    
    RLMRealm *realm = [RLMRealm realmWithPath:path];
    
    [realm beginWriteTransaction];
    
    [realm addObject:[RealmTestClass1 createWithInt:10 string:@"ten"]];
    [realm addObject:[RealmTestClass1 createWithInt:20 string:@"twenty"]];
    [realm addObject:[RealmTestClass1 createWithInt:30 string:@"thirty"]];
    [realm addObject:[RealmTestClass1 createWithInt:40 string:@"fourty"]];
    [realm addObject:[RealmTestClass1 createWithInt:50 string:@"fifty"]];
    [realm addObject:[RealmTestClass1 createWithInt:60 string:@"sixty"]];
    [realm addObject:[RealmTestClass1 createWithInt:70 string:@"seventy"]];
    [realm addObject:[RealmTestClass1 createWithInt:80 string:@"eighty"]];
    [realm addObject:[RealmTestClass1 createWithInt:90 string:@"ninety"]];
    [realm addObject:[RealmTestClass1 createWithInt:100 string:@"hundred"]];
    
    [realm commitWriteTransaction];
}

@end
