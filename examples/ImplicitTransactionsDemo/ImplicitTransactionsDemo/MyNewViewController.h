#import <UIKit/UIKit.h>

@interface MyNewViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    IBOutlet UILabel *changeCount;
    IBOutlet UITableView* tableView;
}

@end
