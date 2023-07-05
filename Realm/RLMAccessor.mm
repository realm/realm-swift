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
#import "RLMDictionary_Private.hpp"
#import "RLMObjectId_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty_Private.h"
#import "RLMRealm_Private.hpp"
#import "RLMResults_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMSet_Private.hpp"
#import "RLMSwiftProperty.h"
#import "RLMUUID_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/results.hpp>
#import <realm/object-store/property.hpp>

#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark Helper functions

using realm::ColKey;

namespace realm {
template<>
Obj Obj::get<Obj>(ColKey col) const {
    ObjKey key = get<ObjKey>(col);
    return key ? get_target_table(col)->get_object(key) : Obj();
}

} // namespace realm

namespace {
realm::Property const& getProperty(__unsafe_unretained RLMObjectBase *const obj, NSUInteger index) {
    return obj->_info->objectSchema->persisted_properties[index];
}

realm::Property const& getProperty(__unsafe_unretained RLMObjectBase *const obj,
                                   __unsafe_unretained RLMProperty *const prop) {
    if (prop.linkOriginPropertyName) {
        return obj->_info->objectSchema->computed_properties[prop.index];
    }
    return obj->_info->objectSchema->persisted_properties[prop.index];
}

template<typename T>
bool isNull(T const& v) {
    return !v;
}
template<>
bool isNull(realm::Timestamp const& v) {
    return v.is_null();
}
template<>
bool isNull(realm::ObjectId const&) {
    return false;
}
template<>
bool isNull(realm::Decimal128 const& v) {
    return v.is_null();
}
template<>
bool isNull(realm::Mixed const& v) {
    return v.is_null();
}
template<>
bool isNull(realm::UUID const&) {
    return false;
}

template<typename T>
T get(__unsafe_unretained RLMObjectBase *const obj, NSUInteger index) {
    RLMVerifyAttached(obj);
    return obj->_row.get<T>(getProperty(obj, index).column_key);
}

template<typename T>
id getBoxed(__unsafe_unretained RLMObjectBase *const obj, NSUInteger index) {
    RLMVerifyAttached(obj);
    auto& prop = getProperty(obj, index);
    RLMAccessorContext ctx(obj, &prop);
    auto value = obj->_row.get<T>(prop.column_key);
    return isNull(value) ? nil : ctx.box(std::move(value));
}

template<typename T>
T getOptional(__unsafe_unretained RLMObjectBase *const obj, uint16_t key, bool *gotValue) {
    auto ret = get<std::optional<T>>(obj, key);
    if (ret) {
        *gotValue = true;
    }
    return ret.value_or(T{});
}

template<typename T>
void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key, T val) {
    obj->_row.set(key, val);
}

template<typename T>
void setValueOrNull(__unsafe_unretained RLMObjectBase *const obj, ColKey col,
                    __unsafe_unretained id const value) {
    RLMVerifyInWriteTransaction(obj);

    RLMTranslateError([&] {
        if (value) {
            if constexpr (std::is_same_v<T, realm::Mixed>) {
                obj->_row.set(col, RLMObjcToMixed(value, obj->_realm, realm::CreatePolicy::SetLink));
            }
            else {
                RLMStatelessAccessorContext ctx;
                obj->_row.set(col, ctx.unbox<T>(value));
            }
        }
        else {
            obj->_row.set_null(col);
        }
    });
}

