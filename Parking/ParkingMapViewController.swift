//
//  ViewController.swift
//  Parking
//
//  Created by 林晏竹 on 2017/6/11.
//  Copyright © 2017年 林晏竹. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import SwiftyJSON
import SCLAlertView
import SwiftPhoenixClient
import KeychainAccess


enum ParkingSpaceStatus: String {
    case parking, available
}


class ParkingMapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var parkingSpaceContainerView: UIView!
    @IBOutlet weak var userLocationBttn: UIButton!
    @IBOutlet weak var logoutBttn: UIButton!
    @IBOutlet weak var refreshPinBttn: UIButton!
    
    
    
    // MARK: - Map Properties
    let getParkingSpaceURL = "http://myptt.masato25.com:8077/api/v1/get_car_list"
    let getPendingParkingURL = "http://myptt.masato25.com:8077/api/v1/pending_parking_check"
    let manager = CLLocationManager() // track user location
    
    
  
    
    // MARK: - Websocket Properties
    let socket = Socket(domainAndPort: "myptt.masato25.com:8077", path: "socket", transport: "websocket")
    let payParkingFeeURL = "http://myptt.masato25.com:8077/api/v1/pay_parking_at/"
    
    
    
    // MARK: - View Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MapView Delegate
        self.mapView.delegate = self

        
        // Configure CLLocationManager
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.manager.requestWhenInUseAuthorization()
        self.manager.startUpdatingLocation()
        
        // Configure views
        self.parkingSpaceContainerView.isHidden = true
        self.decorateOutlets()
        
        // Execute Functions
        self.loadParkingSpacePin(with: .available)
        self.loadPendingParkingPin()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.listenToServerMessage()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.socket.close(callback: {
            print("----------socket close-----------")
        })
    }

    
    
    
    // MARK: - Actions
    @IBAction func getUserLocation(_ sender: UIButton) {
        self.manager.startUpdatingLocation()
    }

    @IBAction func logout(_ sender: UIButton) {
        // remove user data from storage(keychain)
        let keychain = Keychain(service: Bundle.main.bundleIdentifier ?? "")
        do {
            try keychain.removeAll()
            
        } catch {
            print("logout but cannot remove keychain data: \(error)")
        }
        
        // jump to login 
        DispatchQueue.main.async {
            let parkingMapVC = self.storyboard?.instantiateViewController(withIdentifier: "logInNavigationController")
            self.present(parkingMapVC!, animated: false, completion: {
                print("presented loginVC")
            })
        }

    }
    
    @IBAction func refreshPin(_ sender: UIButton) {
        self.refreshParkingSpacePin()
    }
    
    
    // MARK: - CLLocationManager Delegate Functions
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0]
        let span = MKCoordinateSpanMake(0.005, 0.005)
        let region = MKCoordinateRegion(center: userLocation.coordinate, span: span)
        self.mapView.setRegion(region, animated: true)
        
        self.manager.stopUpdatingLocation()
    }
    
    
    
    
    // MARK: - Pin Functions
    private func loadParkingSpacePin(with status: ParkingSpaceStatus) {
        let parameters: Parameters = ["status": status]
        
        Alamofire.request(self.getParkingSpaceURL, method: .get
            , parameters: parameters).validate().responseJSON(completionHandler: { response in
                
                switch response.result {
                    
                case .success(let value):
                    print("Available Pin= \(value)")
                    
                    let responseJson = JSON(value)
                    if let error = responseJson["error"].string {
                        print("Load \(status) parking space pin went wrong: \(error)")
                        return
                        
                    } else {
                        let parkingSpaceArray = responseJson["data"].arrayValue
                        for (_, value) in parkingSpaceArray.enumerated() {
                            let id = value["id"].intValue
                            let name = value["name"].stringValue
                            let custom_name = value["custom_name"].stringValue
                            let status = ParkingSpaceStatus(rawValue: value["parking_status"].stringValue)
                            let price_set = value["price_set"].stringValue
                            let coordinate = value["coordinate"].stringValue
                            
                            
                            let latitude = Double(coordinate.components(separatedBy: ",")[1].replacingOccurrences(of: " ", with: ""))
                            let longitude = Double(coordinate.components(separatedBy: ",")[0].replacingOccurrences(of: " ", with: ""))
                            
                            
                            let parkingSpacePin = ParkingSpaceAnnotation(id: id, name: name, custom_name: custom_name, price_set: price_set, status: status!)
                            parkingSpacePin.coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                            
                            DispatchQueue.main.async {
                                self.mapView.addAnnotation(withoutDuplicateCoordinate: parkingSpacePin)
                            }
                        }
                    }
                case .failure(let error):
                    print("Load \(status) parking space pin fail: \(error)")
                }
            })
    }
    
    private func loadPendingParkingPin() {
        Alamofire.request(self.getPendingParkingURL).validate().responseJSON(completionHandler: { response in
            
            switch response.result {
            case .success(let value):
                print("Pending Pin= \(value)")
                
                let pendingPSpaceArray = JSON(value)["avatars"].arrayValue
                for (_, value) in pendingPSpaceArray.enumerated() {
                    let id = value["id"].intValue    // id and price_set isEmpty here
                    let name = value["name"].stringValue
                    let custom_name = value["custom_name"].stringValue
                    let status = ParkingSpaceStatus(rawValue: value["parking_status"].stringValue)
                    let price_set = value["price_set"].stringValue
                    let coordinate = value["coordinate"].stringValue
                    
                    
                    let latitude = Double(coordinate.components(separatedBy: ",")[1].replacingOccurrences(of: " ", with: ""))
                    let longitude = Double(coordinate.components(separatedBy: ",")[0].replacingOccurrences(of: " ", with: ""))
                    
                    
                    let parkingSpacePin = ParkingSpaceAnnotation(id: id, name: name, custom_name: custom_name, price_set: price_set, status: status!)
                    parkingSpacePin.coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                    
                    DispatchQueue.main.async {
                        self.mapView.addAnnotation(withoutDuplicateCoordinate: parkingSpacePin)
                    }
                }
            case .failure(let error):
                print("Load pending pin fail: \(error)")
            }
        })
    }
    
    private func refreshParkingSpacePin() {
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.loadParkingSpacePin(with: .available)
        self.loadPendingParkingPin()
    }
    
    
    // MARK: - MapViewDelegate Functions
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        switch view.annotation {
        case is ParkingSpaceAnnotation:
            guard let pkspContainerVC = self.childViewControllers[0] as? ParkingSpaceContainerViewController else {
                fatalError("the first childVC of \(self) is not ParkingSpaceContainerVC ")
            }
            pkspContainerVC.parkingSpacePin = view.annotation as? ParkingSpaceAnnotation
            pkspContainerVC.mapViewFromPKMapVC = self.mapView
            
            self.parkingSpaceContainerView.isHidden = false
            
        default:
            print("The selected pin is not a TaskPointAnnotation")
        }
    }
    
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        self.parkingSpaceContainerView.isHidden = true
    }
    
    
    
    // MARK: - Websocket Functions
    private func listenToServerMessage() {
        // retrieve user data from storage(keychain)
        let keychain = Keychain(service: Bundle.main.bundleIdentifier ?? "")
        let userID = keychain["userID"] ?? ""
        
        self.socket.join(topic: "customer:\(userID)", message: Message(subject: "status", body: "joining")) { channel in
            let channel = channel as! Channel
            
            // Channel 1
            channel.on(event: "phx_reply", callback: { message in
                guard let message = message as? Message,
                      let msg     = message.message else {
                        
                        return
                }
                let msgJson = JSON(msg)
                
                
                if let resp = msgJson["response"]["price_pay_info"].dictionary {
                    
                    let price = resp["price"]?.intValue
                    let paymentID = resp["id"]?.intValue
                    
                    // Alert - to pay parking fee
                    DispatchQueue.main.async {
                        print("=======presenting")
                        let payParkingFeeAlert = UIAlertController(title: "您有未付清款項", message: "總金額為\(price!)人民幣", preferredStyle: .alert)
                        payParkingFeeAlert.addAction(UIAlertAction(title: "好，付款", style: .default, handler: { action in
                            
                            self.payParkingFee(at: paymentID!)
                            payParkingFeeAlert.dismiss(animated: true, completion: nil)
                        }))
                        self.present(payParkingFeeAlert, animated: true, completion: nil)
                    }
                }
            })
            
            // Channel 2
            channel.on(event: "payment_request", callback: { message in
                guard let message = message as? Message,
                      let msg     = message.message else {
                        
                        return
                }
                let msgJson = JSON(msg)
                
                
                if let pay_info = msgJson["price_pay_info"].dictionary {
                    
                    let price = pay_info["price"]?.intValue
                    let paymentID = pay_info["id"]?.intValue
                    
                    // Alert - to pay parking fee
                    DispatchQueue.main.async {
                        let payParkingFeeAlert = UIAlertController(title: "您已離開車位", message: "停車結束，總金額為\(price!)人民幣", preferredStyle: .alert)
                        payParkingFeeAlert.addAction(UIAlertAction(title: "好，付款", style: .default, handler: { action in
                            
                            self.payParkingFee(at: paymentID!)
                            payParkingFeeAlert.dismiss(animated: true, completion: nil)
                        }))
                        self.present(payParkingFeeAlert, animated: true, completion: nil)
                    }
                }
            })
        }
    }
    
    
    

    
    
    
    
    // MARK: - Helper Functions
    private func decorateOutlets() {
        
        // User Location Button
        self.userLocationBttn.layer.shadowOffset = CGSize(width: 3.3, height: 3.3)
        self.userLocationBttn.layer.shadowOpacity = 0.3
        self.userLocationBttn.layer.cornerRadius = 23
        self.userLocationBttn.imageEdgeInsets = UIEdgeInsetsMake(11,11,11,11)
        
        // Disable userlocation pin view
        self.mapView.userLocation.title = ""
        
        // Logout Button
        self.logoutBttn.layer.shadowOffset = CGSize(width: 3.3, height: 3.3)
        self.logoutBttn.layer.shadowOpacity = 0.3
        self.logoutBttn.layer.cornerRadius = 23
        
        // RefreshPin Bttn
        self.refreshPinBttn.layer.shadowOffset = CGSize(width: 3.3, height: 3.3)
        self.refreshPinBttn.layer.shadowOpacity = 0.3
        self.refreshPinBttn.layer.cornerRadius = 23
        self.refreshPinBttn.imageEdgeInsets = UIEdgeInsetsMake(11,11,11,11)
        
        // Container View
        self.parkingSpaceContainerView.layer.shadowOffset = CGSize(width: 1, height: 1)
        self.parkingSpaceContainerView.layer.shadowOpacity = 0.3
        self.parkingSpaceContainerView.layer.shadowRadius = 10
    }
    
    private func payParkingFee(at paymentID: Int) {
        Alamofire.request("\(self.payParkingFeeURL)\(paymentID)").validate().responseJSON(completionHandler: { response in
            
            switch response.result {
            case .success(let value):
                print("Pay parking fee success: \(value)")
                
                DispatchQueue.main.async {
                    let paySuccesAlert = SCLAlertView().showSuccess("付款成功", subTitle: "謝謝您的消費", closeButtonTitle: "OK", colorStyle: 0x3CB371, colorTextButton: 0xFFFFFF, animationStyle: .topToBottom)
                    
                    paySuccesAlert.setDismissBlock {
                        self.refreshParkingSpacePin()
                    }
                }
                
                
            case .failure(let error):
                print("Pay parking fee fail: \(error)")
            }
        })
    }
}

extension MKMapView {
    
    func addAnnotation(withoutDuplicateCoordinate pin: MKAnnotation) {
        
        if self.annotations.count == 0 {
            self.addAnnotation(pin)
        } else {
            
            if !self.annotations.contains(where: { element in
                
                let annotation = element as MKAnnotation
                if annotation.coordinate.latitude == pin.coordinate.latitude &&
                   annotation.coordinate.longitude == pin.coordinate.longitude {
                    return true
                } else {
                    return false
                }
            }) {
                self.addAnnotation(pin)
            }
        }
    }
}

