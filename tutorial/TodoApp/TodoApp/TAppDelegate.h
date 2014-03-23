#import <UIKit/UIKit.h>
#import <Tightdb/Tightdb.h>

@interface TAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) TightdbSharedGroup *sharedGroup;

@end
