//
//  AppDelegate.swift
//  Parking
//
//  Created by 林晏竹 on 2017/6/11.
//  Copyright © 2017年 林晏竹. All rights reserved.
//

import UIKit
import Stripe
import Alamofire
import SwiftyJSON
import KeychainAccess
import ReachabilitySwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    var checkSessionURL = "http://myptt.masato25.com:8077/api/v1/current_user"
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)
        -> Bool {
            
            // Stripe
            STPPaymentConfiguration.shared().publishableKey = "pk_test_jm7gGxL3bxOsRWcYaDFWiNSo"
            
            // Check user authentication and navigate to the correct VC
            self.checkIsAuthenticUser()
            
            return true
    }

    
    private func checkIsAuthenticUser() {
        // retrieve user data from storage(keychain)
        let keychain = Keychain(service: Bundle.main.bundleIdentifier ?? "")
        let sessionToken = keychain["sessionToken"] ?? ""
        let userPhoneNum = keychain["userPhoneNumber"] ?? ""
        
        
        let headers: HTTPHeaders = ["authorization": "\(userPhoneNum) \(sessionToken)"]
        
        Alamofire.request(self.checkSessionURL, method: .get, headers: headers).validate().responseJSON(completionHandler: { response in
            
            switch response.result {
            case .success(let value):
                print(value)
                
                let responseJson = JSON(value)
                
                if responseJson["error"].string != nil {
                    // cannot find such user's session need login
                    DispatchQueue.main.async {
                        self.window?.rootViewController = self.storyboard.instantiateViewController(withIdentifier: "logInNavigationController")
                    }
                } else {
                    // session is correct jump to map
                    DispatchQueue.main.async {
                        self.window?.rootViewController = self.storyboard.instantiateViewController(withIdentifier: "parkingMapViewController")
                    }
                }
             
            case .failure(let error):
                print(error)
                
                DispatchQueue.main.async {
                    self.window?.rootViewController = self.storyboard.instantiateViewController(withIdentifier: "logInNavigationController")
                }
            }
        })
    }
}
