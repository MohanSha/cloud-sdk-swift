//
//  CoffeesViewController.swift
//  KenticoCloud
//
//  Created by Martin Makarsky on 31/08/2017.
//  Copyright © 2017 Kentico Software. All rights reserved.
//

import UIKit
import KenticoCloud

class CoffeesViewController: ListingBaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Properties
    
    private let contentType = "coffee"
    private var coffees: [Coffee] = []
    private var screenName = "CoffeesView"
    
    @IBOutlet var tableView: UITableView!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.set(kGAIScreenName, value: self.screenName)
        
        guard let builder = GAIDictionaryBuilder.createScreenView().set(self.screenName, forKey: kGAIScreenName) else { return}
        tracker.send(builder.build() as [NSObject : AnyObject])
        
        guard let eventBuilder = GAIDictionaryBuilder.createEvent(withCategory: "screen", action: "view", label: self.screenName, value: nil) else { return}
        tracker.send(eventBuilder.build() as [NSObject : AnyObject])
        
        if coffees.count == 0 {
            getCoffees()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Delegates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coffees.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "coffeeCell") as! CoffeeTableViewCell
        
        let coffee = coffees[indexPath.row]
        
        cell.title.text = coffee.name?.value
        if let description = coffee.shortDescription?.htmlContentString {
            cell.coffeeDescription.styleWithRichtextString(richtextString: description)
        }
        
        if let price = coffee.price?.value {
            cell.price.text = "$ \(price) / 1lb"
        }
        
        if !((coffee.processing?.value?.isEmpty)!) {
            if let processingTechnique = coffee.processing?.value?[0].name {
                cell.processing.text = processingTechnique
            }
        }
        
        if let assets = coffee.image?.value {
            if assets.count > 0 {
                let url = URL(string: assets[0].url!)
                cell.photo.af_setImage(withURL: url!)
            } else {
                cell.photo.image = UIImage(named: "noContent")
            }
        } else {
            cell.photo.image = UIImage(named: "noContent")
        }
        
        if (coffee.promotion?.containsCodename(codename: "featured"))! {
            cell.featured.isHidden = false
        } else {
            cell.featured.isHidden = true
        }
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "coffeeDetailSegue" {
            
            let coffeeDetailViewController = segue.destination
                as! CoffeeDetailViewController
            
            let indexPath = self.tableView.indexPathForSelectedRow!
            coffeeDetailViewController.coffee = coffees[indexPath.row]
            
            _ = self.tableView.cellForRow(at: indexPath) as! CoffeeTableViewCell
        }
        
        if let index = self.tableView.indexPathForSelectedRow{
            self.tableView.deselectRow(at: index, animated: true)
        }
    }
    
    // MARK: Outlet actions
    
    @IBAction func refreshTable(_ sender: Any) {
        getCoffees()
    }
    
    // MARK: Getting items
    
    private func getCoffees() {
        self.showLoader(message: "Loading coffees...")
        
        let contentTypeQueryParameters = [QueryParameter.init(parameterKey: QueryParameterKey.type, parameterValue: contentType)].addSampleSiteParameter()
        
        DeliveryManager.shared.deliveryClient.getItems(modelType: Coffee.self, queryParameters: contentTypeQueryParameters) { (isSuccess, itemsResponse, error) in
            if isSuccess {
                if let coffees = itemsResponse?.items {
                    
                    // Order coffees - with promotion (aka featured) first
                    self.coffees = coffees.sorted { ($0.promotion!.containsCodename(codename: "featured")) && (!$1.promotion!.containsCodename(codename: "featured")) }
                    self.tableView.reloadData()
                }
            } else {
                if let error = error {
                    print(error)
                }
            }
            
            DispatchQueue.main.async {
                self.finishLoadingItems()
            }
        }
    }
    
    func finishLoadingItems() {
        self.hideLoader()
        self.tableView.refreshControl?.endRefreshing()
        UIView.animate(withDuration: 0.3, animations: {
            self.tableView.contentOffset = CGPoint.zero
        })
    }
}
