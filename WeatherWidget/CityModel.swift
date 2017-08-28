//
//  CitiesModel.swift
//  WeatherWidget
//
//  Created by Roham Akbari on 2017-08-22.
//  Copyright © 2017 bioDigits LTD. All rights reserved.
//

import Foundation
import UIKit

struct WeatherCond {
    /// Date of this weather structure in absolute UNIX
    var dt: TimeInterval = 0 {
        didSet {
            let aDate = Date(timeIntervalSince1970: dt)
            let dateFormatter = DateFormatter()
            // "E, MMM d"  : Mon, Aug 12
            dateFormatter.dateFormat = "E, MMM d"  // Monday ( Full weekday names ) EEEE
            self.fmtDate = dateFormatter.string(from: aDate)
        }
    }
    var temperature: Float = 0.0
    var min: Float = 0.0
    var max: Float = 0.0
    var windSpeed: Float = 0.0 {
        didSet {
            self.fmtWindSpeed = String(format: "%.1f", windSpeed)
            if City.isMetrics {
                self.fmtWindSpeed += " Km/h"
            } else {
                self.fmtWindSpeed += " Mi/h"
            }
        }
    }
    var windDirection: Float = 0.0 {
        // Store the formatted value of wind direction
        didSet {
            if windDirection >= 337.5 || windDirection < 22.5 { self.fmtWindDir = "N" }
            else if windDirection >= 22.5 && windDirection < 67.5 { self.fmtWindDir = "NE" }
            else if windDirection >= 67.5 && windDirection < 112.5 { self.fmtWindDir = "E" }
            else if windDirection >= 112.5 && windDirection < 157.5 { self.fmtWindDir = "SE" }
            else if windDirection >= 157.5 && windDirection < 202.5 { self.fmtWindDir = "S" }
            else if windDirection >= 202.5 && windDirection < 247.5 { self.fmtWindDir = "SW" }
            else if windDirection >= 247.5 && windDirection < 292.5 { self.fmtWindDir = "W" }
            else if windDirection >= 292.5 && windDirection < 337.5 { self.fmtWindDir = "NW" }
        }
    }
    var pressure: Float = 0.0
    var humidity: Float = 0.0
    var weatherMain: String = ""
    var weatherDesc: String = ""
    var weatherIcon: String = ""
    // Formated data
    var fmtDate: String = ""
    var fmtWindDir: String = ""
    var fmtWindSpeed: String = ""
}

typealias DicReg = Dictionary<String, Any>
/// Class to wrap city entity, for which weather should be retrieved
class City : DataTransport {

    /// Name of the city this object is referring to
    var latLon: LatLon?
    var name: String?
    var id: Int?
    var favorite: Bool = false
    let strUrlForecast = "http://api.openweathermap.org/data/2.5/forecast/daily?id=%@&APPID=%@"
    let strUrlCurW     = "http://api.openweathermap.org/data/2.5/find?q=%@&type=like&APPID=%@"
    let strUrlCurWLL   = "http://api.openweathermap.org/data/2.5/weather?lat=%.4f&lon=%.4f&APPID=%@"
    let strUrlIcon     = "http://openweathermap.org/img/w/%@.png"
    var WCur: WeatherCond?
    var WForecast: Array<WeatherCond> = []
    
    var task: (AnyObject & DataTask)?
    
    override init() {
        //self.name = ""
        self.id = 0
        super.init()
    }
    convenience init(_ name: String) {
        self.init()
        self.name = name
    }
    
    convenience init(_ latLon: LatLon) {
        self.init()
        self.latLon = latLon
    }
    
    /// Converts array of value data types into class objects
    ///
    /// - Returns: Array of City class objects
    func loadCities() -> Array<City> {
        var arCities = [City]()
        let arRawCities = super.loadCities()
        for item in arRawCities {
            let aCity: City?
            if let nm = item["name"] as? String {
                aCity = City(nm)
                if let fv = item["favorite"] as? Bool {
                    aCity?.favorite = fv
                }
                arCities.append(aCity!)
            }
        }
        return arCities
    }
    
    /// Converts class object into storable value data types
    ///
    /// - Parameter cities: Array of City objects
    func storeCities(_ cities: Array<City>) {
        var arCities = [DicReg]()
        for aCity in cities {
            arCities.append(["name": aCity.name ?? "", "favorite": aCity.favorite])
        }
        super.storeCities(arCities)
    }
    
