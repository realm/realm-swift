//
//  RLMApplicationDelegate.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 22/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMApplicationDelegate.h"

#import <Realm/Realm.h>

#import "TestClasses.h"
#import "RLMArray+Extension.h"

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
    
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithPath:path
                                     readOnly:NO
                                        error:&error];
    
    [realm beginWriteTransaction];
    
    RealmTestClass0 *tc0_0 = [RealmTestClass0 instanceWithInt:45 string:@"John"];
    RealmTestClass0 *tc0_1 = [RealmTestClass0 instanceWithInt:23 string:@"Mary"];
    RealmTestClass0 *tc0_2 = [RealmTestClass0 instanceWithInt:38 string:@"Peter"];
    RealmTestClass0 *tc0_3 = [RealmTestClass0 instanceWithInt:12 string:@"Susan"];
    RealmTestClass0 *tc0_4 = [RealmTestClass0 instanceWithInt:34 string:@"John"];
    RealmTestClass0 *tc0_5 = [RealmTestClass0 instanceWithInt:75 string:@"James"];
    RealmTestClass0 *tc0_6 = [RealmTestClass0 instanceWithInt:45 string:@"Gilbert"];
    RealmTestClass0 *tc0_7 = [RealmTestClass0 instanceWithInt:45 string:@"Ann"];
    
    [realm addObjectsFromArray:@[tc0_0, tc0_1, tc0_2, tc0_3, tc0_4, tc0_5, tc0_6, tc0_7]];
