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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let img = btnFavorite.imageView?.image?.withRenderingMode(.alwaysTemplate)
        btnFavorite.setImage(img, for: .normal)
        btnFavorite.setImage(img, for: .selected)
    }
}

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var allCities: Array<City> = {
        return City().loadCities()
    }()
    
    /// cities array contains filtered version of allCities for favorites
    lazy var cities: Array<City> = {
        return self.allCities
    }()

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

        let alert = UIAlertController(title: "Search", message: "Enter City Name", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "City Name"
            textField.autocapitalizationType = .words
        })
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { action  in
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
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func btnFavoritehandler(_ sender: UIButton) {
        
        let buttonPosition: CGPoint  = sender.convert(.zero, to: self.tableView)
        if let indexPath: NSIndexPath = self.tableView.indexPathForRow(at: buttonPosition) as NSIndexPath? {
            if cities[indexPath.row].favorite {
                cities[indexPath.row].favorite = false
                sender.isSelected = false
                sender.imageView?.tintColor = UIColor.darkGray
            } else {
                cities[indexPath.row].favorite = true
                sender.isSelected = true
                sender.imageView?.tintColor = UIColor.orange
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
                controller.cities = self.cities
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MasterCellView

        let aCity = cities[indexPath.row]
        cell.lblName.text = aCity.name
        cell.btnFavorite.isSelected = aCity.favorite
        if aCity.favorite {
            cell.btnFavorite.imageView?.tintColor = UIColor.orange
        } else {
            cell.btnFavorite.imageView?.tintColor = UIColor.darkGray
        }
        return cell
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

