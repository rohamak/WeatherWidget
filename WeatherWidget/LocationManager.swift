//
//  LocationManager.swift
//  WeatherWidget
//
//  Created by Roham Akbari on 2017-08-27.
//  Copyright © 2017 bioDigits LTD. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

typealias LatLon = (lat: Double, lon: Double)

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    lazy var lm: CLLocationManager = {
        let l = CLLocationManager()
        l.delegate = self
        return l
    }()
    
    var curLocationHandler : ((_ error: String?, _ ll: LatLon?) -> Void)?
    let locRestrictionMsg = NSLocalizedString("Location Access Restricted", comment: "")
    
    override init() {
        super.init()
    }
    
    convenience init(_ lh: @escaping ((_ error: String?, _ ll: LatLon?) -> Void)) {
        
        self.init()
        self.curLocationHandler = lh
        self.getCurLocation()

    }
    
    func getCurLocation() {
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined {
            lm.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            lm.startUpdatingLocation()
        } else {
            let alert = UIAlertController(title: .none, message:
                locRestrictionMsg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: ""),
                                          style: .default) { [unowned self] action in
                                            if let url = URL(string: UIApplicationOpenSettingsURLString) {
                                                if UIApplication.shared.canOpenURL(url) {
                                                    UIApplication.shared.canOpenURL(url)
                                                }
                                            }
                                            if let lh = self.curLocationHandler {
                                                lh(self.locRestrictionMsg, .none)
                                            }
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                          style: .cancel) { [unowned self] action in
                                            if let lh = self.curLocationHandler {
                                                lh(self.locRestrictionMsg, .none)
                                            }
            })
            if let navC = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
                if let topVC = navC.topViewController {
                    topVC.present(alert, animated: true, completion: .none)
                }
            }
        }
    }
    
    func stopLocationManager() {
        self.lm.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            //loc.timestamp
            if loc.horizontalAccuracy >= 0 {
                if let lh = self.curLocationHandler {
                    lh(.none, (lat: loc.coordinate.latitude, lon: loc.coordinate.longitude))
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let lh = self.curLocationHandler {
            lh(error.localizedDescription, .none)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        } else {
            if let lh = self.curLocationHandler {
                lh(locRestrictionMsg, .none)
            }
        }
    }
}
