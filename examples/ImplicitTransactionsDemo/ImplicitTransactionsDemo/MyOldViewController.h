#import <UIKit/UIKit.h>

@interface MyOldViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    IBOutlet UILabel *refreshCount;
    IBOutlet UISwitch *refreshSwitch;
    IBOutlet UITableView* tableView;
}

- (IBAction)refreshSwitchChanged:(UISwitch*)theSwitch;

- (void)tick:(NSTimer *)theTimer;

@end
