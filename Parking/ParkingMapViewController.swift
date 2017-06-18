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

class ParkingMapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var parkingSpaceContainerView: UIView!
    
    
    
    
    // MARK: - Map Properties
    let parkingSpaceApiURL = "http://data.ntpc.gov.tw/api/v1/rest/datastore/382000000A-000225-002"
    let manager = CLLocationManager()
    
  
    
    
    // MARK: - View Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.parkingSpaceContainerView.isHidden = true
        
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.manager.requestWhenInUseAuthorization()
        self.manager.startUpdatingLocation()
        
        self.loadParkingPin()
    }


    
    // MARK: - CLManagerDelegate Functions
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0]
        let span = MKCoordinateSpanMake(0.0025, 0.0025)
        let region = MKCoordinateRegion(center: userLocation.coordinate, span: span)
        self.mapView.setRegion(region, animated: true)
        
        self.manager.stopUpdatingLocation()
    }
    
    
    
    
    // MARK: - Pin Functions
    private func loadParkingPin() {
      Alamofire.request(self.parkingSpaceApiURL).validate().responseJSON(completionHandler: { response in
            
            switch response.result { 
            case .success(let value):
                let json = JSON(value)
                let result = json["result"].dictionaryValue
                let parkingLotArray = result["records"]?.arrayValue
                
                for parkingLot in parkingLotArray! {
                    let id = parkingLot["ID"].intValue
                    let address = parkingLot["ADDRESS"].stringValue
                    let charging = parkingLot["PAYEX"].stringValue
                    
                    let parkingSpace = ParkingSpaceAnnotation(id: id, address: address, charging: charging, isAvailable: true)
                    self.addParkingSpaceToMap(with: parkingSpace)
                }
            
            case .failure(let error):
                print(error)
            }
        })
    }
    
    
    
    private func addParkingSpaceToMap(with parkingSpacePin: ParkingSpaceAnnotation) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(parkingSpacePin.address, completionHandler: {
            (placemarkArray, error) in
            
            if placemarkArray != nil {
                // success, add pin to map
                guard let placemarkCoordinate = placemarkArray!.first!.location?.coordinate else {
                    print("\(parkingSpacePin.address) did not have a location")
                    return
                }
                parkingSpacePin.coordinate = placemarkCoordinate
                
                DispatchQueue.main.async(execute: {
                    if parkingSpacePin.isAvailable {
                        self.mapView.addAnnotation(parkingSpacePin)
                    } else {
                        print("\(parkingSpacePin.id) is not available")
                    }
                })
               
            } else {
                // fail
                print("\(parkingSpacePin.address) cannot transfer to coordinate")
            }
        })
    }
    
    
    
    
    // MARK: - MapViewDelegate Functions
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let pkspContainerVC = self.childViewControllers[0] as? ParkingSpaceContainerViewController else {
            fatalError("the first childVC of \(self) is not ParkingSpaceContainerVC ")
        }
        pkspContainerVC.parkingSpacePin = view.annotation as? ParkingSpaceAnnotation
        pkspContainerVC.mapViewFromPKMapVC = self.mapView
        
        self.parkingSpaceContainerView.isHidden = false
    }
    
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        self.parkingSpaceContainerView.isHidden = true
    }
}


