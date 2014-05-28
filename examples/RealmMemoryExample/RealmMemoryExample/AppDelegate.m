

#import "AppDelegate.h"
#import "MainViewController.h"
#import <Realm/Realm.h>

#import <sys/mman.h>





@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    UIViewController *vc = [[UIViewController alloc] init];
    
    [self.window setRootViewController:vc];

    
    [self memoryMapTestWithSizeInMb:25 permission:PROT_WRITE numberOfFiles:100];

    
    return YES;
}


- (void)memoryMapTestWithSizeInMb:(int)mb permission:(int)permission numberOfFiles:(int)numberOfFiles;
{
    size_t sizeInBytes = mb*1024*1024;
    
    for (int i=0;i<numberOfFiles;i++) {
        [[NSFileManager defaultManager] createFileAtPath:[AppDelegate writeablePathForFile:[NSString stringWithFormat:@"file%i.realm", i]]
                                                contents:nil
                                              attributes:nil];
    }
    
    const char *paths[numberOfFiles];
    int files[numberOfFiles];
    
    for (int i=0;i<numberOfFiles;i++) {
        paths[i] = [[AppDelegate writeablePathForFile:[NSString stringWithFormat:@"file%i.realm", i]] UTF8String];
        files[i] = open(paths[i], O_RDWR);
    }
    
    void *baseAdresses[numberOfFiles];
    
    int totalmbAlreadyMapped = 0;
    
    for (int i=0;i<numberOfFiles;i++) {
        
        baseAdresses[i] = mmap(NULL, sizeInBytes, permission, MAP_SHARED, files[i], 0);
        
        if (baseAdresses[i] == MAP_FAILED)
        {
            perror("mmap");
            NSLog(@"Failing %i for size: %zu (%d mb) with permission: %@. Already mapped: %i", i, sizeInBytes, mb, [AppDelegate permissionToString:permission], totalmbAlreadyMapped);
            close(files[i]);
        } else {
            NSLog(@"Success %i for size: %zu (%d mb) with permission: %@", i, sizeInBytes, mb, [AppDelegate permissionToString:permission]);
            totalmbAlreadyMapped = totalmbAlreadyMapped + mb;
        }
    }

    for (int i=0;i<numberOfFiles;i++) {
        munmap(baseAdresses[i], sizeInBytes);
    }
}


+ (NSString *)permissionToString:(int)permission
{
    if (permission == 1) {
        return @"PROT_READ";
    } else if (permission == 2) {
        return @"PROT_WRITE";
    } else {
        return @"other";
    }
}


+ (NSString *)writeablePathForFile:(NSString*)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
