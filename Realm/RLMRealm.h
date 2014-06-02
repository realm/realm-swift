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


#import <Foundation/Foundation.h>

@class RLMObject, RLMArray, RLMRealm, RLMSchema, RLMMigrationRealm;

typedef void(^RLMNotificationBlock)(NSString *notification, RLMRealm *realm);
typedef void (^RLMMigrationBlock)(RLMMigrationRealm *realm);

/**
 An RLMRealm instance models a Realm, the . Similiar in concept to a table in a traditional RDBMS 
 such as MySQL, each Realm represents a data store that persists data as objects subclassed from RLMObject.
 Each Realm can persist objects of mixed types.
 
 ### Persistence
 In Realm, data is persisted as RLMObject subclass instances, stored in an RLMRealm instance. Each RLMRealm
 instance can be persisted in a specified file or in-memory.

 ### Accessing & querying RLMRealm

 Sets of RLMObjects can be retrieved either by subclass type, or using a predicate to query
 for specific objects and object values. Sets are returned as RLMArray instances.

 You can query an RLMRealm subclass directly via the following class methods:  

  - allObjects:
  - objects:where:
  - objects:orderedBy:where:
  - objectForKeyedSubscript:

 ### Change notifications<a name="notifications"></a>
 Realm supports a notification handler (RLMNotificationBlock) that can be attached to any Realm
 and is triggered by any changes to a Realm.
 
 RLMNotificationbBock has the following definition:
  
      typedef void(^RLMNotificationBlock)(NSString *notification, RLMRealm *realm);
  
  It receives the following parameters:
  
  - `NSString`: The name of the incoming notification.
     `RLMRealmDidChangeNotification` is the only notification currently supported.
  - `RLMRealm`: The realm for which this notification occurred

 ###Namespaces
 Realm provides a top level key/value store for storing and accessing objects by NSString. This system can be
 extended with the RLMKeyValueStore interface to create nested namespaces as needed.
 */
@interface RLMRealm : NSObject

/**---------------------------------------------------------------------------------------
 *  @name Creating & Initializing a Realm
 * ---------------------------------------------------------------------------------------
 */
/** 
 Gets an instance of the default RLMRealm.
 
 RLMRealm instances are reused when this is called multiple times from the same thread. The 
 default RLMRealm is persisted as default.realm under the 'Documents' directory of your application.
 
 @warning  	RLMRealm instances are not thread safe and cannot be shared across threads or 
           	dispatch queues. You must create a separate RLMRealm instance for each thread and queue.
 
 @return  	The default RLMRealm instance for the current thread.
 */
+ (instancetype)defaultRealm;

/**
 Creates an RLMRealm instance and persists it in the specified file.
 
 RLMRealm instances are reused when this is called multiple times from the same thread.
 
 @warning  	RLMRealm instances are not thread safe and can not be shared across threads or
 			dispatch queues. You must create a separate RLMRealm instance for each thread and queue.
 
 @param 	path	The path to the file you want the RLMRealm persisted in.
 
 @return 	A persisted RLMRealm instance.
 */
+ (instancetype)realmWithPath:(NSString *)path;

/**
 Creates an RLMRealm instance and persists it in the specified file with options.
 
 @warning  RLMRealm instances are not thread safe and can not be shared across threads or
 dispatch queues. You must get a separate RLMRealm instance for each thread and queue.
 
 @param path 	 	The path to the file you want the RLMRealm persisted in.
 @param readonly  	A `BOOL` indicating if this RLMRealm is readonly (must use for readonly files)
 @param error  		A pass-by-reference for errors.
 
 @exception realm:runloop_exception  Thrown if this method is called from a thread that does not have a runloop.

 @return A persisted RLMRealm instance.
 */
+ (instancetype)realmWithPath:(NSString *)path readOnly:(BOOL)readonly error:(NSError **)error;

/**
 Specifies that the default RLMRealm will be persisted in-memory only.
 
 The default RLMRealm is persisted to disk unless this method is called.
 
 @warning 	This must be called before any RLMRealm instances are obtained or an exception will be thrown.

 @exception 
 */
+ (void)useInMemoryDefaultRealm;

/**
 The path to the file where this RLMRealm is being persisted.
 */
@property (nonatomic, readonly) NSString *path;

/**
 Indicates if this RLMRealm is read-only.
 
 @return 	A `BOOL` indicating if this RLMRealm instance is readonly.
 */
@property (nonatomic, readonly) BOOL isReadOnly;


#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Receiving Notification when a Realm Changes
 * ---------------------------------------------------------------------------------------
 */

/**
 Adds a notification handler (RLMNotificationBlock) to be triggered by changes in an RLMRealm.
  
 @param block 	The [RLMNotificationBlock](#notifications) to be called to process notifications from this RLMRealm. 			   

 @see 	[Change notifications](#notifications)
 */
- (void)addNotificationBlock:(RLMNotificationBlock)block;

/**
 Removes a notification handler from an RLMRealm.
  
 @param block  The [RLMNotificationBlock](#notifications) to remove.
 
 @see 	[Change notifications](#notifications)
 */
- (void)removeNotificationBlock:(RLMNotificationBlock)block;

#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Writing to a Realm
 * ---------------------------------------------------------------------------------------
 */

/**
 Begins a write transaction to an RLMRealm.
 
 Only one write transaction can be open at a time. Calls to beginWriteTransaction from RLMRealm instances
 in other threads will block until the current write transaction terminates.
 
 If writes were made in other threads or processes to other instances of the same RLMRealm, the RLMRealm 
 on which beginWriteTransaction is called and all outstanding objects obtained from this RLMRealm are updated to
 the latest RLMRealm version when this method is called.
 */
