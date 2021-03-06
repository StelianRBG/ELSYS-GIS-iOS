//
//  ViewController.swift
//  MarkMe
//
//  Created by Stelian Todorichkov on 2.01.22.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let router = MainRouter(root: self)
        let viewModel = MainViewModel()
        viewModel.makeLoad() { (result) in
            if result {
                router.goToTabs()
            }
            else {
                router.goToLogin()
            }
        }
    }
}
