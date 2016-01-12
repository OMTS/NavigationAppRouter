# NavigationAppRouter

[![CI Status](http://img.shields.io/travis/fpoisson/NavigationAppRouter.svg?style=flat)](https://travis-ci.org/fpoisson/NavigationAppRouter)
[![Version](https://img.shields.io/cocoapods/v/NavigationAppRouter.svg?style=flat)](http://cocoapods.org/pods/NavigationAppRouter)
[![License](https://img.shields.io/cocoapods/l/NavigationAppRouter.svg?style=flat)](http://cocoapods.org/pods/NavigationAppRouter)
[![Platform](https://img.shields.io/cocoapods/p/NavigationAppRouter.svg?style=flat)](http://cocoapods.org/pods/NavigationAppRouter)

## Overview

NavigationAppRouter is a class, written in Swift, that allows user to choose his prefered navigation app to go to a place.

Third party navigation apps supported:
	 - Google Maps,
	 - Waze,
	 - Citymapper.

## Usage

```Swift
import NavigationAppRouter

let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 48.867460, longitude: 2.346767), addressDictionary: nil)

NavigationAppRouter.goToPlace(placemark, fromViewController: viewController)
```

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

* iOS8

## Installation

NavigationAppRouter is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "NavigationAppRouter"
```

## Author

fpoisson, fpoissonfr@yahoo.fr

## License

NavigationAppRouter is available under the MIT license. See the LICENSE file for more info.