void setValue(__unsafe_unretained RLMObjectBase *const obj,
              ColKey key, __unsafe_unretained NSDate *const date) {
    setValueOrNull<realm::Timestamp>(obj, key, date);
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained NSData *const value) {
    setValueOrNull<realm::BinaryData>(obj, key, value);
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained NSString *const value) {
    setValueOrNull<realm::StringData>(obj, key, value);
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

id RLMCollectionClassForProperty(RLMProperty *prop, bool isManaged) {
    Class cls = nil;
    if (prop.array) {
        cls = isManaged ? [RLMManagedArray class] : [RLMArray class];
    } else if (prop.set) {
        cls = isManaged ? [RLMManagedSet class] : [RLMSet class];
    } else if (prop.dictionary) {
        cls = isManaged ? [RLMManagedDictionary class] : [RLMDictionary class];
    } else {
        @throw RLMException(@"Invalid collection '%@' for class '%@'.",
                            prop.name, prop.objectClassName);
    }
    return cls;
}

// collection getter/setter
id<RLMCollection> getCollection(__unsafe_unretained RLMObjectBase *const obj, NSUInteger propIndex) {
    RLMVerifyAttached(obj);
    auto prop = obj->_info->rlmObjectSchema.properties[propIndex];
    Class cls = RLMCollectionClassForProperty(prop, true);
    return [[cls alloc] initWithParent:obj property:prop];
}

template <typename Collection>
void assignValue(__unsafe_unretained RLMObjectBase *const obj,
                 __unsafe_unretained RLMProperty *const prop,
                 ColKey key,
                 __unsafe_unretained id<NSFastEnumeration> const value) {
    auto info = obj->_info;
    Collection collection(obj->_realm->_realm, obj->_row, key);
    if (collection.get_type() == realm::PropertyType::Object) {
        info = &obj->_info->linkTargetType(prop.index);
    }
    RLMAccessorContext ctx(*info);
    RLMTranslateError([&] {
        collection.assign(ctx, value, realm::CreatePolicy::ForceCreate);
    });
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained id<NSFastEnumeration> const value) {
    auto prop = obj->_info->propertyForTableColumn(key);
    RLMValidateValueForProperty(value, obj->_info->rlmObjectSchema, prop, true);

    if (prop.array) {
        assignValue<realm::List>(obj, prop, key, value);
    }
    else if (prop.set) {
        assignValue<realm::object_store::Set>(obj, prop, key, value);
    }
    else if (prop.dictionary) {
        assignValue<realm::object_store::Dictionary>(obj, prop, key, value);
    }
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained NSNumber<RLMInt> *const intObject) {
    setValueOrNull<int64_t>(obj, key, intObject);
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained NSNumber<RLMFloat> *const floatObject) {
    setValueOrNull<float>(obj, key, floatObject);
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained NSNumber<RLMDouble> *const doubleObject) {
    setValueOrNull<double>(obj, key, doubleObject);
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained NSNumber<RLMBool> *const boolObject) {
    setValueOrNull<bool>(obj, key, boolObject);
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained RLMDecimal128 *const value) {
    setValueOrNull<realm::Decimal128>(obj, key, value);
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained RLMObjectId *const value) {
    setValueOrNull<realm::ObjectId>(obj, key, value);
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained NSUUID *const value) {
    setValueOrNull<realm::UUID>(obj, key, value);
}

void setValue(__unsafe_unretained RLMObjectBase *const obj, ColKey key,
              __unsafe_unretained id<RLMValue> const value) {
    setValueOrNull<realm::Mixed>(obj, key, value);
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
        return getBoxed<std::optional<Type>>(obj, index);
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
    if (prop.collection && prop.type != RLMPropertyTypeLinkingObjects) {
        return ^id(__unsafe_unretained RLMObjectBase *const obj) {
            return getCollection(obj, index);
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
            // Mixed is represented as optional in Core,
            // but not in Cocoa. We use `makeBoxedGetter` over
            // `makeWrapperGetter` becuase Mixed can box a `null` representation.
            return makeBoxedGetter<realm::Mixed>(index);
        case RLMPropertyTypeLinkingObjects:
            return ^(__unsafe_unretained RLMObjectBase *const obj) {
                return getLinkingObjects(obj, prop);
            };
        case RLMPropertyTypeUUID:
            return makeWrapperGetter<realm::UUID>(index, prop.optional);
    }
}

static realm::ColKey willChange(RLMObservationTracker& tracker,
                                __unsafe_unretained RLMObjectBase *const obj, NSUInteger index) {
    auto& prop = getProperty(obj, index);
    if (prop.is_primary) {
        @throw RLMException(@"Primary key can't be changed after an object is inserted.");
    }
    tracker.willChange(RLMGetObservationInfo(obj->_observationInfo, obj->_row.get_key(), *obj->_info),
                       obj->_objectSchema.properties[index].name);
    return prop.column_key;
}

template<typename ArgType, typename StorageType=ArgType>
void kvoSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger index, ArgType value) {
    RLMVerifyInWriteTransaction(obj);
    RLMObservationTracker tracker(obj->_realm);
    auto key = willChange(tracker, obj, index);
    if constexpr (std::is_same_v<ArgType, RLMObjectBase *>) {
        tracker.trackDeletions();
    }
    setValue(obj, key, static_cast<StorageType>(value));
}

template<typename ArgType, typename StorageType=ArgType>
id makeSetter(__unsafe_unretained RLMProperty *const prop) {
    if (prop.isPrimary) {
        return ^(__unused RLMObjectBase *obj, __unused ArgType val) {
            @throw RLMException(@"Primary key can't be changed after an object is inserted.");
        };
    }

    NSUInteger index = prop.index;
    return ^(__unsafe_unretained RLMObjectBase *const obj, ArgType val) {
        kvoSetValue<ArgType, StorageType>(obj, index, val);
    };
}

// dynamic setter with column closure
id managedSetter(RLMProperty *prop, const char *type) {
    if (prop.collection && prop.type != RLMPropertyTypeLinkingObjects) {
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
        case RLMPropertyTypeAny:            return makeSetter<id<RLMValue>>(prop);
        case RLMPropertyTypeLinkingObjects: return nil;
        case RLMPropertyTypeObject:         return makeSetter<RLMObjectBase *>(prop);
        case RLMPropertyTypeObjectId:       return makeSetter<RLMObjectId *>(prop);
        case RLMPropertyTypeDecimal128:     return makeSetter<RLMDecimal128 *>(prop);
        case RLMPropertyTypeUUID:           return makeSetter<NSUUID *>(prop);
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
    typedef void (*setter_type)(RLMObjectBase *, SEL, id<RLMCollection> collection);
    RLMProperty *prop = obj->_objectSchema[propName];
    Class superClass = class_getSuperclass(obj.class);
    setter_type superSetter = (setter_type)[superClass instanceMethodForSelector:prop.setterSel];
    superSetter(obj, prop.setterSel, val);
}

// getter/setter for unmanaged object
id unmanagedGetter(RLMProperty *prop, const char *) {
    // only override getters for RLMCollection and linking objects properties
    if (prop.type == RLMPropertyTypeLinkingObjects) {
        return ^(RLMObjectBase *) { return [RLMResults emptyDetachedResults]; };
    }
    if (prop.collection) {
        NSString *propName = prop.name;
        Class cls = RLMCollectionClassForProperty(prop, false);
        if (prop.type == RLMPropertyTypeObject) {
            NSString *objectClassName = prop.objectClassName;
            RLMPropertyType keyType = prop.dictionaryKeyType;
            return ^(RLMObjectBase *obj) {
                id val = superGet(obj, propName);
                if (!val) {
                    val = [[cls alloc] initWithObjectClassName:objectClassName keyType:keyType];
                    superSet(obj, propName, val);
                }
                return val;
            };
        }
        auto type = prop.type;
        auto optional = prop.optional;
        auto dictionaryKeyType = prop.dictionaryKeyType;
        return ^(RLMObjectBase *obj) {
            id val = superGet(obj, propName);
            if (!val) {
                val = [[cls alloc] initWithObjectType:type optional:optional keyType:dictionaryKeyType];
                superSet(obj, propName, val);
            }
            return val;
        };
    }
    return nil;
}

id unmanagedSetter(RLMProperty *prop, const char *) {
    // Only RLMCollection types need special handling for the unmanaged setter
    if (!prop.collection) {
        return nil;
    }

    NSString *propName = prop.name;
    return ^(RLMObjectBase *obj, id<NSFastEnumeration> values) {
        auto prop = obj->_objectSchema[propName];
        RLMValidateValueForProperty(values, obj->_objectSchema, prop, true);

        Class cls = RLMCollectionClassForProperty(prop, false);
        id collection;
            // make copy when setting (as is the case for all other variants)
        if (prop.type == RLMPropertyTypeObject) {
            collection = [[cls alloc] initWithObjectClassName:prop.objectClassName keyType:prop.dictionaryKeyType];
        }
        else {
            collection = [[cls alloc] initWithObjectType:prop.type optional:prop.optional keyType:prop.dictionaryKeyType];
        }

        if (prop.dictionary)
            [collection addEntriesFromDictionary:(id)values];
        else
            [collection addObjects:values];
        superSet(obj, propName, collection);
    };
}

void addMethod(Class cls, __unsafe_unretained RLMProperty *const prop,
               id (*getter)(RLMProperty *, const char *),
               id (*setter)(RLMProperty *, const char *)) {
    SEL sel = prop.getterSel;
    if (!sel) {
        return;
    }
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

bool requiresUnmanagedAccessor(RLMObjectSchema *schema) {
    for (RLMProperty *prop in schema.properties) {
        if (prop.collection && !prop.swiftIvar) {
            return true;
        }
    }
    for (RLMProperty *prop in schema.computedProperties) {
        if (prop.collection && !prop.swiftIvar) {
            return true;
        }
    }
    return false;
}
} // anonymous namespace

#pragma mark - Public Interface

Class RLMManagedAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema, const char *name) {
    return createAccessorClass(objectClass, schema, name, managedGetter, managedSetter);
}

Class RLMUnmanagedAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema) {
    if (!requiresUnmanagedAccessor(schema)) {
        return objectClass;
    }
    return createAccessorClass(objectClass, schema,
                               [@"RLM:Unmanaged " stringByAppendingString:schema.className].UTF8String,
                               unmanagedGetter, unmanagedSetter);
}

