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

import XCTest
import RealmSwift
import Realm.Private

// Template `EmbeddedObject` for storing GeoPoints in Realm.
public class Location: EmbeddedObject {
    @Persisted private(set) var coordinates: List<Double>
    @Persisted public var type: String = "Point" // public for testing

    public var latitude: Double { return coordinates[1] }
    public var longitude: Double { return coordinates[0] }

    convenience init(_ latitude: Double, _ longitude: Double) {
        self.init()
        coordinates.append(objectsIn: [longitude, latitude])
    }
}

public class PersonWithInvalidTypes: Object {
    @Persisted public var geoPointCoordinatesEmbedded: CoordinatesGeoPointEmbedded?
    @Persisted public var geoPointTypeEmbedded: TypeGeoPointEmbedded?
    @Persisted public var geoPoint: TopLevelGeoPoint?
}

public class CoordinatesGeoPointEmbedded: EmbeddedObject {
    @Persisted public var coordinates: List<Double>
}

public class TypeGeoPointEmbedded: EmbeddedObject {
    @Persisted public var type: String = "Point" // public for testing
}

public class TopLevelGeoPoint: Object {
    @Persisted public var coordinates: List<Double>
    @Persisted public var type: String = "Point" // public for testing
}

class PersonLocation: Object {
    @Persisted var name: String
    @Persisted var location: Location?

    convenience init(_ name: String, _ location: Location?) {
        self.init()
        self.name = name
        self.location = location
    }
}

class GeospatialTests: TestCase, @unchecked Sendable {
    func populatePersonLocationTable() throws {
        let realm = realmWithTestPath()
        try realm.write {
            realm.add(PersonLocation("Diana", Location(40.7128, -74.0060)))
            realm.add(PersonLocation("Maria", Location(55.6761, 12.5683)))
            realm.add(PersonLocation("Tomas", Location(55.6280, 12.0826)))
            realm.add(PersonLocation("Alba", Location(-76, -76)))
            realm.add(PersonLocation("Manuela", nil))
        }
    }

    func testGeoPoints() throws {
        assertGeoPoint(90, 0)
        assertGeoPoint(-90, 0)
        assertGeoPoint(12.3456789, 0)
        assertGeoPoint(90.000000001, 0, isNull: true)
        assertGeoPoint(-90.000000001, 0, isNull: true)
        assertGeoPoint(9999999, 0, isNull: true)
        assertGeoPoint(-9999999, 0, isNull: true)

        assertGeoPoint(0, 180)
        assertGeoPoint(0, -180)
        assertGeoPoint(0, 12.3456789)
        assertGeoPoint(0, 180.000000001, isNull: true)
        assertGeoPoint(0, -180.000000001, isNull: true)
        assertGeoPoint(0, 9999999, isNull: true)
        assertGeoPoint(0, -9999999, isNull: true)

        assertGeoPoint(90, 0, 0)
        assertGeoPoint(90, 0, 500)
        assertGeoPoint(90, 0, -1, isNull: true)
        assertGeoPoint(90, 0, Double.nan, isNull: true)
        assertGeoPoint(90, 0, -500, isNull: true)

        assertGeoPoint(Double.nan, 0, isNull: true)
        assertGeoPoint(0, Double.nan, isNull: true)

        func assertGeoPoint(_ latitude: Double, _ longitude: Double, _ altitude: Double = 0, isNull: Bool = false) {
            if isNull {
                XCTAssertNil(GeoPoint(latitude: latitude, longitude: longitude, altitude: altitude))
            } else {
                XCTAssertNotNil(GeoPoint(latitude: latitude, longitude: longitude, altitude: altitude))
            }
        }
    }

    func testGeoBox() throws {
        XCTAssertNotNil(GeoBox(bottomLeft: GeoPoint(latitude: -90, longitude: -180)!, topRight: GeoPoint(latitude: 90, longitude: 180)!))
        XCTAssertNotNil(GeoBox(bottomLeft: (-90, -180), topRight: (90, 180)))
        XCTAssertNil(GeoBox(bottomLeft: (-91, -181), topRight: (91, 181)))
    }

