#import "TAppDelegate.h"
#import <Tightdb/Tightdb.h>

@implementation TAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    self.sharedGroup = [TightdbSharedGroup sharedGroupWithFile:[self pathForDataFile:@"todosdb2.tightdb"] withError:nil];
    
    
    TAppDelegate* delegate = (TAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    [delegate.sharedGroup writeWithBlock:^(TightdbGroup *tnx) {
        
   
        TightdbTable *todoTable = [tnx getTable:@"todos" error:nil];
        
        if([todoTable getColumnCount] == 0) {
            [todoTable addColumnWithType:tightdb_String andName:@"todoName"];
            [todoTable addColumnWithType:tightdb_Bool   andName:@"completed"];
        }
        
        return YES; // Commit
    } withError:nil];
    
    return YES;
}

- (NSString *) pathForDataFile:(NSString *)filename {
        NSArray* documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                 NSString*   path = nil;
                            
                            if (documentDir) {
                                path = [documentDir objectAtIndex:0];
                            }
                            
                            return [NSString stringWithFormat:@"%@/%@", path, filename];
                        }

@end
