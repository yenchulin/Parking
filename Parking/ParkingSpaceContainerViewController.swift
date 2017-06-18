//
//  ParkingSpaceContainerViewController.swift
//  Parking
//
//  Created by 林晏竹 on 2017/6/17.
//  Copyright © 2017年 林晏竹. All rights reserved.
//

import UIKit
import MapKit

class ParkingSpaceContainerViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var parkingSpaceIDLabel: UILabel!
    @IBOutlet weak var parkingSpaceAddrLabel: UILabel!
    @IBOutlet weak var parkingSpaceChargingLabel: UILabel!
    
    
    // MARK: - Pin Properties
    var parkingSpacePin: ParkingSpaceAnnotation? = nil {
        didSet {
            if self.parkingSpacePin != nil {
                self.parkingSpaceIDLabel.text = String(self.parkingSpacePin!.id)
                self.parkingSpaceAddrLabel.text = self.parkingSpacePin!.address
                self.parkingSpaceChargingLabel.text = self.parkingSpacePin!.charging
            } else {
                fatalError("Seting parkingSpacePin Error: parkingSpacePin is nil")
            }
        }
    }
    
    // MARK: - Properties
    var mapViewFromPKMapVC: MKMapView!
    
    
    // MARK: - Timer Properties
    var parkingTimer = Timer()
    
    
    
    // MARK: - View Functions
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    
    
    // MARK: - Actions
    @IBAction func wantParking(_ sender: UIButton) {
        guard let myParkingSpacePin = self.parkingSpacePin else {
            fatalError("Press Button Error: self.parkingSpacePin is nil")
        }
        self.mapViewFromPKMapVC.removeAnnotation(myParkingSpacePin)
        
        
        let finishParkingAlert = UIAlertController(title: "已幫您保留車位", message: "請在5分鐘內完成停車，否則將取消保留", preferredStyle: .alert)
        
        
        finishParkingAlert.addAction(UIAlertAction(title: "停好了", style: .default, handler: { action in
            self.parkingTimer.invalidate()
            print("Pressed \(action.title!) -> alert dismissed")
        }))
        
        
        finishParkingAlert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { action in
            self.parkingTimer.invalidate()
            self.mapViewFromPKMapVC.addAnnotation(myParkingSpacePin)
            print("Pressed \(action.title!) -> alert dismissed")
        }))
        
        self.present(finishParkingAlert, animated: true, completion: {
            print("presented finishParkingAlert")
            self.parkingTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { timer in
                
                self.dismiss(animated: true, completion: {
                    self.mapViewFromPKMapVC.addAnnotation(myParkingSpacePin)
                    print("dismissed alert")
                })
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