    func testGeoPolygon() throws {
        // GeoPolygon require outerRing with at least three vertices and 4 points
        assertGeoPolygon(outerRing: GeoPoint(latitude: 0, longitude: 0)!, isNull: true)
        assertGeoPolygon(outerRing: GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 0, longitude: 0)!, isNull: true)
        assertGeoPolygon(outerRing: GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 2)!, isNull: true)

        // GeoPolygon require outerRing first and last point to be equal to close the Polygon
        assertGeoPolygon(outerRing: GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 0)!, GeoPoint(latitude: 0, longitude: 0)!)
        assertGeoPolygon(outerRing: GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 0)!, GeoPoint(latitude: 3, longitude: 3)!, isNull: true)

        // GeoPolygon require holes to have at least three vertices and 4 points, and first and last point to be equal for each hole
        assertGeoPolygon(outerRing: GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 2)!, GeoPoint(latitude: 0, longitude: 0)!, holes: [GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 2)!, GeoPoint(latitude: 0, longitude: 0)!])
        assertGeoPolygon(outerRing: GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 2)!, GeoPoint(latitude: 0, longitude: 0)!, holes: [GeoPoint(latitude: 0, longitude: 0)!], isNull: true)
        assertGeoPolygon(outerRing: GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 2)!, GeoPoint(latitude: 0, longitude: 0)!, holes: [GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 0, longitude: 0)!], isNull: true)
        assertGeoPolygon(outerRing: GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 2)!, GeoPoint(latitude: 0, longitude: 0)!, holes: [GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 2)!], isNull: true)
        assertGeoPolygon(outerRing: GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 2)!, GeoPoint(latitude: 0, longitude: 0)!, holes: [GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 2)!, GeoPoint(latitude: 3, longitude: 3)!], isNull: true)
        assertGeoPolygon(outerRing: GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 2)!, GeoPoint(latitude: 0, longitude: 0)!, holes: [GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 2)!, GeoPoint(latitude: 0, longitude: 0)!], [GeoPoint(latitude: 0, longitude: 0)!], isNull: true)
        assertGeoPolygon(outerRing: GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 2)!, GeoPoint(latitude: 0, longitude: 0)!, holes: [GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 2)!, GeoPoint(latitude: 0, longitude: 0)!], [GeoPoint(latitude: 0, longitude: 0)!, GeoPoint(latitude: 1, longitude: 1)!, GeoPoint(latitude: 2, longitude: 2)!, GeoPoint(latitude: 3, longitude: 3)!], isNull: true)

        func assertGeoPolygon(outerRing: GeoPoint..., holes: [GeoPoint]..., isNull: Bool = false) {
            if isNull {
                XCTAssertNil(GeoPolygon(outerRing: outerRing.map { $0 }, holes: holes.map { $0 }))
            } else {
                XCTAssertNotNil(GeoPolygon(outerRing: outerRing.map { $0 }, holes: holes.map { $0 }))
            }
        }

        // Using Simplified initialisers
        XCTAssertNotNil(GeoPolygon(outerRing: [(40.0096192, -75.5175781), (60, 20), (20, 20), (-75.5175781, -75.5175781), (40.0096192, -75.5175781)]))
        XCTAssertNil(GeoPolygon(outerRing: [(40.0096192, -75.5175781)]))
        XCTAssertNotNil(GeoPolygon(outerRing: [(0, 0), (1, 1), (2, 2), (0, 0)], holes: [[(0, 0), (1, 1), (2, 2), (0, 0)]]))
        XCTAssertNotNil(GeoPolygon(outerRing: [(0, 0), (1, 1), (2, 2), (0, 0)], holes: [(0, 0), (1, 1), (2, 2), (0, 0)], [(0, 0), (1, 1), (2, 2), (0, 0)]))
        XCTAssertNil(GeoPolygon(outerRing: [(0, 0), (1, 1), (2, 2), (0, 0)], holes: [[(0, 0)]]))
        XCTAssertNil(GeoPolygon(outerRing: [(0, 0), (1, 1), (2, 2), (0, 0)], holes: [[(0, 0), (1, 1), (2, 2), (3, 3)]]))
        XCTAssertNil(GeoPolygon(outerRing: [(0, 0), (1, 1), (2, 2), (0, 0)], holes: [(0, 0), (1, 1), (2, 2), (0, 0)], [(0, 0), (1, 1), (2, 2), (3, 3)]))
    }

    func testGeoDistance() throws {
        assertGeoDistance(Distance.radians(0))
        assertGeoDistance(Distance.radians(20))
        assertGeoDistance(Distance.radians(-20), isNull: true)
        assertGeoDistance(Distance.radians(.nan), isNull: true)

        assertGeoDistance(Distance.kilometers(0))
        assertGeoDistance(Distance.kilometers(10))
        assertGeoDistance(Distance.kilometers(-10), isNull: true)
        assertGeoDistance(Distance.kilometers(.nan), isNull: true)

        assertGeoDistance(Distance.miles(0))
        assertGeoDistance(Distance.miles(10))
        assertGeoDistance(Distance.miles(-10), isNull: true)
        assertGeoDistance(Distance.miles(.nan), isNull: true)

        assertGeoDistance(Distance.degrees(0))
        assertGeoDistance(Distance.degrees(90))
        assertGeoDistance(Distance.degrees(-90), isNull: true)
        assertGeoDistance(Distance.degrees(.nan), isNull: true)

        func assertGeoDistance(_ radius: Distance?, isNull: Bool = false) {
            if isNull {
                XCTAssertNil(radius)
            } else {
                XCTAssertNotNil(radius)
            }
        }
    }

    func testGeoCircle() throws {
        XCTAssertNotNil(GeoCircle(center: GeoPoint(latitude: 0, longitude: 70)!, radius: .radians(0)!))
        XCTAssertNotNil(GeoCircle(center: GeoPoint(latitude: 0, longitude: 70)!, radiusInRadians: 500))
        XCTAssertNil(GeoCircle(center: GeoPoint(latitude: 0, longitude: 70)!, radiusInRadians: Double.nan))
        XCTAssertNil(GeoCircle(center: GeoPoint(latitude: 0, longitude: 70)!, radiusInRadians: -500))

        // Using Simplified initialiser
        XCTAssertNotNil(GeoCircle(center: (0, 70), radiusInRadians: 0))
        XCTAssertNil(GeoCircle(center: (0, 70), radiusInRadians: -500))
    }

    func testDistanceFromKilometers() throws {
        let earthCircumferenceKM: Double = 40075
        let distance = Distance.kilometers(earthCircumferenceKM)!
        XCTAssertEqual(distance.radians, Double.pi * 2, accuracy: distance.radians * 0.0001)
        XCTAssertEqual(distance.asKilometers(), earthCircumferenceKM, accuracy: distance.asKilometers() * 0.0001)
    }

    func testDistanceFromMiles() throws {
        let earthCircumferenceMiles: Double = 24901
        let distance = Distance.miles(earthCircumferenceMiles)!
        XCTAssertEqual(distance.radians, Double.pi * 2, accuracy: distance.radians * 0.0001)
        XCTAssertEqual(distance.asMiles(), earthCircumferenceMiles, accuracy: distance.asMiles() * 0.0001)
    }

    func testDistanceFromDegrees() throws {
        let distance = Distance.degrees(180)!
        XCTAssertEqual(distance.radians, Double.pi, accuracy: distance.radians * 0.0001)
        XCTAssertEqual(distance.asDegrees(), 180, accuracy: distance.asDegrees() * 0.0001)
    }

    func testDistanceFromRadians() throws {
        let distance = Distance.radians(Double.pi)!
        XCTAssertEqual(distance.radians, Double.pi)
    }

    func testFilterShapes() throws {
        try populatePersonLocationTable()

        assertFilterShape(GeoBox(bottomLeft: (55.6281, 12.0826), topRight: (55.6762, 12.5684))!, count: 1, expectedMatches: ["Maria"])
        assertFilterShape(GeoBox(bottomLeft: (55.6279, 12.0825), topRight: (55.6762, 12.5684))!, count: 2, expectedMatches: ["Maria", "Tomas"])
        assertFilterShape(GeoBox(bottomLeft: (0, -75), topRight: (60, 15))!, count: 3, expectedMatches: ["Diana", "Maria", "Tomas"])
        assertFilterShape(GeoBox(bottomLeft: (0, -75), topRight: (60, 15))!, count: 3, expectedMatches: ["Diana", "Maria", "Tomas"])

        assertFilterShape(GeoPolygon(outerRing: [(55.6281, 12.0826), (55.6761, 12.0826), (55.6761, 12.5684), (55.6281, 12.5684), (55.6281, 12.0826)])!, count: 1, expectedMatches: ["Maria"])
        assertFilterShape(GeoPolygon(outerRing: [(55, 12), (55.67, 12.5), ( 55.67, 11.5), (55, 12)])!, count: 1, expectedMatches: ["Tomas"])
        assertFilterShape(GeoPolygon(outerRing: [(40.0096192, -75.5175781), (60, 20), (20, 20), (-75.5175781, -75.5175781), (40.0096192, -75.5175781)])!, count: 3, expectedMatches: ["Diana", "Maria", "Tomas"])
        assertFilterShape(GeoPolygon(outerRing: [(40.0096192, -75.5175781), (60, 20), (20, 20), (-75.5175781, -75.5175781), (40.0096192, -75.5175781)])!, count: 3, expectedMatches: ["Diana", "Maria", "Tomas"])

        // GeoPolygon with holes
        assertFilterShape(GeoPolygon(outerRing: [(50, -80), (61, 21), (21, 21), (-80, -80), (50, -80)], holes: [[(40.0096192, -75.5175781), (60, 20), (20, 20), (-75.5175781, -75.5175781), (40.0096192, -75.5175781)]])!, count: 1, expectedMatches: ["Alba"])
        assertFilterShape(GeoPolygon(outerRing: [(50, -80), (62, 22), (22, 22), (-80, -80), (50, -80)], holes: [[(40.7129, -75), (40.7129, -74), (40.7126, -74), (40.7129, -75)]])!, count: 3, expectedMatches: ["Maria", "Tomas", "Alba"])
        assertFilterShape(GeoPolygon(outerRing: [(50, -80), (62, 22), (22, 22), (-80, -80), (50, -80)], holes: [[(40.7129, -75), (40.7129, -74), (40.7126, -74), (40.7129, -75)], [(-77, -77), (-77, -75), (-75, -75), (-75, -77), (-77, -77)]])!, count: 2, expectedMatches: ["Maria", "Tomas"])
        assertFilterShape(GeoPolygon(outerRing: [(50, -80), (62, 22), (22, 22), (-80, -80), (50, -80)], holes: [[(40.7129, -75), (40.7129, -74), (40.7126, -74), (40.7129, -75)], [(-77, -77), (-77, -75), (-75, -75), (-75, -77), (-77, -77)], [(55.6760, 12.5682), (55.6760, 12.5684), (55.6763, 12.5684), (55.6763, 12.5682), (55.6760, 12.5682)]])!, count: 1, expectedMatches: ["Tomas"])
        assertFilterShape(GeoPolygon(outerRing: [(50, -80), (62, 22), (22, 22), (-80, -80), (50, -80)], holes: [[(40.7129, -75), (40.7129, -74), (40.7126, -74), (40.7129, -75)], [(-77, -77), (-77, -75), (-75, -75), (-75, -77), (-77, -77)], [(55.6760, 12.5682), (55.6760, 12.5684), (55.6763, 12.5684), (55.6763, 12.5682), (55.6760, 12.5682)], [(55.6279, 12.0825), (55.6279, 12.0827), (55.6281, 12.0827), (55.6281, 12.0825), (55.6279, 12.0825)]])!, count: 0, expectedMatches: [])

        assertFilterShape(GeoCircle(center: (55.67, 12.56), radiusInRadians: 0.001)!, count: 1, expectedMatches: ["Maria"])
        assertFilterShape(GeoCircle(center: (55.67, 12.56), radiusInRadians: 0.001)!, count: 1, expectedMatches: ["Maria"])
        assertFilterShape(GeoCircle(center: (55.67, 12.56), radius: .kilometers(10)!)!, count: 1, expectedMatches: ["Maria"])
        assertFilterShape(GeoCircle(center: (55.67, 12.56), radius: .kilometers(100)!)!, count: 2, expectedMatches: ["Maria", "Tomas"])
        assertFilterShape(GeoCircle(center: (45, -20), radius: .kilometers(5000)!)!, count: 3, expectedMatches: ["Diana", "Maria", "Tomas"])
        assertFilterShape(GeoCircle(center: (45, -20), radius: .kilometers(5000)!)!, count: 3, expectedMatches: ["Diana", "Maria", "Tomas"])

        func assertFilterShape<U: RLMGeospatial>(_ shape: U, count: Int, expectedMatches: [String]) {
            let realm = realmWithTestPath()
            let resultsBox = realm.objects(PersonLocation.self).where { $0.location.geoWithin(shape) }
            XCTAssertEqual(resultsBox.count, count)
            expectedMatches.forEach { match in
                XCTAssertTrue(resultsBox.contains(where: { $0.name == match }))
            }

            let resultsBoxFilter = realm.objects(PersonLocation.self).filter("location IN %@", shape)
            XCTAssertEqual(resultsBoxFilter.count, count)
            expectedMatches.forEach { match in
                XCTAssertTrue(resultsBoxFilter.contains(where: { $0.name == match }))
            }

            let resultsBoxNSPredicate = realm.objects(PersonLocation.self).filter(NSPredicate(format: "location IN %@", shape as! CVarArg))
            XCTAssertEqual(resultsBoxNSPredicate.count, count)
            expectedMatches.forEach { match in
                XCTAssertTrue(resultsBoxNSPredicate.contains(where: { $0.name == match }))
            }
        }
    }

    func testInvalidTypeValueForObjectGeoPoint() throws {
        try populatePersonLocationTable()

        let realm = realmWithTestPath()
        let persons = realm.objects(PersonLocation.self)

        let shape = GeoBox(bottomLeft: (55.6281, 12.0826), topRight: (55.6762, 12.5684))!
        // Executing the query will return one object which is in the region of the GeoBox
        XCTAssertEqual(realm.objects(PersonLocation.self).where { $0.location.geoWithin(shape) }.count, 1)

        try realm.write {
            for person in persons {
                person.location?.type = "Polygon"
            }
        }

        // Even though one of the GeoPoints is within the box regions, having the type set as
        // Polygon will cause a no return.
        XCTAssertEqual(realm.objects(PersonLocation.self).where { $0.location.geoWithin(shape) }.count, 0)
    }

    func testInvalidObjectTypesForGeoQuery() throws {
        let realm = realmWithTestPath()

        // Populate
        try realm.write {
            let geoPointCoordinatesEmbedded = CoordinatesGeoPointEmbedded()
            geoPointCoordinatesEmbedded.coordinates.append(objectsIn: [2, 1])

            let geoPointTypeEmbedded = TypeGeoPointEmbedded()
            let topLevelGeoPoint = TopLevelGeoPoint()

            let object = PersonWithInvalidTypes()
            object.geoPointCoordinatesEmbedded = geoPointCoordinatesEmbedded
            object.geoPointTypeEmbedded = geoPointTypeEmbedded
            object.geoPoint = topLevelGeoPoint
            realm.add(object)
        }

        let shape = GeoCircle(center: (0, 0), radiusInRadians: 10.0)!

        assertThrowsFilter(PersonWithInvalidTypes.self, query: {
            $0.geoPointCoordinatesEmbedded.geoWithin(shape)
        }, reason: "Query 'geoPointCoordinatesEmbedded GEOWITHIN GeoCircle([0, 0, 0], 10)' links to data in the wrong format for a geoWithin query")

        assertThrowsFilter(PersonWithInvalidTypes.self, query: { $0.geoPointTypeEmbedded.geoWithin(shape) }, reason: "Query 'geoPointTypeEmbedded GEOWITHIN GeoCircle([0, 0, 0], 10)' links to data in the wrong format for a geoWithin query")

        // This is only allowed using filter/NSPredicate
        assertThrows(realm.objects(PersonWithInvalidTypes.self).filter(NSPredicate(format: "geoPoint IN %@", shape)), reason: "A GEOWITHIN query can only operate on a link to an embedded class but 'TopLevelGeoPoint' is at the top level")

        func assertThrowsFilter<T: Object>(_ object: T.Type, query: ((Query<T>) -> Query<Bool>), reason: String) {
            let realm = realmWithTestPath()
            assertThrows(realm.objects(object).where(query), reason: reason)

            let (queryStr, constructedValues) = query(Query<T>._constructForTesting())._constructPredicate()
            assertThrows(realm.objects(object)
                .filter(queryStr, constructedValues), reason: reason)
            assertThrows(realm.objects(object)
                .filter(NSPredicate(format: queryStr, argumentArray: constructedValues)), reason: reason)
        }
    }

    func testGeoPolygonHoleNotContainedInOuterRingThrows() throws {
        let realm = realmWithTestPath()
        assertThrows(realm.objects(PersonLocation.self).where { $0.location.geoWithin(GeoPolygon(outerRing: [(0, 0), (0, 1), (1, 1), (1, 0), (0, 0)], holes: [[(2, 2), (2, 3), (3, 3), (3, 2), (2, 2)]])!) }, reason: "Invalid region in GEOWITHIN query for parameter 'GeoPolygon({[0, 0, 0], [1, 0, 0], [1, 1, 0], [0, 1, 0], [0, 0, 0]}, {[2, 2, 0], [3, 2, 0], [3, 3, 0], [2, 3, 0], [2, 2, 0]})': 'Secondary ring 1 not contained by first exterior ring - secondary rings must be holes in the first ring")
        assertThrows(realm.objects(PersonLocation.self).where { $0.location.geoWithin(GeoPolygon(outerRing: [(0, 0), (0, 1), (1, 1), (1, 0), (0, 0)], holes: [[(0, 0.1), (0.5, 0.1), (0.5, 0.5), (0, 0.5), (0, 0.1)]])!) }, reason: "Invalid region in GEOWITHIN query for parameter 'GeoPolygon({[0, 0, 0], [1, 0, 0], [1, 1, 0], [0, 1, 0], [0, 0, 0]}, {[0.1, 0, 0], [0.1, 0.5, 0], [0.5, 0.5, 0], [0.5, 0, 0], [0.1, 0, 0]})': 'Secondary ring 1 not contained by first exterior ring - secondary rings must be holes in the first ring")
        assertThrows(realm.objects(PersonLocation.self).where { $0.location.geoWithin(GeoPolygon(outerRing: [(0, 0), (0, 1), (1, 1), (1, 0), (0, 0)], holes: [[(0.25, 0.5), (0.75, 0.5), (0.75, 1.5), (0.25, 1.5), (0.25, 0.5)]])!) }, reason: "Invalid region in GEOWITHIN query for parameter 'GeoPolygon({[0, 0, 0], [1, 0, 0], [1, 1, 0], [0, 1, 0], [0, 0, 0]}, {[0.5, 0.25, 0], [0.5, 0.75, 0], [1.5, 0.75, 0], [1.5, 0.25, 0], [0.5, 0.25, 0]})': 'Secondary ring 1 not contained by first exterior ring - secondary rings must be holes in the first ring")
    }

    func testGeoPolygonWithEdgesIntersectionThrows() throws {
        let realm = realmWithTestPath()
        assertThrows(realm.objects(PersonLocation.self).where { $0.location.geoWithin(GeoPolygon(outerRing: [GeoPoint(latitude: 50, longitude: -50)!, GeoPoint(latitude: 55, longitude: 55)!, GeoPoint(latitude: -50, longitude: 50)!, GeoPoint(latitude: 70, longitude: -25)!, GeoPoint(latitude: 50, longitude: -50)!])!) }, reason: "Invalid region in GEOWITHIN query for parameter 'GeoPolygon({[-50, 50, 0], [55, 55, 0], [50, -50, 0], [-25, 70, 0], [-50, 50, 0]})': 'Ring 0 is not valid: 'Edges 0 and 2 cross. Edge locations in degrees: [50.0000000, -50.0000000]-[55.0000000, 55.0000000] and [-50.0000000, 50.0000000]-[70.0000000, -25.0000000]''")
    }

    func testGeoPolygonDuplicateEdgesThrows() throws {
        let realm = realmWithTestPath()
        assertThrows(realm.objects(PersonLocation.self).where { $0.location.geoWithin(GeoPolygon(outerRing: [(50, -80), (60, 20), (20, 20), (-80, -80), (50, -80)], holes: [[(40.0096192, -75.5175781), (60, 20), (20, 20), (-75.5175781, -75.5175781), (40.0096192, -75.5175781)]])!) }, reason: "Invalid region in GEOWITHIN query for parameter 'GeoPolygon({[-80, 50, 0], [20, 60, 0], [20, 20, 0], [-80, -80, 0], [-80, 50, 0]}, {[-75.5176, 40.0096, 0], [20, 60, 0], [20, 20, 0], [-75.5176, -75.5176, 0], [-75.5176, 40.0096, 0]})': 'Polygon isn't valid: 'Duplicate edge: ring 1, edge 1 and ring 0, edge 1''")
    }

    func testGeoPolygonNestedRingsThrows() throws {
        let realm = realmWithTestPath()
        assertThrows(realm.objects(PersonLocation.self).where { $0.location.geoWithin(GeoPolygon(outerRing: [(50, -80), (62, 22), (22, 22), (-80, -80), (50, -80)], holes: [[(45, -77), (61, 21), (21, 21), (-77, -77), (45, -77)], [(40.0096192, -75.5175780), (60, 20), (20, 20), (-75.5175781, -75.5175781), (40.0096192, -75.5175780)]])!) }, reason: "Invalid region in GEOWITHIN query for parameter 'GeoPolygon({[-80, 50, 0], [22, 62, 0], [22, 22, 0], [-80, -80, 0], [-80, 50, 0]}, {[-77, 45, 0], [21, 61, 0], [21, 21, 0], [-77, -77, 0], [-77, 45, 0]}, {[-75.5176, 40.0096, 0], [20, 60, 0], [20, 20, 0], [-75.5176, -75.5176, 0], [-75.5176, 40.0096, 0]})': 'Polygon interior rings cannot be nested: 2")
    }

    func testGeoEquality() throws {
        XCTAssertEqual(GeoPoint(latitude: 1, longitude: 1, altitude: 1), GeoPoint(latitude: 1, longitude: 1, altitude: 1))
        XCTAssertNotEqual(GeoPoint(latitude: 1, longitude: 1, altitude: 1), GeoPoint(latitude: 2, longitude: 1, altitude: 1))
        XCTAssertNotEqual(GeoPoint(latitude: 1, longitude: 1, altitude: 1), GeoPoint(latitude: 1, longitude: 2, altitude: 1))
        XCTAssertNotEqual(GeoPoint(latitude: 1, longitude: 1, altitude: 1), GeoPoint(latitude: 1, longitude: 1, altitude: 2))

        XCTAssertEqual(GeoBox(bottomLeft: (0, 0), topRight: (1, 1)), GeoBox(bottomLeft: (0, 0), topRight: (1, 1)))
        XCTAssertNotEqual(GeoBox(bottomLeft: (1, 1), topRight: (0, 0)), GeoBox(bottomLeft: (0, 0), topRight: (1, 1)))

        XCTAssertEqual(GeoPolygon(outerRing: [(0, 0), (10, 0), (5, 4), (0, 0)], holes: [[(1, 1), (9, 0), (4, 4), (1, 1)]]), GeoPolygon(outerRing: [(0, 0), (10, 0), (5, 4), (0, 0)], holes: [[(1, 1), (9, 0), (4, 4), (1, 1)]]))
        XCTAssertNotEqual(GeoPolygon(outerRing: [(0, 0), (15, 0), (5, 4), (0, 0)], holes: [[(1, 1), (9, 0), (4, 4), (1, 1)]]), GeoPolygon(outerRing: [(0, 0), (10, 0), (5, 4), (0, 0)], holes: [[(1, 1), (9, 0), (4, 4), (1, 1)]]))
        XCTAssertNotEqual(GeoPolygon(outerRing: [(0, 0), (10, 0), (5, 4), (0, 0)], holes: [[(1, 1), (9, 0), (3, 3), (1, 1)]]), GeoPolygon(outerRing: [(0, 0), (10, 0), (5, 4), (0, 0)], holes: [[(1, 1), (9, 0), (4, 4), (1, 1)]]))

        XCTAssertEqual(GeoCircle(center: (55.67, 12.56), radiusInRadians: 0.001), GeoCircle(center: (55.67, 12.56), radiusInRadians: 0.001))
        XCTAssertNotEqual(GeoCircle(center: (55, 12), radiusInRadians: 1), GeoCircle(center: (55, 13), radiusInRadians: 1))
        XCTAssertNotEqual(GeoCircle(center: (55, 12), radiusInRadians: 1), GeoCircle(center: (55, 12), radiusInRadians: 5))

        XCTAssertEqual(Distance.kilometers(1), Distance.kilometers(1))
        XCTAssertEqual(Distance.miles(1), Distance.miles(1))
        XCTAssertEqual(Distance.radians(50), Distance.radians(50))
        XCTAssertEqual(Distance.degrees(180), Distance.degrees(180))
        XCTAssertNotEqual(Distance.kilometers(25.01), Distance.kilometers(25.02))
        XCTAssertNotEqual(Distance.miles(6.055), Distance.miles(6.054))
        XCTAssertNotEqual(Distance.degrees(180.04), Distance.degrees(180.05))
        XCTAssertNotEqual(Distance.radians(20.00007695), Distance.degrees(20.00007694))
    }
}
