//
//  NavigationAppRouter.swift
//  Pods
//
//  Created by Florent Poisson on 11/01/2016.
//
//

import UIKit
import MapKit
import AddressBook

/// Third party navigation app list

private enum ThirdPartyNavigationApp {

    case GoogleMaps
    case Waze
    case CityMapper

    /**
     Get name string of third party navigation app.
     */
    func getName() -> String {
        switch self {
        case .GoogleMaps:
            return "Google Maps"

        case Waze:
            return "Waze"

        case CityMapper:
            return "CityMapper"
        }
    }
    
    /**
     Get third party navigation app URL scheme
     */
    func getUrlScheme() -> String {
        switch self {
        case .GoogleMaps:
            return "comgooglemaps://"

        case Waze:
            return "waze://"

        case CityMapper:
            return "citymapper://"
        }
    }
    
    /**
     Get third party navigation app URL scheme parameters requesting routing to a place.
     
        - Parameters:
            - location: the coordinates of the place to go (i.e. latitude & longitude)
     
        - Returns: the location parameters formated string
     
     */
    func getURLSchemeParametersForLocation(location: CLLocationCoordinate2D) -> String {
        switch self {
        case .GoogleMaps:
            return "?daddr=\(location.latitude),\(location.longitude)&directionsmode=driving"

        case Waze:
            return "?ll=\(location.latitude),\(location.longitude)&navigate=yes"

        case CityMapper:
            return "directions?endcoord=\(location.latitude),\(location.longitude)"
        }
    }
    
    /**
     Check if the third party app can be opened by the app.
     
        - Returns: true or false
     
     */
    func canOpen() -> Bool {
        return UIApplication.sharedApplication().canOpenURL(NSURL(string: self.getUrlScheme())!)
    }
    
    /**
     Open the correponding third party navigation requesting routing to a place.
     
        - Parameter place: destination as a placemark.
     
     */
    func goToPlace(place: MKPlacemark) {
        let urlStr = self.getUrlScheme() + self.getURLSchemeParametersForLocation(CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude))
        if let deepLinkUrl = NSURL(string: urlStr) {
            UIApplication.sharedApplication().openURL(deepLinkUrl)
        }
    }
    
    /**
     Get supported third party navigation apps installed on the device.
     
        - Returns: an array of the supported third party navigation apps.
     
     */
    static func getThirdPartyApplications() -> [ThirdPartyNavigationApp] {
        return [ThirdPartyNavigationApp.GoogleMaps, ThirdPartyNavigationApp.Waze, ThirdPartyNavigationApp.CityMapper]
    }
    
    
    /**
     Get supported third party navigation apps installation count.
     
        - Returns: installation count

     */
    static func getThirdPartyApplicationInstallations() -> Int {
        var count = 0
        
        for thirdPartyApp in ThirdPartyNavigationApp.getThirdPartyApplications() {
            if thirdPartyApp.canOpen() {
                ++count
            }
        }
        
        return count
    }
}

/// Navigation app router

public class NavigationAppRouter {
    
    /**
     Open navigation app selection menu.
     
        - Note: if no supported navigation app is installed, routing request is immediately handled by Maps.
     
        - Parameters:
     
            - place: destination as a placemark,
            - fromViewController: view controller presenting the navigation apps if needed.
     
     */
    public static func goToPlace(place: MKPlacemark, fromViewController viewController: UIViewController) {
        
        let thirdPartyApplicationInstallations = ThirdPartyNavigationApp.getThirdPartyApplicationInstallations()
        
        if thirdPartyApplicationInstallations > 0 {

            // Get bundle for localization strings
            let bundlePath: String! = NSBundle(forClass: NavigationAppRouter.self).pathForResource("NavigationAppRouter", ofType: "bundle")
            let bundle: NSBundle! = NSBundle(path: bundlePath)
            
            // Display action sheet
            let alertController = UIAlertController(title: NSLocalizedString("NavigationAppRouter.sheet.title", tableName: nil, bundle: bundle, comment: ""), message: nil, preferredStyle: .ActionSheet)
            
            // Default app navigation with Apple Plans
            let goWithPlans = UIAlertAction(title: "Plans", style: UIAlertActionStyle.Default) { (_) -> Void in
                NavigationAppRouter.goWithAppleMapsToPlace(place)
            }
            alertController.addAction(goWithPlans)
            
            // Third party navigation app management
            for thirdPartyApp in ThirdPartyNavigationApp.getThirdPartyApplications() {
                if thirdPartyApp.canOpen() {
                    let goWithThirdPartyApp = UIAlertAction(title: thirdPartyApp.getName(), style: UIAlertActionStyle.Default) { (_) -> Void in
                        thirdPartyApp.goToPlace(place)
                    }
                    alertController.addAction(goWithThirdPartyApp)
                }
            }
            
            let cancel = UIAlertAction(title: NSLocalizedString("NavigationAppRouter.button.title.cancel", tableName: nil, bundle: bundle, comment: ""), style: .Cancel, handler: nil)
            alertController.addAction(cancel)
            viewController.presentViewController(alertController, animated: true, completion: nil)
        }
        else {
            NavigationAppRouter.goWithAppleMapsToPlace(place)
        }
    }
    
    /**
     Open Maps requesting routing to the place.
     
        - Parameter place: the place to go.

     */
    private static func goWithAppleMapsToPlace(place: MKPlacemark) {
        // Current user location
        let itemUser = MKMapItem.mapItemForCurrentLocation()

        // Destination
        let itemPlace = MKMapItem(placemark: place)
        itemPlace.name = place.name

        let mapItems = [itemUser, itemPlace]
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsShowsTrafficKey: true]
        MKMapItem.openMapsWithItems(mapItems, launchOptions: options as? [String : AnyObject])
    }
    
}