// implement the class method className on accessors to return the className of the
// base object
void RLMReplaceClassNameMethod(Class accessorClass, NSString *className) {
    Class metaClass = object_getClass(accessorClass);
    IMP imp = imp_implementationWithBlock(^(Class) { return className; });
    class_addMethod(metaClass, @selector(className), imp, "@@:");
}

// implement the shared schema method
void RLMReplaceSharedSchemaMethod(Class accessorClass, RLMObjectSchema *schema) {
    REALM_ASSERT(accessorClass != [RealmSwiftObject class]);
    Class metaClass = object_getClass(accessorClass);
    IMP imp = imp_implementationWithBlock(^(Class cls) {
        if (cls == accessorClass) {
            return schema;
        }

        // If we aren't being called directly on the class this was overridden
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
    bool is_embedded = prop.type == RLMPropertyTypeObject && obj->_info->linkTargetType(prop.index).rlmObjectSchema.isEmbedded;
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
        o.set_property_value(c, getProperty(obj, prop).name, val ?: NSNull.null);
    });
}

id RLMDynamicGet(__unsafe_unretained RLMObjectBase *const obj, __unsafe_unretained RLMProperty *const prop) {
    if (auto accessor = prop.swiftAccessor; accessor && [obj isKindOfClass:obj->_objectSchema.objectClass]) {
        return RLMCoerceToNil([accessor get:prop on:obj]);
    }
    if (!obj->_realm) {
        return [obj valueForKey:prop.name];
    }

    realm::Object o(obj->_realm->_realm, *obj->_info->objectSchema, obj->_row);
    RLMAccessorContext c(obj);
    c.currentProperty = prop;
    return RLMTranslateError([&] {
        return RLMCoerceToNil(o.get_property_value<id>(c, getProperty(obj, prop)));
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

#pragma mark - Swift property getters and setter

#define REALM_SWIFT_PROPERTY_ACCESSOR(objc, swift, rlmtype) \
    objc RLMGetSwiftProperty##swift(__unsafe_unretained RLMObjectBase *const obj, uint16_t key) { \
        return get<objc>(obj, key); \
    } \
    objc RLMGetSwiftProperty##swift##Optional(__unsafe_unretained RLMObjectBase *const obj, uint16_t key, bool *gotValue) { \
        return getOptional<objc>(obj, key, gotValue); \
    } \
    void RLMSetSwiftProperty##swift(__unsafe_unretained RLMObjectBase *const obj, uint16_t key, objc value) { \
        RLMVerifyAttached(obj); \
        kvoSetValue(obj, key, value); \
    }
