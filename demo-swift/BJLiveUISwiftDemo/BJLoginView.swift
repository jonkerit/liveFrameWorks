//
//  BJLoginView.swift
//  BJLiveUISwiftDemo
//
//  Created by HuangJie on 2017/9/22.
//  Copyright © 2017年 BaijiaYun. All rights reserved.
//

import Foundation

class BJLoginView: UIView {
    var codeTextField = UITextField.init()
    var nameTextField = UITextField.init()
    var privateDomainPrefixField = UITextField.init()
    
    var doneButton = UIButton.init()
    var tipLabel = UILabel.init()
    
    
    private var backgroundView: UIImageView?
    private var appLogoView, logoView: UIImageView?
    private var inputContainerView, inputSeparatorFirstLine, inputSeparatorSecondLine: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.makeSubViews()
        self.makeConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:subviews
    
    private func makeSubViews() {
        // backgroundView
        let backgroundView = UIImageView.init()
        backgroundView.contentMode = UIView.ContentMode.scaleAspectFill
        backgroundView.image = UIImage.init(named: "login-bg")
        self.backgroundView = backgroundView
        self.addSubview(self.backgroundView!)
        
        // appLogoView
        self.appLogoView = UIImageView.init(image: UIImage.init(named: "login-logo-app"))
        self.addSubview(self.appLogoView!)
        
        // logoView
        self.logoView = UIImageView.init(image: UIImage.init(named: "login-logo"))
        self.addSubview(self.logoView!)
        
        // inputContainerView
        let inputContainerView = UIView.init()
        inputContainerView.backgroundColor = UIColor.init(white: 1.0, alpha: 0.5)
        inputContainerView.layer.masksToBounds = true
        inputContainerView.layer.cornerRadius = 3.0
        self.inputContainerView = inputContainerView;
        self.addSubview(self.inputContainerView!)
        
        let inputSeparatorFirstLine = UIView.init()
        inputSeparatorFirstLine.backgroundColor = UIColor.init(white: 1.0, alpha: 0.5)
        self.inputSeparatorFirstLine = inputSeparatorFirstLine
        self.addSubview(self.inputSeparatorFirstLine!)
        
        let inputSeparatorSecondLine = UIView.init()
        inputSeparatorSecondLine.backgroundColor = UIColor.init(white: 1.0, alpha: 0.5)
        self.inputSeparatorSecondLine = inputSeparatorSecondLine
        self.addSubview(self.inputSeparatorSecondLine!)
        
        // privateDomainPrefixField
        self.privateDomainPrefixField = self.textField(icon: UIImage.init(named: "login-icon-domain")!, placeholder: "请输入机构代码")
        self.privateDomainPrefixField.returnKeyType = UIReturnKeyType.next
        self.inputContainerView?.addSubview(self.privateDomainPrefixField)
        
        // codeTextField
        self.codeTextField = self.textField(icon: UIImage.init(named: "login-icon-code")!, placeholder: "请输入参加码")
        self.codeTextField.returnKeyType = UIReturnKeyType.next
        self.inputContainerView?.addSubview(self.codeTextField)
        
        // nameTextField
        self.nameTextField = self.textField(icon: UIImage.init(named: "login-icon-name")!, placeholder: "请输入昵称")
        self.nameTextField.returnKeyType = UIReturnKeyType.done
        self.inputContainerView?.addSubview(self.nameTextField)
        
        // doneButton
        let doneButton = UIButton.init()
        doneButton.isEnabled = false
        doneButton.backgroundColor = UIColor.bjl_color(withHexString: "#1694FF")
        doneButton.layer.masksToBounds = true
        doneButton.layer.cornerRadius = 2.0
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        doneButton.setTitleColor(UIColor.white, for: UIControl.State.normal)
        doneButton.setTitleColor(UIColor.init(white: 1.0, alpha: 0.5), for: UIControl.State.disabled)
        doneButton.setTitle("登录", for: UIControl.State.normal)
        self.doneButton = doneButton
        self.addSubview(self.doneButton)
        
        // tipLabel
        let tipLabel = UILabel.init()
        tipLabel.text = ""
        tipLabel.textColor = UIColor.white
        tipLabel.textAlignment = .center
        tipLabel.lineBreakMode = .byTruncatingTail
        tipLabel.font = .systemFont(ofSize: 14.0)
        tipLabel.numberOfLines = 0
        self.tipLabel = tipLabel
        self.addSubview(self.tipLabel)
    }
    
    // MARK:constraints
    
