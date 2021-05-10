////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMAccessor.hpp"

#import "RLMArray_Private.hpp"
#import "RLMListBase.h"
#import "RLMObjectId_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty_Private.h"
#import "RLMRealm_Private.hpp"
#import "RLMResults_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMUtil.hpp"

#import <realm/object-store/results.hpp>
#import <realm/object-store/property.hpp>

#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - Helper functions

namespace realm {
template<>
Obj Obj::get<Obj>(ColKey col) const {
    ObjKey key = get<ObjKey>(col);
    return key ? get_target_table(col)->get_object(key) : Obj();
}
}

namespace {
using realm::ColKey;

realm::Property const& get_property(__unsafe_unretained RLMObjectBase *const obj, NSUInteger index) {
    return obj->_info->objectSchema->persisted_properties[index];
}

realm::Property const& get_property(__unsafe_unretained RLMObjectBase *const obj,
                                    __unsafe_unretained RLMProperty *const prop) {
    if (prop.linkOriginPropertyName) {
        return obj->_info->objectSchema->computed_properties[prop.index];
    }
    return obj->_info->objectSchema->persisted_properties[prop.index];
}

template<typename T>
bool is_null(T const& v) {
    return !v;
}
template<>
bool is_null(realm::Timestamp const& v) {
    return v.is_null();
}
template<>
bool is_null(realm::ObjectId const&) {
    return false;
}
template<>
bool is_null(realm::Decimal128 const& v) {
    return v.is_null();
}

template<typename T>
T get(__unsafe_unretained RLMObjectBase *const obj, NSUInteger index) {
    RLMVerifyAttached(obj);
    return obj->_row.get<T>(get_property(obj, index).column_key);
}

template<typename T>
id getBoxed(__unsafe_unretained RLMObjectBase *const obj, NSUInteger index) {
    RLMVerifyAttached(obj);
    auto& prop = get_property(obj, index);
    RLMAccessorContext ctx(obj, &prop);
    auto value = obj->_row.get<T>(prop.column_key);
    return is_null(value) ? nil : ctx.box(std::move(value));
}

template<typename T>
void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key, T val) {
    obj->_row.set(key, val);
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained NSString *const val) {
    RLMTranslateError([&] {
        obj->_row.set(key, RLMStringDataWithNSString(val));
    });
}

[[gnu::noinline]]
void setNull(realm::Obj& row, ColKey key) {
    RLMTranslateError([&] { row.set_null(key); });
}

void setValue(__unsafe_unretained RLMObjectBase *const obj,
              ColKey key, __unsafe_unretained NSDate *const date) {
    if (date) {
        obj->_row.set(key, RLMTimestampForNSDate(date));
    }
    else {
        setNull(obj->_row, key);
    }
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained NSData *const data) {
    RLMTranslateError([&] {
        obj->_row.set(key, RLMBinaryDataForNSData(data));
    });
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained RLMObjectBase *const val) {
    if (!val) {
        obj->_row.set(key, realm::null());
        return;
    }

    if (!val->_row) {
        RLMAccessorContext{obj, key}.createObject(val, {.create = true}, false, {});
    }

    // make sure it is the correct type
    auto table = val->_row.get_table();
    if (table != obj->_row.get_table()->get_link_target(key)) {
        @throw RLMException(@"Can't set object of type '%@' to property of type '%@'",
                            val->_objectSchema.className,
                            obj->_info->propertyForTableColumn(key).objectClassName);
    }
    if (!table->is_embedded()) {
        obj->_row.set(key, val->_row.get_key());
    }
    else if (obj->_row.get_linked_object(key).get_key() != val->_row.get_key()) {
        @throw RLMException(@"Can't set link to existing managed embedded object");
    }
}

