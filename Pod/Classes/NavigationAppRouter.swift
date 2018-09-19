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

extension String {

    func getAddressUrlEncoded(usePlusSign: Bool) -> String? {
        if usePlusSign {
            let arrayOfComponents = self.split(separator: " ")
            let escapedAddress = arrayOfComponents.joined(separator: "+")
            return escapedAddress.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        } else {
            return self.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        }
    }
}
private enum ThirdPartyNavigationApp {

    case googleMaps
    case waze
    case cityMapper

    /**
     Get name string of third party navigation app.
     */
    func getName() -> String {
        switch self {
        case .googleMaps:
            return "Google Maps"

        case .waze:
            return "Waze"

        case .cityMapper:
            return "CityMapper"
        }
    }
    
    /**
     Get third party navigation app URL scheme
     */
    func getUrlScheme() -> String {
        switch self {
        case .googleMaps:
            return "comgooglemaps://"

        case .waze:
            return "waze://"

        case .cityMapper:
            return "citymapper://"
        }
    }
    
    /**
     Get third party navigation app URL scheme parameters requesting routing to a place.
     
        - Parameters:
            - location: the coordinates of the place to go (i.e. latitude & longitude)
     
        - Returns: the location parameters formated string
     
     */
    func getURLSchemeParametersForLocation(_ location: CLLocationCoordinate2D) -> String {
        switch self {
        case .googleMaps:
            return "?daddr=\(location.latitude),\(location.longitude)&directionsmode=driving"

        case .waze:
            return "?ll=\(location.latitude),\(location.longitude)&navigate=yes"

        case .cityMapper:
            return "directions?endcoord=\(location.latitude),\(location.longitude)"
        }
    }

    func getURLSchemeParametersForAddress(_ address: String) -> String {
        switch self {
        case .googleMaps:
            return "?q=" + (address.getAddressUrlEncoded(usePlusSign: true) ?? "")
        case .waze:
            return "?q=" + (address.getAddressUrlEncoded(usePlusSign: false) ?? "")
        default:
            return ""
        }
    }
    
    /**
     Check if the third party app can be opened by the app.
     
        - Returns: true or false
     
     */
    func canOpen() -> Bool {
        return UIApplication.shared.canOpenURL(URL(string: self.getUrlScheme())!)
    }
    
