////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

/**
 RLMDegrees represents an angle in degrees. It is used to represent latitudes and longitudes,
 with positive numbers representing North and East, and negative numbers representing South and West.
 */
typedef double RLMDegrees;

/**
 RLMDistance represents a distance in meters.
 */
typedef double RLMDistance;

/**
 RLMCoordinate2D represents a geographical coordinate.
 */
typedef struct {
    RLMDegrees latitude;
    RLMDegrees longitude;
} RLMCoordinate2D;

/**
 A bounding box is rectangle that is represented by coordinates for opposing corners.
 */
typedef struct {
    RLMCoordinate2D corner1;
    RLMCoordinate2D corner2;
} RLMBoundingBox;
