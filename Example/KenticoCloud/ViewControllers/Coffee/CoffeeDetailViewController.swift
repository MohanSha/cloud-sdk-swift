//
//  CoffeeDetailViewController.swift
//  KenticoCloud
//
//  Created by Martin Makarsky on 31/08/2017.
//  Copyright © 2017 Kentico Software. All rights reserved.
//

import UIKit
import KenticoCloud

class CoffeeDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Properties
    
    var coffee: Coffee!
    
    private var callToAction: CallToAction?
    private var selectedCafes: [Cafe?] = []
    
    @IBOutlet var backButton: UIButton!
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var price: UILabel!
    @IBOutlet var farm: UILabel!
    @IBOutlet var variety: UILabel!
    @IBOutlet var processing: UILabel!
    @IBOutlet var altitude: UILabel!
    @IBOutlet var coffeeImage: UIImageView!
    
    @IBOutlet var ctaView: UIView!
    @IBOutlet var callToActionButton: UIButton!
    @IBOutlet var ctaImage: UIImageView!
    @IBOutlet var ctaSubtitle: UILabel!
    @IBOutlet var ctaTitle: UILabel!
    private var screenName = "CoffeeDetailView"
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.set(kGAIScreenName, value: self.screenName)
        
        guard let builder = GAIDictionaryBuilder.createScreenView().set(self.screenName, forKey: kGAIScreenName) else { return}
        tracker.send(builder.build() as [NSObject : AnyObject])
        
        guard let eventBuilder = GAIDictionaryBuilder.createEvent(withCategory: "screen", action: "view", label: self.screenName, value: nil) else { return}
        tracker.send(eventBuilder.build() as [NSObject : AnyObject])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        ctaView.removeFromSuperview()
        callToActionButton.stylePinkButton()
        backButton.stylePinkButton()
        
        setContent()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Delegates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "coffeeDescriptionCell") as! CoffeeDescriptionViewCell
        cell.coffeeDescription.styleWithRichtextString(richtextString: (coffee.longDescription?.htmlContentString)!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 1000
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension;
    }
    
    // MARK: Outlet actions
    
    @IBAction func navigateBack(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    // MARK: Behaviour
    
    /// Updates Call to Action view if there is cto AND selected cafes
    private func tryToUpdateCallToActionView() {
        if let titleText = self.callToAction?.actionButtonText?.value {
            if selectedCafes.count > 0 {
                callToActionButton.setTitle(titleText, for: .normal)
                
                if let imageUrl = callToAction?.image?.value?[0].url {
                    let url = URL(string: imageUrl)
                    ctaImage.af_setImage(withURL: url!)
                }
                
                ctaSubtitle.text = callToAction?.shortText?.value
                ctaTitle.text = callToAction?.title?.value
                
                tableView.addSubview(ctaView)
            }
        }
    }
    
    private func setContent() {
        if let callToActionNames = coffee.callToActions?.value {
            getCoffeeEnthusiastCta(callToActionNames: callToActionNames)
        }
        
        if let price = coffee.price?.value {
            self.price.text = "$\(price) / 1lb"
        }
        self.farm.text = coffee.farm?.value
        
        self.variety.text = coffee.variety?.value
        
        if !((coffee.processing?.value?.isEmpty)!) {
            if let processingTechnique = coffee.processing?.value?[0].name {
                self.processing.text = processingTechnique
            }
        }
        
        if let altitude = coffee.altitude?.value {
            self.altitude.text = "\(altitude) ft"
        }

        if let assets = coffee.image?.value {
            if assets.count > 0 {
                let url = URL(string: assets[0].url!)
                coffeeImage.af_setImage(withURL: url!)
            } else {
                coffeeImage.image = UIImage(named: "noContent")
            }
        } else {
            coffeeImage.image = UIImage(named: "noContent")
        }
    }
    
    // MARK: Getting items
    
    /// Get Call to Action for Coffee enthusiast persona only
    private func getCoffeeEnthusiastCta(callToActionNames: [String?]) {
        
        for callToActionName in callToActionNames {
            if let ctoName = callToActionName {
                let client = DeliveryClient.init(projectId: AppConstants.getProjectId())
                let customQuery = QueryStringParameter.addSampleSiteQueryStringParameter(param: "/items/\(ctoName)/")
                client.getItem(modelType: CallToAction.self, customQuery: customQuery, completionHandler: {isSuccess, itemResponse, error in
                    if isSuccess {
                        if let cto = itemResponse?.item {
                            if (cto.persona?.containsName(name: "Coffee enthusiast"))! {
                                self.callToAction = cto
                                self.tryToUpdateCallToActionView()
                            }
                        }
                    } else {
                        print("Error while getting CTOs. Error: \(String(describing: error))")
                    }
                })
            }
        }
        
        /// Get SelectedCafes
        let client = DeliveryClient.init(projectId: AppConstants.getProjectId())
        let customQuery = QueryStringParameter.addSampleSiteQueryStringParameter(param: "items/cafes_in_your_area/")
        client.getItem(modelType: SelectedCafes.self, customQuery: customQuery, completionHandler: {isSuccess, itemResponse, error in
            if isSuccess {
                var cafes : [Cafe?] = []
                
                for cafeCodeName in (itemResponse?.item?.handpickedCafes?.value)! {
                    let selectedCafe = itemResponse?.getModularContent(codename: cafeCodeName, type: Cafe.self)
                    cafes.append(selectedCafe)
                    self.selectedCafes = cafes
                    
                    self.selectedCafes = cafes as! [Cafe]
                    self.tryToUpdateCallToActionView()
                }
            } else {
                print("Error while getting CTOs. Error: \(String(describing: error))")
            }
        })
    }
}