    /**
     Open the correponding third party navigation requesting routing to a place.
     
        - Parameter place: destination as a placemark.
     
     */
    func goToPlace(_ place: MKPlacemark) {
        let urlStr = self.getUrlScheme() + self.getURLSchemeParametersForLocation(CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude))
        if let deepLinkUrl = URL(string: urlStr) {
            UIApplication.shared.openURL(deepLinkUrl)
        }
    }
    /**
     Open the correponding third party navigation requesting searching for an address.

     - Parameter address: destination as an address.

     */
    func goToAddress(_ address: String) {
        let urlStr = self.getUrlScheme() + self.getURLSchemeParametersForAddress(address)
        if let deepLinkUrl = URL(string: urlStr) {
            UIApplication.shared.openURL(deepLinkUrl)
        }
    }

    /**
     Get supported third party navigation apps installed on the device.
     
        - Returns: an array of the supported third party navigation apps.
     
     */
    static func getThirdPartyApplications() -> [ThirdPartyNavigationApp] {
        return [ThirdPartyNavigationApp.googleMaps, ThirdPartyNavigationApp.waze, ThirdPartyNavigationApp.cityMapper]
    }
    
    
    /**
     Get supported third party navigation apps installation count.
     
        - Returns: installation count

     */
    static func getThirdPartyApplicationInstallations() -> Int {
        var count = 0
        
        for thirdPartyApp in ThirdPartyNavigationApp.getThirdPartyApplications() {
            if thirdPartyApp.canOpen() {
                count += 1
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
    public static func goToPlace(_ place: MKPlacemark, fromViewController viewController: UIViewController) {
        
        let thirdPartyApplicationInstallations = ThirdPartyNavigationApp.getThirdPartyApplicationInstallations()
        
        if thirdPartyApplicationInstallations > 0 {

            // Get bundle for localization strings
            let bundlePath: String! = Bundle(for: NavigationAppRouter.self).path(forResource: "NavigationAppRouter", ofType: "bundle")
            let bundle: Bundle! = Bundle(path: bundlePath)
            
            // Display action sheet
            let alertController = UIAlertController(title: NSLocalizedString("NavigationAppRouter.sheet.title", tableName: nil, bundle: bundle, comment: ""), message: nil, preferredStyle: .actionSheet)
            
            // Default app navigation with Apple Plans
            let goWithPlans = UIAlertAction(title: "Plans", style: UIAlertActionStyle.default) { (_) -> Void in
                NavigationAppRouter.goWithAppleMapsToPlace(place)
            }
            alertController.addAction(goWithPlans)
            
            // Third party navigation app management
            for thirdPartyApp in ThirdPartyNavigationApp.getThirdPartyApplications() {
                if thirdPartyApp.canOpen() {
                    let goWithThirdPartyApp = UIAlertAction(title: thirdPartyApp.getName(), style: UIAlertActionStyle.default) { (_) -> Void in
                        thirdPartyApp.goToPlace(place)
                    }
                    alertController.addAction(goWithThirdPartyApp)
                }
            }
            
            let cancel = UIAlertAction(title: NSLocalizedString("NavigationAppRouter.button.title.cancel", tableName: nil, bundle: bundle, comment: ""), style: .cancel, handler: nil)
            alertController.addAction(cancel)
            viewController.present(alertController, animated: true, completion: nil)
        }
        else {
            NavigationAppRouter.goWithAppleMapsToPlace(place)
        }
    }

    public static func goToPlacefromASimpleAddress(address: String, fromViewController viewController: UIViewController) {
        let thirdPartyApplicationInstallations = ThirdPartyNavigationApp.getThirdPartyApplicationInstallations()
        if thirdPartyApplicationInstallations > 0 {
            let bundlePath: String! = Bundle(for: NavigationAppRouter.self).path(forResource: "NavigationAppRouter", ofType: "bundle")
            let bundle: Bundle! = Bundle(path: bundlePath)

            // Display action sheet
            let alertController = UIAlertController(title: NSLocalizedString("NavigationAppRouter.sheet.title", tableName: nil, bundle: bundle, comment: ""), message: nil, preferredStyle: .actionSheet)

            // Default app navigation with Apple Plans
            let goWithPlans = UIAlertAction(title: "Plans", style: UIAlertActionStyle.default) { (_) -> Void in
                NavigationAppRouter.goWithAppleMapsToAddress(address)
            }
            alertController.addAction(goWithPlans)

            for thirdPartyApp in ThirdPartyNavigationApp.getThirdPartyApplications() {
                if thirdPartyApp.canOpen() {
                    let goWithThirdPartyApp = UIAlertAction(title: thirdPartyApp.getName(), style: UIAlertActionStyle.default) { (_) -> Void in
                        thirdPartyApp.goToAddress(address)
                    }
                    alertController.addAction(goWithThirdPartyApp)
                }
            }

            let cancel = UIAlertAction(title: NSLocalizedString("NavigationAppRouter.button.title.cancel", tableName: nil, bundle: bundle, comment: ""), style: .cancel, handler: nil)
            alertController.addAction(cancel)
            viewController.present(alertController, animated: true, completion: nil)
        } else {
            NavigationAppRouter.goWithAppleMapsToAddress(address)
        }
    }
    
    /**
     Open Maps requesting routing to the place.
     
        - Parameter place: the place to go.

     */
    private static func goWithAppleMapsToPlace(_ place: MKPlacemark) {
        // Current user location
        let itemUser = MKMapItem.forCurrentLocation()

        // Destination
        let itemPlace = MKMapItem(placemark: place)
        itemPlace.name = place.name

        let mapItems = [itemUser, itemPlace]
        let options: [String : Any] = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsShowsTrafficKey: true]
        MKMapItem.openMaps(with: mapItems, launchOptions: options)
    }

    private static func goWithAppleMapsToAddress(_ address: String) {
        guard let urlEscapedAddress = address.getAddressUrlEncoded(usePlusSign: true),
            let url = URL(string: "http://maps.apple.com/?address=" + urlEscapedAddress),
            UIApplication.shared.canOpenURL(url) else {
                return
        }
        UIApplication.shared.openURL(url)
    }

}
