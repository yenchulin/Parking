//
//  ParkingSpaceContainerViewController.swift
//  Parking
//
//  Created by 林晏竹 on 2017/6/17.
//  Copyright © 2017年 林晏竹. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import KeychainAccess

class ParkingSpaceContainerViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var parkingSpaceNameLabel: UILabel!
    @IBOutlet weak var parkingSpaceAddrLabel: UILabel!
    @IBOutlet weak var parkingSpacePriceLabel: UILabel!
    
    
    // MARK: - Pin Properties
    var mapViewFromPKMapVC: MKMapView!
    var parkingSpacePin: ParkingSpaceAnnotation? = nil {
        didSet {
            if self.parkingSpacePin != nil {
                self.parkingSpaceNameLabel.text = String(self.parkingSpacePin!.name)
                self.parkingSpacePriceLabel.text = self.parkingSpacePin!.price_set
                self.setParkingSpaceAddrLabel(with: self.parkingSpacePin!)
                
            } else {
                fatalError("Setting parkingSpacePin Error: parkingSpacePin is nil")
            }
        }
    }
    
    
    // MARK: - Server Properties
    let reserveParkingURL = "http://myptt.masato25.com:8077/api/v1/reservation_parking"
    let startParkingURL = ""
    
    
    
    // MARK: - Timer Properties
    var reserveParkingTimer = Timer()
    
    
    // MARK: - View Functions
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    
    // MARK: - Helper Functions
    private func setParkingSpaceAddrLabel (with pin: ParkingSpaceAnnotation) {
        let location = CLLocation(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarkArray, error) in
            
            guard let address = placemarkArray?.first?.addressDictionary?["FormattedAddressLines"] as? [String] else {
                print("Pin \(pin.id) cannot transfer \(pin.coordinate) to address")
                return
            }
            self.parkingSpaceAddrLabel.text = address.joined(separator: ",")
        })
    }
    
    
    private func startParking(_ pSpaceID: Int) {
        let parameters: Parameters = ["id": pSpaceID]
        
        Alamofire.request(self.startParkingURL, method: .post, parameters: parameters).validate().responseString(completionHandler: { response in
            
            switch response.result {
            case .success(let value):
                print(value)
                
            case .failure(let error):
                print("Start parking fails: \(error)")
            }
        })
    }
    
    
    private func cancelReserveParking(_ pSpaceID: Int) {
        // retrieve user data from storage(keychain)
        let keychain = Keychain(service: Bundle.main.bundleIdentifier ?? "")
        let sessionToken = keychain["sessionToken"] ?? ""
        let userPhoneNum = keychain["userPhoneNumber"] ?? ""
        
        let parameters: Parameters = ["parking_id": pSpaceID, "rs": false]
        let headers: HTTPHeaders = ["authorization": "\(userPhoneNum) \(sessionToken)"]
        
        Alamofire.request(self.reserveParkingURL, method: .get, parameters: parameters, headers: headers).validate().responseString(completionHandler: { response in
            
            switch response.result {
            case .success(let value):
                print(value)
                
            case .failure(let error):
                print("Cancel reserve parking fails: \(error)")
            }
        })
    }
    
    
    
    
    // MARK: - Actions
    @IBAction func wantReserveParking(_ sender: UIButton) {
        guard let myParkingSpacePin = self.parkingSpacePin else {
            fatalError("Press wantParking_Button Error: self.parkingSpacePin is nil")
        }
        
        // 1. Connect Server
        // retrieve user data from storage(keychain)
        let keychain = Keychain(service: Bundle.main.bundleIdentifier ?? "")
        let sessionToken = keychain["sessionToken"] ?? ""
        let userPhoneNum = keychain["userPhoneNumber"] ?? ""
        
        let parameters: Parameters = ["parking_id": myParkingSpacePin.id, "rs": true]
        let headers: HTTPHeaders = ["authorization": "\(userPhoneNum) \(sessionToken)"]
        
        Alamofire.request(self.reserveParkingURL, method: .get, parameters: parameters, headers: headers).validate().responseString(completionHandler: { response in
            
            switch response.result {
            case .success(let value):
                print(value)
                
            case .failure(let error):
                print("Want reserve parking fails: \(error)")
            }
        })
        
        
        // 2. Remove pin
        self.mapViewFromPKMapVC.removeAnnotation(myParkingSpacePin)
        
        
        // 3. Alert
        let reserveParkingAlert = UIAlertController(title: "已幫您保留車位", message: "請在5分鐘內完成停車，否則將取消保留", preferredStyle: .alert)
        
        
        // 3.1 Action1
        reserveParkingAlert.addAction(UIAlertAction(title: "停好了", style: .default, handler: { action in
            // Connect server
            self.startParking(myParkingSpacePin.id)
            
            // Stop Timing
            self.reserveParkingTimer.fire()
            
            print("Pressed \(action.title!) -> alert dismissed")
        }))
        
        
        // 3.2 Action2
        reserveParkingAlert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { action in
            // Connect Server
            self.cancelReserveParking(myParkingSpacePin.id)
            
            // Readd Pin
            self.mapViewFromPKMapVC.addAnnotation(myParkingSpacePin)
            
            // Stop Timing
            self.reserveParkingTimer.fire()
            
            print("Pressed \(action.title!) -> alert dismissed")
        }))
        
        self.present(reserveParkingAlert, animated: true, completion: {
            print("presented reserveParkingAlert")
        })
        
        
        // 4. Timing
        self.reserveParkingTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { timer in
            
            // 3.3 No Action
            self.dismiss(animated: true, completion: {
                // Connect Server
                self.cancelReserveParking(myParkingSpacePin.id)
                
                // Readd Pin
                self.mapViewFromPKMapVC.addAnnotation(myParkingSpacePin)
                
                print("dismissed alert")
            })
        })
    }
    
    
    
    
    
    
    
    
    
    
    // MARK: - Not Used
    private func remove(_ pin: ParkingSpaceAnnotation) {
        guard let parkingMapView = self.view.sibilingviews(MKMapView.self)?[0] else {
            print("container view has no sibiling view whose type is MKMapView")
            return
        }
        parkingMapView.removeAnnotation(pin)
    }
    
    
    private func readd(_ pin: ParkingSpaceAnnotation) {
        guard let parkingMapView = self.view.sibilingviews(MKMapView.self)?[0] else {
            print("container view has no sibiling view whose type is MKMapView")
            return
        }
        parkingMapView.addAnnotation(pin)
    }
}



// MARK: - Not Used
extension UIView {
    func sibilingviews<T> (_: T.Type) -> [T]? {
        guard let superV = UIView().superview else {
            print("this view does not have a superview")
            return nil
        }
        return (
            superV.subviews
                .filter { subV in
                    subV != self
                }
                .flatMap { subV in
                    subV as? T
                }
        )
    }
}

