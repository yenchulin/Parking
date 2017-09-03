//
//  CreditCardViewController.swift
//  Parking
//
//  Created by 林晏竹 on 2017/8/3.
//  Copyright © 2017年 林晏竹. All rights reserved.
//

import UIKit
import Stripe
import Alamofire
import SwiftyJSON
import KeychainAccess

class CreditCardViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlets
    @IBOutlet weak var cardNumberTextField: UITextField!
    @IBOutlet weak var expiredMonthTextField: UITextField!
    @IBOutlet weak var expiredYearTextField: UITextField!
    @IBOutlet weak var cvcTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    
    @IBOutlet weak var signUpBttn: UIButton!
    
    
    
    // MARK: - User Properties
    var userPhoneNum: String?
    var userPassword: String?
    var userVechicleID: String?
    
    
    // MARK: - Server Properties
    let createUserURL = "http://myptt.masato25.com:8077/api/v1/user"
    
    
    // MARK: - View Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegates
        self.cardNumberTextField.delegate = self
        self.expiredMonthTextField.delegate = self
        self.expiredYearTextField.delegate = self
        self.cvcTextField.delegate = self
        self.lastNameTextField.delegate = self
        self.firstNameTextField.delegate = self
    }


    // MARK: - TextField Delegate Functions
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.signUpBttn.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSignUpBttnState()
    }
    
    
    
    // MARK: - Actions
    @IBAction func textFieldResignFirstResponder(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
        sender.cancelsTouchesInView = false
        self.view.addGestureRecognizer(sender)
    }
    
    
    @IBAction func finishEnteringCreditCardInfo(_ sender: UIButton) {

        self.getStripeToken() // also send user info to server
    }

    
    // MARK: - Helper Functions
    private func getStripeToken() {
        
        let stripeCard = STPCard()
        stripeCard.number = self.cardNumberTextField.text!
        stripeCard.expMonth = UInt(self.expiredMonthTextField.text!)!
        stripeCard.expYear = UInt(self.expiredYearTextField.text!)!
        stripeCard.cvc = self.cvcTextField.text!
        
        let cardValidState = STPCardValidator.validationState(forCard: stripeCard)
        if cardValidState == .valid {
            STPAPIClient.shared().createToken(withCard: stripeCard, completion: { result, error in
                
                if error == nil {
                    print("stripeToken: \(result?.tokenId ?? "")")
                    
                    self.sendUserInfoToServer(self.lastNameTextField.text!,
                                              self.firstNameTextField.text!,
                                              self.userPhoneNum!,
                                              self.userPassword!,
                                              self.userVechicleID!,
                                              result?.tokenId)
                    
                } else {
                    // alert
                    fatalError("Something went wrong when creating a stripe token: \(error.debugDescription)")
                }
            })
        } else if cardValidState == .incomplete {
            // alert
            let cardIncompleteAlert = UIAlertController(title: "卡片驗證程序未完成", message: "網路連線有問題，請稍後再試", preferredStyle: .alert)
            cardIncompleteAlert.addAction(UIAlertAction(title: "好", style: .default, handler: { action in
                print("Dismissed \(cardIncompleteAlert.title!) alert")
            }))
            self.present(cardIncompleteAlert, animated: true, completion: {
                print("Present \(cardIncompleteAlert.title!) alert")
            })
            
        } else {
            // invalid
            // alert
            let cardInvalidAlert = UIAlertController(title: "卡片驗證有誤", message: "卡片資訊填寫錯誤，請重新填寫", preferredStyle: .alert)
            cardInvalidAlert.addAction(UIAlertAction(title: "好", style: .default, handler: { action in
                print("Dismissed \(cardInvalidAlert.title!) alert")
            }))
            self.present(cardInvalidAlert, animated: true, completion: {
                print("Present \(cardInvalidAlert.title!) alert")
            })
        }

    }
    
    
    
    private func sendUserInfoToServer(_ userLastName: String, _ userFirstName: String, _ userPhoneNum: String, _ userPassword: String, _ userVechicleID: String, _ stripeToke: String?) {
        
        // check whether stripe token is nil
        guard let mystripeToken = stripeToke else {
            print("stripeToken is nil when sending info to server")
            return
        }
        
        // transfer userInfo to Json
        let parameters: Parameters =
            ["user":
                ["name": "\(userLastName) \(userFirstName)",
                    "parking_license": userVechicleID,
                    "password": userPassword,
                    "username": userPhoneNum,
                    "payment": mystripeToken
                ]
            ]
        
        
        Alamofire.request(self.createUserURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON(completionHandler: { response in
            
            switch response.result {
            case .success(let value):
                print("register= \(value)")
                
                let responseJson = JSON(value)
                
                if responseJson["error"].string == nil{
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
                
                // alert: phoneNum(username) is used
                let phoneNumIsUsedAlert = UIAlertController(title: "無法註冊", message: "此手機號碼已有人使用", preferredStyle: .alert)
                phoneNumIsUsedAlert.addAction(UIAlertAction(title: "好", style: .default, handler: { action in
                    print("Dismissed \(phoneNumIsUsedAlert.title!) alert")
                }))
                self.present(phoneNumIsUsedAlert, animated: true, completion: {
                    print("Present \(phoneNumIsUsedAlert.title!) alert")
                })
            }
        })
    }
    
    
    // Disable the SignUp button if text field is empty.
    private func updateSignUpBttnState() {
        let cardNumText = self.cardNumberTextField.text ?? ""
        let expiredMText = self.expiredMonthTextField.text ?? ""
        let expiredYText = self.expiredYearTextField.text ?? ""
        let cvcText = self.cvcTextField.text ?? ""
        let lastNameText = self.lastNameTextField.text ?? ""
        let firstNameText = self.firstNameTextField.text ?? ""
        
        self.signUpBttn.isEnabled = !cardNumText.isEmpty &&
                                    !expiredMText.isEmpty &&
                                    !expiredYText.isEmpty &&
                                    !cvcText.isEmpty &&
                                    !lastNameText.isEmpty &&
                                    !firstNameText.isEmpty
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