// array getter/setter
RLMArray *getArray(__unsafe_unretained RLMObjectBase *const obj, NSUInteger propIndex) {
    RLMVerifyAttached(obj);
    auto prop = obj->_info->rlmObjectSchema.properties[propIndex];
    return [[RLMManagedArray alloc] initWithParent:obj property:prop];
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained id<NSFastEnumeration> const value) {
    auto prop = obj->_info->propertyForTableColumn(key);
    RLMValidateValueForProperty(value, obj->_info->rlmObjectSchema, prop, true);

    realm::List list(obj->_realm->_realm, obj->_row, key);
    RLMClassInfo *info = obj->_info;
    if (list.get_type() == realm::PropertyType::Object) {
        info = &obj->_info->linkTargetType(prop.index);
    }
    RLMAccessorContext ctx(*info);
    RLMTranslateError([&] {
        list.assign(ctx, value, realm::CreatePolicy::ForceCreate);
    });
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained NSNumber<RLMInt> *const intObject) {
    if (intObject) {
        obj->_row.set(key, intObject.longLongValue);
    }
    else {
        setNull(obj->_row, key);
    }
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained NSNumber<RLMFloat> *const floatObject) {
    if (floatObject) {
        obj->_row.set(key, floatObject.floatValue);
    }
    else {
        setNull(obj->_row, key);
    }
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained NSNumber<RLMDouble> *const doubleObject) {
    if (doubleObject) {
        obj->_row.set(key, doubleObject.doubleValue);
    }
    else {
        setNull(obj->_row, key);
    }
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained NSNumber<RLMBool> *const boolObject) {
    if (boolObject) {
        obj->_row.set(key, (bool)boolObject.boolValue);
    }
    else {
        setNull(obj->_row, key);
    }
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained RLMDecimal128 *const value) {
    if (value) {
        obj->_row.set(key, value.decimal128Value);
    }
    else {
        setNull(obj->_row, key);
    }
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained RLMObjectId *const value) {
    if (value) {
        obj->_row.set(key, value.value);
    }
    else {
        setNull(obj->_row, key);
    }
}

RLMLinkingObjects *getLinkingObjects(__unsafe_unretained RLMObjectBase *const obj,
                                     __unsafe_unretained RLMProperty *const property) {
    RLMVerifyAttached(obj);
    auto& objectInfo = obj->_realm->_info[property.objectClassName];
    auto& linkOrigin = obj->_info->objectSchema->computed_properties[property.index].link_origin_property_name;
    auto linkingProperty = objectInfo.objectSchema->property_for_name(linkOrigin);
    auto backlinkView = obj->_row.get_backlink_view(objectInfo.table(), linkingProperty->column_key);
    realm::Results results(obj->_realm->_realm, std::move(backlinkView));
    return [RLMLinkingObjects resultsWithObjectInfo:objectInfo results:std::move(results)];
}

// any getter/setter
template<typename Type, typename StorageType=Type>
id makeGetter(NSUInteger index) {
    return ^(__unsafe_unretained RLMObjectBase *const obj) {
        return static_cast<Type>(get<StorageType>(obj, index));
    };
}

template<typename Type>
id makeBoxedGetter(NSUInteger index) {
    return ^(__unsafe_unretained RLMObjectBase *const obj) {
        return getBoxed<Type>(obj, index);
    };
}
template<typename Type>
id makeOptionalGetter(NSUInteger index) {
    return ^(__unsafe_unretained RLMObjectBase *const obj) {
        return getBoxed<realm::util::Optional<Type>>(obj, index);
    };
}
template<typename Type>
id makeNumberGetter(NSUInteger index, bool boxed, bool optional) {
    if (optional) {
        return makeOptionalGetter<Type>(index);
    }
    if (boxed) {
        return makeBoxedGetter<Type>(index);
    }
    return makeGetter<Type>(index);
}
template<typename Type>
id makeWrapperGetter(NSUInteger index, bool optional) {
    if (optional) {
        return makeOptionalGetter<Type>(index);
    }
    return makeBoxedGetter<Type>(index);
}

