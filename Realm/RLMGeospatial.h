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

#import <Realm/RLMConstants.h>

RLM_HEADER_AUDIT_BEGIN(nullability)
/// Conforming protocol for a Geo-shape.
@protocol RLMGeospatial
@end

/**
 A class that represents the coordinates of a point formed by a latitude and a longitude value.

  * Latitude ranges between -90 and 90 degrees, inclusive.
  * Longitude ranges between -180 and 180 degrees, inclusive.
  * Altitude cannot have negative values.

 Values outside this ranges will return nil when trying to create a `RLMGeospatialPoint`.

 @note There is no dedicated type to store Geospatial points, instead points should be stored as
 [GeoJson-shaped](https://www.mongodb.com/docs/manual/reference/geojson/) 
 embedded object, as explained below. Geospatial queries (`geoWithin`) can only be executed
 in such a type of objects and will throw otherwise.

 Persisting geo points in Realm is currently done using duck-typing, which means that any model class with a specific **shape**
 can be queried as though it contained a geographical location. The recommended approach is using an embedded object.

 @warning This structure cannot be persisted and can only be used to build other geospatial shapes
 such as (`RLMGeospatialBox`, `RLMGeospatialPolygon` and `RLMGeospatialCircle`).

 @warning Altitude is not used in any of the query calculations.
 */
RLM_SWIFT_SENDABLE
@interface RLMGeospatialPoint : NSObject
/// Latitude in degrees.
@property (readonly) double latitude;
/// Longitude in degrees.
@property (readonly) double longitude;
/// Altitude distance.
@property (readonly) double altitude;

/**
Initialize a `RLMGeospatialPoint`, with the specific values for latitude and longitude.

Returns `nil` if the values of latitude and longitude are not within the ranges specified.

@param latitude Latitude in degrees. Ranges between -90 and 90 degrees, inclusive.
@param longitude Longitude in degrees. Ranges between -180 and 180 degrees, inclusive.
 */
- (nullable instancetype)initWithLatitude:(double)latitude longitude:(double)longitude;

/**
Initialize a `RLMGeospatialPoint`, with the specific values for latitude and longitude.

Returns `nil` if the values of latitude and longitude are not within the ranges specified.

@param latitude Latitude in degrees. Ranges between -90 and 90 degrees, inclusive.
@param longitude Longitude in degrees. Ranges between -180 and 180 degrees, inclusive.
@param altitude Altitude. Distance cannot have negative values

 @warning Altitude is not used in any of the query calculations.
 */
- (nullable instancetype)initWithLatitude:(double)latitude longitude:(double)longitude altitude:(double)altitude;
@end

/**
 A class that represents a rectangle, that can be used in a geospatial `geoWithin`query.

 - warning: This class cannot be persisted and can only be use within a geospatial `geoWithin` query.
 */
RLM_SWIFT_SENDABLE
@interface RLMGeospatialBox : NSObject <RLMGeospatial>
/// The bottom left corner of the rectangle.
@property (readonly, strong) RLMGeospatialPoint *bottomLeft;
/// The top right corner of the rectangle.
@property (readonly, strong) RLMGeospatialPoint *topRight;

/**
 Initialize a `RLMGeospatialBox`, with values for bottom left corner and top right corner.

@param bottomLeft The bottom left corner of the rectangle.
@param topRight The top right corner of the rectangle.
 */
- (instancetype)initWithBottomLeft:(RLMGeospatialPoint *)bottomLeft topRight:(RLMGeospatialPoint *)topRight;
@end

/**
 A class that represents a polygon, that can be used in a geospatial `geoWithin`query.

 A `RLMGeospatialPolygon` describes a shape conformed of and outer `Polygon`, called `outerRing`,
 and 0 or more inner `Polygon`s, called `holes`, which represents an unlimited number of internal holes
 inside the outer `Polygon`.
 A `Polygon` describes a shape conformed by at least three segments, where the last and the first `RLMGeospatialPoint`
 must be the same to indicate a closed polygon (meaning you need at least 4 points to define a polygon).
 Inner holes in a `RLMGeospatialPolygon` must  be entirely inside the outer ring

 A `hole` has the following restrictions:
 - Holes may not cross, i.e. the boundary of a hole 
 may not intersect both the interior and the exterior of any other
   hole.
 - Holes may not share edges, i.e. if a hole contains and edge AB, the no other hole may contain it.
 - Holes may share vertices, however no vertex may appear twice in a single hole.
 - No hole may be empty.
 - Only one nesting is allowed.

 @warning This class cannot be persisted and can only be use within a geospatial `geoWithin` query.
 */