/*
    RLMArray<RealmTestClass0> *ta_0 = (RLMArray<RealmTestClass0> *)[[RLMArray alloc] initWithObjectClassName:NSStringFromClass([RealmTestClass0 class])];
    RLMArray<RealmTestClass0> *ta_1 = (RLMArray<RealmTestClass0> *)[[RLMArray alloc] initWithObjectClassName:NSStringFromClass([RealmTestClass0 class])];
    RLMArray<RealmTestClass0> *ta_2 = (RLMArray<RealmTestClass0> *)[[RLMArray alloc] initWithObjectClassName:NSStringFromClass([RealmTestClass0 class])];
    RLMArray<RealmTestClass0> *ta_3 = (RLMArray<RealmTestClass0> *)[[RLMArray alloc] initWithObjectClassName:NSStringFromClass([RealmTestClass0 class])];
    RLMArray<RealmTestClass0> *ta_4 = (RLMArray<RealmTestClass0> *)[[RLMArray alloc] initWithObjectClassName:NSStringFromClass([RealmTestClass0 class])];
    RLMArray<RealmTestClass0> *ta_5 = (RLMArray<RealmTestClass0> *)[[RLMArray alloc] initWithObjectClassName:NSStringFromClass([RealmTestClass0 class])];
    RLMArray<RealmTestClass0> *ta_6 = (RLMArray<RealmTestClass0> *)[[RLMArray alloc] initWithObjectClassName:NSStringFromClass([RealmTestClass0 class])];
    RLMArray<RealmTestClass0> *ta_7 = (RLMArray<RealmTestClass0> *)[[RLMArray alloc] initWithObjectClassName:NSStringFromClass([RealmTestClass0 class])];
    RLMArray<RealmTestClass0> *ta_8 = (RLMArray<RealmTestClass0> *)[[RLMArray alloc] initWithObjectClassName:NSStringFromClass([RealmTestClass0 class])];
    RLMArray<RealmTestClass0> *ta_9 = (RLMArray<RealmTestClass0> *)[[RLMArray alloc] initWithObjectClassName:NSStringFromClass([RealmTestClass0 class])];
    
    [realm addObjectsFromArray:@[ta_0, ta_1, ta_2, ta_3, ta_4, ta_5, ta_6, ta_7, ta_8, ta_9]];
    
    [ta_0 addObjectsFromArray:@[tc0_0, tc0_1, tc0_3]];
    [ta_1 addObjectsFromArray:@[tc0_2]];
    [ta_2 addObjectsFromArray:@[tc0_0, tc0_4]];
    [ta_3 addObjectsFromArray:@[]];
    [ta_4 addObjectsFromArray:@[tc0_5]];
    [ta_5 addObjectsFromArray:@[tc0_1, tc0_2, tc0_3, tc0_4, tc0_5, tc0_6, tc0_7]];
    [ta_6 addObjectsFromArray:@[tc0_6, tc0_7]];
    [ta_7 addObjectsFromArray:@[tc0_7, tc0_6]];
    [ta_8 addObjectsFromArray:@[]];
    [ta_9 addObjectsFromArray:@[tc0_0]];
*/    
    RealmTestClass1 *tc1_0 = [RealmTestClass1 instanceWithInt:10    bool:YES float:123.456 double:123456.789 string:@"ten"      date:[NSDate date]                                                      arrayRef:nil];// ta_0];
    RealmTestClass1 *tc1_1 = [RealmTestClass1 instanceWithInt:20    bool:NO  float:23.4561 double:987654.321 string:@"twenty"   date:[NSDate distantPast]                                               arrayRef:nil];// ta_1];
    RealmTestClass1 *tc1_2 = [RealmTestClass1 instanceWithInt:30    bool:YES float:3.45612 double:1234.56789 string:@"thirty"   date:[NSDate distantFuture]                                             arrayRef:nil];// ta_2];
    RealmTestClass1 *tc1_3 = [RealmTestClass1 instanceWithInt:40    bool:NO  float:.456123 double:9876.54321 string:@"fourty"   date:[[NSDate date] dateByAddingTimeInterval:-60.0 * 60.0 * 24.0 * 7.0] arrayRef:nil];// ta_3];
    RealmTestClass1 *tc1_4 = [RealmTestClass1 instanceWithInt:50    bool:YES float:654.321 double:123.456789 string:@"fifty"    date:[[NSDate date] dateByAddingTimeInterval:+60.0 * 60.0 * 24.0 * 7.0] arrayRef:nil];// ta_4];
    RealmTestClass1 *tc1_5 = [RealmTestClass1 instanceWithInt:60    bool:NO  float:6543.21 double:987.654321 string:@"sixty"    date:[[NSDate date] dateByAddingTimeInterval:-60.0 * 60.0 * 24.0 * 1.0] arrayRef:nil];// ta_5];
    RealmTestClass1 *tc1_6 = [RealmTestClass1 instanceWithInt:70    bool:YES float:65432.1 double:12.3456789 string:@"seventy"  date:[[NSDate date] dateByAddingTimeInterval:+60.0 * 60.0 * 24.0 * 1.0] arrayRef:nil];// ta_6];
    RealmTestClass1 *tc1_7 = [RealmTestClass1 instanceWithInt:80    bool:NO  float:654321. double:98.7654321 string:@"eighty"   date:[[NSDate date] dateByAddingTimeInterval:-60.0 * 60.0 * 12.0 * 1.0] arrayRef:nil];// ta_7];
    RealmTestClass1 *tc1_8 = [RealmTestClass1 instanceWithInt:90    bool:YES float:123.456 double:1.23456789 string:@"ninety"   date:[[NSDate date] dateByAddingTimeInterval:+60.0 * 60.0 * 12.0 * 1.0] arrayRef:nil];// ta_8];
    RealmTestClass1 *tc1_9 = [RealmTestClass1 instanceWithInt:100   bool:NO  float:123.456 double:9.87654321 string:@"hundred"  date:[[NSDate date] dateByAddingTimeInterval:+60.0 *  5.0 *  1.0 * 1.0] arrayRef:nil];// ta_9];
    
    RealmTestClass2 *tc2_0 = [RealmTestClass2 instanceWithInt:1111  bool:YES objectRef:tc1_0];
    RealmTestClass2 *tc2_1 = [RealmTestClass2 instanceWithInt:2211  bool:YES objectRef:tc1_2];
    RealmTestClass2 *tc2_2 = [RealmTestClass2 instanceWithInt:3322  bool:YES objectRef:tc1_4];
    RealmTestClass2 *tc2_3 = [RealmTestClass2 instanceWithInt:4433  bool:NO  objectRef:tc1_6];
    RealmTestClass2 *tc2_4 = [RealmTestClass2 instanceWithInt:5544  bool:YES objectRef:tc1_8];
//    RealmTestClass2 *tc2_5 = [RealmTestClass2 instanceWithInt:6655  bool:YES objectRef:nil];
    RealmTestClass2 *tc2_6 = [RealmTestClass2 instanceWithInt:7766  bool:NO  objectRef:tc1_0];
    
    [realm addObjectsFromArray:@[tc1_0, tc1_1, tc1_2, tc1_3, tc1_4, tc1_5, tc1_6, tc1_7, tc1_8, tc1_9]];
    
    [realm addObjectsFromArray:@[tc2_0, tc2_1, tc2_2, tc2_2, tc2_3, tc2_4, tc2_6]];
    // [realm addObject:tc2_5];
    
    [realm commitWriteTransaction];
}

@end
