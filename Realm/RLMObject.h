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
#import <Realm/RLMConstants.h>

@class RLMRealm;
@class RLMArray;


/**
 In Realm you define your model classes by subclassing RLMObject and adding properties to be persisted.
 You then instantiate and use your custom subclasses instead of using the RLMObject class directly.

     // in Dog.h
     @interface Dog : RLMObject
 
     @property NSString *name;
     @property NSDate   *birthdate;
     @property BOOL      adopted;
 
     @end
 
     // in Dog.m
     @implementation Dog
     @end //none needed
 
 ### RLMObject Properties
 Supported property types are:
 
 - `NSString`
 - `NSInteger`, `CGFloat`, `int`, `long`, `float`, and `double`
 - `BOOL` or `bool`
 - `NSDate`
 - `NSData`
 - Other objects subclassing `RLMObject`, so you can link RLMObject instances together.
 
 #### Customizing properties
 You can set which of these properties should be indexed, stored inline, unique, required
 as well as delete rules for the links by implementing the attributesForProperty: method.
 
 You can set properties to ignore (i.e. transient properties you do not want
 persisted to a Realm) by implementing ignoredProperties.
 
 You can set default values for properties by implementing defaultPropertyValues.
 
 ### Accessing & querying RLMObject

 You can query an RLMObject subclass directly by using the methods listed under 
 [Getting & Querying Objects from the Default Realm](#task_Getting &amp; Querying Objects from the Default Realm).

 These methods allow you to easily query the default Realm. To search in a Realm other than
 the defaut Realm, use the interface on an RLMRealm instance.
 
 ### Using keyed subscripts

 Realm also supports keyed subscripts for accessing and setting RLMObjects stored in an RLMRealm. 

 For example, to set a property of an RLMObject with an NSString value, the syntax would look like this:

       	myRLMObject[@"name"] = @"Tom";

 The syntax to retrieve the property from the RLMObject would look like this:
 
       	NSString * myName = myRLMObject[@"name"];

 */


@interface RLMObject : NSObject

/**---------------------------------------------------------------------------------------
 *  @name Creating & Initializing Objects
 * ---------------------------------------------------------------------------------------
 */

/**
 Initialize an unpersisted, standalone RLMObject
 
 To add a standalone RLMObject to an RLMRealm, call [RLMRealm addObject:].
 
 @see  [RLMRealm addObject:]
 */
-(instancetype)init;

/**
 Returns the class name of the RLMObject subclass.
 
 @return  The subclass name.
 */
+ (NSString *)className;

/**
 Creates an RLMObject instance from a given object and adds it to a specified RLMRealm, 
 where it will be persisted.
 
 @param  realm   The RLMRealm instance to add the object to.
 @param  object  The object used to populate the RLMObject instance. This can be any key/value compliant
                 object, a JSON object such as those returned from the methods in 
                 [NSJSONSerialization](https://developer.apple.com/library/ios/documentation/foundation/reference/nsjsonserialization_class/Reference/Reference.html), 
                 or an [NSArray](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSArray_Class/NSArray.html)
                 that contains one object for each persisted property. 
 
 @exception  RLMException  Thrown if all required properties are not present or no default is provided.
                           When passing in an NSArray, all properties must be present and valid.
 
 @see            defaultPropertyValues
 */
+(instancetype)createInRealm:(RLMRealm *)realm withObject:(id)object;

/**
 Creates an RLMObject instance from a JSONString and adds it to a specified RLMRealm,
 where it will be persisted.
  
 @param  realm       The RLMRealm instance to add the RLMObject to.
 @param  JSONString  An NSString with valid JSON to create the RLMObject instance from. 

 @exception  RLMException  An exception will be thrown if required properties are
                           not present in the JSON for which defaults are not provided.
 
 @see                defaultPropertyValues
 */
+(instancetype)createInRealm:(RLMRealm *)realm withJSONString:(NSString *)JSONString;

/**
 Returns the RLMRealm instance in which this object is persisted, or nil if the instance
 is a standalone RLMObject.
 */
@property (nonatomic, readonly) RLMRealm *realm;


/**---------------------------------------------------------------------------------------
 *  @name Customizing your Objects
 * ---------------------------------------------------------------------------------------
 */