// dynamic getter with column closure
id managedGetter(RLMProperty *prop, const char *type) {
    NSUInteger index = prop.index;
    if (prop.array && prop.type != RLMPropertyTypeLinkingObjects) {
        return ^id(__unsafe_unretained RLMObjectBase *const obj) {
            return getArray(obj, index);
        };
    }

    bool boxed = *type == '@';
    switch (prop.type) {
        case RLMPropertyTypeInt:
            if (prop.optional || boxed) {
                return makeNumberGetter<long long>(index, boxed, prop.optional);
            }
            switch (*type) {
                case 'c': return makeGetter<char, int64_t>(index);
                case 's': return makeGetter<short, int64_t>(index);
                case 'i': return makeGetter<int, int64_t>(index);
                case 'l': return makeGetter<long, int64_t>(index);
                case 'q': return makeGetter<long long, int64_t>(index);
                default:
                    @throw RLMException(@"Unexpected property type for Objective-C type code");
            }
        case RLMPropertyTypeFloat:
            return makeNumberGetter<float>(index, boxed, prop.optional);
        case RLMPropertyTypeDouble:
            return makeNumberGetter<double>(index, boxed, prop.optional);
        case RLMPropertyTypeBool:
            return makeNumberGetter<bool>(index, boxed, prop.optional);
        case RLMPropertyTypeString:
            return makeBoxedGetter<realm::StringData>(index);
        case RLMPropertyTypeDate:
            return makeBoxedGetter<realm::Timestamp>(index);
        case RLMPropertyTypeData:
            return makeBoxedGetter<realm::BinaryData>(index);
        case RLMPropertyTypeObject:
            return makeBoxedGetter<realm::Obj>(index);
        case RLMPropertyTypeDecimal128:
            return makeBoxedGetter<realm::Decimal128>(index);
        case RLMPropertyTypeObjectId:
            return makeWrapperGetter<realm::ObjectId>(index, prop.optional);
        case RLMPropertyTypeAny:
            @throw RLMException(@"Cannot create accessor class for schema with Mixed properties");
        case RLMPropertyTypeLinkingObjects:
            return ^(__unsafe_unretained RLMObjectBase *const obj) {
                return getLinkingObjects(obj, prop);
            };
    }
}

template<typename ArgType, typename StorageType=ArgType>
id makeSetter(__unsafe_unretained RLMProperty *const prop) {
    NSUInteger index = prop.index;
    NSString *name = prop.name;
    if (prop.isPrimary) {
        return ^(__unused RLMObjectBase *obj, __unused ArgType val) {
            @throw RLMException(@"Primary key can't be changed after an object is inserted.");
        };
    }

    return ^(__unsafe_unretained RLMObjectBase *const obj, ArgType val) {
        RLMVerifyInWriteTransaction(obj);
        RLMObservationTracker tracker(obj->_realm);
        tracker.willChange(RLMGetObservationInfo(obj->_observationInfo, obj->_row.get_key(), *obj->_info), name);
        if constexpr (std::is_same_v<ArgType, RLMObjectBase *>) {
            tracker.trackDeletions();
        }
        setValue(obj, get_property(obj, index).column_key, static_cast<StorageType>(val));
    };
}

// dynamic setter with column closure
id managedSetter(RLMProperty *prop, const char *type) {
    if (prop.array && prop.type != RLMPropertyTypeLinkingObjects) {
        return makeSetter<id<NSFastEnumeration>>(prop);
    }

    bool boxed = prop.optional || *type == '@';
    switch (prop.type) {
        case RLMPropertyTypeInt:
            if (boxed) {
                return makeSetter<NSNumber<RLMInt> *>(prop);
            }
            switch (*type) {
                case 'c': return makeSetter<char, long long>(prop);
                case 's': return makeSetter<short, long long>(prop);
                case 'i': return makeSetter<int, long long>(prop);
                case 'l': return makeSetter<long, long long>(prop);
                case 'q': return makeSetter<long long>(prop);
                default:
                    @throw RLMException(@"Unexpected property type for Objective-C type code");
            }
        case RLMPropertyTypeFloat:
            return boxed ? makeSetter<NSNumber<RLMFloat> *>(prop) : makeSetter<float>(prop);
        case RLMPropertyTypeDouble:
            return boxed ? makeSetter<NSNumber<RLMDouble> *>(prop) : makeSetter<double>(prop);
        case RLMPropertyTypeBool:
            return boxed ? makeSetter<NSNumber<RLMBool> *>(prop) : makeSetter<BOOL, bool>(prop);
        case RLMPropertyTypeString:         return makeSetter<NSString *>(prop);
        case RLMPropertyTypeDate:           return makeSetter<NSDate *>(prop);
        case RLMPropertyTypeData:           return makeSetter<NSData *>(prop);
        case RLMPropertyTypeAny:            return nil;
        case RLMPropertyTypeLinkingObjects: return nil;
        case RLMPropertyTypeObject:         return makeSetter<RLMObjectBase *>(prop);
        case RLMPropertyTypeObjectId:       return makeSetter<RLMObjectId *>(prop);
        case RLMPropertyTypeDecimal128:     return makeSetter<RLMDecimal128 *>(prop);
    }
}

// call getter for superclass for property at key
id superGet(RLMObjectBase *obj, NSString *propName) {
    typedef id (*getter_type)(RLMObjectBase *, SEL);
    RLMProperty *prop = obj->_objectSchema[propName];
    Class superClass = class_getSuperclass(obj.class);
    getter_type superGetter = (getter_type)[superClass instanceMethodForSelector:prop.getterSel];
    return superGetter(obj, prop.getterSel);
}

