//
//  CafeDetailViewController.swift
//  KenticoCloud
//
//  Created by Martin Makarsky on 17/08/2017.
//  Copyright © 2017 Kentico Software. All rights reserved.
//

import UIKit
import MapKit
import KenticoCloud

class CafeDetailViewController: UIViewController {
    
    // MARK: Properties
    
    var cafe: Cafe?
    var image: UIImage?
    private var screenName = "CafeDetailViewController"
    
    @IBOutlet var name: UILabel!
    @IBOutlet var email: UILabel!
    @IBOutlet weak var city: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var phone: UILabel!
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var map: MKMapView?
    @IBOutlet var backButton: UIButton!
    
    // MARK: VC lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        backButton.stylePinkButton()
        SetContent()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Outlet actions
    
    @IBAction func navigateBack(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    // MARK: Behaviour
    
    private func SetContent() {
        if let cafe = cafe {
            name.text = cafe.name
            city.text = cafe.city
            address.text = "\(cafe.street ?? "") \(cafe.city ?? "")"
            phone.text = cafe.phone
            email.text = cafe.email
            setImages()
            setMap(cafe: cafe)
        }
    }
    
    private func setMap(cafe: Cafe) {
        let address = "\(cafe.street ?? "")  \(cafe.state ?? "") \(cafe.country ?? "")  \(cafe.zip ?? "")"
        
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { (placemarks, error) in
            guard
                let placemarks = placemarks,
                let location = placemarks.first?.location
                else {
                    // handle no location found
                    return
            }
            
            let pinPoint = MKPointAnnotation()
            pinPoint.coordinate = location.coordinate
            pinPoint.title = cafe.name
            self.map?.addAnnotation(pinPoint)
            
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
            self.map?.setRegion(region, animated: true)
        }
    }
    
    private func setImages() {
        if (photo) != nil {
            self.photo.image = image
        } else {
            self.photo.image = UIImage(named: "noContent")
        }
    }
}
