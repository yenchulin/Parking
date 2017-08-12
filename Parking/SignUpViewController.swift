//
//  SignUpViewController.swift
//  Parking
//
//  Created by 林晏竹 on 2017/8/3.
//  Copyright © 2017年 林晏竹. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlets
    @IBOutlet weak var phoneNumTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var vechicleIDTextField: UITextField!
    @IBOutlet weak var nextStepBttn: UIButton!
    
    
    
    // MARK: - View Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegates
        self.phoneNumTextField.delegate = self
        self.passwordTextField.delegate = self
        self.vechicleIDTextField.delegate = self
    }

    
    
    // MARK: - Actions
    @IBAction func textFieldResignFirstResponder(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
        sender.cancelsTouchesInView = false
        self.view.addGestureRecognizer(sender)
    }
    
    
    // MARK: - TextField Delegate Functions
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.nextStepBttn.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.updateNextStepBttnState()
    }
    
    
    // MARK: - Helper Functions
    // Disable the NextStep button if text field is empty.
    private func updateNextStepBttnState() {
        let phoneNumText = self.phoneNumTextField.text ?? ""
        let passwordText = self.passwordTextField.text ?? ""
        let vechicleIDText = self.vechicleIDTextField.text ?? ""
        self.nextStepBttn.isEnabled = !phoneNumText.isEmpty &&
                                      !passwordText.isEmpty &&
                                      !vechicleIDText.isEmpty
    }
    
    

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch (segue.identifier ?? "") {
        case "signUpSegue":
            guard let creditCardVC = segue.destination as? CreditCardViewController else {
                fatalError("The segue destination of \(self) is not CreditCardVC")
            }
            creditCardVC.userPhoneNum = self.phoneNumTextField.text
            creditCardVC.userPassword = self.passwordTextField.text
            creditCardVC.userVechicleID = self.vechicleIDTextField.text
            
        default:
            fatalError("There is an unexpected segue: \(segue.identifier ?? "")")
        }
    }
    

}
