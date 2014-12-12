//
//  ViewController.swift
//  SixSquare
//
//  Created by Samuel E. Giddins on 12/9/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import UIKit
import MapKit
import Realm

class ViewController: UIViewController, MKMapViewDelegate {
    let realm: RLMRealm
    let venueManager: VenueManager
    var realmNotification: RLMNotificationToken?
    let iconImageCache = NSCache()
    let sixsquareBlue = UIColor(red: 28/255, green: 173/255, blue: 236/255, alpha: 1)
    var mapView: MKMapView?
    
    var restaurants: RLMResults {
        willSet(restaurants) {
            title = "\(restaurants.count) venues nearby"
        }

        didSet {
            mapView?.removeAnnotations(mapView!.annotations)
            for restaurant in restaurants {
                let annotation = RestaurantLocation(restaurant as Restaurant)
                mapView?.addAnnotation(annotation)
            }
        }
    }

    init(realm: RLMRealm) {
        self.realm = realm
        venueManager = VenueManager(realm: realm)
        restaurants = venueManager.venues
        super.init(nibName: .None, bundle: .None)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        restaurants = venueManager.venues.sortedResultsUsingProperty("venueScore", ascending: false)
        super.viewDidLoad()
        realmNotification = realm.addNotificationBlock { [weak self] (name, realm) -> Void in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                if let vc = self {
                    vc.restaurants = vc.venueManager.venues.sortedResultsUsingProperty("venueScore", ascending: false)
                }
            }
        }
        venueManager.monitoring = true

        mapView = MKMapView(frame: view.bounds)
        mapView?.delegate = self
        mapView?.rotateEnabled = false
        mapView?.pitchEnabled = false
        mapView?.mapType = .Standard
        mapView?.centerCoordinate = venueManager.location.coordinate
        view.addSubview(mapView!)

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Refine", style: .Plain, target: self, action: "refine")
        navigationController?.navigationBar.barTintColor = sixsquareBlue
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Relocate", style: .Bordered, target: self, action: "relocate")
        navigationItem.rightBarButtonItem?.tintColor = UIColor.whiteColor()

        venueManager.fetchVenues()
    }

    func refine() {

    }

    func relocate() {
        if let mapView = mapView {
            let location = mapView.centerCoordinate
            venueManager.searchRadius = mapView.region.span.latitudeDelta * 111 * 1000
            venueManager.location = CLLocation(latitude: location.latitude, longitude: location.longitude)
        }
    }

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: RestaurantLocation) -> MKAnnotationView! {
        let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("AnnotationIdentifier") ??
                             MKPinAnnotationView(annotation: annotation, reuseIdentifier: "AnnotationIdentifier")
        if let iconImage = annotation.image {
            annotationView?.image = iconImage
        }
        annotationView?.canShowCallout = true

        return annotationView
    }
}

