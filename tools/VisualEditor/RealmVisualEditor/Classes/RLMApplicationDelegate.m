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

@property (nonatomic, readonly) NSInteger integerValue;
@property (nonatomic, readonly) BOOL boolValue;
@property (nonatomic, readonly) float floatValue;
@property (nonatomic, readonly) float doubleValue;
@property (nonatomic, readonly) NSString *stringValue;
@property (nonatomic, readonly) NSDate *dateValue;

+ (instancetype)instanceWithInt:(NSInteger)integerValue bool:(BOOL)boolValue float:(float)floatValue double:(double)doubleValue string:(NSString *)stringValue date:(NSDate *)dateValue;

@end

@implementation RealmTestClass1

+ (instancetype)instanceWithInt:(NSInteger)integerValue bool:(BOOL)boolValue float:(float)floatValue double:(double)doubleValue string:(NSString *)stringValue date:(NSDate *)dateValue
{
    RealmTestClass1 *result = [[RealmTestClass1 alloc] init];
    result->_integerValue = integerValue;
    result->_boolValue = boolValue;
    result->_floatValue = floatValue;
    result->_doubleValue = doubleValue;
    result->_stringValue = stringValue;
    result->_dateValue = dateValue;
    return result;
}

@end

@interface RealmTestClass2 : RLMObject

@property (nonatomic, readonly) NSInteger integerValue;
@property (nonatomic, readonly) BOOL boolValue;

+ (instancetype)instanceWithInt:(NSInteger)integerValue bool:(BOOL)boolValue;

@end

@implementation RealmTestClass2

+ (instancetype)instanceWithInt:(NSInteger)integerValue bool:(BOOL)boolValue
{
    RealmTestClass2 *result = [[RealmTestClass2 alloc] init];
    result->_integerValue = integerValue;
    result->_boolValue = boolValue;
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
    
    [realm addObject:[RealmTestClass1 instanceWithInt:10    bool:YES float:123.456 double:123456.789 string:@"ten"      date:[NSDate date]]];
    [realm addObject:[RealmTestClass1 instanceWithInt:20    bool:NO  float:23.4561 double:987654.321 string:@"twenty"   date:[NSDate distantPast]]];
    [realm addObject:[RealmTestClass1 instanceWithInt:30    bool:YES float:3.45612 double:1234.56789 string:@"thirty"   date:[NSDate distantFuture]]];
    [realm addObject:[RealmTestClass1 instanceWithInt:40    bool:NO  float:.456123 double:9876.54321 string:@"fourty"   date:[[NSDate date] dateByAddingTimeInterval:-60.0 * 60.0 * 24.0 * 7.0]]];
    [realm addObject:[RealmTestClass1 instanceWithInt:50    bool:YES float:654.321 double:123.456789 string:@"fifty"    date:[[NSDate date] dateByAddingTimeInterval:+60.0 * 60.0 * 24.0 * 7.0]]];
    [realm addObject:[RealmTestClass1 instanceWithInt:60    bool:NO  float:6543.21 double:987.654321 string:@"sixty"    date:[[NSDate date] dateByAddingTimeInterval:-60.0 * 60.0 * 24.0 * 1.0]]];
    [realm addObject:[RealmTestClass1 instanceWithInt:70    bool:YES float:65432.1 double:12.3456789 string:@"seventy"  date:[[NSDate date] dateByAddingTimeInterval:+60.0 * 60.0 * 24.0 * 1.0]]];
    [realm addObject:[RealmTestClass1 instanceWithInt:80    bool:NO  float:654321. double:98.7654321 string:@"eighty"   date:[[NSDate date] dateByAddingTimeInterval:-60.0 * 60.0 * 12.0 * 1.0]]];
    [realm addObject:[RealmTestClass1 instanceWithInt:90    bool:YES float:123.456 double:1.23456789 string:@"ninety"   date:[[NSDate date] dateByAddingTimeInterval:+60.0 * 60.0 * 12.0 * 1.0]]];
    [realm addObject:[RealmTestClass1 instanceWithInt:100   bool:NO  float:123.456 double:9.87654321 string:@"hundred"  date:[[NSDate date] dateByAddingTimeInterval:+60.0 *  5.0 *  1.0 * 1.0]]];
    
    [realm addObject:[RealmTestClass2 instanceWithInt:1111  bool:YES]];
    [realm addObject:[RealmTestClass2 instanceWithInt:2211  bool:YES]];
    [realm addObject:[RealmTestClass2 instanceWithInt:3322  bool:YES]];
    [realm addObject:[RealmTestClass2 instanceWithInt:4433  bool:NO]];
    [realm addObject:[RealmTestClass2 instanceWithInt:5544  bool:YES]];
    [realm addObject:[RealmTestClass2 instanceWithInt:6655  bool:YES]];
    [realm addObject:[RealmTestClass2 instanceWithInt:7766  bool:NO]];
    
    [realm commitWriteTransaction];
}

@end
