//
//  RLMHandover.m
//  Realm
//
//  Created by Realm on 7/22/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import "RLMHandover_Private.hpp"

#import "RLMRealm_Private.hpp"
#import "RLMUtil.hpp"
#import "shared_realm.hpp"

using namespace realm;

@interface RLMHandoverImport ()

- (instancetype)initWithRealm:(RLMRealm *)realm objects:(NSArray<id<RLMHandoverable>> *)objects;

@end

@implementation RLMHandoverImport

- (instancetype)initWithRealm:(RLMRealm *)realm objects:(NSArray<id<RLMHandoverable>> *)objects {
    if (self = [super init]) {
        _realm = realm;
        _objects = objects;
    }
    return self;
}

@end

@implementation RLMHandoverPackage {
    bool _already_imported;
    NSMutableArray<id> *_metadata;
    NSMutableArray<Class> *_classes;
    std::shared_ptr<Realm::HandoverPackage> _package;
    RLMRealmConfiguration *_configuration;
}

- (instancetype)initWithRealm:(RLMRealm *)realm objects:(NSArray<id<RLMHandoverable>> *)objectsToHandOver {
    if (self = [super init]) {
        _metadata = [NSMutableArray arrayWithCapacity:objectsToHandOver.count];
        _classes = [NSMutableArray arrayWithCapacity:objectsToHandOver.count];

        std::vector<realm::AnyHandoverable> handoverables;
        handoverables.reserve(objectsToHandOver.count);
        for (id<RLMHandoverable, RLMHandoverable_Private> object in objectsToHandOver) {
            if (![object conformsToProtocol: @protocol(RLMHandoverable_Private)]) {
                @throw RLMException(@"Illegal custom conformances to `RLMHandoverable` by %@", [object class]);
            }
            if (realm != object.realm) {
                if (object.realm == nil) {
                    @throw RLMException(@"Can only hand over objects that are mangaged by a Realm");
                } else {
                    @throw RLMException(@"Can only hand over objects from the Realm they belong");
                }
            }
            handoverables.push_back(object.rlm_handoverable);
            [_metadata addObject:[object rlm_handoverMetadata]];
            [_classes addObject:[object class]];
        }
        _package = realm->_realm->package_for_handover(handoverables);
        _configuration = realm.configuration;
    }
    return self;
}

- (RLMHandoverImport *)importOnCurrentThreadWithError:(NSError **)error {
    if (_already_imported) {
        @throw RLMException(@"Illegal to import a handover package more than once");
    }
    _already_imported = true;

    RLMRealm *realm = [RLMRealm realmWithConfiguration:_configuration error:error];
    if (!realm) {
        _metadata = nil;
        _classes = nil;
        _package = nil;
        _configuration = nil;
        return nil;
    }

    std::vector<AnyHandoverable> handoverables = realm->_realm->accept_handover(*_package);

    NSMutableArray<id<RLMHandoverable>> *objects = [NSMutableArray arrayWithCapacity:handoverables.size()];
    for (NSUInteger i = 0; i < handoverables.size(); i++) {
        [objects addObject:[_classes[i] rlm_objectWithHandoverable:handoverables[i] metadata:_metadata[i] inRealm:realm]];
    }

    _metadata = nil;
    _classes = nil;
    _package = nil;
    _configuration = nil;
    return [[RLMHandoverImport alloc] initWithRealm:realm objects:[NSArray arrayWithArray:objects]];
}

@end