- (void)beginWriteTransaction;

/**
 Commits all write operations from the current write transaction. 
 
 After this is called, the RLMRealm reverts back to being read-only.
 */
- (void)commitWriteTransaction;

/**
 Abandons all write operations in the current write transaction and terminates the transaction.
 
 After this is called, the RLMRealm reverts back to being read-only.
 */
- (void)rollbackWriteTransaction;

/**
 Updates an RLMRealm and all oustanding objects to point to the most recent data for this RLMRealm.
 */
- (void)refresh;

/**
 Specifies whether this RLMRealm should be automatically updated when changes occur in other threads.
 Set to `YES` to automacially update. Set to `NO` to require refresh to be manually called on the RLMRealm.
 
 Defaults to YES on the main thread, and NO on all others.

 Notifications are sent immediately when a change is avaiable whether or not the RLMRealm is automatically
 updated. 
 */
@property (nonatomic) BOOL autorefresh;

#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Adding and Removing Objects from a Realm
 * ---------------------------------------------------------------------------------------
 */
/**
 Adds an RLMObject to this RLMRealm to be persisted.
 
 Once added, this object can be retrieved using the objectsWhere: selectors on RLMRealm and on
 subclasses of RLMObject. 

 Once added, all linked (child) objects referenced by the specified object will
 also be added to the RLMRealm if they are not already in it. If linked objects already belong to a
 different RLMRealm an exception will be thrown.
 
 @param object	An RLMObject instance to be added to this RLMRealm.
 
 @exception
 */
- (void)addObject:(RLMObject *)object;

/**
 Adds all RLMObject subclass instances in the given array to this RLMRealm to be persistsed.
 
 This is similar equivalent of addObject:, except that it accepts an NSArray of objects.
 
 @param array  	NSArray or RLMArray of RLMObjects (or subclasses) to be added to this RLMRealm.
 
 @see   addObject:
 */
- (void)addObjectsFromArray:(id)array;

/**
 Deletes an RLMObject from this RLMRealm.
 
 @param object  An RLMObject to be deleted from this Realm.
 */
- (void)deleteObject:(RLMObject *)object;


/**---------------------------------------------------------------------------------------
 *  @name Getting Objects from a Realm
 * ---------------------------------------------------------------------------------------
 */
/**
 Retrieves all RLMObject instances of a specified subclass type from this RLMRealm.
 
 @param className   The name of the RLMObject subclass to retrieve eg. `MyClass.className`.
 
 @return    An RLMArray of all objects in this RLMRealm of the given type.
 
 @see       RLMObject allObjects
 */
- (RLMArray *)allObjects:(NSString *)className;

/**
 Retrieves all RLMObject instances that match the given predicate from the this RLMRealm.
 
 In the future this method will be used to get an RLMArray with objects of mixed types. For now, you must
 specify an RLMObject type in the predicate in the form: `Class = className`.

 The preferred way to get RLMObjects of a single class is to use the class methods on RLMObject.
 
 @param predicate   An [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html), 
 					a predicte string, or predicate format string that can accept variable arguments.
 
 @return    An RLMArray of results matching the given predicate.
 
 @see       RLMObject objectsWhere:
 */
- (RLMArray *)objects:(NSString *)className where:(id)predicate, ...;

/**
 Retrieves an ordered array of RLMObjects instances that match the subclass type and given predicate from the this Realm.
 
 In the future this method will be used to get an RLMArray with objects of mixed types. For now, you must
 specify an object type in the predicate of the form `Class = className`.

 The preferred way to get objects of a single class is to use the class methods on RLMObject.
 
 @param order 		An NSString containing a property name, or an [NSSortDescriptor](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/NSSortDescriptor_Class/Reference/Reference.html) 
	   		   		containing a property name and order to sort the results by.
 @param predicate   An [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html), 
 					a predicte string, or predicate format string that can accept variable arguments.
 
 @return    An ordered RLMArray of RLMObjects from the default Realm that match the specified predicate and subclass type.
 
 @see 	[RLMObject objectsOrderedBy:where:]
 */
- (RLMArray *)objects:(NSString *)className orderedBy:(id)order where:(id)predicate, ...;

#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Named Object Storage and Retrieval
 * ---------------------------------------------------------------------------------------
 */

/**
 Retrieves a persisted RLMObject with an NSString.
 
 @usage 	RLMObject * object = RLMRealm.defaultRealm[@"name"];
 @param 	key 	The NSString used to identify an object
 
 @return    RLMObject or nil if no object is stored for the specified key.
 */
-(id)objectForKeyedSubscript:(id <NSCopying>)key;

/**
 Store an object with an NSString key.
 
 @usage RLMRealm.defaultRealm[@"name"] = object;
 @param obj     The object to be stored.
 @param key     The key that itentifies the object to be used for future lookups.
 */
-(void)setObject:(RLMObject *)obj forKeyedSubscript:(id <NSCopying>)key;


#pragma mark -

//---------------------------------------------------------------------------------------
// @name Realm and Object Schema
//---------------------------------------------------------------------------------------

/**
 The schema used by this RLMRealm. This can be used to enumerate and introspect object
 types during migrations for dynamic introspection.
 */
@property (nonatomic, readonly) RLMSchema *schema;

/**
 The schema version used by this RLMRealm.
 */ 
@property (nonatomic, readonly) NSUInteger schemaVersion;

@end
