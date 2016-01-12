//
//  ViewController.swift
//  NavigationAppRouter
//
//  Created by fpoisson on 01/11/2016.
//  Copyright (c) 2016 fpoisson. All rights reserved.
//

import UIKit
import MapKit
import NavigationAppRouter

class ViewController: UIViewController {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var gotoButton: UIButton!
    @IBOutlet var activityLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    lazy var locationManager: CLLocationManager? = CLLocationManager()
    var placeAnnotation: MKPointAnnotation!
    lazy var geocoder = CLGeocoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.activityIndicator.hidden = true;
        self.setupMapView()
        self.askForLocationAccessPermissions()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupMapView() {
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true;
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "userDidTapMapView:")
        tapGesture.numberOfTapsRequired = 1;
        tapGesture.numberOfTouchesRequired = 1;
        self.mapView.addGestureRecognizer(tapGesture);
        
        let tapGesture2 = UITapGestureRecognizer(target: self, action: nil)
        tapGesture2.numberOfTapsRequired = 2;
        tapGesture2.numberOfTouchesRequired = 1;
        self.mapView.addGestureRecognizer(tapGesture2);
        
        tapGesture.requireGestureRecognizerToFail(tapGesture2)
        tapGesture.delegate = self
    }
    
    func askForLocationAccessPermissions() {
        // Ask for location permission access
        let locationAuthorizationStatus: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        
        if locationAuthorizationStatus == CLAuthorizationStatus.NotDetermined {
            if let locationManager = self.locationManager {
                locationManager.delegate = self
                locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    func displaySearchActivity(displayed: Bool) {
        self.gotoButton.hidden = displayed
        self.activityLabel.hidden = !displayed;
        self.activityIndicator.hidden = !displayed;
        
        if displayed {
            self.activityIndicator.startAnimating()
        } else {
            self.activityIndicator.stopAnimating()
        }
    }
    
    func userDidTapMapView(tapGesture: UITapGestureRecognizer) {
        let location: CGPoint = tapGesture.locationInView(self.mapView)
        
        // Update place annotation
        if self.placeAnnotation == nil {
            self.placeAnnotation = MKPointAnnotation()
            self.mapView.addAnnotation(self.placeAnnotation)
        }
        
        self.placeAnnotation.coordinate = self.mapView.convertPoint(location, toCoordinateFromView: self.mapView)
    }
    
    @IBAction func goToButtonTapped(sender: UIButton) {

        if self.placeAnnotation == nil {
            return
        }
        
        // Setup address search display
        self.displaySearchActivity(true)
        
        // Search for location address
        let placeLocaton = CLLocation(latitude: self.placeAnnotation.coordinate.latitude, longitude: self.placeAnnotation.coordinate.longitude)
        self.geocoder.reverseGeocodeLocation(placeLocaton) { [weak self] (placemarks, _) -> Void in
            if (self == nil) {
                return
            }

            self!.displaySearchActivity(false)

            if placemarks != nil && placemarks!.count > 0 {
                let place = MKPlacemark(placemark: placemarks![0]);

                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // Navigation app routing
                    // ----------------------
                    NavigationAppRouter.goToPlace(place, fromViewController: self!)
                })
            }
        }
    }
}

// MARK: - CLLocationManager delegate

extension ViewController: CLLocationManagerDelegate {

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if (status != CLAuthorizationStatus.NotDetermined) {
            // Location manager instance not needed anymore
            self.locationManager = nil
        }
    }
}

// MARK: - MKMapView delegate

extension ViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        // Center map on user when his location is available
        struct TokenContainer {
            static var token: dispatch_once_t = 0
        }
        dispatch_once(&TokenContainer.token) { [weak self] in
            if self == nil {
                return
            }

            if let userCoordinate: CLLocationCoordinate2D = userLocation.location?.coordinate {
                let region = MKCoordinateRegion(center: userCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
                self!.mapView.setRegion(region, animated: true)
            }
        }
    }
}

// MARK: - UIGestureRecognizer delegate

extension ViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        // Discard touch if in annotation view
        if touch.view is MKAnnotationView {
            return false
        }
        return true
    }
}