REALM_FOR_EACH_SWIFT_PRIMITIVE_TYPE(REALM_SWIFT_PROPERTY_ACCESSOR)
#undef REALM_SWIFT_PROPERTY_ACCESSOR

#define REALM_SWIFT_PROPERTY_ACCESSOR(objc, swift, rlmtype) \
    void RLMSetSwiftProperty##swift(__unsafe_unretained RLMObjectBase *const obj, uint16_t key, objc *value) { \
        RLMVerifyAttached(obj); \
        kvoSetValue(obj, key, value); \
    }
REALM_FOR_EACH_SWIFT_OBJECT_TYPE(REALM_SWIFT_PROPERTY_ACCESSOR)
#undef REALM_SWIFT_PROPERTY_ACCESSOR

NSString *RLMGetSwiftPropertyString(__unsafe_unretained RLMObjectBase *const obj, uint16_t key) {
    return getBoxed<realm::StringData>(obj, key);
}

NSData *RLMGetSwiftPropertyData(__unsafe_unretained RLMObjectBase *const obj, uint16_t key) {
    return getBoxed<realm::BinaryData>(obj, key);
}

NSDate *RLMGetSwiftPropertyDate(__unsafe_unretained RLMObjectBase *const obj, uint16_t key) {
    return getBoxed<realm::Timestamp>(obj, key);
}

