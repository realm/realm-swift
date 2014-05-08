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
#import "RLMProxy.h"
#import "RLMObjectDescriptor.h"
#import "RLMPrivate.h"
#import <objc/runtime.h>

static NSMutableDictionary *s_proxyClassNameCache;

// determine if class is a or a descendent of class2
BOOL is_class_subclass(Class class1, Class class2) {
    while (class1) {
        if (class1 == class2) return YES;
        class1 = class_getSuperclass(class1);
    }
    return NO;
}


@implementation RLMProxy

+ (void)initialize {
    if (self == RLMProxy.class) {
        s_proxyClassNameCache = [NSMutableDictionary dictionary];
    }
}

+(Class)proxyClassForObjectClass:(Class)objectClass {
    // if objectClass is RLMRow use it, otherwise use proxy class
    if (is_class_subclass(objectClass, RLMRow.class)) {
        // if we haven't done so, generate getters and setters
        NSString *objectClassName = NSStringFromClass(objectClass);
        if (!s_proxyClassNameCache[objectClassName]) {
            RLMObjectDescriptor *descriptor = [RLMObjectDescriptor descriptorForObjectClass:objectClass];
            for (unsigned int propNum = 0; propNum < descriptor.properties.count; propNum++) {
                RLMProperty *prop = descriptor.properties[propNum];
                [prop addToClass:objectClass column:propNum];
            }
            s_proxyClassNameCache[objectClassName] = objectClassName;
        }
        return objectClass;
    }
    
    @throw [NSException exceptionWithName:@"RLMException" reason:@"objectClass must derive from RLMRow" userInfo:nil];
}

// Disabled code to generate new proxy class
//    // see if we have a cached version
//    NSString *objectClassName = NSStringFromClass(objectClass);
//    if (s_proxyClassNameCache[objectClassName]) {
//        return NSClassFromString(s_proxyClassNameCache[objectClassName]);
//    }
//    
//    // create and register proxy class
//    NSString *proxyClassName = [@"RLMProxy_" stringByAppendingString:objectClassName];
//    Class proxyClass = objc_allocateClassPair(RLMProxy.class, proxyClassName.UTF8String, 0);
//    objc_registerClassPair(proxyClass);
//    
//    // add getters/setters for each propery
//    RLMObjectDescriptor *descriptor = [RLMObjectDescriptor descriptorForObjectClass:objectClass];
//    NSSet *selectorNames = selectorNamesForClass(objectClass);
//    for (unsigned int propNum = 0; propNum < descriptor.properties.count; propNum++) {
//        RLMProperty *prop = descriptor.properties[propNum];
//        [prop addToClass:proxyClass existing:selectorNames column:propNum];
//    }
//    
//    // set in cache to indiate this proxy class has been created and return
//    s_proxyClassNameCache[objectClassName] = proxyClassName;
//    return proxyClass;
//
//- (id)object {
//    // create object on demand
//    if (!_object) {
//        NSString *className = NSStringFromClass(self.class);
//        className = [className substringFromIndex:9];
//        Class objectClass = NSClassFromString(className);
//        
//        // create object
//        _object = [[objectClass alloc] init];
//        RLMObjectDescriptor *descriptor = [RLMObjectDescriptor descriptorForObjectClass:objectClass];
//        for (RLMProperty *prop in descriptor.properties) {
//            [_object setValue:self[prop.name] forKeyPath:prop.name];
//        }
//    }
//    return _object;
//}
//// return our objects method signature
//    -(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
//    return [self.object methodSignatureForSelector:aSelector];
//}
//// invocate on object
//    - (void)forwardInvocation:(NSInvocation *)anInvocation {
//    [anInvocation invokeWithTarget:self.object];
//}

@end