    private func makeConstraints() {
        let margin: CGFloat = 10.0
        
        _ = self.backgroundView?.mas_makeConstraints({ (make: MASConstraintMaker!) in
            make.edges.equalTo()(self)
        })
        
        _ = self.inputContainerView?.mas_makeConstraints({ (make: MASConstraintMaker!) in
            make.centerX.equalTo()(self)
            make.bottom.equalTo()(self.mas_centerY)?.offset()(18.0)
            make.left.right().equalTo()(self)?.with().insets()(UIEdgeInsets.init(top: 0.0, left: 15.0, bottom: 0.0, right: 15.0))
            make.height.equalTo()(150.0)
        })
        
        _ = self.privateDomainPrefixField.mas_makeConstraints({ (make: MASConstraintMaker!) in
            make.top.left().right().equalTo()(self.inputContainerView)?.with().insets()(UIEdgeInsets.init(top: 0.0, left: 12.0, bottom: 0.0, right: 12.0))
        })
        
        _ = self.inputSeparatorFirstLine?.mas_makeConstraints({ (make: MASConstraintMaker!) in
            make.top.equalTo()(self.privateDomainPrefixField.mas_bottom)
            make.left.right().equalTo()(self.inputContainerView)?.with().insets()(UIEdgeInsets.init(top: 0.0, left: margin, bottom: 0.0, right: margin))
            make.height.equalTo()(1.0 / UIScreen.main.scale)
        })
        
        _ = self.codeTextField.mas_makeConstraints({ (make: MASConstraintMaker!) in
            make.left.right().equalTo()(self.inputContainerView)?.with().insets()(UIEdgeInsets.init(top: 0.0, left: 12.0, bottom: 0.0, right: 12.0))
            make.top.equalTo()(self.privateDomainPrefixField.mas_bottom)
            make.height.equalTo()(self.privateDomainPrefixField)
        })
        
        _ = self.inputSeparatorSecondLine?.mas_makeConstraints({ (make: MASConstraintMaker!) in
            make.top.equalTo()(self.codeTextField.mas_bottom)
            make.left.right().equalTo()(self.inputContainerView)?.with().insets()(UIEdgeInsets.init(top: 0.0, left: margin, bottom: 0.0, right: margin))
            make.height.equalTo()(1.0 / UIScreen.main.scale)
        })
        
        _ = self.nameTextField.mas_makeConstraints({ (make: MASConstraintMaker!) in
            make.bottom.left().right().equalTo()(self.inputContainerView)?.with().insets()(UIEdgeInsets.init(top: 0.0, left: 12.0, bottom: 0.0, right: 12.0))
            make.top.equalTo()(self.codeTextField.mas_bottom)
            make.height.equalTo()(self.codeTextField)
        })
        
        _ = self.appLogoView?.mas_makeConstraints({ (make: MASConstraintMaker!) in
            make.centerX.equalTo()(self)
            make.bottom.equalTo()(self.inputContainerView?.mas_top)?.offset()(-32.0)
        })
        
        _ = self.logoView?.mas_makeConstraints({ (make: MASConstraintMaker!) in
            make.centerX.equalTo()(self)
            make.bottom.equalTo()(self)?.offset()(-40.0)
        })
        
        _ = self.doneButton.mas_makeConstraints({ (make: MASConstraintMaker!) in
            make.centerX.equalTo()(self)
            make.top.equalTo()(self.inputContainerView?.mas_bottom)?.offset()(32.0)
            make.width.equalTo()(self.inputContainerView)
            make.height.equalTo()(50.0)
        })
        
        _ = self.tipLabel.mas_makeConstraints({ (make: MASConstraintMaker!) in
            make.top.equalTo()(self.doneButton.mas_bottom)?.offset()(8.0)
            make.left.right().equalTo()(self.doneButton)
        })
    }
    
    // MARK:private
    private func textField(icon: UIImage, placeholder: String) -> UITextField {
        let fontSize: CGFloat = 14.0
        
        let textField = UITextField.init()
        textField.font = UIFont.systemFont(ofSize: fontSize)
        textField.textColor = UIColor.white
        textField.clearButtonMode = UITextField.ViewMode.whileEditing
        
        // placeholder
        let attributeDic: Dictionary = [convertFromNSAttributedStringKey(NSAttributedString.Key.font) : UIFont.systemFont(ofSize: fontSize),
                                        convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor) : UIColor.init(white: 1.0, alpha: 0.69)];
        textField.attributedPlaceholder = NSAttributedString.init(string: placeholder, attributes:convertToOptionalNSAttributedStringKeyDictionary(attributeDic))
        
        // leftView
        let button = UIButton.init()
        button.setImage(icon, for: UIControl.State.normal)
        textField.leftView = button
        textField.leftViewMode = UITextField.ViewMode.always
        button.mas_makeConstraints { (make: MASConstraintMaker!) in
            make.size.mas_equalTo()(CGSize.init(width: 27.0, height: 27.0))
        }
        button.rac_signal(for: UIControl.Event.touchUpInside).subscribeNext { (sender) in
            textField.becomeFirstResponder()
        }
        return textField
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
