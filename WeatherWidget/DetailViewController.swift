//
//  DetailViewController.swift
//  WeatherWidget
//
//  Created by Roham Akbari on 2017-08-22.
//  Copyright © 2017 bioDigits LTD. All rights reserved.
//

import UIKit

class ForecastCell: UITableViewCell {

    @IBOutlet weak var lblWeekday: UILabel!
    @IBOutlet weak var imgWeatherIcon: UIImageView!
    @IBOutlet weak var lblMin: UILabel!
    @IBOutlet weak var lblMax: UILabel!
    @IBOutlet weak var lblWeatherMain: UILabel!
    @IBOutlet weak var lblWind: UILabel!
    @IBOutlet weak var lblWindSpeed: UILabel!
    @IBOutlet weak var lblWindDirection: UILabel!
    
    var task: URLSessionDataTask?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        lblWind.text    =   NSLocalizedString(lblWind.text ?? "", comment: "")
    }
    // Make sure there is no left over task when cells are de-initialised
    deinit {
        if let tsk = task {
            tsk.cancel()
        }
    }

}

class DetailViewController: UIViewController {

    @IBOutlet weak var lblWeatherMain: UILabel!
    @IBOutlet weak var lblTemperature: UILabel!
    @IBOutlet weak var lblUnit: UILabel!
    @IBOutlet weak var lblWind: UILabel!
    @IBOutlet weak var lblWindSpeed: UILabel!
    @IBOutlet weak var lblWindDirection: UILabel!
    @IBOutlet weak var tbl: UITableView!

    let forecastCellId = "ForecastCell"
    var curIndex = 0
    var cities: [City]? {
        didSet {
            // Update the view.
            configureView()
        }
    }
    var latLon: LatLon? {
        didSet {
            // Update the view.
            configureView()
        }
    }

    /// Controller updates views
    func configureView() {
        // Update the user interface for the detail item.
        if let city = cities?[curIndex] {
            city.loadCurrentWeather {
                // In case user hits back button before this closure is called
                DispatchQueue.main.sync { [weak self] in
                    if let weakSelf = self {
                        weakSelf.navigationItem.title = city.name
                        weakSelf.lblWeatherMain?.text = city.WCur?.weatherMain
                        if let weatherDesc = city.WCur?.weatherDesc,
                            let text = weakSelf.lblWeatherMain?.text {
                            weakSelf.lblWeatherMain?.text = text + " - " + weatherDesc
                        }
                        weakSelf.lblTemperature?.text = String(format: "%.0f", city.WCur?.temperature ?? 0.0)
                        weakSelf.lblUnit?.text = City.isMetrics ? "º" : "F"
                        weakSelf.lblWindSpeed?.text = city.WCur?.fmtWindSpeed
                        weakSelf.lblWindDirection?.text = city.WCur?.fmtWindDir
                    }
                }
                // Now load the forecast
                city.load5DaysForecast {
                    DispatchQueue.main.sync { [weak self] in
                        if let weakSelf = self {
                            weakSelf.tbl.reloadData()
                        }
                    }
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tbl.layer.cornerRadius = 10.0
        tbl.layer.borderWidth = 1.0
        tbl.layer.borderColor = UIColor.darkGray.cgColor
        
        lblWind.text    =   NSLocalizedString(lblWind.text ?? "", comment: "")
        
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension DetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.cities?[curIndex].WForecast.count) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.forecastCellId) as! ForecastCell
        if let c = self.cities?[curIndex],
            indexPath.row < c.WForecast.count {
            let wf = c.WForecast[indexPath.row]
            cell.lblWeekday.text = wf.fmtDate
            //cell.imgWeatherIcon.image = icon
            cell.lblMin.text = String(format: "%.0f", wf.min)
            cell.lblMax.text = String(format: "%.0f", wf.max)
            cell.lblWeatherMain.text = wf.weatherMain + " " + wf.weatherDesc
            cell.lblWindSpeed.text = wf.fmtWindSpeed
            cell.lblWindDirection.text = wf.fmtWindDir
            
            cell.task = self.cities?[curIndex].loadImage(wf.weatherIcon, completionHandler: { image in
                if let image = image {
                    DispatchQueue.main.sync {
                        cell.imgWeatherIcon.image = image
                    }
                }
                cell.task = .none       //  nulify to know there is no task is running
            })
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if let cell = cell as? ForecastCell {
            if let task = cell.task {
                task.cancel()
                cell.task = .none
            }
        }
    }
}