// call setter for superclass for property at key
void superSet(RLMObjectBase *obj, NSString *propName, id val) {
    typedef void (*setter_type)(RLMObjectBase *, SEL, RLMArray *ar);
    RLMProperty *prop = obj->_objectSchema[propName];
    Class superClass = class_getSuperclass(obj.class);
    setter_type superSetter = (setter_type)[superClass instanceMethodForSelector:prop.setterSel];
    superSetter(obj, prop.setterSel, val);
}

// getter/setter for unmanaged object
id unmanagedGetter(RLMProperty *prop, const char *) {
    // only override getters for RLMArray and linking objects properties
    if (prop.type == RLMPropertyTypeLinkingObjects) {
        return ^(RLMObjectBase *) { return [RLMResults emptyDetachedResults]; };
    }
    if (prop.array) {
        NSString *propName = prop.name;
        if (prop.type == RLMPropertyTypeObject) {
            NSString *objectClassName = prop.objectClassName;
            return ^(RLMObjectBase *obj) {
                id val = superGet(obj, propName);
                if (!val) {
                    val = [[RLMArray alloc] initWithObjectClassName:objectClassName];
                    superSet(obj, propName, val);
                }
                return val;
            };
        }
        auto type = prop.type;
        auto optional = prop.optional;
        return ^(RLMObjectBase *obj) {
            id val = superGet(obj, propName);
            if (!val) {
                val = [[RLMArray alloc] initWithObjectType:type optional:optional];
                superSet(obj, propName, val);
            }
            return val;
        };
    }
    return nil;
}

id unmanagedSetter(RLMProperty *prop, const char *) {
    // Only RLMArray needs special handling for the unmanaged setter
    if (!prop.array) {
        return nil;
    }

    NSString *propName = prop.name;
    return ^(RLMObjectBase *obj, id<NSFastEnumeration> values) {
        auto prop = obj->_objectSchema[propName];
        RLMValidateValueForProperty(values, obj->_objectSchema, prop, true);

        // make copy when setting (as is the case for all other variants)
        RLMArray *ar;
        if (prop.type == RLMPropertyTypeObject)
            ar = [[RLMArray alloc] initWithObjectClassName:prop.objectClassName];
        else
            ar = [[RLMArray alloc] initWithObjectType:prop.type optional:prop.optional];
        [ar addObjects:values];
        superSet(obj, propName, ar);
    };
}

void addMethod(Class cls, __unsafe_unretained RLMProperty *const prop,
               id (*getter)(RLMProperty *, const char *),
               id (*setter)(RLMProperty *, const char *)) {
    SEL sel = prop.getterSel;
    auto getterMethod = class_getInstanceMethod(cls, sel);
    if (!getterMethod) {
        return;
    }

    const char *getterType = method_getTypeEncoding(getterMethod);
    if (id block = getter(prop, getterType)) {
        class_addMethod(cls, sel, imp_implementationWithBlock(block), getterType);
    }

    if (!(sel = prop.setterSel)) {
        return;
    }
    auto setterMethod = class_getInstanceMethod(cls, sel);
    if (!setterMethod) {
        return;
    }
    if (id block = setter(prop, getterType)) { // note: deliberately getterType as it's easier to grab the relevant type from
        class_addMethod(cls, sel, imp_implementationWithBlock(block), method_getTypeEncoding(setterMethod));
    }
}

Class createAccessorClass(Class objectClass,
                          RLMObjectSchema *schema,
                          const char *accessorClassName,
                          id (*getterGetter)(RLMProperty *, const char *),
                          id (*setterGetter)(RLMProperty *, const char *)) {
    REALM_ASSERT_DEBUG(RLMIsObjectOrSubclass(objectClass));

    // create and register proxy class which derives from object class
    Class accClass = objc_allocateClassPair(objectClass, accessorClassName, 0);
    if (!accClass) {
        // Class with that name already exists, so just return the pre-existing one
        // This should only happen for our standalone "accessors"
        return objc_lookUpClass(accessorClassName);
    }

    // override getters/setters for each propery
    for (RLMProperty *prop in schema.properties) {
        addMethod(accClass, prop, getterGetter, setterGetter);
    }
    for (RLMProperty *prop in schema.computedProperties) {
        addMethod(accClass, prop, getterGetter, setterGetter);
    }

    objc_registerClassPair(accClass);

    return accClass;
}
} // anonymous namespace

