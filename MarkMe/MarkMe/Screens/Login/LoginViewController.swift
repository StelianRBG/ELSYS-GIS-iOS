//
//  LoginVC.swift
//  MarkMe
//
//  Created by Stelian Todorichkov on 2.01.22.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet private var line: UIView!
    @IBOutlet private var usernameField: UITextField!
    @IBOutlet private var passwordField: UITextField!
    
    private let viewModel = LoginViewModel()
    private var router: LoginRouter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        router = LoginRouter(root: self)
    }
}

extension LoginViewController{
    // login with username and password
    @IBAction func signIn(_ sender: UIButton) {
        viewModel.loginWithUsername(usernameField: usernameField.text, passwordField: passwordField.text) {[weak self] (result) in
            self?.processResult(result: result)
        }
    }
    
    // login with facebook
    @IBAction func loginWithFacebook(_ sender: UIButton) {
        viewModel.loginWithFacebook(view: self) { [weak self] (result) in
            self?.processResult(result: result)
        }
    }
    
    @IBAction func loginWithGoogle(_ sender: UIButton)  {
        viewModel.loginWithGoogle(root: self) { [weak self] (result) in
            self?.processResult(result: result)
        }
    }

    // go to registation screen
    @IBAction func goToRegister(_ sender: UIButton) {
        router?.goToRegistration()
    }
    
    @IBAction func goToForgotPassword(_ sender: UIButton) {
        router?.goToForgotPassword()
    }
    
    // process result
    func processResult(result: AlertError?) {
        if let alert = result {
            showAlert(title: alert.title, alertMessage: alert.errorDescription)
        }
        else {
            router?.goToTabs()
        }
    }
}