NSUUID *RLMGetSwiftPropertyUUID(__unsafe_unretained RLMObjectBase *const obj, uint16_t key) {
    return getBoxed<std::optional<realm::UUID>>(obj, key);
}

RLMObjectId *RLMGetSwiftPropertyObjectId(__unsafe_unretained RLMObjectBase *const obj, uint16_t key) {
    return getBoxed<std::optional<realm::ObjectId>>(obj, key);
}

RLMDecimal128 *RLMGetSwiftPropertyDecimal128(__unsafe_unretained RLMObjectBase *const obj, uint16_t key) {
    return getBoxed<realm::Decimal128>(obj, key);
}

RLMArray *RLMGetSwiftPropertyArray(__unsafe_unretained RLMObjectBase *const obj, uint16_t key) {
    return getCollection(obj, key);
}
RLMSet *RLMGetSwiftPropertySet(__unsafe_unretained RLMObjectBase *const obj, uint16_t key) {
    return getCollection(obj, key);
}
RLMDictionary *RLMGetSwiftPropertyMap(__unsafe_unretained RLMObjectBase *const obj, uint16_t key) {
    return getCollection(obj, key);
}

void RLMSetSwiftPropertyNil(__unsafe_unretained RLMObjectBase *const obj, uint16_t key) {
    RLMVerifyInWriteTransaction(obj);
    if (getProperty(obj, key).type == realm::PropertyType::Object) {
        kvoSetValue(obj, key, (RLMObjectBase *)nil);
    }
    else {
        // The type used here is arbitrary; it simply needs to be any non-object type
        kvoSetValue(obj, key, (NSNumber<RLMInt> *)nil);
    }
}

void RLMSetSwiftPropertyObject(__unsafe_unretained RLMObjectBase *const obj, uint16_t key,
                               __unsafe_unretained RLMObjectBase *const target) {
    kvoSetValue(obj, key, target);
}

RLMObjectBase *RLMGetSwiftPropertyObject(__unsafe_unretained RLMObjectBase *const obj, uint16_t key) {
    return getBoxed<realm::Obj>(obj, key);
}

void RLMSetSwiftPropertyAny(__unsafe_unretained RLMObjectBase *const obj, uint16_t key,
                            __unsafe_unretained id<RLMValue> const value) {
    kvoSetValue(obj, key, value);
}

id<RLMValue> RLMGetSwiftPropertyAny(__unsafe_unretained RLMObjectBase *const obj, uint16_t key) {
    return getBoxed<realm::Mixed>(obj, key);
}

#pragma mark - RLMAccessorContext

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
, _parentObject(parent->_row)
, _parentObjectInfo(parent->_info)
, _colKey(prop ? prop->column_key : ColKey{})
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