#pragma mark - Public Interface

Class RLMManagedAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema, const char *name) {
    return createAccessorClass(objectClass, schema, name, managedGetter, managedSetter);
}

Class RLMUnmanagedAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema) {
    return createAccessorClass(objectClass, schema,
                               [@"RLM:Unmanaged " stringByAppendingString:schema.className].UTF8String,
                               unmanagedGetter, unmanagedSetter);
}

// implement the class method className on accessors to return the className of the
// base object
void RLMReplaceClassNameMethod(Class accessorClass, NSString *className) {
    Class metaClass = object_getClass(accessorClass);
    IMP imp = imp_implementationWithBlock(^(Class){ return className; });
    class_addMethod(metaClass, @selector(className), imp, "@@:");
}

// implement the shared schema method
void RLMReplaceSharedSchemaMethod(Class accessorClass, RLMObjectSchema *schema) {
    Class metaClass = object_getClass(accessorClass);
    IMP imp = imp_implementationWithBlock(^(Class cls) {
        if (cls == accessorClass) {
            return schema;
        }

        // If we aren't being called directly on the class this was overriden
        // for, the class is either a subclass which we haven't initialized yet,
        // or it's a runtime-generated class which should use the parent's
        // schema. We check for the latter by checking if the immediate
        // descendent of the desired class is a class generated by us (there
        // may be further subclasses not generated by us for things like KVO).
        Class parent = class_getSuperclass(cls);
        while (parent != accessorClass) {
            cls = parent;
            parent = class_getSuperclass(cls);
        }

        static const char accessorClassPrefix[] = "RLM:";
        if (!strncmp(class_getName(cls), accessorClassPrefix, sizeof(accessorClassPrefix) - 1)) {
            return schema;
        }

        return [RLMSchema sharedSchemaForClass:cls];
    });
    class_addMethod(metaClass, @selector(sharedSchema), imp, "@@:");
}

void RLMDynamicValidatedSet(RLMObjectBase *obj, NSString *propName, id val) {
    RLMVerifyAttached(obj);
    RLMObjectSchema *schema = obj->_objectSchema;
    RLMProperty *prop = schema[propName];
    if (!prop) {
        @throw RLMException(@"Invalid property name '%@' for class '%@'.",
                            propName, obj->_objectSchema.className);
    }
    if (prop.isPrimary) {
        @throw RLMException(@"Primary key can't be changed to '%@' after an object is inserted.", val);
    }

    // Because embedded objects cannot be created directly, we accept anything
    // that can be converted to an embedded object for dynamic link set operations.
    bool is_embedded = prop.type == RLMPropertyTypeObject && obj->_info->linkTargetType(prop.index).objectSchema->is_embedded;
    RLMValidateValueForProperty(val, schema, prop, !is_embedded);
    RLMDynamicSet(obj, prop, RLMCoerceToNil(val));
}

// Precondition: the property is not a primary key
void RLMDynamicSet(__unsafe_unretained RLMObjectBase *const obj,
                   __unsafe_unretained RLMProperty *const prop,
                   __unsafe_unretained id const val) {
    REALM_ASSERT_DEBUG(!prop.isPrimary);
    realm::Object o(obj->_info->realm->_realm, *obj->_info->objectSchema, obj->_row);
    RLMAccessorContext c(obj);
    RLMTranslateError([&] {
        o.set_property_value(c, get_property(obj, prop).name, val ?: NSNull.null);
    });
}

id RLMDynamicGet(__unsafe_unretained RLMObjectBase *const obj, __unsafe_unretained RLMProperty *const prop) {
    realm::Object o(obj->_realm->_realm, *obj->_info->objectSchema, obj->_row);
    RLMAccessorContext c(obj);
    c.currentProperty = prop;
    return RLMTranslateError([&] {
        return RLMCoerceToNil(o.get_property_value<id>(c, get_property(obj, prop)));
    });
}

id RLMDynamicGetByName(__unsafe_unretained RLMObjectBase *const obj,
                       __unsafe_unretained NSString *const propName) {
    RLMProperty *prop = obj->_objectSchema[propName];
    if (!prop) {
        @throw RLMException(@"Invalid property name '%@' for class '%@'.",
                            propName, obj->_objectSchema.className);
    }
    return RLMDynamicGet(obj, prop);
}

