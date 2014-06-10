////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMArray.h"
#import "RLMAccessor.h"
#import <tightdb/query.hpp>
#import <tightdb/link_view.hpp>
#import <tightdb/table_view.hpp>

//
// RLMArray private properties/ivars for all subclasses
//
// NOTE: We put all sublass properties in the same class to keep
//       the ivar layout the same - this allows us to switch implementations
//       after creation
@interface RLMArray () <RLMAccessor> {
  @private
    // array for standalone
    NSMutableArray *_backingArray;
  @protected
    // accessor ivars
    RLMRealm *_realm;
    BOOL _writable;     // YES when in write transaction
    BOOL _readOnly;     // YES for RLMArrays which are never mutable
}

/**
 Initialize an RLMArray.
 
 @warning Realm arrays are typed. You must specify an RLMObject class name during initialization
 and can only add objects of this type to the array.
 
 @param objectClassName     The class name of the RLMObjects this RLMArray will hold.
 
 @return                    An initialized RLMArray instance.
 */
- (instancetype)initWithObjectClassName:(NSString *)objectClassName;

// create standalone array variant
+ (instancetype)standaloneArrayWithObjectClassName:(NSString *)objectClassName;

@end


//
// LinkView backed RLMArray subclass
//
@interface RLMArrayLinkView : RLMArray {
    // FIXME - make private once we have self updating accessors - for
    //         now this gets set externally
    @public
    tightdb::LinkViewRef _backingLinkView;
}
+ (instancetype)arrayWithObjectClassName:(NSString *)objectClassName
                                          view:(tightdb::LinkViewRef)view
                                         realm:(RLMRealm *)realm;

// FIXME - remove once we have self-updating LinkView accessors
// we need to hold onto these until LinkView accessors self update
@property (nonatomic, strong) RLMObject *parentObject;
@property (nonatomic, assign) NSUInteger arrayColumnInParent;

@end


//
// TableView backed RLMArray subclass
//
@interface RLMArrayTableView : RLMArray {
    tightdb::TableView _backingView;
    tightdb::util::UniquePtr<tightdb::Query> _backingQuery;
}
+ (instancetype)arrayWithObjectClassName:(NSString *)objectClassName
                                   query:(tightdb::Query *)query
                                    view:(tightdb::TableView &)view
                                   realm:(RLMRealm *)realm;

// custom getter/setter for query - query lifcycle management
// is different from other accessors and requires special treatment
@property (nonatomic, assign) tightdb::Query *backingQuery;

@end


//
// Invalid and readonly RLMArray variants
//

// IMPORTANT NOTE: Do not add any ivars or properties to these sub-classes
//                 we switch the class of RLMArray instances after creation

// RLMArrayLinkView variant used when read only
@interface RLMArrayLinkViewReadOnly : RLMArrayLinkView
@end

// RLMArrayLinkView variant used when invalidated
@interface RLMArrayLinkViewInvalid : RLMArrayLinkView
@end

// RLMArrayTableView variant used when read only
@interface RLMArrayTableViewReadOnly : RLMArrayTableView
@end

// RLMArrayTableView variant used when invalidated
@interface RLMArrayTableViewInvalid : RLMArrayTableView
@end