id RLMAccessorContext::propertyValue(id obj, size_t propIndex,
                                     __unsafe_unretained RLMProperty *const prop) {
    obj = RLMBridgeSwiftValue(obj) ?: obj;

    // Property value from an NSArray
    if ([obj respondsToSelector:@selector(objectAtIndex:)]) {
        return propIndex < [obj count] ? [obj objectAtIndex:propIndex] : nil;
    }

    // Property value from an NSDictionary
    if ([obj respondsToSelector:@selector(objectForKey:)]) {
        return [obj objectForKey:prop.name];
    }

    // Property value from an instance of this object type
    if ([obj isKindOfClass:_info.rlmObjectSchema.objectClass] && prop.swiftAccessor) {
        return [prop.swiftAccessor get:prop on:obj];
    }

    // Property value from some object that's KVC-compatible
    id value = RLMValidatedValueForProperty(obj, [obj respondsToSelector:prop.getterSel] ? prop.getterName : prop.name,
                                            _info.rlmObjectSchema.className);
    return value ?: NSNull.null;
}

realm::Obj RLMAccessorContext::create_embedded_object() {
    if (!_parentObject) {
        @throw RLMException(@"Embedded objects cannot be created directly");
    }
    return _parentObject.create_and_set_linked_object(_colKey);
}

id RLMAccessorContext::box(realm::Mixed v) {
    return RLMMixedToObjc(v, _realm, &_info);
}

id RLMAccessorContext::box(realm::List&& l) {
    REALM_ASSERT(_parentObjectInfo);
    REALM_ASSERT(currentProperty);
    return [[RLMManagedArray alloc] initWithBackingCollection:std::move(l)
                                                   parentInfo:_parentObjectInfo
                                                     property:currentProperty];
}

id RLMAccessorContext::box(realm::object_store::Set&& s) {
    REALM_ASSERT(_parentObjectInfo);
    REALM_ASSERT(currentProperty);
    return [[RLMManagedSet alloc] initWithBackingCollection:std::move(s)
                                                 parentInfo:_parentObjectInfo
                                                   property:currentProperty];
}

id RLMAccessorContext::box(realm::object_store::Dictionary&& d) {
    REALM_ASSERT(_parentObjectInfo);
    REALM_ASSERT(currentProperty);
    return [[RLMManagedDictionary alloc] initWithBackingCollection:std::move(d)
                                                        parentInfo:_parentObjectInfo
                                                          property:currentProperty];
}

id RLMAccessorContext::box(realm::Object&& o) {
    REALM_ASSERT(currentProperty);
    return RLMCreateObjectAccessor(_info.linkTargetType(currentProperty.index), o.get_obj());
}

id RLMAccessorContext::box(realm::Obj&& r) {
    if (!currentProperty) {
        // If currentProperty is set, then we're reading from a Collection and
        // that reported an audit read for us. If not, we need to report the
        // audit read. This happens automatically when creating a
        // `realm::Object`, but our object accessors don't wrap that type.
        realm::Object(_realm->_realm, *_info.objectSchema, r, _parentObject, _colKey);
    }
    return RLMCreateObjectAccessor(_info, std::move(r));
}

id RLMAccessorContext::box(realm::Results&& r) {
    REALM_ASSERT(currentProperty);
    return [RLMResults resultsWithObjectInfo:_realm->_info[currentProperty.objectClassName]
                                     results:std::move(r)];
}

using realm::ObjKey;
using realm::CreatePolicy;

template<typename T>
static T *bridged(__unsafe_unretained id const value) {
    return [value isKindOfClass:[T class]] ? value : RLMBridgeSwiftValue(value);
}

template<>
realm::Timestamp RLMStatelessAccessorContext::unbox(__unsafe_unretained id const value) {
    id v = RLMCoerceToNil(value);
    return RLMTimestampForNSDate(bridged<NSDate>(v));
}

