//
//  MapVC.swift
//  Cleer
//
//  Created by Nicholas Assaderaghi on 4/16/20.
//  Copyright © 2020 zachary. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import MapKit
import CoreLocation
import CoreTelephony
import SystemConfiguration

class MapVC: UIViewController
{
    @IBOutlet weak var map: MKMapView!
    
    private let locationManager = CLLocationManager()
    private let regionInMeters: Double = 1000
    private let uid: String = UUID().uuidString
    private let reachability = SCNetworkReachabilityCreateWithName(nil, "google.com")
    private var latitude: Double = 0
    private var longitude: Double = 0
    private var locationHasBeenUpdatedOnce = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        checkLocationServices()
        _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounting), userInfo: nil, repeats: true)
    }
    @objc func updateCounting()
    {
        if (!locationHasBeenUpdatedOnce)
        {
            return
        }
        checkReachable()
        /*let db = Firestore.firestore()
        db.collection("Locations")
            .getDocuments() { (querySnapshot, err) in
                if let err = err
                {
                    print("Error getting documents: \(err)")
                    let alert = UIAlertController(title: "Something Went Wrong", message: "An error occured while querying to the database.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: nil))
                }
                else
                {
                    var locations = [[String:Any]]()
                    for document in querySnapshot!.documents
                    {
                        let longitude = document.data()["Longitude"] as! [Double]
                        let latitude = document.data()["Latitude"] as! [Double]
                        let userID = document.data()["UserID"] as! String
                        locations.append(["title": userID, "latitude": latitude, "longitude": longitude])
                    }
                    self.plotLocations(locations: locations)
                }
        }*/
    }
    private func plotLocations(locations: [[String:Any]])
    {
        for location in locations
        {
            let annotation = MKPointAnnotation()
            annotation.title = location["title"] as? String
            annotation.coordinate = CLLocationCoordinate2D(latitude: location["latitude"] as! CLLocationDegrees, longitude: location["longitude"] as! CLLocationDegrees)
            map.addAnnotation(annotation)
        }
    }
    private func setupLocationManager()
    {
        locationManager.delegate  = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    private func checkLocationServices()
    {
        if CLLocationManager.locationServicesEnabled()
        {
            setupLocationManager()
            checkLocationAuthorization()
        }
        else
        {
            let alert = UIAlertController(title: "Location inacessible", message: "Location services are needed for \"Stear Cleer\"", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    private func centerViewOnUserLocation()
    {
        if let location = locationManager.location?.coordinate
        {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            map.setRegion(region, animated: true)
            map.isZoomEnabled = true
        }
    }
    private func checkLocationAuthorization()
    {
        switch CLLocationManager.authorizationStatus()
        {
            case .authorizedWhenInUse:
                map.showsUserLocation = true
                centerViewOnUserLocation()
                locationManager.startUpdatingLocation()
                break
            case .denied:
                let alert = UIAlertController(title: "Location inacessible", message: "Location services are needed for \"Stear Cleer\"", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                let alert = UIAlertController(title: "Location inacessible", message: "Parental controls is preventing location usage.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                break
            case .authorizedAlways:
                break
            @unknown default:
                break
            }
    }
    private func checkReachable()
    {
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(self.reachability!, &flags)
        
        if (!isNetworkReachable(with: flags))
        {
            let alert = UIAlertController(title: "Internet Connection Required", message: "You can turn on mobile data for this app in Settings.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    private func isNetworkReachable (with flags: SCNetworkReachabilityFlags) -> Bool
    {
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
        return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
}
extension MapVC: CLLocationManagerDelegate
{
    // MARK: - when user's location changes. I'll probs use this to query to firebase
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        guard let location = locations.last else { return }
        longitude = location.coordinate.longitude
        latitude = location.coordinate.latitude
        if (!locationHasBeenUpdatedOnce)
        {
            locationHasBeenUpdatedOnce = true
        }
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters:
            regionInMeters)
        map.setRegion(region, animated: true)
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        checkLocationAuthorization()
    }
}
