//
//  RLMResults+RLMResults_Sync.m
//  Realm
//
//  Created by Adam Fish on 8/30/17.
//  Copyright © 2017 Realm. All rights reserved.
//

#import "RLMResults+RLMResults_Sync.h"

@implementation RLMResults (RLMResults_Sync)

- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults<RLMObjectType> *__nullable results,
                                                         RLMCollectionChange *__nullable change,
                                                         NSError *__nullable error))block __attribute__((warn_unused_result)) {
    // Pseudo-code
    
    /*
     1. Check if existing `ResultSets` object exists
     1a. If NO, create or update the `ResultSets` table in the Realm
     
     @interface ResultSets : RLMObject
     
     // The name of the matches property to be used for the query associated
     // with this result set (`'car_matches'` for instance).
     @property NSString *matches_property;
     
     // The query (usual predicate syntax) to be executed against
     // the class associated with the selected matches property
     // (see `matches_property`).
     @property NSString *query;
     
     // Status    meaning
     // -------------------------------
     //   0       uninitialized
     //   1       initialized
     //  -1       query parsing failed
     //
     // Application should leave the status at zero for new result
     // sets. Server will set to 1 after each successful execution, and -1 on
     // failure to parse the query. While the status remains -1, the server
     // will ignore that result set. The application may reset the status
     // back to 0 at any time.
     @property NSInteger status;
     
     // When the server fails to parse the specified query, it
     // stores the associated error message here. Expect a multi
     // lined message with a line terminator on the final line.
     @property NSString *error_message;
     
     // Custom matches properties. One for each class that needs to be
     // queryable.
     @property RLMArray<RLMObjectType *><RLMObjectType> *matches;
     @end
     1b. If YES, skip to step 3
     2. Create a `ResultSets` object for the query
     3. Obtain the session and use `wait_for_download_completion` to then fire the first callback
     
     */
    
}

@end
