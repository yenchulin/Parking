//
//  ParkingSpace.swift
//  Parking
//
//  Created by 林晏竹 on 2017/6/17.
//  Copyright © 2017年 林晏竹. All rights reserved.
//

import UIKit
import MapKit

class ParkingSpaceAnnotation: MKPointAnnotation {
    var id: Int
    var address: String
    var charging: String // 計費方式
    var isAvailable: Bool
    
    
    init(id: Int, address: String, charging: String, isAvailable: Bool) {
        self.id = id
        self.address = address
        self.charging = charging
        self.isAvailable = isAvailable
    }
}