RLMAccessorContext::~RLMAccessorContext() = default;

RLMAccessorContext::RLMAccessorContext(RLMAccessorContext& parent, realm::Obj const& obj,
                                       realm::Property const& property)
: _realm(parent._realm)
, _info(property.type == realm::PropertyType::Object ? parent._info.linkTargetType(property) : parent._info)
, _parentObject(obj)
, _parentObjectInfo(&parent._info)
, _colKey(property.column_key)
{
}

RLMAccessorContext::RLMAccessorContext(RLMClassInfo& info)
: _realm(info.realm), _info(info)
{
}

RLMAccessorContext::RLMAccessorContext(__unsafe_unretained RLMObjectBase *const parent,
                                       const realm::Property *prop)
: _realm(parent->_realm)
, _info(prop && prop->type == realm::PropertyType::Object ? parent->_info->linkTargetType(*prop)
                                                          : *parent->_info)
, _parentObjectInfo(parent->_info)
{
}

RLMAccessorContext::RLMAccessorContext(__unsafe_unretained RLMObjectBase *const parent,
                                       realm::ColKey col)
: _realm(parent->_realm)
, _info(_realm->_info[parent->_info->propertyForTableColumn(col).objectClassName])
, _parentObject(parent->_row)
, _parentObjectInfo(parent->_info)
, _colKey(col)
{
}

id RLMAccessorContext::defaultValue(__unsafe_unretained NSString *const key) {
    if (!_defaultValues) {
        _defaultValues = RLMDefaultValuesForObjectSchema(_info.rlmObjectSchema);
    }
    return _defaultValues[key];
}

id RLMAccessorContext::propertyValue(__unsafe_unretained id const obj, size_t propIndex,
                                     __unsafe_unretained RLMProperty *const prop) {
    // Property value from an NSArray
    if ([obj respondsToSelector:@selector(objectAtIndex:)]) {
        return propIndex < [obj count] ? [obj objectAtIndex:propIndex] : nil;
    }

    // Property value from an NSDictionary
    if ([obj respondsToSelector:@selector(objectForKey:)]) {
        return [obj objectForKey:prop.name];
    }

    // Property value from an instance of this object type
    id value;
    if ([obj isKindOfClass:_info.rlmObjectSchema.objectClass] && prop.swiftIvar) {
        if (prop.array) {
            return static_cast<RLMListBase *>(object_getIvar(obj, prop.swiftIvar))._rlmArray;
        }
        else { // optional
            value = RLMGetOptional(static_cast<RLMOptionalBase *>(object_getIvar(obj, prop.swiftIvar)));
        }
    }
    else {
    // Property value from some object that's KVC-compatible
        value = RLMValidatedValueForProperty(obj, [obj respondsToSelector:prop.getterSel] ? prop.getterName : prop.name,
                                             _info.rlmObjectSchema.className);
    }
    return value ?: NSNull.null;
}

realm::Obj RLMAccessorContext::create_embedded_object() {
    if (!_parentObject) {
        @throw RLMException(@"Embedded objects cannot be created directly");
    }
    return _parentObject.create_and_set_linked_object(_colKey);
}

id RLMAccessorContext::box(realm::List&& l) {
    REALM_ASSERT(_parentObjectInfo);
    REALM_ASSERT(currentProperty);
    return [[RLMManagedArray alloc] initWithList:std::move(l)
                                      parentInfo:_parentObjectInfo
                                        property:currentProperty];
}

id RLMAccessorContext::box(realm::Object&& o) {
    REALM_ASSERT(currentProperty);
    return RLMCreateObjectAccessor(_info.linkTargetType(currentProperty.index), o.obj());
}

id RLMAccessorContext::box(realm::Obj&& r) {
    return RLMCreateObjectAccessor(_info, std::move(r));
}

id RLMAccessorContext::box(realm::Results&& r) {
    REALM_ASSERT(currentProperty);
    return [RLMResults resultsWithObjectInfo:_realm->_info[currentProperty.objectClassName]
                                     results:std::move(r)];
}

using realm::ObjKey;
using realm::CreatePolicy;

template<>
realm::Timestamp RLMAccessorContext::unbox(__unsafe_unretained id const value, CreatePolicy, ObjKey) {
    id v = RLMCoerceToNil(value);
    return RLMTimestampForNSDate(v);
}

