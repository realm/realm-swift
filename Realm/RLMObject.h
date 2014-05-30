/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#import <Foundation/Foundation.h>

@class RLMRealm;
@class RLMArray;

/**---------------------------------------------------------------------------------------
 *  @name Initializing a subclass of RLMObject
 *  ---------------------------------------------------------------------------------------
 */
@interface RLMObject : NSObject

/**
 Initialize an standalone RLMObject
 
 Initializes an unpersisted RLMObject.
 Call [RLMRealm addObject:] to add an RLMObject to a realm.
 
 @see [RLMRealm addObject:]
 */
-(instancetype)init;

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

@end


/**---------------------------------------------------------------------------------------
 *  @name Property Attributes
 *  ---------------------------------------------------------------------------------------
 * Attributes which can be returned when implementing attributesForProperty:
 */

typedef NS_ENUM(NSUInteger, RLMPropertyAttributes) {
    /**
     Create an index for this property for improved search performance.
     */
    RLMPropertyAttributeIndexed = 1 << 2,
    
    /**
     Store this property inline (de-normalization) which in some cases can improve performance. Setting this
     attribute will result in objects being copied (rather than linked) when getting and setting this property.
     */
    RLMPropertyAttributeInlined = 1 << 3,

    /**
     The value for a property with this attribute must be unique across all objects of this type. An exception
     will be thrown when setting a property with this attribute to a non-unique value.
     */
    RLMPropertyAttributeUnique = 1 << 4,

    /**
     This property value must be set before the object can be added to a Realm. If not set an
     exception will be thrown if no default value for this property is specified. If a default
     value is specified it is set upon insertion into a Realm
     
    @see [RLMObject defaultPropertyValues]
     */
    RLMPropertyAttributeRequired = 1 << 5,
    
    
    /**---------------------------------------------------------------------------------------
     *  @name Delete Rule Attributes
     * ---------------------------------------------------------------------------------------
     * Set the following attributes on RLMPropertyTypeObject or RLMPropertyTypeArray properties
     * to customize a properties delete rules. These rules are mutually exclusive.
     */

    /**
     When a parent object is deleted or a child property is nullified nothing is done.
     This is the default delete rule.
     */
    RLMPropertyAttributeDeleteNever = 0,
    
    /**
     Delete a child object (or object in an RLMArray) when the parent is deleted or the object is
     nullified only if no other objects in the realm reference the object.
     */
    RLMPropertyAttributeDeleteIfOnlyOwner = 1 << 0,
    
    /**
     Always delete a child object or object in a child array when the parent is deleted or the
     reference in nullified. If other objects reference the same child object those references are
     nullified.
     */
    RLMPropertyAttributeDeleteAlways = 1 << 1
};


/**---------------------------------------------------------------------------------------
 *  @name Subclass Customization
 *  ---------------------------------------------------------------------------------------
 *
 * These methods can be overridden to customize the behavior of RLMObject subclasses.
 */
@interface RLMObject (SubclassOverrides)

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

@end


//---------------------------------------------------------------------------------------
// @name RLMArray Property Declaration
//---------------------------------------------------------------------------------------
//
// Properties on RLMObjects of type RLMArray must have an associated type. A type is associated
// with an RLMArray property by defining a protocol for the object type which the RLMArray will
// hold. To define an protocol for an object you can use the macro RLM_OBJECT_PROTOCOL:
//
// ie. RLM_OBJECT_PROTOCOL(ObjectType)
//     \@property RLMArray<ObjectType> *arrayOfObjectTypes;
//
#define RLM_OBJECT_PROTOCOL(RLM_OBJECT_SUBCLASS)\
@protocol RLM_OBJECT_SUBCLASS <NSObject>        \
@end


/**---------------------------------------------------------------------------------------
 *  @name Querying the Default Realm
 *  ---------------------------------------------------------------------------------------
 */
/*
 These methods allow you to easily query a custom subclass for instances of this class in the
 default Realm. To search across Realms other than the defaut or across multiple object classes
 use the interface on an RLMRealm instance.
 */

@interface RLMObject (DefaultRealm)

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

@end


/**---------------------------------------------------------------------------------------
 *  @name Dynamic Accessors
 *  ---------------------------------------------------------------------------------------
 *
 * Properties on RLMObjects can be accessed and set using keyed subscripting.
 * ie. rlmObject[@"propertyName"] = object;
 *     id object = rlmObject[@"propertyName"];
 */
@interface RLMObject (Accessors)

-(id)objectForKeyedSubscript:(NSString *)key;
-(void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

@end


/**---------------------------------------------------------------------------------------
 *  @name JSON Serialization
 *  ---------------------------------------------------------------------------------------
 */
@interface RLMObject (JSONSerialization)
/**
 Returns an RLMObject represented as a JSON string.
 
 @return  JSON string representation of the RLMObject.
 */
- (NSString *)JSONString;

@end


/**---------------------------------------------------------------------------------------
 *  @name RLMObject Class Name
 *  ---------------------------------------------------------------------------------------
 */
@interface RLMObject (ClassName)
/**
 Returns the class name for an RLMObject.
 
 @return  The class name for a given RLMObject.
 */
+ (NSString *)className;

@end




