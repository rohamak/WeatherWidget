//
//  MasterViewController.swift
//  WeatherWidget
//
//  Created by Roham Akbari on 2017-08-22.
//  Copyright © 2017 bioDigits LTD. All rights reserved.
//

import UIKit

class MasterCellView: UITableViewCell {
    
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var btnFavorite: UIButton!
    
    var btnTintColor: UIColor = UIColor.darkGray
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setImageViewImage(_ image: UIImage) {
        let img = image.withRenderingMode(.alwaysTemplate)
        btnFavorite.setImage(img, for: .normal)
        btnFavorite.setImage(img, for: .selected)
    }
    
    func selectButton(selected: Bool = true) {
        MasterCellView.select(button: self.btnFavorite, withTint: self.btnTintColor, selected: selected)
    }
    
    static func select(button: UIButton, withTint: UIColor, selected: Bool = true) {
        button.isSelected = selected
        button.tintColor = selected ? withTint : UIColor.darkGray
    }
}

class MasterViewController: UITableViewController {

    @IBOutlet weak var sgmFilter: UISegmentedControl!
    
    enum Sections: Int {
        case coordinates, cityNames
    }
    
    var detailViewController: DetailViewController? = nil
    var allCities: Array<City> = {
        return City().loadCities()
    }()
    
    /// cities array contains filtered version of allCities for favorites
    lazy var cities: Array<City> = {
        return self.allCities
    }()
    
    var locationManager: LocationManager? = nil
    var latLon: LatLon?

    deinit {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillResignActive, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResign), name: .UIApplicationWillResignActive, object: nil)

        navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        for i in 0..<sgmFilter.numberOfSegments {
            sgmFilter.setTitle(NSLocalizedString(sgmFilter.titleForSegment(at: i) ?? "", comment: ""), forSegmentAt: i)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /// This will store unsaved data
    func applicationWillResign() {
        // Update the user defaults
        if cities.count > 0 {           //  To avoid creating an object if we have one in the array
            cities[0].storeCities(self.allCities)
        } else {
            City().storeCities(self.allCities)
        }
    }
    
    @IBAction func segFavarites(_ sender: UISegmentedControl) {

        if sender.selectedSegmentIndex == 0 {               //  0 is to show all cities
            self.cities = self.allCities
        } else if sender.selectedSegmentIndex == 1 {       //  1 is to show only favorites
            self.cities = self.allCities.filter( { item in
                return item.favorite
            })
        }
        self.tableView.reloadData()
    }

    func insertNewObject(_ sender: Any) {
        
        let alert = UIAlertController(title: NSLocalizedString("Search", comment: ""),
                                      message: NSLocalizedString("Enter City Name", comment: ""), preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("City Name", comment: "")
            textField.autocapitalizationType = .words
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .default, handler: { action  in
            if let text = alert.textFields?[0].text {
                let city = City(text)
                city.loadCurrentWeather { [unowned self] in
                    self.allCities.append(city)
                    self.cities.append(city)
                    DispatchQueue.main.sync {
                        self.tableView.reloadData()
                    }
                }
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func btnFavoritehandler(_ sender: UIButton) {
        
        let buttonPosition: CGPoint  = sender.convert(.zero, to: self.tableView)
        if let indexPath: NSIndexPath = self.tableView.indexPathForRow(at: buttonPosition) as NSIndexPath? {
            if let sc = Sections(rawValue: indexPath.section) {
                switch sc {
                case .coordinates:
                    if let lm = self.locationManager {
                        lm.stopLocationManager()
                        self.locationManager = nil
                        MasterCellView.select(button: sender, withTint: .blue, selected: false)
                    } else {
                        self.locationManager = LocationManager() { [unowned self] err, latLon in
                            if let ll = latLon {
                                self.latLon = ll
                                MasterCellView.select(button: sender, withTint: .blue, selected: true)
                            } else {
                                MasterCellView.select(button: sender, withTint: .blue, selected: false)
                                // Show error message
                                let alert = UIAlertController(title: .none, message:
                                    err ?? "Fatal Error", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: NSLocalizedString("Okay", comment: ""),
                                                              style: .cancel))
                                self.present(alert, animated: true, completion: .none)
                            }
                        }
                    }
                case .cityNames:
                    if cities[indexPath.row].favorite {
                        cities[indexPath.row].favorite = false
                        MasterCellView.select(button: sender, withTint: .orange, selected: false)
                    } else {
                        cities[indexPath.row].favorite = true
                        MasterCellView.select(button: sender, withTint: .orange, selected: true)
                    }
                }
            }
        }
    }
    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                //let object = cities[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                //controller.cities = object
                controller.curIndex = indexPath.row
                if let sc = Sections(rawValue: indexPath.section) {
                    switch sc {
                    case .coordinates:
                        if let ll = self.latLon {
                            controller.cities = [City(ll)]
                        }
                    case .cityNames:
                        controller.cities = self.cities
                    }
                }
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var retVal = 0
        if let sc = Sections(rawValue: section) {
            switch sc {
            case .coordinates:
                retVal = 1
            case .cityNames:
                retVal = cities.count
            }
        }
        return retVal
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MasterCellView

        if let sc = Sections(rawValue: indexPath.section) {
            switch sc {
            case .coordinates:
                cell.lblName.text = NSLocalizedString("Current Location", comment: "")
                cell.btnTintColor = .blue
                cell.setImageViewImage(#imageLiteral(resourceName: "location"))
                cell.selectButton(selected: locationManager != nil)
            case .cityNames:
                let aCity = cities[indexPath.row]
                cell.lblName.text = aCity.name
                cell.btnTintColor = .orange
                cell.setImageViewImage(#imageLiteral(resourceName: "star"))
                cell.selectButton(selected: aCity.favorite)
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {

        if let sc = Sections(rawValue: indexPath.section) {
            if sc == .coordinates && self.latLon == nil {
                return nil     //  should be disabled, user should activate location manager first
            }
        }
        return indexPath
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            cities.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