template<>
bool RLMAccessorContext::unbox(__unsafe_unretained id const v, CreatePolicy, ObjKey) {
    return [v boolValue];
}
template<>
double RLMAccessorContext::unbox(__unsafe_unretained id const v, CreatePolicy, ObjKey) {
    return [v doubleValue];
}
template<>
float RLMAccessorContext::unbox(__unsafe_unretained id const v, CreatePolicy, ObjKey) {
    return [v floatValue];
}
template<>
long long RLMAccessorContext::unbox(__unsafe_unretained id const v, CreatePolicy, ObjKey) {
    return [v longLongValue];
}
template<>
realm::BinaryData RLMAccessorContext::unbox(id v, CreatePolicy, ObjKey) {
    v = RLMCoerceToNil(v);
    return RLMBinaryDataForNSData(v);
}
template<>
realm::StringData RLMAccessorContext::unbox(id v, CreatePolicy, ObjKey) {
    v = RLMCoerceToNil(v);
    return RLMStringDataWithNSString(v);
}
template<>
realm::Decimal128 RLMAccessorContext::unbox(id v, CreatePolicy, ObjKey) {
    return RLMObjcToDecimal128(v);
}
template<>
realm::ObjectId RLMAccessorContext::unbox(id v, CreatePolicy, ObjKey) {
    return static_cast<RLMObjectId *>(v).value;
}
template<>
realm::UUID RLMAccessorContext::unbox(id, CreatePolicy, ObjKey) {
    REALM_UNREACHABLE();
}
template<>
realm::Mixed RLMAccessorContext::unbox(id, CreatePolicy, ObjKey) {
    REALM_UNREACHABLE();
}
template<>
realm::object_store::Set RLMAccessorContext::unbox(id, CreatePolicy, ObjKey) {
    REALM_UNREACHABLE();
}
template<>
realm::object_store::Dictionary RLMAccessorContext::unbox(id, CreatePolicy, ObjKey) {
    REALM_UNREACHABLE();
}

template<typename Fn>
static auto to_optional(__unsafe_unretained id const value, Fn&& fn) {
    id v = RLMCoerceToNil(value);
    return v && v != NSNull.null ? realm::util::make_optional(fn(v)) : realm::util::none;
}

template<>
realm::util::Optional<bool> RLMAccessorContext::unbox(__unsafe_unretained id const v, CreatePolicy, ObjKey) {
    return to_optional(v, [&](__unsafe_unretained id v) { return (bool)[v boolValue]; });
}
template<>
realm::util::Optional<double> RLMAccessorContext::unbox(__unsafe_unretained id const v, CreatePolicy, ObjKey) {
    return to_optional(v, [&](__unsafe_unretained id v) { return [v doubleValue]; });
}
template<>
realm::util::Optional<float> RLMAccessorContext::unbox(__unsafe_unretained id const v, CreatePolicy, ObjKey) {
    return to_optional(v, [&](__unsafe_unretained id v) { return [v floatValue]; });
}
template<>
realm::util::Optional<int64_t> RLMAccessorContext::unbox(__unsafe_unretained id const v, CreatePolicy, ObjKey) {
    return to_optional(v, [&](__unsafe_unretained id v) { return [v longLongValue]; });
}
template<>
realm::util::Optional<realm::ObjectId> RLMAccessorContext::unbox(__unsafe_unretained id const v, CreatePolicy, ObjKey) {
    return to_optional(v, [&](__unsafe_unretained RLMObjectId *v) { return v.value; });
}
template<>
realm::util::Optional<realm::UUID> RLMAccessorContext::unbox(__unsafe_unretained id const, CreatePolicy, ObjKey) {
    REALM_UNREACHABLE();
}

