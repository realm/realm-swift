//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

#import <Realm/Realm.h>

@interface ___FILEBASENAMEASIDENTIFIER___ : RLMObject
<# Add properties here to define the model #>
@end

// This protocol enables typed collections. i.e.:
// RLMArray<___FILEBASENAMEASIDENTIFIER___ *><___FILEBASENAMEASIDENTIFIER___>
RLM_COLLECTION_TYPE(___FILEBASENAMEASIDENTIFIER___)
