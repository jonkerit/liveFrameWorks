//
//  BJLoginViewController.swift
//  BJLiveUISwiftDemo
//
//  Created by HuangJie on 2017/9/21.
//  Copyright © 2017年 BaijiaYun. All rights reserved.
//

import Foundation
import UIKit
// import BJLiveUI

struct loginConstants {
    static let BJLoginCodeKey = "BJLoginCode"
    static let BJLoginNameKey = "BJLoginName"
    static let BJLoginDomainKey = "BJLoginDomainKey"
}

class BJLoginViewController: UIViewController, UITextFieldDelegate, BJLRoomViewControllerDelegate {
    
    private var codeLoginView: BJLoginView?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.codeLoginView = self.createLoginView()
        let codeString: String? = UserDefaults.standard.string(forKey: loginConstants.BJLoginCodeKey)
        let nameString: String? = UserDefaults.standard.string(forKey: loginConstants.BJLoginNameKey)
        let domainString: String? = UserDefaults.standard.string(forKey: loginConstants.BJLoginDomainKey)
        if (codeString != nil) && (nameString != nil) {
            self.set(code: codeString!, name: nameString!, domain: domainString!)
        }
        
        self.makeSignals()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let iPad = (UI_USER_INTERFACE_IDIOM() == .pad)
        return iPad ? .portrait : .allButUpsideDown
    }
    
    override func shouldAutomaticallyForwardRotationMethods() -> Bool {
        return (UIApplication.shared.statusBarOrientation != UIInterfaceOrientation.portrait)
    }
    
    private func set(code : String, name : String, domain : String) {
        let loginView = self.codeLoginView!
        loginView.codeTextField.text = code
        loginView.nameTextField.text = name
        loginView.privateDomainPrefixField.text = domain
    }
    
    private func createLoginView() -> BJLoginView {
        let loginView = BJLoginView.init(frame: CGRect.zero)
        self.view.addSubview(loginView)
        loginView.mas_makeConstraints { (make: MASConstraintMaker!) in
            make.edges.equalTo()(self.view)
        }
        return loginView
    }
    
    private func makeSignals() {
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(endEditing))
        let panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(endEditing))
        self.view.addGestureRecognizer(tapGesture)
        self.view.addGestureRecognizer(panGesture)
        
        // clear cache if changed
        self.codeLoginView?.codeTextField.rac_textSignal().distinctUntilChanged().skip(1).subscribeNext({ (codeText: NSString?) in
            UserDefaults.standard.removeObject(forKey: loginConstants.BJLoginCodeKey)
            UserDefaults.standard.synchronize()
            self.setDoneButtonEnable()
        })
        self.codeLoginView?.nameTextField.rac_textSignal().distinctUntilChanged().skip(1).subscribeNext({ (nameText: NSString?) in
            UserDefaults.standard.removeObject(forKey: loginConstants.BJLoginNameKey)
            UserDefaults.standard.synchronize()
            self.setDoneButtonEnable()
        })
        
        // delegate
        self.codeLoginView?.codeTextField.delegate = self
        self.codeLoginView?.nameTextField.delegate = self
        
        // login
        self.codeLoginView?.doneButton .rac_signal(for: UIControl.Event.touchUpInside).subscribeNext({ (button) in
            self.login()
        })
    }
    
    private func login() {
        self.endEditing()
        
        BJLRoom.setPrivateDomainPrefix(self.codeLoginView?.privateDomainPrefixField.text)
        
        let codeString:String  = (self.codeLoginView?.codeTextField.text)!
        let nameString:String = (self.codeLoginView?.nameTextField.text)!
        
        let alertController = UIAlertController.init(title: "选择教室类型", message: "", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction.init(title: "大班课三分屏", style: .default, handler: { [weak self] (_) in
            let roomViewController = BJLScRoomViewController.instance(withSecret: codeString, userName: nameString, userAvatar: nil) as! BJLScRoomViewController
            self?.present(roomViewController, animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction.init(title: "小班课", style: .default, handler: { [weak self] (_) in
            let roomViewController = BJLIcRoomViewController.instance(withSecret: codeString, userName: nameString, userAvatar: nil) as! BJLIcRoomViewController
            self?.present(roomViewController, animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction.init(title: "大班课旧模板", style: .default, handler: { [weak self] (_) in
            let roomViewController = BJLRoomViewController.instance(withSecret: codeString, userName: nameString, userAvatar: nil) as! BJLRoomViewController
            roomViewController.delegate = self
            self?.present(roomViewController, animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        alertController.popoverPresentationController?.sourceView = self.codeLoginView?.doneButton
        alertController.popoverPresentationController?.sourceRect = self.codeLoginView?.doneButton.frame ?? self.view.frame
        alertController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: UIPopoverArrowDirection.up.rawValue | UIPopoverArrowDirection.down.rawValue)
        self.present(alertController, animated: true, completion: nil)
        self.storeCodeAndName()
    }
    
    // MARK: <UITextFieldDelegate>
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.codeLoginView?.codeTextField {
            self.codeLoginView?.nameTextField.becomeFirstResponder()
        }
        else if textField == self.codeLoginView?.nameTextField {
            if (self.codeLoginView?.doneButton.isEnabled)! {
                self.login()
            }
        }
        return false
    }
    
    // MARK: <BJLRoomViewControllerDelegate>
    
    func roomViewControllerEnterRoomSuccess(_ roomViewController: BJLRoomViewController) {
        print("enter room success")
    }
    
    func roomViewController(_ roomViewController: BJLRoomViewController, enterRoomFailureWithError error: Error) {
        print("enter room failure with error:" + error.localizedDescription)
    }
    
    func roomViewController(_ roomViewController: BJLRoomViewController, willExitWithError error: Error?) {
        var logString = "will exit room"
        if (error != nil) {
            logString = logString + "with error:" + (error?.localizedDescription)!
        }
        print(logString)
    }
    
    func roomViewController(_ roomViewController: BJLRoomViewController, didExitWithError error: Error?) {
        var logString = "did exit room"
        if (error != nil) {
            logString = logString + "with error:" + (error?.localizedDescription)!
        }
        print(logString)
    }
    
    func roomViewController(_ roomViewController: BJLRoomViewController, viewControllerToShowForCustomButton button: UIButton) -> UIViewController? {
        return nil
    }
    
    private func setDoneButtonEnable() {
        let codeString = self.codeLoginView?.codeTextField.text
        let nameString = self.codeLoginView?.nameTextField.text
        self.codeLoginView?.doneButton.isEnabled = (!(codeString?.isEmpty)! && !(nameString?.isEmpty)!)
    }
    
    private func storeCodeAndName() {
        UserDefaults.standard.set(self.codeLoginView?.codeTextField.text, forKey: loginConstants.BJLoginCodeKey)
        UserDefaults.standard.set(self.codeLoginView?.nameTextField.text, forKey: loginConstants.BJLoginNameKey)
        UserDefaults.standard.set(self.codeLoginView?.privateDomainPrefixField.text, forKey: loginConstants.BJLoginDomainKey)
        UserDefaults.standard.synchronize()
    }
    
    @objc func endEditing() {
        self.view.endEditing(true)
    }
}