template<>
bool RLMStatelessAccessorContext::unbox(__unsafe_unretained id const v) {
    return [bridged<NSNumber>(v) boolValue];
}
template<>
double RLMStatelessAccessorContext::unbox(__unsafe_unretained id const v) {
    return [bridged<NSNumber>(v) doubleValue];
}
template<>
float RLMStatelessAccessorContext::unbox(__unsafe_unretained id const v) {
    return [bridged<NSNumber>(v) floatValue];
}
template<>
long long RLMStatelessAccessorContext::unbox(__unsafe_unretained id const v) {
    return [bridged<NSNumber>(v) longLongValue];
}
template<>
realm::BinaryData RLMStatelessAccessorContext::unbox(id v) {
    v = RLMCoerceToNil(v);
    return RLMBinaryDataForNSData(bridged<NSData>(v));
}
template<>
realm::StringData RLMStatelessAccessorContext::unbox(id v) {
    v = RLMCoerceToNil(v);
    return RLMStringDataWithNSString(bridged<NSString>(v));
}
template<>
realm::Decimal128 RLMStatelessAccessorContext::unbox(id v) {
    return RLMObjcToDecimal128(v);
}
template<>
realm::ObjectId RLMStatelessAccessorContext::unbox(id v) {
    return bridged<RLMObjectId>(v).value;
}
template<>
realm::UUID RLMStatelessAccessorContext::unbox(id v) {
    return RLMObjcToUUID(bridged<NSUUID>(v));
}
template<>
realm::Mixed RLMAccessorContext::unbox(__unsafe_unretained id v, CreatePolicy p, ObjKey) {
    return RLMObjcToMixed(v, _realm, p);
}

template<typename T>
static auto toOptional(__unsafe_unretained id const value) {
    id v = RLMCoerceToNil(value);
    return v ? realm::util::make_optional(RLMStatelessAccessorContext::unbox<T>(v))
             : realm::util::none;
}

template<>
std::optional<bool> RLMStatelessAccessorContext::unbox(__unsafe_unretained id const v) {
    return toOptional<bool>(v);
}
template<>
std::optional<double> RLMStatelessAccessorContext::unbox(__unsafe_unretained id const v) {
    return toOptional<double>(v);
}
template<>
std::optional<float> RLMStatelessAccessorContext::unbox(__unsafe_unretained id const v) {
    return toOptional<float>(v);
}
template<>
std::optional<int64_t> RLMStatelessAccessorContext::unbox(__unsafe_unretained id const v) {
    return toOptional<int64_t>(v);
}
template<>
std::optional<realm::ObjectId> RLMStatelessAccessorContext::unbox(__unsafe_unretained id const v) {
    return toOptional<realm::ObjectId>(v);
}
template<>
std::optional<realm::UUID> RLMStatelessAccessorContext::unbox(__unsafe_unretained id const v) {
    return toOptional<realm::UUID>(v);
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
    bool requiresSwiftUIObservers = false;
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
                requiresSwiftUIObservers = [RLMSwiftUIKVO removeObserversFromObject:objBase];
                if (!requiresSwiftUIObservers) {
                    @throw RLMException(@"Cannot add an object with observers to a Realm");
                }
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
                              (id)value, policy, existingKey, outObj);
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
        RLMInitializeSwiftAccessor(objBase, true);
    }

    if (requiresSwiftUIObservers) {
        [RLMSwiftUIKVO addObserversToObject:objBase];
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

bool RLMStatelessAccessorContext::is_same_list(realm::List const& list,
                                               __unsafe_unretained id const v) noexcept {
    return [v respondsToSelector:@selector(isBackedByList:)] && [v isBackedByList:list];
}

bool RLMStatelessAccessorContext::is_same_set(realm::object_store::Set const& set,
                                              __unsafe_unretained id const v) noexcept {
    return [v respondsToSelector:@selector(isBackedBySet:)] && [v isBackedBySet:set];
}

bool RLMStatelessAccessorContext::is_same_dictionary(realm::object_store::Dictionary const& dict,
                                                     __unsafe_unretained id const v) noexcept {
    return [v respondsToSelector:@selector(isBackedByDictionary:)] && [v isBackedByDictionary:dict];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation RLMManagedPropertyAccessor
// Most types don't need to distinguish between promote and init so provide a default
+ (void)promote:(RLMProperty *)property on:(RLMObjectBase *)parent {
    [self initialize:property on:parent];
}
@end
#pragma clang diagnostic pop
