#import "AppDelegate.h"
#import <Realm/Realm.h>

// Define your models
@interface Dog : RLMObject
@property NSString *name;
@property NSInteger age;
@end

@implementation Dog
// No need for implementation
@end

RLM_ARRAY_TYPE(Dog)

@interface Person : RLMObject
@property NSString        *name;
@property NSData          *picture;
@property RLMArray<Dog>   *dogs;
@end

@implementation Person
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    // Create a standalone object
    Dog *mydog = [[Dog alloc] init];
    
    // Set & read properties
    mydog.name = @"Rex";
    mydog.age = 9;
    NSLog(@"Name of dog: %@", mydog.name);
    
    // Realms are used to group data together
    RLMRealm *realm = [RLMRealm defaultRealm]; // Create realm pointing to default file
    
    // Save your object
    [realm beginWriteTransaction];
    [realm addObject:mydog];
    [realm commitWriteTransaction];
    
    // Query
    RLMArray *results = [realm objects:[Dog className] where:@"name contains 'x'"];
    
    // Queries are chainable!
    RLMArray *results2 = [results objectsWhere:@"age > 8"];
    NSLog(@"Number of dogs: %li", (unsigned long)results2.count);
    
    // Link objects
    Person *person = [[Person alloc] init];
    person.name = @"Tim";
    [person.dogs addObject:mydog];
    
    [realm beginWriteTransaction];
    [realm addObject:person];
    [realm commitWriteTransaction];
    
    // Query across objects
    RLMArray *peopleWithDogNamesContainingX = [Person objectsWhere:@"dog.name contains 'x' for dog in dogs"];
    NSLog(@"Number of people: %li", (unsigned long)peopleWithDogNamesContainingX.count);

    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,	0),	^{
        RLMRealm *otherRealm = [RLMRealm	defaultRealm];
        RLMArray *otherResults = [otherRealm objects:[Dog className] where:@"name contains 'rex'"];
        NSLog(@"Number of dogs: %li", (unsigned long)otherResults.count);
    });
    
    return YES;
}

@end
