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
import SwiftyJSON
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
                self.parkingSpaceNameLabel.text = String(self.parkingSpacePin!.custom_name)
                self.parkingSpacePriceLabel.text = "1人民幣 /秒"
                self.setParkingSpaceAddrLabel(with: self.parkingSpacePin!)
                
            } else {
                fatalError("Setting parkingSpacePin Error: parkingSpacePin is nil")
            }
        }
    }
    
    
    // MARK: - Server Properties
    let startParkingURL = "http://myptt.masato25.com:8077/api/v1/user_report_parking"
   
    
    
    
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
    
    
    private func startParking(at pSpace: ParkingSpaceAnnotation) {
        
        // retrieve user data from storage(keychain)
        let keychain = Keychain(service: Bundle.main.bundleIdentifier ?? "")
        let sessionToken = keychain["sessionToken"] ?? ""
        let userPhoneNum = keychain["userPhoneNumber"] ?? ""
        
        // Connect Server
        let parameters: Parameters = ["custom_name": pSpace.custom_name]
        let headers: HTTPHeaders = ["authorization": "\(userPhoneNum) \(sessionToken)"]
        
        Alamofire.request(self.startParkingURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().responseJSON(completionHandler: { response in
            
            switch response.result {
            case .success(let value):
                
                let responseJson = JSON(value)
                if responseJson["error"].string != nil {
                    
                    // Alert: no car on parking space
                    let noParkingAlert = UIAlertController(title: "您不在此車位上", message: "請將車停好後再進行回報", preferredStyle: .alert)
                    noParkingAlert.addAction(UIAlertAction(title: "好", style: .default, handler: { action in
                        noParkingAlert.dismiss(animated: true, completion: nil)
                    }))
                    self.present(noParkingAlert, animated: true, completion: nil)
                    
                } else {
                    print("Start parking: \(responseJson["msg"].stringValue)")
                    
                    // Remove Pin
                    self.mapViewFromPKMapVC.removeAnnotation(pSpace)
                }
                
            case .failure(let error):
                print("Start parking fails: \(error)")
            }
        })
    }
    
    
    
    
    
    // MARK: - Actions
    @IBAction func wantParking(_ sender: UIButton) {
        guard let myParkingSpacePin = self.parkingSpacePin else {
            fatalError("Press wantParking_Button Error: self.parkingSpacePin is nil")
        }
        
        
        // 1. Alert
        let wantParkingAlert = UIAlertController(title: "您確定要停車？", message: "按下確定後，將開始進行計費", preferredStyle: .alert)
        
        
        // 1.1 Action1
        wantParkingAlert.addAction(UIAlertAction(title: "確定", style: .default, handler: { action in
            // Connect server
            self.startParking(at: myParkingSpacePin)
        }))
        
        
        // 1.2 Action2
        wantParkingAlert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        self.present(wantParkingAlert, animated: true, completion: nil)
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

