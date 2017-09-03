//
//  LoginViewController.swift
//  Parking
//
//  Created by 林晏竹 on 2017/8/5.
//  Copyright © 2017年 林晏竹. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import KeychainAccess

class LoginViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlets
    @IBOutlet weak var phoneNumTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginBttn: UIButton!
    
    
    
    // MARK: - Server Properties
    let loginURL = "http://myptt.masato25.com:8077/api/v1/login"
    
    
    
    // MARK: - View Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegates
        self.phoneNumTextField.delegate = self
        self.passwordTextField.delegate = self
    }

    
    
    // MARK: - Actions
    @IBAction func textFieldResignFirstResponder(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
        sender.cancelsTouchesInView = false
        self.view.addGestureRecognizer(sender)
    }
    
    @IBAction func login(_ sender: UIButton) {
        self.checkUserInfo(self.phoneNumTextField.text!, self.passwordTextField.text!)
    }

    @IBAction func useWechatLogIn(_ sender: UIButton) {
        self.checkUserInfo("12345", "wechat")
    }
    
    
    
    // MARK: - TextField Delegate Functions
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.loginBttn.isEnabled = false
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.updateLoginBttnState()
    }
    
    
    
    // MARK: - Helper Functions
    private func checkUserInfo(_ userPhoneNum: String, _ userPassword: String) {
        
        let parameters: Parameters = [
            "username": userPhoneNum,
            "password": userPassword
        ]
        
        Alamofire.request(self.loginURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON(completionHandler: { response in
            
            switch response.result {
            case .success(let value):
                print("login= \(value)")
                
                let responseJson = JSON(value)
                
                if responseJson["error"].string != nil {
                    // alert: user not found or password is incorrent
                    let accountWrongAlert = UIAlertController(title: "無法登入", message: "您輸入的帳號密碼有誤", preferredStyle: .alert)
                    accountWrongAlert.addAction(UIAlertAction(title: "好", style: .default, handler: nil))
                    self.present(accountWrongAlert, animated: true, completion: nil)
                } else {
                    let session = responseJson["session"].dictionaryValue
                    let sessionToken = session["session"]?.stringValue
                    
                    let userData = responseJson["data"].dictionaryValue
                    let id = userData["id"]?.intValue
                    let name = userData["name"]?.stringValue
                    let lastName = name!.components(separatedBy: " ")[0]
                    let firstName = name!.components(separatedBy: " ")[1]
                    let phoneNumber = userData["username"]?.stringValue
                    let vechicleID = userData["parking_license"]?.stringValue
                    
                    
                    // save user data to storage(keychain)
                    let keychain = Keychain(service: Bundle.main.bundleIdentifier ?? "")
                    do {
                        try keychain.set(sessionToken!, key: "sessionToken")
                        try keychain.set(String(id!), key: "userID")
                        try keychain.set(lastName, key: "userLastName")
                        try keychain.set(firstName, key: "userFirstName")
                        try keychain.set(phoneNumber!, key: "userPhoneNumber")
                        try keychain.set(vechicleID!, key: "userVechicleID")
                    } catch {
                        print("Create user saving session token to keychain went wrong: \(error.localizedDescription)")
                    }
                    
                    // jump to map
                    DispatchQueue.main.async {
                        let parkingMapVC = self.storyboard?.instantiateViewController(withIdentifier: "parkingMapViewController")
                        self.present(parkingMapVC!, animated: false, completion: {
                            print("presented parkingMapVC")
                        })
                    }
                }
                
            case .failure(let error):
                print("Sending user info to server went wrong: \(error)")
                
                // alert: sth went wrong with server or network
                let loginIncompleteAlert = UIAlertController(title: "登入程序未完成", message: "網路連線有問題，請稍後再試", preferredStyle: .alert)
                loginIncompleteAlert.addAction(UIAlertAction(title: "好", style: .default, handler: { action in
                    print("Dismissed \(loginIncompleteAlert.title!) alert")
                }))
                self.present(loginIncompleteAlert, animated: true, completion: {
                    print("Present \(loginIncompleteAlert.title!) alert")
                })
            }
        })
    }

    
    
    
    // Disable the Login button if text field is empty.
    private func updateLoginBttnState() {
        let phoneNumText = self.phoneNumTextField.text ?? ""
        let passwordText = self.passwordTextField.text ?? ""
        self.loginBttn.isEnabled = !phoneNumText.isEmpty && !passwordText.isEmpty
    }
}
