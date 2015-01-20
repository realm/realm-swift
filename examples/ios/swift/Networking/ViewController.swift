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
        didSet {
            title = "\(restaurants.count) venues nearby"
            if let mapView = mapView {
                let oldIDs = NSSet(array: map(mapView.annotations, { ($0 as RestaurantLocation).venueID }))
                for r in restaurants {
                    let restaurant = r as Restaurant
                    if !oldIDs.containsObject(restaurant.venueID) {
                        mapView.addAnnotation(RestaurantLocation(restaurant))
                    }
                }
            }
        }
    }

    var selectedCategory: Category? = nil

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
        let restaurants = venueManager.venues
        if let category = selectedCategory {
            self.restaurants = restaurants.objectsWhere("category == %@", category)
        }
        else {
            self.restaurants = restaurants
        }
        super.viewDidLoad()
        realmNotification = realm.addNotificationBlock { [weak self] (name, realm) -> Void in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                if let vc = self {
                    let restaurants = vc.venueManager.venues
                    if let category = vc.selectedCategory {
                        vc.restaurants = restaurants.objectsWhere("category == %@", category)
                    }
                    else {
                        vc.restaurants = restaurants
                    }
                }
            }
        }
        venueManager.monitoring = true

        mapView = MKMapView(frame: view.bounds)
        mapView?.delegate = self
        mapView?.rotateEnabled = false
        mapView?.pitchEnabled = false
        mapView?.mapType = .Standard
        mapView?.region = MKCoordinateRegionMakeWithDistance(venueManager.location.coordinate, 2_500, 2_500)
        view.addSubview(mapView!)

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Refine", style: .Plain, target: self, action: "refine")
        navigationController?.navigationBar.barTintColor = sixsquareBlue
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Relocate", style: .Bordered, target: self, action: "relocate")
        navigationItem.rightBarButtonItem?.tintColor = UIColor.whiteColor()

        venueManager.fetchVenues()
    }

    func refine() {
        self.navigationItem.leftBarButtonItem?.enabled = false
        let pickerViewHeight = min(CGRectGetHeight(view.bounds) / 3.0, 206.0)
        let pickerView = CategoryPickerView(frame: CGRect(x: 0, y: CGRectGetHeight(view.bounds) - pickerViewHeight, width: CGRectGetWidth(view.bounds), height: pickerViewHeight))
        pickerView.categories = Category.allObjectsInRealm(realm)
        pickerView.selectionBlock = { category in
            self.navigationItem.leftBarButtonItem?.enabled = true
            self.restaurants = self.restaurants.objectsWhere("category == %@", category)
            self.selectedCategory = category
            pickerView.removeFromSuperview()
        }
        if let selectedCategory = selectedCategory {
            pickerView.pickerView.selectRow(Int(pickerView.categories.indexOfObject(selectedCategory)), inComponent: 0, animated: false)
        }
        view.addSubview(pickerView)
    }

    func relocate() {
        if let location = venueManager.locationManager.location {
            mapView?.region = MKCoordinateRegionMakeWithDistance(location.coordinate, 2_500, 2_500)
        }
    }

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: RestaurantLocation) -> MKAnnotationView! {
        let annotationView: LocationAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("AnnotationIdentifier") as LocationAnnotationView? ??
                                                     LocationAnnotationView(annotation: annotation, reuseIdentifier: "AnnotationIdentifier")

        annotationView.iconImage = annotation.image
        annotationView.canShowCallout = true
        annotationView.venueScore = annotation.venueScore

        return annotationView
    }

    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        let location = mapView.centerCoordinate
        venueManager.searchRadius = mapView.region.span.latitudeDelta * 111 * 1000
        venueManager.location = CLLocation(latitude: location.latitude, longitude: location.longitude)
    }
}