    func loadCurrentWeather(_ completionHandler: @escaping () -> Void) {
        if let name = self.name?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            
            let strUrl = String(format: strUrlCurW, name , self.apiKey)
            self.loadCW(strUrl, completionHandler)

        } else if let ll = latLon {

            let strUrl = String(format: strUrlCurWLL, ll.lat, ll.lon , self.apiKey)
            self.loadCW(strUrl, completionHandler)

        } else {
            self.errors.append("City name is blank")
            completionHandler()         //  let the UI update itself
        }
    }
    
    func loadCW(_ strUrl: String, _ completionHandler: @escaping () -> Void) {

        self.loadJSONData(strUrl, []) { [unowned self] dic in
            if let dic = dic as? DicReg,
                let list = dic["list"] as? Array<Any>,
                list.count > 0,
                let item = list[0] as? DicReg {
                var wc = WeatherCond()
                
                if let id = item["id"] as? Int { self.id = id }
                if let name = item["name"] as? String { self.name = name }  //  Get the properly formatted name
                
                // The following is for populating the Weather structure
                if let dt = item["dt"] as? TimeInterval { wc.dt = dt }
                if let main = item["main"] as? DicReg {
                    if let temp = main["temp"] as? Float { wc.temperature = temp }
                    if let pressure = main["pressure"] as? Float { wc.pressure = pressure }
                    if let humidity = main["humidity"] as? Float { wc.humidity = humidity }
                    if let min = main["temp_min"] as? Float { wc.min = min }
                    if let max = main["temp_max"] as? Float { wc.max = max }
                }
                if let wind = item["wind"] as? DicReg {
                    if let speed = wind["speed"] as? Float { wc.windSpeed = speed }
                    if let deg = wind["deg"] as? Float { wc.windDirection = deg }
                }
                if let weatherList = item["weather"] as? Array<Any>,
                    weatherList.count > 0,
                    let weather = weatherList[0] as? DicReg {
                    if let main = weather["main"] as? String { wc.weatherMain = main }
                    if let description = weather["description"] as? String { wc.weatherDesc = description }
                    if let icon = weather["icon"] as? String { wc.weatherIcon = icon }
                }
                self.WCur = wc
            }
            completionHandler()     //  let the UI update itself
        }
    }
    
    func load5DaysForecast(_ completionHandler: @escaping () -> Void) {

        if let i = self.id {
            let strUrl = String(format: strUrlForecast, String(i), self.apiKey)
            self.loadJSONData(strUrl, []) { [weak self] dic in
                if let dic = dic as? DicReg,
                    let list = dic["list"] as? Array<Any>,
                    list.count > 0 {
                    self?.WForecast = []
                    for itm in list {
                        if let item = itm as? DicReg {
                            var wc = WeatherCond()
                            // The following is for populating the Weather structure
                            // Only add forecast days ahead of today
                            if let dt = item["dt"] as? TimeInterval,
                                let dt1 = self?.WCur?.dt,
                                dt > dt1 {
                                wc.dt = dt
                                if let pressure = item["pressure"] as? Float { wc.pressure = pressure }
                                if let humidity = item["humidity"] as? Float { wc.humidity = humidity }
                                if let speed = item["speed"] as? Float { wc.windSpeed = speed }
                                if let deg = item["deg"] as? Float { wc.windDirection = deg }
                                if let temp = item["temp"] as? DicReg {
                                    if let day = temp["day"] as? Float { wc.temperature = day }
                                    if let min = temp["min"] as? Float { wc.min = min }
                                    if let max = temp["max"] as? Float { wc.max = max }
                                }
                                if let weatherList = item["weather"] as? Array<Any>,
                                    weatherList.count > 0,
                                    let weather = weatherList[0] as? DicReg {
                                    if let main = weather["main"] as? String { wc.weatherMain = main }
                                    if let description = weather["description"] as? String { wc.weatherDesc = description }
                                    if let icon = weather["icon"] as? String { wc.weatherIcon = icon }
                                }
                                self?.WForecast.append(wc)
                            }
                        }
                    }
                }
                completionHandler()     //  let the UI update itself
            }
        } else {
            self.errors.append("City id is blank")
            completionHandler()         //  let the UI update itself
        }
        
    }
    
    override func loadImage(_ imageName: String, completionHandler: @escaping (_ img: UIImage?) -> Void) -> URLSessionDataTask {
        
        let strUrl = String(format: strUrlIcon, imageName)

        let task = super.loadImage(strUrl, completionHandler: completionHandler)
        
        return task
    }
    
}
