#import <Tightdb/Tightdb.h>

#import "MyAppDelegate.h"
#import "MyOldViewController.h"
#import "MyNewViewController.h"
#import "MyBackgroundThread.h"


@implementation MyAppDelegate

- (NSString *)pathForName:(NSString *)name
{
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [NSString stringWithFormat:@"%@/%@", [dirs objectAtIndex:0], name];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    TDBContext *context = [TDBContext contextWithPersistenceToFile:[self pathForName:@"demo.tightdb"] error:nil];
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

    NSThread *thread = [[MyBackgroundThread alloc] init];
    [thread start];

    [self.window makeKeyAndVisible];
    return YES;
}

@end
