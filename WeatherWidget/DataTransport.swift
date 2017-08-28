//
//  DataTransport.swift
//  WeatherWidget
//
//  Created by Roham Akbari on 2017-08-22.
//  Copyright © 2017 bioDigits LTD. All rights reserved.
//

import Foundation
import UIKit

protocol DataTask {
    func cancelTask()
}

extension URLSessionDataTask: DataTask {
    func cancelTask() {
        self.cancel()
    }
}

class DataTransport {
    
    /// Intermediate variable for dependency injection
    var innerUserDefaults: UserDefaults?
    private lazy var userDefaults: UserDefaults = {
        if self.innerUserDefaults == .none {
            self.innerUserDefaults = UserDefaults.standard
        }
        return self.innerUserDefaults! ;
    }()
    
    static let lang: String = {
        var retVal = "en"
        if let l = NSLocale.current.languageCode {
            retVal = l
        }
        return retVal
    }()

    static let isMetrics: Bool = {
        return DataTransport.units == "metric"
    }()
    
    static let units: String = {
        var retVal = "metric"
        if !NSLocale.current.usesMetricSystem {
            retVal = "imperial"
        }
        return retVal
    }()

    let citiesTable = "Cities"
    let apiKey = "58d58b185631f850edc5928ed7a690d7"
    var errors: Array<Any> = []
    
    func loadCities() -> Array<Dictionary<String, Any>> {
        var retVal = [Dictionary<String, Any>]()
        if let cities = (userDefaults.object(forKey: citiesTable) as? Array<Dictionary<String, Any>>),
            cities.count > 0 {
            retVal = cities
        } else {
            retVal = [["name" : "Las Vegas"]]
        }
        return retVal
    }
    
    func storeCities(_ cities: Array<Dictionary<String, Any>>) {
        userDefaults.set(cities, forKey: citiesTable)
        userDefaults.synchronize()
    }
    
    func addUrlLocalizations( _ urlString: String) -> String {
        var retVal = urlString
        retVal = retVal.appendingFormat("&units=%@&lang=%@", DataTransport.units, DataTransport.lang)
        return retVal
    }
    
    /// Loads JSON data from a url, traversing the returned dictionary
    ///
    /// - Parameters:
    ///   - fromUrl: The url to load JSON data from
    ///   - nodePath: The path should be traversed to the interested node in the Dictionary
    func loadJSONData(_ fromUrlString: String, _ nodePath: Array<String>, completionHandler: @escaping (_ dic: Any) -> Void) {

        let urlString = self.addUrlLocalizations(fromUrlString)

        URLSession.shared.dataTask(with: URL(string: urlString)!, completionHandler: {  [weak self] (data, response, error) -> Void  in
            
            if let weakSelf = self {
                if let err = error {
                    weakSelf.errors.append(err)
                } else if let dt = data {
                    do {
                        let dic = try JSONSerialization.jsonObject(with: dt, options: .mutableLeaves)
                        completionHandler(dic)
                    } catch  {
                        weakSelf.errors.append(error)
                        completionHandler([:])
                    }
                }
            }
        }).resume()
    }
    
    func loadImage(_ fromUrlString: String, completionHandler: @escaping (_ img: UIImage?) -> Void) -> URLSessionDataTask {
        
        let task = URLSession.shared.dataTask(with: URL(string: fromUrlString)!, completionHandler: { [unowned self] (data, response, error) in

            if let err = error {
                self.errors.append(err)
                completionHandler(.none)
            } else if let dt = data {
                let img = UIImage(data: dt)
                completionHandler(img)
            }
        })
        task.resume()
        
        return task
    }
    
    /// Parses a dictionary to a node recursively
    ///
    /// - Parameters:
    ///   - dic: The dictionary to be traversed
    ///   - nodePath: The path of node that should be traversed
    /// - Returns: returne's either the value of final node in the nodePath a dictionary or an array
    func parseDic(_ dic: Any, _ nodePath: Array<String>) -> Any {
        
        var nodePath = nodePath
        var retVal: Any? = .none
        
        if dic is Dictionary<AnyHashable, Any>,
            nodePath.count > 0 {
            if let obj = (dic as! Dictionary<AnyHashable, Any>)[nodePath[0]] {
                nodePath.removeFirst()                      //  Recursive call
                retVal = self.parseDic(obj, nodePath)
            } else {                                        //  next node not found
                retVal = [:]
            }
        } else {                                            //  we have hit an array so return it
            retVal = dic
        }
        return retVal!
    }
}
