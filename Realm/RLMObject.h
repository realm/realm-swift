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
 
 Supported property types are:
 
 - `NSString`
 - `NSInteger`, `CGFloat`, `int`, `long`, `float`, and `double`
 - `BOOL` or `bool`
 - `NSDate`
 - `NSData`
 - Other objects subclassing `RLMObject`, so you can link RLMObjects together.
 
 You can set which of these properties should be indexed, stored inline, unique, required
 as well as delete rules for the links by implementing the attributesForProperty: method.
 
 You can set properties to ignore (i.e. transient properties you do not want
 persisted to a Realm) by implementing ignoredProperties.
 
 You can set default values for properties by implementing defaultPropertyValues.
 
 You can query an object directly via the class methods: allObjects, objectsWhere:, objectsOrderedBy:where: and objectForKeyedSubscript:
 These methods allow you to easily query a custom subclass for instances of this class in the
 default Realm. To search in a Realms other than the defaut Realm
 use the interface on an RLMRealm instance.
 
 */


@interface RLMObject : NSObject

/**---------------------------------------------------------------------------------------
 *  @name Creating & Initializing Objects
 * ---------------------------------------------------------------------------------------
 */

/**
 Initialize an standalone RLMObject
 
 Initializes an unpersisted RLMObject.
 Call [RLMRealm addObject:] to add an RLMObject to a realm.
 
 @see [RLMRealm addObject:]
 */
-(instancetype)init;

/**
 Helper to return the class name for an RLMObject subclass.
 
 @return    The class name for the model class.
 */
+ (NSString *)className;

/**
 Creates an RLMObject instance from a given object and adds it to a specified RLMRealm, 
 where it will be persisted.
 
 @param realm   The RLMRealm instance to add the object to.
 @param object  The object used to populate the RLMObject instance. This can be any key/value compliant
                object, a JSON object such as those returned from the methods in [NSJSONSerialization](https://developer.apple.com/library/ios/documentation/foundation/reference/nsjsonserialization_class/Reference/Reference.html), 
                or an [NSArray](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSArray_Class/NSArray.html)
                that contains one object for each persisted property. 
 
 @exception RLMException  Thrown if all required properties are not present or no default is provided.
                		  When passing in an NSArray, all properties must be present and valid.
 
 @see   defaultPropertyValues
 */
+(instancetype)createInRealm:(RLMRealm *)realm withObject:(id)object;

/**
 Creates an RLMObject instance from a JSONString and adds it to a specified RLMRealm,
 where it will be persisted.
  
 @param realm       The RLMRealm instance to add the JSONString to.
 @param JSONString  An NSString with valid JSON. 

 @exception RLMException  An exception will be thrown if required properties are
 						  not present in the JSON for which defaults are not provided.
 
 @see   defaultPropertyValues
 */
+(instancetype)createInRealm:(RLMRealm *)realm withJSONString:(NSString *)JSONString;

/**
 The RLMRealm instance in which this object is persisted. Returns nil for standalone objects.
 */
@property (nonatomic, readonly) RLMRealm *realm;


/**---------------------------------------------------------------------------------------
 *  @name Customizing your Objects
 * ---------------------------------------------------------------------------------------
 */

/**
 Implement to set custom attributes for each property.
 
 @param propertyName    Name of property for which attributes have been requested.
 @return                Bitmask of property attributes for the given property.
 */
+ (RLMPropertyAttributes)attributesForProperty:(NSString *)propertyName;

/**
 Implement to indicate the default values to be used for each property.
 
 @return    NSDictionary mapping property names to their default values.
 */
+ (NSDictionary *)defaultPropertyValues;

/**
 Implement to return an NSArray of property names to ignore. These properties will not be persisted
 and are treated as transient.
 
 @return    NSArray of property names to igonre.
 */
+ (NSArray *)ignoredProperties;


/**---------------------------------------------------------------------------------------
 *  @name Getting & Querying Objects from the Default Realm
 *  ---------------------------------------------------------------------------------------
 */

/**
 Retrieves all objects of the specified type from the default RLMRealm.
 
 @return    An RLMArray of all objects of the specified type that are stored the default RLMRealm.
 */
+ (RLMArray *)allObjects;

/**
 Retrieves all objects that match the specified predicate and type from the default RLMRealm.
 
 @param predicate   The argument can be an [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html), 
 a predicte string, or predicate format string
 which can accept variable arguments.
 
 @return    An RLMArray of RLMObjects from the default RLMRealm that match the specified predicate and subclass type
 */
+ (RLMArray *)objectsWhere:(id)predicate, ...;

/**
 Retrieves an ordered RLMArray of objects matching the specified predicate and type from the default RLMRealm.
 
 @param predicate  The argument can be an NSPredicate, a predicte string, or predicate format string
 which can accept variable arguments.
 @param order  An NSString containing a property name, or an 
 			   NSSortDescriptor](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/NSSortDescriptor_Class/Reference/Reference.html) 
	   		   containing a property name and order to sort the results by.
 
 @return  An RLMArray of RLMObjects from the default Realm that match the specified predicate and subclass type
 ordered by the specified order.
 */
+ (RLMArray *)objectsOrderedBy:(id)order where:(id)predicate, ...;


#pragma mark -

//---------------------------------------------------------------------------------------
// @name Dynamic Accessors
//---------------------------------------------------------------------------------------
//
// Properties on RLMObjects can be accessed and set using keyed subscripting.
// ie. rlmObject[@"propertyName"] = object;
//     id object = rlmObject[@"propertyName"];
//

-(id)objectForKeyedSubscript:(NSString *)key;
-(void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

#pragma mark -

/**---------------------------------------------------------------------------------------
 *  @name Serializing Objects to JSON
 *  ---------------------------------------------------------------------------------------
 */
/**
 Returns an RLMObject represented as a JSON string.
 
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