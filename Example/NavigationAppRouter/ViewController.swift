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
    @IBOutlet weak var addressTF: UITextField!

    lazy var locationManager: CLLocationManager? = CLLocationManager()
    var placeAnnotation: MKPointAnnotation!
    lazy var geocoder = CLGeocoder()
    var didInitialZoom = false


    override func viewDidLoad() {
        super.viewDidLoad()

        self.activityIndicator.isHidden = true;
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(userDidTapMapView(tapGesture:)))
        tapGesture.numberOfTapsRequired = 1;
        tapGesture.numberOfTouchesRequired = 1;
        self.mapView.addGestureRecognizer(tapGesture);
        
        let tapGesture2 = UITapGestureRecognizer(target: self, action: nil)
        tapGesture2.numberOfTapsRequired = 2;
        tapGesture2.numberOfTouchesRequired = 1;
        self.mapView.addGestureRecognizer(tapGesture2);
        
        tapGesture.require(toFail: tapGesture2)
        tapGesture.delegate = self
    }
    
    func askForLocationAccessPermissions() {
        // Ask for location permission access
        let locationAuthorizationStatus: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        
        if locationAuthorizationStatus == CLAuthorizationStatus.notDetermined {
            if let locationManager = self.locationManager {
                locationManager.delegate = self
                locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    func displaySearchActivity(displayed: Bool) {
        self.gotoButton.isHidden = displayed
        self.activityLabel.isHidden = !displayed;
        self.activityIndicator.isHidden = !displayed;
        
        if displayed {
            self.activityIndicator.startAnimating()
        } else {
            self.activityIndicator.stopAnimating()
        }
    }
    
    @objc func userDidTapMapView(tapGesture: UITapGestureRecognizer) {
        let location: CGPoint = tapGesture.location(in: self.mapView)
        
        // Update place annotation
        if self.placeAnnotation == nil {
            self.placeAnnotation = MKPointAnnotation()
            self.mapView.addAnnotation(self.placeAnnotation)
        }
        
        self.placeAnnotation.coordinate = self.mapView.convert(location, toCoordinateFrom: self.mapView)
    }

    @IBAction func goToButtonTapped() {

        if self.placeAnnotation == nil {
            return
        }
        
        // Setup address search display
        self.displaySearchActivity(displayed: true)
        
        // Search for location address
        let placeLocaton = CLLocation(latitude: self.placeAnnotation.coordinate.latitude, longitude: self.placeAnnotation.coordinate.longitude)
        self.geocoder.reverseGeocodeLocation(placeLocaton) { [weak self] (placemarks, _) -> Void in
            if (self == nil) {
                return
            }

            self!.displaySearchActivity(displayed: false)

            if placemarks != nil && placemarks!.count > 0 {
                let place = MKPlacemark(placemark: placemarks![0]);

                DispatchQueue.main.async {
                    // Navigation app routing
                    // ----------------------
                    NavigationAppRouter.goToPlace(place, fromViewController: self!)
                }
            }
        }
    }

    @IBAction func gotToWithAddresButtonTapped(_ sender: UIButton) {
        guard addressTF.text?.count ?? 0 > 0 else{
             return
        }
        NavigationAppRouter.goToPlacefromASimpleAddress(address: addressTF.text!, fromViewController: self)
    }

}

// MARK: - CLLocationManager delegate

extension ViewController: CLLocationManagerDelegate {

    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if (status != CLAuthorizationStatus.notDetermined) {
            // Location manager instance not needed anymore
            self.locationManager = nil
        }
    }
}

// MARK: - MKMapView delegate

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        // Center map on user when his location is available
        if didInitialZoom == false  {
            if let userCoordinate: CLLocationCoordinate2D = userLocation.location?.coordinate {
                let region = MKCoordinateRegion(center: userCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
                didInitialZoom = true
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
}

// MARK: - UIGestureRecognizer delegate

extension ViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Discard touch if in annotation view
        if touch.view is MKAnnotationView {
            return false
        }
        return true
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
