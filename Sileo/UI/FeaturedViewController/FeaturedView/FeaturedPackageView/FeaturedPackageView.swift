//
//  FeaturedPackageView.swift
//  Sileo
//
//  Created by CoolStar on 7/6/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//

import SDWebImage

@objc(FeaturedPackageView)
class FeaturedPackageView: FeaturedBaseView, UIViewControllerPreviewingDelegate {
    let imageView: PackageIconView
    let titleLabel, authorLabel, versionLabel: UILabel
    
    let repoName: String
    
    let packageButton: PackageQueueButton
    
    let package: String
    
    var separatorView: UIView?
    var separatorHeightConstraint: NSLayoutConstraint?
    
    var isUpdatingPurchaseStatus: Bool = false
    
    required init?(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor) {
        guard let package = dictionary["package"] as? String else {
            return nil
        }
        guard let packageIcon = dictionary["packageIcon"] as? String else {
            return nil
        }
        guard let packageName = dictionary["packageName"] as? String else {
            return nil
        }
        guard let packageAuthor = dictionary["packageAuthor"] as? String else {
            return nil
        }
        guard let repoName = dictionary["repoName"] as? String else {
            return nil
        }
        
        self.package = package
        self.repoName = repoName
        
        imageView = PackageIconView(frame: .zero)
        
        titleLabel = SileoLabelView(frame: .zero)
        authorLabel = UILabel(frame: .zero)
        versionLabel = UILabel(frame: .zero)
        
        packageButton = PackageQueueButton()
        
        separatorView = UIView(frame: .zero)
        
        super.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor)
        
        imageView.image = UIImage(named: "Tweak Icon")
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        if !packageIcon.isEmpty {
            imageView.sd_setImage(with: URL(string: packageIcon))
        }
        
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.text = packageName
        
        authorLabel.text = packageAuthor
        authorLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        authorLabel.textColor = UIColor(red: 143.0/255.0, green: 142.0/255.0, blue: 148.0/255.0, alpha: 1.0)
        
        versionLabel.text = String(format: "%@ · %@", String(localizationKey: "Loading"), repoName)
        versionLabel.textColor = UIColor(red: 143.0/255.0, green: 142.0/255.0, blue: 148.0/255.0, alpha: 1.0)
        versionLabel.font = UIFont.systemFont(ofSize: 11)
        
        let titleStackView = UIStackView(arrangedSubviews: [titleLabel, authorLabel, versionLabel])
        titleStackView.spacing = 2
        titleStackView.axis = .vertical
        titleStackView.setCustomSpacing(4, after: authorLabel)
        
        if let buttonText = dictionary["buttonText"] as? String {
            packageButton.overrideTitle = buttonText
        }
        packageButton.package = PackageListManager.shared.newestPackage(identifier: package)
        packageButton.viewControllerForPresentation = viewController
        packageButton.setContentHuggingPriority(.required, for: .horizontal)
        
        let stackView = UIStackView(arrangedSubviews: [imageView, titleStackView, packageButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 16
        stackView.alignment = .center
        self.addSubview(stackView)
        
        stackView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: 8).isActive = true
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -8).isActive = true
        stackView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16).isActive = true
        stackView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16).isActive = true
        
        let useSeparator = (dictionary["useSeparator"] as? Bool) ?? true
        if useSeparator {
            let separatorView = UIView(frame: .zero)
            separatorView.translatesAutoresizingMaskIntoConstraints = false
            if #available(iOS 13, *) {
                separatorView.backgroundColor = .separator
            } else {
                separatorView.backgroundColor = .sileoSeparatorColor
            }
            self.addSubview(separatorView)
            
            weak var weakSelf: FeaturedPackageView? = self
            if UIColor.useSileoColors {
                NotificationCenter.default.addObserver(weakSelf as Any,
                                                       selector: #selector(FeaturedPackageView.updateSileoColors),
                                                       name: UIColor.sileoDarkModeNotification,
                                                       object: nil)
            }
            
            self.separatorView = separatorView
            
            separatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            separatorView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
            separatorView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
            let separatorHeightConstraint = separatorView.heightAnchor.constraint(equalToConstant: 1)
            
            separatorHeightConstraint.isActive = true
            self.separatorHeightConstraint = separatorHeightConstraint
        }
        
        self.isAccessibilityElement = true
        self.accessibilityLabel = String(format: String(localizationKey: "Package_By_Author"), titleLabel.text ?? "", authorLabel.text ?? "")
        self.accessibilityTraits = .button
        
        DispatchQueue.global(qos: .default).async {
            PackageListManager.shared.waitForReady()
            DispatchQueue.main.async {
                if let package = PackageListManager.shared.newestPackage(identifier: self.package) {
                    self.versionLabel.text = String(format: "%@ · %@", package.version, self.repoName)
                    if self.packageButton.package == nil {
                        self.packageButton.package = package
                    }
                } else {
                    self.versionLabel.text = String(localizationKey: "Package_Unavailable")
                }
            }
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(FeaturedPackageView.openDepiction))
        tap.delaysTouchesBegan = false
        self.addGestureRecognizer(tap)
        
        viewController.registerForPreviewing(with: self, sourceView: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func updateSileoColors() {
        self.separatorView?.backgroundColor = .sileoSeparatorColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateSileoColors()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        packageButton.tintColor = UINavigationBar.appearance().tintColor
        if let separatorHeightConstraint = self.separatorHeightConstraint {
            separatorHeightConstraint.constant = 1 / (self.window?.screen.scale ?? 1)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // If our container has a bigger width, give us a pleasant corner radius
        self.layer.cornerRadius = (self.superview?.bounds.width ?? 0) > self.bounds.width ? 4 : 0
    }
    
    override func depictionHeight(width: CGFloat) -> CGFloat {
        81
    }
    
    override func accessibilityActivate() -> Bool {
        openDepiction(packageButton)
        return true
    }
    
    @objc func openDepiction(_ : Any?) {
        if let package = PackageListManager.shared.newestPackage(identifier: self.package) {
            let packageViewController = PackageViewController(nibName: "PackageViewController", bundle: nil)
            packageViewController.package = package
            self.parentViewController?.navigationController?.pushViewController(packageViewController, animated: true)
        } else {
            let title = String(localizationKey: "Package Unavailable")
            let message = String(format: String(localizationKey: "Package_Unavailable"), repoName)
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: String(localizationKey: "OK"), style: .cancel, handler: { _ in
                alertController.dismiss(animated: true, completion: nil)
            }))
            self.parentViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let package = PackageListManager.shared.newestPackage(identifier: self.package) {
            let packageViewController = PackageViewController(nibName: "PackageViewController", bundle: nil)
            packageViewController.package = package
            return packageViewController
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.parentViewController?.navigationController?.pushViewController(viewControllerToCommit, animated: false)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.highlighted = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.highlighted = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.highlighted = false
    }
    
    public var highlighted: Bool = false {
        didSet {
            self.backgroundColor = highlighted ? .sileoHighlightColor : nil
        }
    }
    
    @objc public func updatePurchaseStatus() {
        if isUpdatingPurchaseStatus {
            return
        }
        
        guard let package = PackageListManager.shared.newestPackage(identifier: self.package) else {
            return
        }
        isUpdatingPurchaseStatus = true
        
        var isPurchased = false
        
        if let existingPurchased = UserDefaults.standard.array(forKey: "cydia-purchased") as? [String] {
            if existingPurchased.contains(package.package) {
                isPurchased = true
            }
        }
        
        guard let repo = package.sourceRepo else {
            return
        }
    }
}