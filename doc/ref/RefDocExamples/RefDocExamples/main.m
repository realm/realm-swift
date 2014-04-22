#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "examples.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {
        ex_objc_query_dynamic_intro();
        ex_objc_query_typed_intro();
        ex_objc_context_intro();
        ex_objc_smart_context_intro();
        ex_objc_table_dynamic_intro();
        ex_objc_table_typed_intro();
        ex_objc_table_typed_intro_with_many_comments();
        ex_objc_tableview_dynamic_intro();
        ex_objc_tableview_typed_intro();
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