RLM_SWIFT_SENDABLE
@interface RLMGeospatialPolygon : NSObject <RLMGeospatial>
/// The polygon's external (outer) ring.
@property (readonly, strong) NSArray<RLMGeospatialPoint *> *outerRing;
/// The holes (if any) in the polygon.
@property (readonly, strong, nullable) NSArray<NSArray<RLMGeospatialPoint *> *> *holes;

/**
Initialize a `RLMGeospatialPolygon`, with its outer rings and holes (if any).

Returns `nil` if the `RLMGeospatialPoints` representing a polygon (outer ring or holes), don't have at least 4 points.
Returns `nil` if the first and the last `RLMGeospatialPoint` in a polygon are not the same.

@param outerRing The polygon's external (outer) ring.
 */
- (nullable instancetype)initWithOuterRing:(NSArray<RLMGeospatialPoint *> *)outerRing;

/**
Initialize a `RLMGeospatialPolygon`, with its outer rings and holes (if any).

Returns `nil` if the `RLMGeospatialPoints` representing a polygon (outer ring or holes), don't have at least 4 points.
Returns `nil` if the first and the last `RLMGeospatialPoint` in a polygon are not the same.

@param outerRing The polygon's external (outer) ring.
@param holes The holes (if any) in the polygon.
 */
- (nullable instancetype)initWithOuterRing:(NSArray<RLMGeospatialPoint *> *)outerRing holes:(nullable NSArray<NSArray<RLMGeospatialPoint *> *> *)holes;
@end

/**
 This structure is a helper to represent/convert a distance. It can be used in geospatial
 queries like those represented by a `RLMGeospatialCircle`

 - warning: This structure cannot be persisted and can only be used to build other geospatial shapes
 */
RLM_SWIFT_SENDABLE
@interface RLMDistance : NSObject
/// The distance in radians.
@property (readonly) double radians;

/**
Constructs a `Distance`.

Returns `nil` if the value is lower than 0, because we cannot construct negative distances.
@param kilometers Distance in kilometers.
@returns A value that represents the provided distance in radians.
 */
+ (nullable instancetype)distanceFromKilometers:(double)kilometers NS_SWIFT_NAME(kilometers(_:));

/**
Constructs a `Distance`.

Returns `nil` if the value is lower than 0, because we cannot construct negative distances.

@param miles Distance in miles.
@return A value that represents the provided distance in radians.
*/
+ (nullable instancetype)distanceFromMiles:(double)miles NS_SWIFT_NAME(miles(_:));

/**
Constructs a `Distance`.

Returns `nil` if the value is lower than 0, because we cannot construct negative distances.

@param degrees Distance in degrees.
@returns A value that represents the provided distance in radians.
*/
+ (nullable instancetype)distanceFromDegrees:(double)degrees NS_SWIFT_NAME(degrees(_:));

/**
Constructs a `Distance`.

Returns `nil` if the value is lower than 0, because we cannot construct negative distances.

@param radians Distance in radians.
@returns A value that represents the provided distance in radians.
*/
+ (nullable instancetype)distanceFromRadians:(double)radians NS_SWIFT_NAME(radians(_:));

/**
Returns the current `Distance` value in kilometers.

@returns The value un kilometers.
*/
- (double)asKilometers;

/**
Returns the current `Distance` value in miles.

@returns The value un miles.
*/
- (double)asMiles;

/**
Returns the current `Distance` value in degrees.

@returns The value un degrees.
*/
- (double)asDegrees;
@end

/**
A class that represents a circle, that can be used in a geospatial `geoWithin`query.

@warning This class cannot be persisted and can only be use within a geospatial `geoWithin` query.
*/
RLM_SWIFT_SENDABLE
@interface RLMGeospatialCircle : NSObject <RLMGeospatial>
/// Center of the circle.
@property (readonly, strong) RLMGeospatialPoint *center;
/// Radius of the circle.
@property (readonly) double radians;

/**
Initialize a `RLMGeospatialCircle`, from its center and radius.

@param center Center of the circle.
@param radians Radius of the circle.
*/
- (nullable instancetype)initWithCenter:(RLMGeospatialPoint *)center radiusInRadians:(double)radians;

/**
Initialize a `GeoCircle`, from its center and radius.

@param center Center of the circle.
@param radius Radius of the circle.
*/
- (instancetype)initWithCenter:(RLMGeospatialPoint *)center radius:(RLMDistance *)radius;
@end

RLM_HEADER_AUDIT_END(nullability)
