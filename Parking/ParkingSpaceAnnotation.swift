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
    var name: String
    var custom_name: String
    var price_set: String // 計費方式
    var status: ParkingSpaceStatus
    
    
    init(id: Int, name: String, custom_name: String, price_set: String, status: ParkingSpaceStatus) {
        self.id = id
        self.name = name
        self.custom_name = custom_name
        self.price_set = price_set
        self.status = status
    
    }
    
}
