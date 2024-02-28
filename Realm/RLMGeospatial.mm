////////////////////////////////////////////////////////////////////////////
//
// Copyright 2023 Realm Inc.
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

#import "RLMGeospatial_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/geospatial.hpp>

@implementation RLMGeospatialPoint
- (nullable instancetype)initWithLatitude:(double)latitude longitude:(double)longitude {
    return [self initWithLatitude:latitude longitude:longitude altitude:0];
}

- (nullable instancetype)initWithLatitude:(double)latitude longitude:(double)longitude altitude:(double)altitude {
    if (self = [super init]) {
        if ((isnan(latitude) || isnan(longitude) || isnan(altitude)) || (latitude < -90 || latitude > 90) || (longitude < -180 || longitude > 180) || (altitude < 0)) {
            return nil;
        }
        _latitude = latitude;
        _longitude = longitude;
        _altitude = altitude;
    }
    return self;
}

- (realm::GeoPoint)value {
    return realm::GeoPoint{_longitude, _latitude, _altitude};
}

- (BOOL)isEqual:(id)other {
    if (auto point = RLMDynamicCast<RLMGeospatialPoint>(other)) {
        return point.latitude == self.latitude && point.longitude == self.longitude && point.altitude == self.altitude;
    }
    return NO;
}
@end

@interface RLMGeospatialBox () <RLMGeospatial_Private>
@end

@implementation RLMGeospatialBox
- (instancetype)initWithBottomLeft:(RLMGeospatialPoint *)bottomLeft topRight:(RLMGeospatialPoint *)topRight {
    if (self = [super init]) {
        _bottomLeft = bottomLeft;
        _topRight = topRight;
    }
    return self;
}

- (realm::Geospatial)geoSpatial {
    realm::GeoBox geo_box{realm::GeoPoint{_bottomLeft.longitude, _bottomLeft.latitude}, realm::GeoPoint{_topRight.longitude, _topRight.latitude}};
    return realm::Geospatial{geo_box};
}

- (BOOL)isEqual:(id)other {
    if (auto box = RLMDynamicCast<RLMGeospatialBox>(other)) {
        if ([box.bottomLeft isEqual:self.bottomLeft] && [box.topRight isEqual: self.topRight])
            return YES;
    }
    return NO;
}
@end

@interface RLMGeospatialPolygon () <RLMGeospatial_Private>
@end

@implementation RLMGeospatialPolygon
- (nullable instancetype)initWithOuterRing:(NSArray<RLMGeospatialPoint *> *)outerRing holes:(nullable NSArray<NSArray<RLMGeospatialPoint *> *> *)holes {
    if (self = [super init]) {
        if (([outerRing count] <= 3) || (![[outerRing firstObject] isEqual:[outerRing lastObject]])) {
            return nil;
        }
        if (holes) {
            for(NSArray<RLMGeospatialPoint *> *hole in holes) {
                if (([hole count] <= 3) || (![[hole firstObject] isEqual:[hole lastObject]])) {
                    return nil;
                }
            }
        }
        _outerRing = outerRing;
        _holes = holes;
    }
    return self;
}

- (nullable instancetype)initWithOuterRing:(NSArray<RLMGeospatialPoint *> *)outerRing {
    return [self initWithOuterRing:outerRing holes:nil];
}

- (realm::Geospatial)geoSpatial {
    std::vector<std::vector<realm::GeoPoint>> points;
    std::vector<realm::GeoPoint> outer_ring;
    for (RLMGeospatialPoint *point : _outerRing) {
        outer_ring.push_back(point.value);
    }
    points.push_back(outer_ring);

    if (_holes) {
        for (NSArray<RLMGeospatialPoint *> *array_points : _holes) {
            std::vector<realm::GeoPoint> hole;
            for (RLMGeospatialPoint *point : array_points) {
                hole.push_back(point.value);
            }
            points.push_back(hole);
        }
    }

    realm::GeoPolygon geo_polygon{points};
    return realm::Geospatial{geo_polygon};
}

- (BOOL)isEqual:(id)other {
    if (auto polygon = RLMDynamicCast<RLMGeospatialPolygon>(other)) {
        if ([polygon.outerRing isEqualToArray:self.outerRing] && [polygon.holes isEqualToArray:self.holes])
            return YES;
    }
    return NO;
}
@end

/// Earth radius.
static double const c_earthRadiusMeters = 6378100.0;

@implementation RLMDistance
+ (nullable instancetype)distanceFromKilometers:(double)kilometers {
    double radians = (kilometers * 1000) / c_earthRadiusMeters;
    return [[RLMDistance alloc] initWithRadians:radians];
}

+ (nullable instancetype)distanceFromMiles:(double)miles {
    double radians = (miles * 1609.344) / c_earthRadiusMeters;
    return [[RLMDistance alloc] initWithRadians:radians];
}

+ (nullable instancetype)distanceFromDegrees:(double)degrees {
    double radiansPerDegree = M_PI / 180;
    return [[RLMDistance alloc] initWithRadians:(degrees * radiansPerDegree)];
}

+ (nullable instancetype)distanceFromRadians:(double)radians {
    return [[RLMDistance alloc] initWithRadians:radians];
}

- (double)asKilometers {
    return (self.radians * c_earthRadiusMeters) / 1000;
}

- (double)asMiles {
    return (self.radians * c_earthRadiusMeters) / 1609.344;
}

- (double)asDegrees {
    double radiansPerDegree = M_PI / 180;
    return (self.radians / radiansPerDegree);
}

- (nullable instancetype)initWithRadians:(double)radians {
    if (self = [super init]) {
        if (isnan(radians) || radians < 0) {
            return nil;
        }
        _radians = radians;
    }
    return self;
}

- (BOOL)isEqual:(id)other {
    if (auto distance = RLMDynamicCast<RLMDistance>(other)) {
        if (distance.radians == self.radians)
            return YES;
    }
    return NO;
}
@end

@interface RLMGeospatialCircle () <RLMGeospatial_Private>
@end

@implementation RLMGeospatialCircle
- (nullable instancetype)initWithCenter:(RLMGeospatialPoint *)center radiusInRadians:(double)radians {
    if (self = [super init]) {
        if (isnan(radians) || radians < 0) {
            return nil;
        }

        _center = center;
        _radians = radians;
    }
    return self;
}

- (instancetype)initWithCenter:(RLMGeospatialPoint *)center radius:(RLMDistance *)radius {
    return [self initWithCenter:center radiusInRadians:radius.radians];
}

- (realm::Geospatial)geoSpatial {
    realm::GeoCircle geo_circle{_radians, _center.value};
    return realm::Geospatial{geo_circle};
}

- (BOOL)isEqual:(id)other {
    if (auto circle = RLMDynamicCast<RLMGeospatialCircle>(other)) {
        if (circle.radians == self.radians && [circle.center isEqual:self.center])
            return YES;
    }
    return NO;
}
@end
