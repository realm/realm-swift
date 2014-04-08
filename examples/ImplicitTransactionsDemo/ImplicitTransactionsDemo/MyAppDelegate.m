#import <Tightdb/Tightdb.h>

#import "MyAppDelegate.h"
#import "MyOldViewController.h"
#import "MyNewViewController.h"
#import "MyBackgroundThread.h"

@implementation MyAppDelegate

- (NSString *)pathForName:(NSString *)name
{
    NSArray* dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [NSString stringWithFormat:@"%@/%@", [dirs objectAtIndex:0], name];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    TDBContext* context = [TDBContext contextWithPersistenceToFile:[self pathForName:@"demo.tightdb"] error:nil];
    [context writeWithBlock:^(TDBTransaction *transact) {
        TDBTable *table = nil;
        if (![transact hasTableWithName:@"demo"]) {
            table = [transact createTableWithName:@"demo"];
            [table addColumnWithName:@"text" type:TDBStringType];
        }
        else {
            table = [transact tableWithName:@"demo"];
        }
        [table removeAllRows];
        for (int i = 0; i < 5; ++i) {
            [table addRow:@[@"Lorem"]];
            [table addRow:@[@"Ipsum"]];
        }
        return YES; // Commit
    } error:nil];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    UIViewController *viewController1 =
        [[MyOldViewController alloc] initWithNibName:@"MyOldViewController" bundle:nil];
    UIViewController *viewController2 =
        [[MyNewViewController alloc] initWithNibName:@"MyNewViewController" bundle:nil];
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[viewController1, viewController2];
    self.window.rootViewController = self.tabBarController;

    NSThread* thread = [[MyBackgroundThread alloc] init];
    [thread start];

    [self.window makeKeyAndVisible];
    return YES;
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

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

@end