std::pair<realm::Obj, bool>
RLMAccessorContext::createObject(id value, realm::CreatePolicy policy,
                                 bool forceCreate, ObjKey existingKey) {
    if (!value || value == NSNull.null) {
        @throw RLMException(@"Must provide a non-nil value.");
    }

    if ([value isKindOfClass:[NSArray class]] && [value count] > _info.objectSchema->persisted_properties.size()) {
        @throw RLMException(@"Invalid array input: more values (%llu) than properties (%llu).",
                            (unsigned long long)[value count],
                            (unsigned long long)_info.objectSchema->persisted_properties.size());
    }

    RLMObjectBase *objBase = RLMDynamicCast<RLMObjectBase>(value);
    realm::Obj obj, *outObj = nullptr;
    if (objBase) {
        if (objBase.isInvalidated) {
            if (policy.create && !policy.copy) {
                @throw RLMException(@"Adding a deleted or invalidated object to a Realm is not permitted");
            }
            else {
                @throw RLMException(@"Object has been deleted or invalidated.");
            }
        }
        if (policy.copy) {
            if (policy.update || !forceCreate) {
                // create(update: true) is a no-op when given an object already in
                // the Realm which is of the correct type
                if (objBase->_realm == _realm && objBase->_row.get_table() == _info.table() && !_info.table()->is_embedded()) {
                    return {objBase->_row, true};
                }
            }
            // Otherwise we copy the object
            objBase = nil;
        }
        else {
            outObj = &objBase->_row;
            // add() on an object already managed by this Realm is a no-op
            if (objBase->_realm == _realm) {
                return {objBase->_row, true};
            }
            if (!policy.create) {
                return {realm::Obj(), false};
            }
            if (objBase->_realm) {
                @throw RLMException(@"Object is already managed by another Realm. Use create instead to copy it into this Realm.");
            }
            if (objBase->_observationInfo && objBase->_observationInfo->hasObservers()) {
                @throw RLMException(@"Cannot add an object with observers to a Realm");
            }

            REALM_ASSERT([objBase->_objectSchema.className isEqualToString:_info.rlmObjectSchema.className]);
            REALM_ASSERT([objBase isKindOfClass:_info.rlmObjectSchema.unmanagedClass]);

            objBase->_info = &_info;
            objBase->_realm = _realm;
            objBase->_objectSchema = _info.rlmObjectSchema;
        }
    }
    if (!policy.create) {
        return {realm::Obj(), false};
    }
    if (!outObj) {
        outObj = &obj;
    }

    try {
        realm::Object::create(*this, _realm->_realm, *_info.objectSchema,
                              (id)value, policy, existingKey, outObj).obj();
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }

    if (objBase) {
        for (RLMProperty *prop in _info.rlmObjectSchema.properties) {
            // set the ivars for object and array properties to nil as otherwise the
            // accessors retain objects that are no longer accessible via the properties
            // this is mainly an issue when the object graph being added has cycles,
            // as it's not obvious that the user has to set the *ivars* to nil to
            // avoid leaking memory
            if (prop.type == RLMPropertyTypeObject && !prop.swiftIvar) {
                ((void(*)(id, SEL, id))objc_msgSend)(objBase, prop.setterSel, nil);
            }
        }

        object_setClass(objBase, _info.rlmObjectSchema.accessorClass);
        RLMInitializeSwiftAccessorGenerics(objBase);
    }
    return {*outObj, false};
}

template<>
realm::Obj RLMAccessorContext::unbox(__unsafe_unretained id const v, CreatePolicy policy, ObjKey key) {
    return createObject(v, policy, false, key).first;
}

void RLMAccessorContext::will_change(realm::Obj const& row, realm::Property const& prop) {
    auto obsInfo = RLMGetObservationInfo(nullptr, row.get_key(), _info);
    if (!_observationHelper) {
        if (obsInfo || prop.type == realm::PropertyType::Object) {
            _observationHelper = std::make_unique<RLMObservationTracker>(_info.realm);
        }
    }
    if (_observationHelper) {
        _observationHelper->willChange(obsInfo, _info.propertyForTableColumn(prop.column_key).name);
        if (prop.type == realm::PropertyType::Object) {
            _observationHelper->trackDeletions();
        }
    }
}

void RLMAccessorContext::did_change() {
    if (_observationHelper) {
        _observationHelper->didChange();
    }
}

RLMOptionalId RLMAccessorContext::value_for_property(__unsafe_unretained id const obj,
                                                     realm::Property const&, size_t propIndex) {
    auto prop = _info.rlmObjectSchema.properties[propIndex];
    id value = propertyValue(obj, propIndex, prop);
    if (value) {
        RLMValidateValueForProperty(value, _info.rlmObjectSchema, prop);
    }

    return RLMOptionalId{value};
}

RLMOptionalId RLMAccessorContext::default_value_for_property(realm::ObjectSchema const&,
                                                             realm::Property const& prop)
{
    return RLMOptionalId{defaultValue(@(prop.name.c_str()))};
}

bool RLMAccessorContext::is_same_list(realm::List const& list, __unsafe_unretained id const v) const noexcept {
    return [v respondsToSelector:@selector(isBackedByList:)] && [v isBackedByList:list];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation RLMManagedPropertyAccessor
@end
#pragma clang diagnostic pop
