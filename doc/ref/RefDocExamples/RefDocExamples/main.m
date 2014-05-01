#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "examples.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {
        remove_default_persistence_file(); // Ensure default persistence file is removed
        
        ex_objc_query_dynamic_intro();
        remove_default_persistence_file();
        
        ex_objc_query_typed_intro();
        remove_default_persistence_file();
        
        ex_objc_context_intro();
        remove_default_persistence_file();
        
        ex_objc_realm_intro();
        remove_default_persistence_file();
        
        ex_objc_table_dynamic_intro();
        remove_default_persistence_file();
        
        ex_objc_table_dyn_table_sizes();
        remove_default_persistence_file();
        
        ex_objc_table_typed_intro();
        remove_default_persistence_file();
        
        ex_objc_table_typed_intro_with_many_comments();
        remove_default_persistence_file();
        
        ex_objc_tableview_dynamic_intro();
        remove_default_persistence_file();
        
        ex_objc_tableview_typed_intro();
        remove_default_persistence_file();
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
