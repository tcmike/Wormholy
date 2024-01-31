//
//  ChangeServerViewController.swift
//  Wormholy-iOS
//
//  Created by MIKHAIL CHEPELEV on 26.07.2021.
//  Copyright © 2021 Wormholy. All rights reserved.
//

import UIKit

class ChangeServerViewController: UIViewController {
    
    let scrollView = UIScrollView()
    let currentServerLabel = UILabel()
    let firstDivider = UIView()
    let prodServerButton = BorderedButton()
    let demoServerButton = BorderedButton()
    let secondDivider = UIView()
    let commonServerLabel = UILabel()
    let commonUrlTextfield = InsettedTextField()
    let epsServerLabel = UILabel()
    let epsUrlTextfield = InsettedTextField()
    let customServerButton = BorderedButton()
    
    let mainColor: UIColor = UIColor(red: 0.286, green: 0.490, blue: 0.998, alpha: 1)
    let secondaryColor: UIColor = .lightGray
    
    var currentServer: ServerInfoStorage.Server? {
        ServerInfoStorage.shared.currentServer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placeSubviews()

        view.backgroundColor = UIColor.white
        title = "Change server"
        
        //dividers
        firstDivider.backgroundColor = secondaryColor
        secondDivider.backgroundColor = secondaryColor
        
        //current label
        currentServerLabel.numberOfLines = 0
        currentServerLabel.text = getCurrentServerLabelText()
        currentServerLabel.textColor = secondaryColor
        
        //prod button
        configureProdButton()
        
        //demo button
        configureDemoButton()
        
        //common label
        commonServerLabel.text = "Common server:"
        commonServerLabel.textColor = secondaryColor
        
        //common textfield
        commonUrlTextfield.autocapitalizationType = .none
        if #available(iOS 10.0, *) { commonUrlTextfield.textContentType = .URL }
        commonUrlTextfield.keyboardType = .URL
        commonUrlTextfield.layer.borderColor = secondaryColor.cgColor
        commonUrlTextfield.placeholder = "https://www.common_server_url.com"
        
        //EPS label
        epsServerLabel.text = "EPS server:"
        epsServerLabel.textColor = secondaryColor
        
        //EPS textfield
        epsUrlTextfield.autocapitalizationType = .none
        if #available(iOS 10.0, *) { epsUrlTextfield.textContentType = .URL }
        epsUrlTextfield.keyboardType = .URL
        epsUrlTextfield.layer.borderColor = secondaryColor.cgColor
        epsUrlTextfield.placeholder = "https://www.eps_server_url.com"
        
        //custon button
        customServerButton.setTitle("Save", for: .normal, with: .white, on: secondaryColor)
        customServerButton.addTarget(self, action: #selector(switchToCustom), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func configureProdButton() {
        if currentServer == .prod {
            prodServerButton.setTitle("Currently at prod", for: .normal, with: .white, on: mainColor)
            prodServerButton.isEnabled = false
            
        } else {
            prodServerButton.setTitle("Prod server", for: .normal, with: .white, on: mainColor)
            prodServerButton.addTarget(self, action: #selector(switchToProd), for: .touchUpInside)
        }
    }
    
    func configureDemoButton() {
        if currentServer == .demo {
            demoServerButton.setTitle("Currently at demo", for: .normal, with: .white, on: mainColor)
            demoServerButton.isEnabled = false
            
        } else {
            demoServerButton.setTitle("Demo server", for: .normal, with: .white, on: mainColor)
            demoServerButton.addTarget(self, action: #selector(switchToDemo), for: .touchUpInside)
        }
    }
    
    @objc func switchToProd() {
        guard currentServer != .prod,
              let url = urls(for: .prod),
              let common = url.common?.url,
              let eps = url.eps?.url
        else {
            return failedToSwitch(to: .prod)
        }
        
        swichTo(common: common, eps: eps)
    }
    
    @objc func switchToDemo() {
        guard currentServer != .demo,
              let url = urls(for: .demo),
              let common = url.common?.url,
              let eps = url.eps?.url
        else {
            return failedToSwitch(to: .demo)
        }
        
        swichTo(common: common, eps: eps)
    }
    
    @objc func switchToCustom() {
        guard commonIsValid() && epsIsEmptyOrValid() else {
            return failedToSwitch(to: .custom)
        }
        
        let targetCommon = commonUrlTextfield.text?.lowercased().url
        
        guard let targetCommon else {
            return failedToSwitch(to: .custom)
        }
        
        let targetEps = epsUrlTextfield.text?.lowercased().url
        let knownURLs = ServerInfoStorage.shared.knownURLs
        
        if targetCommon.absoluteString == knownURLs[.prod]?.common && (targetEps?.absoluteString == knownURLs[.prod]?.eps || targetEps == nil) {
            return switchToProd()
        }
        
        if targetCommon.absoluteString == knownURLs[.demo]?.common && (targetEps?.absoluteString == knownURLs[.demo]?.eps || targetEps == nil) {
            return switchToDemo()
        }
        
        if let epsURL = targetEps ?? knownURLs[.demo]?.eps?.url {
            return swichTo(common: targetCommon, eps: epsURL)
        }
        
        return failedToSwitch(to: .custom)
    }
    
    func commonIsValid() -> Bool {
        if let commonText = commonUrlTextfield.text, !commonText.isEmpty {
            return true
        }
        
        return false
    }
    
    func epsIsEmptyOrValid() -> Bool {
        if let epsText = epsUrlTextfield.text, !epsText.isEmpty {
            return true
        }
        
        return false
    }
    
    func swichTo(common commonUrl: URL, eps epsUrl: URL) {
        UIView.animate(withDuration: 0.15) { [weak self] in
            self?.view.subviews.forEach {
                $0.alpha = 0.0
            }
            
        } completion: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
            self?.parent?.dismiss(animated: false, completion: {
                NotificationCenter.default.post(
                    name: NSNotification.Name("kWormholyRequestChangeServer"),
                    object: nil,
                    userInfo: ["commonUrl": commonUrl, "epsUrl": epsUrl]
                )
            })
        }
    }
    
    func failedToSwitch(to server: ServerInfoStorage.Server) {
        let errorColor = UIColor.red
        
        switch server {
        case .prod:
            UIView.animate(withDuration: 0.1) { [weak self] in
                self?.prodServerButton.backgroundColor = errorColor
            } completion: { [weak self] _ in
                UIView.animate(withDuration: 0.1) { [weak self] in
                    self?.prodServerButton.backgroundColor = self?.mainColor
                }
            }
        case .demo:
            UIView.animate(withDuration: 0.1) { [weak self] in
                self?.demoServerButton.backgroundColor = errorColor
            } completion: { [weak self] _ in
                UIView.animate(withDuration: 0.1) { [weak self] in
                    self?.demoServerButton.backgroundColor = self?.mainColor
                }
            }
        case .custom:
            if !commonIsValid() {
                UIView.animate(withDuration: 0.1) { [weak self] in
                    self?.commonServerLabel.textColor = errorColor
                    self?.commonUrlTextfield.layer.borderColor = errorColor.cgColor
                    
                    self?.customServerButton.backgroundColor = errorColor
                } completion: { [weak self] _ in
                    UIView.animate(withDuration: 0.1) { [weak self] in
                        self?.commonServerLabel.textColor = self?.secondaryColor
                        self?.commonUrlTextfield.layer.borderColor = self?.secondaryColor.cgColor
                        
                        self?.customServerButton.backgroundColor = self?.secondaryColor
                    }
                }
            }
            if !epsIsEmptyOrValid() {
                UIView.animate(withDuration: 0.1) { [weak self] in
                    self?.epsServerLabel.textColor = errorColor
                    self?.epsUrlTextfield.layer.borderColor = errorColor.cgColor
                    
                    self?.customServerButton.backgroundColor = errorColor
                } completion: { [weak self] _ in
                    UIView.animate(withDuration: 0.1) { [weak self] in
                        self?.epsServerLabel.textColor = self?.secondaryColor
                        self?.epsUrlTextfield.layer.borderColor = self?.secondaryColor.cgColor
                        
                        self?.customServerButton.backgroundColor = self?.secondaryColor
                    }
                }
            }
        }
    }
    
    func getCurrentServerLabelText() -> String {
        guard let urls = urls(for: currentServer) else {
            return "Not registered"
        }
        
        let defaultString = "not determined"
        
        let serverString = urls.common ?? defaultString
        let epsString = urls.eps ?? defaultString
        
        return "Common: \(serverString)\nEPS: \(epsString)"
    }
    
    func urls(for server: ServerInfoStorage.Server?) -> ServerInfoStorage.ServerURLs? {
        guard let server else {
            return nil
        }
        
        return ServerInfoStorage.shared.knownURLs[server]
    }
    
    func placeSubviews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
            ])
        }
        
        currentServerLabel.translatesAutoresizingMaskIntoConstraints = false
        firstDivider.translatesAutoresizingMaskIntoConstraints = false
        prodServerButton.translatesAutoresizingMaskIntoConstraints = false
        demoServerButton.translatesAutoresizingMaskIntoConstraints = false
        secondDivider.translatesAutoresizingMaskIntoConstraints = false
        commonServerLabel.translatesAutoresizingMaskIntoConstraints = false
        commonUrlTextfield.translatesAutoresizingMaskIntoConstraints = false
        epsServerLabel.translatesAutoresizingMaskIntoConstraints = false
        epsUrlTextfield.translatesAutoresizingMaskIntoConstraints = false
        customServerButton.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(currentServerLabel)
        scrollView.addSubview(firstDivider)
        scrollView.addSubview(prodServerButton)
        scrollView.addSubview(demoServerButton)
        scrollView.addSubview(secondDivider)
        scrollView.addSubview(commonServerLabel)
        scrollView.addSubview(commonUrlTextfield)
        scrollView.addSubview(epsServerLabel)
        scrollView.addSubview(epsUrlTextfield)
        scrollView.addSubview(customServerButton)
        
        NSLayoutConstraint.activate([
            currentServerLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            firstDivider.topAnchor.constraint(equalTo: currentServerLabel.bottomAnchor, constant: 20),
            prodServerButton.topAnchor.constraint(equalTo: firstDivider.bottomAnchor, constant: 20),
            demoServerButton.topAnchor.constraint(equalTo: prodServerButton.bottomAnchor, constant: 20),
            secondDivider.topAnchor.constraint(equalTo: demoServerButton.bottomAnchor, constant: 20),
            commonServerLabel.topAnchor.constraint(equalTo: secondDivider.bottomAnchor, constant: 20),
            commonUrlTextfield.topAnchor.constraint(equalTo: commonServerLabel.bottomAnchor, constant: 4),
            epsServerLabel.topAnchor.constraint(equalTo: commonUrlTextfield.bottomAnchor, constant: 12),
            epsUrlTextfield.topAnchor.constraint(equalTo: epsServerLabel.bottomAnchor, constant: 4),
            customServerButton.topAnchor.constraint(equalTo: epsUrlTextfield.bottomAnchor, constant: 20),
            customServerButton.bottomAnchor.constraint(greaterThanOrEqualTo: scrollView.bottomAnchor, constant: -40),
            
            currentServerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            currentServerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            firstDivider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            firstDivider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            prodServerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            prodServerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            demoServerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            demoServerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            secondDivider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            secondDivider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            commonServerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            commonServerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            commonUrlTextfield.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            commonUrlTextfield.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            epsServerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            epsServerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            epsUrlTextfield.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            epsUrlTextfield.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            customServerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            customServerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            firstDivider.heightAnchor.constraint(equalToConstant: 1),
            prodServerButton.heightAnchor.constraint(equalToConstant: 44),
            demoServerButton.heightAnchor.constraint(equalToConstant: 44),
            secondDivider.heightAnchor.constraint(equalToConstant: 1),
            commonUrlTextfield.heightAnchor.constraint(equalToConstant: 44),
            epsUrlTextfield.heightAnchor.constraint(equalToConstant: 44),
            customServerButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}

// MARK: - Support

extension String {
    
    var url: URL? {
        return URL(string: self)
    }
}


open class ServerInfoStorage {
    
    public typealias ServerURLs = (common: String?, eps: String?)
    
    public enum Server: CaseIterable {
        case prod
        case demo
        case custom
    }
    
    public static let shared = ServerInfoStorage()
    
    private(set) var knownURLs: [Server: ServerURLs] = [:]
    private(set) var currentServer: Server?
    
    public func register(urls: ServerURLs, for server: Server) {
        knownURLs[server] = urls
    }
    
    public func setCurrent(server: Server) {
        currentServer = server
    }
}

// MARK: - Views

class InsettedTextField: UITextField {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.borderWidth = 2
        self.layer.cornerRadius = 12
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return super.textRect(forBounds: bounds).inset(by: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return super.editingRect(forBounds: bounds).inset(by: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class BorderedButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
    }
    
    override var isHighlighted: Bool {
        get { return super.isHighlighted }
        set {
            super.isHighlighted = newValue
            self.backgroundColor = mBackgroundcolor?.withAlphaComponent(newValue ? 0.6 : 1.0)
        }
    }
    
    override var isEnabled: Bool {
        get { return super.isEnabled }
        set {
            super.isEnabled = newValue
            self.backgroundColor = mBackgroundcolor?.withAlphaComponent(newValue ? 1.0 : 0.6)
        }
    }
    
    var mBackgroundcolor: UIColor? {
        didSet {
            self.backgroundColor = mBackgroundcolor
        }
    }
    
    func setTitle(_ title: String?, for state: UIControl.State, with titleColor: UIColor?, on backgroundColor: UIColor?) {
        super.setTitle(title, for: state)
        super.setTitleColor(titleColor, for: state)
        self.mBackgroundcolor = backgroundColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
