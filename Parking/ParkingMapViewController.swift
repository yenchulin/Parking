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
import SwiftPhoenixClient
import SCLAlertView
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
    
    
    // MARK: - Map Properties
    let getParkingSpaceURL = "http://myptt.masato25.com:8077/api/v1/get_car_list"
    let manager = CLLocationManager() // track user location
    
    
    
    
    
    // MARK: - Websocket Properties
    let socket = Socket(domainAndPort: "myptt.masato25.com:8077", path: "socket", transport: "websocket")


  
    
    
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
    
    
    
    // MARK: - CLLocationManager Delegate Functions
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0]
        let span = MKCoordinateSpanMake(0.0025, 0.0025)
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
                    
                    let responseJson = JSON(value)
                    
                    if responseJson["error"].string != nil {
                        print("Loading parking space pin went wrong: \(responseJson["error"].stringValue)")
                        
                        return
                    } else {
                        let parkingSpaceArray = responseJson["data"].arrayValue
                        for (_, value) in parkingSpaceArray.enumerated() {
                            let id = value["id"].intValue
                            let name = value["name"].stringValue
                            let status = ParkingSpaceStatus(rawValue: value["parking_status"].stringValue)
                            let price_set = value["price_set"].stringValue
                            let coordinate = value["coordinate"].stringValue
                            
                            
                            let latitude = Double(coordinate.components(separatedBy: ",")[0].replacingOccurrences(of: " ", with: ""))
                            let longitude = Double(coordinate.components(separatedBy: ",")[1].replacingOccurrences(of: " ", with: ""))
                            
                            
                            let parkingSpacePin = ParkingSpaceAnnotation(id: id, name: name, price_set: price_set, status: status!)
                            parkingSpacePin.coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                            
                            DispatchQueue.main.async {
                                self.mapView.addAnnotation(parkingSpacePin)
                            }
                        }
                    }
                case .failure(let error):
                    print("Cannot load parking space pin: \(error)")
                }
            })
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
        self.socket.join(topic: "customer:m1", message: Message(subject: "status", body: "joining")) { channel in
            
            let channel = channel as! Channel
            channel.on(event: "phx_reply", callback: { message in
            
                guard let message  = message as? Message,
                      let status   = message["status"],
                      let response = message["response"] else {
                            
                    return
                }
                let msg = JSON(response)["message"].stringValue
    
                print("----------- \(status) \(msg)")
                
                
                // Alert - to pay parking fee
                DispatchQueue.main.async {
                    let payParkingFeeAlert = UIAlertController(title: "您已離開車位", message: "停車已結束，總金額為", preferredStyle: .alert)
                    payParkingFeeAlert.addAction(UIAlertAction(title: "付款", style: .default, handler: { action in
                        
                        SCLAlertView().showSuccess("付款成功", subTitle: "",closeButtonTitle: "OK", colorStyle: 0x000000, colorTextButton: 0xFFFFFF, animationStyle: .topToBottom)
                        
                    }))
                    self.present(payParkingFeeAlert, animated: true, completion: nil)
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
        
        // Container View
        self.parkingSpaceContainerView.layer.shadowOffset = CGSize(width: 1, height: 1)
        self.parkingSpaceContainerView.layer.shadowOpacity = 0.3
        self.parkingSpaceContainerView.layer.shadowRadius = 10
    }
}
