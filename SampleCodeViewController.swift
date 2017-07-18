//
//  ViewController.swift
//  MotoParking
//
//  Created by Kevin Tran on 5/22/17.
//  Copyright © 2017 com.example. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController, GMSMapViewDelegate {
    
    //MARK: - Variables
    var locationManager = CLLocationManager() //new instance of CLLocation for map events
    var currentLocation: CLLocation?  //optional class for lon, lat, direction, etc.
    var mapView: GMSMapView!
    var zoomLevel: Float = 16.0
    let defaultLocation = CLLocation(latitude: 37.7749, longitude: -122.4194) //default location if not permitted
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
    }
    
    //MARK: - Functions
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        let lat = position.target.latitude
        let lon = position.target.longitude
        
        APIManager.sharedInstance.meteredParking(lat: lat, lon: lon) { //metered parking call
            (latitude, longitude) in
            DispatchQueue.main.sync {
                let position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let marker = GMSMarker(position: position)
                marker.title = "Metered Parking"
                marker.icon = GMSMarker.markerImage(with: UIColor(red:0.17, green:0.38, blue:0.45, alpha:1.0))
                marker.map = self.mapView
            }
        }//end of metered parking call
        
        APIManagerNonMetered.sharedInstance.nonMeteredParking(lat: lat, lon: lon) {  //unmetered parking call
            (unmeteredLatitude, unmeteredLongitude) in
            DispatchQueue.main.sync {
                let position = CLLocationCoordinate2D(latitude: unmeteredLatitude, longitude: unmeteredLongitude)
                let marker = GMSMarker(position: position)
                marker.title = "Unmetered Parking"
                marker.icon = GMSMarker.markerImage(with: UIColor(red:0.99, green:0.75, blue:0.03, alpha:1.0))
                marker.map = self.mapView
            }
        }//end of unmetered parking call
        mapView.camera = position
    } //end of mapView
    
    func setupMap() {
        locationManager = CLLocationManager()  //create locationManager
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude, longitude: defaultLocation.coordinate.longitude, zoom: zoomLevel)  //create map
        
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)  //set map configerations
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        mapView.isMyLocationEnabled = true
        
        view.addSubview(mapView)  //add map to view till location updates
        mapView.isHidden = true
        mapView.delegate = self
    }//end of setupMap

} //ViewController end bracket

//MARK: - Extensions
extension ViewController: CLLocationManagerDelegate {  //delegate for location manager
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: zoomLevel)
        
        if mapView.isHidden { //display mapView if hidden
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        APIManager.sharedInstance.meteredParking(lat: lat, lon: lon) {
            (latitude, longitude) in
            DispatchQueue.main.sync {
                let position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let marker = GMSMarker(position: position)
                marker.title = "Metered Parking"
                marker.icon = GMSMarker.markerImage(with: UIColor(red:0.99, green:0.75, blue:0.03, alpha:1.0))
                marker.map = self.mapView
            }
        }
        
        APIManagerNonMetered.sharedInstance.nonMeteredParking(lat: lat, lon: lon) {
            (unmeteredLatitude, unmeteredLongitude) in
            DispatchQueue.main.sync {
            let position = CLLocationCoordinate2D(latitude: unmeteredLatitude, longitude: unmeteredLongitude)
            let marker = GMSMarker(position: position)
            marker.title = "Unmetered Parking"
            marker.icon = GMSMarker.markerImage(with: UIColor(red:0.99, green:0.75, blue:0.03, alpha:1.0))
            marker.map = self.mapView
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
    
} //extension end bracket
