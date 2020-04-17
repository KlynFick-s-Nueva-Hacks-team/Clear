//
//  MapVC.swift
//  Cleer
//
//  Created by Nicholas Assaderaghi on 4/16/20.
//  Copyright © 2020 zachary. All rights reserved.
//
/*
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
    private let reachability = SCNetworkReachabilityCreateWithName(nil, "google.com")
    private var uid: String = "undefined"
    private var latitude: Double = 0
    private var longitude: Double = 0
    private var locationHasBeenUpdatedOnce = false
    private var currentAnnotations = [[String:Any]]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        checkLocationServices()
        map.mapType = .mutedStandard
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        map.showsBuildings = true
        map.isPitchEnabled = true
        map.showsCompass = true
        map.showsScale = true
        _ = Timer.scheduledTimer(timeInterval: 100.0, target: self, selector: #selector(updateLocations), userInfo: nil, repeats: true)
        updateLocations()
    }
    @objc public func updateLocations()
    {
        checkReachable()
        let db = Firestore.firestore()
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
                    let oldAnnotations = self.currentAnnotations
                    self.currentAnnotations = []
                    for document in querySnapshot!.documents
                    {
                        let longitude = document.data()["Longitude"] as! [Double]
                        let latitude = document.data()["Latitude"] as! [Double]
                        let userID = document.documentID
                        if (userID != self.uid)
                        {
                            self.currentAnnotations.append(["title": userID, "latitude": latitude, "longitude": longitude])
                        }
                    }
                    self.plotLocations(locations: self.currentAnnotations, oldLocations: oldAnnotations)
                    if (!self.locationHasBeenUpdatedOnce)
                    {
                        return
                    }
                    let data = [
                      "Longitude": self.longitude,
                      "Latitude": self.latitude
                    ] as [String : Any]
                    if (self.uid == "undefined")
                    {
                        let dataReference = Firestore.firestore().collection("Locations").document()
                        self.uid = dataReference.documentID
                        dataReference.setData(data, completion: {(err) in
                          if (err != nil)
                          {
                            let alert = UIAlertController(title: "Something Went Wrong", message: "An error occured while uploading your location to the database.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                          }
                        })
                    }
                    else
                    {
                        Firestore.firestore().collection("Locations").document(self.uid).updateData(data, completion: {(err) in
                            if (err != nil)
                            {
                                let alert = UIAlertController(title: "Something Went Wrong", message: "An error occured while uploading your location to the database.", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }
                        })
                    }
               }
        }
    }
    private func plotLocations(locations: [[String:Any]], oldLocations: [[String:Any]])
    {
        var annotations = [MKPointAnnotation]()
        for location in oldLocations
        {
            let annotation = MKPointAnnotation()
            annotation.title = location["title"] as? String
            annotation.coordinate = CLLocationCoordinate2D(latitude: location["latitude"] as! CLLocationDegrees, longitude: location["longitude"] as! CLLocationDegrees)
            annotations.append(annotation)
        }
        map.removeAnnotations(annotations)
        annotations = [MKPointAnnotation]()
        for location in locations
        {
            let annotation = MKPointAnnotation()
            annotation.title = location["title"] as? String
            annotation.coordinate = CLLocationCoordinate2D(latitude: location["latitude"] as! CLLocationDegrees, longitude: location["longitude"] as! CLLocationDegrees)
            annotations.append(annotation)
        }
        map.addAnnotations(annotations)
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
        self.longitude = location.coordinate.longitude
        self.latitude = location.coordinate.latitude
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
*/