/**
 Implement to set custom attributes for each property.
 
 @param  propertyName  Name of the property whose attributes should be retrieved.
 @return               A bitmask of property attributes for the specified property.
 */
+ (RLMPropertyAttributes)attributesForProperty:(NSString *)propertyName;

/**
 Implement to set the default values to be used for each property of the RLMObject instance.
 
 @return  NSDictionary mapping property names to their default values.
 */
+ (NSDictionary *)defaultPropertyValues;

/**
 Implement to retrieve an NSArray of property names currently being ignored.

 Ignored properties will not be persisted and are treated as transient.
 
 @return  NSArray of ignored property names.
 */
+ (NSArray *)ignoredProperties;


/**---------------------------------------------------------------------------------------
 *  @name Getting & Querying Objects from the Default Realm
 *  ---------------------------------------------------------------------------------------
 */

/**
 Retrieves all RLMObject subclass instances of the same type from the default RLMRealm.
 
 To specify the type of RLMObject to retrieve, use [RLMRealm allObjects:].

 @return  An RLMArray of all RLMObjects of the same type stored in the default RLMRealm.

 @see     [RLMRealm allObjects:]
 */
+ (RLMArray *)allObjects;

/**
 Retrieves all RLMObject instances of the same type that match the specified predicate from the default RLMRealm.

 To specify the type of RLMObject to retrieve, use [RLMRealm objects:where:].
 
 @param  predicate  An [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html), 
                    a predicate string, or predicate format string that can accept variable arguments.
 
 @return            An RLMArray of RLMObjects from the default RLMRealm that match the specified predicate and type

 @see               [RLMRealm objects:where:]
 */
+ (RLMArray *)objectsWhere:(id)predicate, ...;

/**
 Retrieves an ordered RLMArray of objects matching the specified predicate and type from the default RLMRealm.
 
 @param  predicate  An [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html), 
                    a predicate string, or predicate format string that can accept variable arguments.
 @param  order      An NSString containing a property name, or an [NSSortDescriptor](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/NSSortDescriptor_Class/Reference/Reference.html) 
	   		        containing a property name and order to sort the results by.
 
 @return            An ordered RLMArray of RLMObjects from the default Realm that match the specified predicate 
                    and subclass type.
 */
+ (RLMArray *)objectsOrderedBy:(id)order where:(id)predicate, ...;


#pragma mark -

/*---------------------------------------------------------------------------------------
 * @name Dynamic Accessors
 *---------------------------------------------------------------------------------------
 */

/*
 Retrieves the property value of the specified key from the RLMObject.

 @param  key  The key of the property to be retrieved.

 @return      The value of the specified property or `nil` if there is no value for the
              specified key.

 Properties on RLMObjects can also be accessed using keyed subscripting, i.e. 
 RLMObject[@"propertyName"] = object;
 */
-(id)objectForKeyedSubscript:(NSString *)key;

/*
 Sets a property value for the specified key in the RLMObject. 

 @param obj  The object to be stored as the property value.

 @param key  The key to use for future lookups of the property being saved.

 Properties on RLMObjects can also be set using keyed subscripting, 
 ie. RLMObject[@"propertyName"] = object;
 */
-(void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Serializing Objects to JSON
 *  ---------------------------------------------------------------------------------------
 */
/**
 Returns a JSON string representation of the RLMObject instance.
 
 @return  JSON string representation of the RLMObject.
 */
- (NSString *)JSONString;

@end

//---------------------------------------------------------------------------------------
// @name RLMArray Property Declaration
//---------------------------------------------------------------------------------------
//
// Properties on RLMObjects of type RLMArray must have an associated type. A type is associated
// with an RLMArray property by defining a protocol for the object type which the RLMArray will
// hold. To define an protocol for an object you can use the macro RLM_OBJECT_PROTOCOL:
//
// ie. RLM_ARRAY_TYPE(ObjectType)
//
//     @property RLMArray<ObjectType> *arrayOfObjectTypes;
//
#define RLM_ARRAY_TYPE(RLM_OBJECT_SUBCLASS)\
@protocol RLM_OBJECT_SUBCLASS <NSObject>   \
@end