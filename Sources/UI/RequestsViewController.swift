//
//  RequestsViewController.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 13/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

class RequestsViewController: WHBaseViewController {
    
    @IBOutlet weak var collectionView: WHCollectionView!
    var filteredRequests: [RequestModel] = []
    var searchController: UISearchController?
    weak var menuButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSearchController()
        
        let btn = UIButton()
        btn.tintColor = UIColor.systemBlue
        btn.setTitle("More", for: .normal)
        btn.setTitleColor(UIColor.systemBlue, for: .normal)
        btn.addTarget(self, action: #selector(openActionSheet(_:)), for: .touchUpInside)
        menuButton = btn
        
        let newBarButton = UIBarButtonItem(customView: btn)
        navigationItem.leftBarButtonItem = newBarButton
        
        if #available(iOS 14.0, *) {
            btn.showsMenuAsPrimaryAction = true
            btn.addTarget(self, action: #selector(reloadMenu(_:)), for: .menuActionTriggered)
            reloadMenu(newBarButton)
        }
        
        //navigationItem.leftBarButtonItem = UIBarButtonItem(title: "More", style: .plain, target: self, action: #selector(openActionSheet(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        collectionView?.register(UINib(nibName: "RequestCell", bundle:WHBundle.getBundle()), forCellWithReuseIdentifier: "RequestCell")
        
        filteredRequests = Storage.shared.requests
        NotificationCenter.default.addObserver(forName: newRequestNotification, object: nil, queue: nil) { [weak self] (notification) in
            DispatchQueue.main.sync { [weak self] in
                self?.filteredRequests = self?.filterRequests(text: self?.searchController?.searchBar.text) ?? []
                self?.collectionView.reloadData()
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            //Place code here to perform animations during the rotation.
            
        }) { (completionContext) in
            //Code here will execute after the rotation has finished.
            (self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 76)
            self.collectionView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //  MARK: - Search
    func addSearchController(){
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        if #available(iOS 9.1, *) {
            searchController?.obscuresBackgroundDuringPresentation = false
        } else {
            // Fallback
        }
        searchController?.searchBar.placeholder = "Search URL"
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            navigationItem.titleView = searchController?.searchBar
        }
        definesPresentationContext = true
    }
    
    func filterRequests(text: String?) -> [RequestModel]{
        guard text != nil && text != "" else {
            return Storage.shared.requests
        }
        
        return Storage.shared.requests.filter { (request) -> Bool in
            return (request.url.range(of: text!, options: .caseInsensitive) != nil || request.headers["X-APOLLO-OPERATION-NAME"]?.range(of: text!, options: .caseInsensitive) != nil) ? true : false
        }
    }
    
    // MARK: - Actions
    
    @available(iOS 14.0, *)
    @objc func reloadMenu(_ sender: UIBarButtonItem) {
        menuButton.menu = .init(
            title: "Choose an option", options: [.displayInline], children: [
                UIDeferredMenuElement({ [weak self, weak sender] resovle in
                    guard let self, let sender else {
                        return resovle([])
                    }
                    
                    return resovle(self.createActions(sender: sender).map({ $0.toMenuAction(presenter: self) }))
                })
            ]
        )
    }
    
    @objc func openActionSheet(_ sender: UIBarButtonItem) {
        present(createAlert(sender: sender), animated: true, completion: nil)
    }
    
    //as soon as UIAlertAction is added to UIAlertViewController, it's handler == nil, and it's broken
    func createActions(sender: UIBarButtonItem) -> [Wormholy.ButtonDescriptor] {
        var ac = [Wormholy.ButtonDescriptor]()
        
        ac.append(.action(title: "🗑️ Clear", style: .default, handler: { [weak self] in
            self?.clearRequests()
            return nil
        }))
        
        ac.append(.submenu(title: "📤 Share", style: .default, children: [
            .action(title: "Share as it is", style: .default, handler: { [weak self] in
                self?.shareContent(sender)
                return nil
            }),
            
            .action(title: "Share as cURL", style: .default, handler: { [weak self] in
                self?.shareContent(sender, requestExportOption: .curl)
                return nil
            }),
            
            .action(title: "Share as Postman", style: .default, handler: { [weak self] in
                self?.shareContent(sender, requestExportOption: .postman)
                return nil
            })
        ]))
        
        ac.append(contentsOf: Wormholy.additionalButtonsBlock())
        
        return ac
    }
    
    func createAlert(sender: UIBarButtonItem) -> UIAlertController {
        let alertController = UIAlertController(title: "Wormholy", message: "Choose an option", preferredStyle: .actionSheet)
        
        for buttonDescriptor in createActions(sender: sender) {
            let action = createAlertAction(from: buttonDescriptor, presenter: self)
            alertController.addAction(action)
        }
        
        alertController.addAction(UIAlertAction(title: "Close", style: .cancel))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.barButtonItem = sender
        }
        
        return alertController
    }
    
    func createAlertAction(from: Wormholy.ButtonDescriptor, presenter: UIViewController) -> UIAlertAction {
        
        var actionBlockFree: Bool = true
        let actionBlock: () -> Void
        
        switch from {
        case .action(_, _, let handler):
            actionBlock = { [weak presenter, weak self] in
                guard actionBlockFree else {
                    return
                }
                
                actionBlockFree = false
                
                if let (isPush, controller) = handler() {
                    if isPush, let navigationController = self?.navigationController {
                        navigationController.pushViewController(controller, animated: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2/3) {
                            actionBlockFree = true
                        }
                        
                        
                    } else if !isPush, let presenter {
                        presenter.present(controller, animated: true) {
                            actionBlockFree = true
                        }
                        
                    } else {
                        actionBlockFree = true
                    }
                    
                } else {
                    actionBlockFree = true
                }
            }
            
        case .submenu(let title, _, let children):
            actionBlock = { [weak presenter] in
                guard actionBlockFree else {
                    return
                }
                
                actionBlockFree = false
                
                let childAlert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
                for child in children {
                    childAlert.addAction(self.createAlertAction(from: child, presenter: self))
                }
                
                childAlert.addAction(.init(title: "Cancel", style: .cancel))
                guard let presenter else {
                    actionBlockFree = true
                    return
                }
                
                presenter.present(childAlert, animated: true) {
                    actionBlockFree = true
                }
            }
        }
        
        switch from {
        case .action(var title, let buttonStyle, _), .submenu(var title, let buttonStyle, _):
            let alertStyle: UIAlertAction.Style
            if buttonStyle.contains(.destructive) {
                alertStyle = .destructive
                
            } else if buttonStyle.contains(.cancel) {
                alertStyle = .cancel
                
            } else {
                alertStyle = .default
            }
            
            if buttonStyle.contains(.selected) {
                title = "→ \(title)"
            }
            
            return UIAlertAction(title: title, style: alertStyle, handler: { _ in
                actionBlock()
            })
        }
    }
    
    func clearRequests() {
        Storage.shared.clearRequests()
        filteredRequests = Storage.shared.requests
        collectionView.reloadData()
    }
    
    func shareContent(_ sender: UIBarButtonItem, requestExportOption: RequestResponseExportOption = .flat){
        ShareUtils.shareRequests(presentingViewController: self, sender: sender, requests: filteredRequests, requestExportOption: requestExportOption)
    }
    
    // MARK: - Navigation
    @objc func done(){
        self.dismiss(animated: true, completion: nil)
    }
    
    func openRequestDetailVC(request: RequestModel){
        let storyboard = UIStoryboard(name: "Flow", bundle: WHBundle.getBundle())
        if let requestDetailVC = storyboard.instantiateViewController(withIdentifier: "RequestDetailViewController") as? RequestDetailViewController{
            requestDetailVC.request = request
            self.show(requestDetailVC, sender: self)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: newRequestNotification, object: nil)
    }
}

extension RequestsViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredRequests.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RequestCell", for: indexPath) as! RequestCell
        
        cell.populate(request: filteredRequests[indexPath.item])
        return cell
    }
}

extension RequestsViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openRequestDetailVC(request: filteredRequests[indexPath.item])
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 76)
    }
}

// MARK: - UISearchResultsUpdating Delegate
extension RequestsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filteredRequests = filterRequests(text: searchController.searchBar.text)
        collectionView.reloadData()
    }
}

extension UIAlertAction {
    
    typealias AlertHandler = @convention(block) (UIAlertAction) -> Void
    
    func callHandler() {
        guard let block = perform(Selector("handler")) else {
            return
        }
        
        unsafeBitCast(block.takeUnretainedValue(), to: AlertHandler.self)(self)
    }
    
    func toMenuAction() -> UIAction {
        return UIAction(
            title: title ?? "",
            attributes: {
                var attrs = UIAction.Attributes()
                if style == .destructive {
                    attrs.insert(.destructive)
                }
                
                return attrs
            }(),
            handler: { [self] _ in
                self.callHandler()
            }
        )
    }
}

extension Wormholy.ButtonDescriptor {
    
    func toMenuAction(presenter: UIViewController) -> UIMenuElement {
        var actionBlockFree: Bool = true
        
        switch self {
        case .action(let title, let style, let handler):
            var attributes: UIMenuElement.Attributes = []
            if style.contains(.destructive) {
                attributes.insert(.destructive)
            }
            
            var state: UIMenuElement.State = .init(rawValue: 0)!
            if style.contains(.selected) {
                state = .on
            }
            
            return UIAction(title: title, attributes: attributes, state: state) { [weak presenter] action in
                guard actionBlockFree else { return }
                actionBlockFree = false
                
                if let (isPush, controller) = handler() {
                    if isPush, let navigationController = presenter?.navigationController {
                        navigationController.pushViewController(controller, animated: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2/3) {
                            actionBlockFree = true
                        }
                        
                        
                    } else if !isPush, let presenter {
                        presenter.present(controller, animated: true) {
                            actionBlockFree = true
                        }
                        
                    } else {
                        actionBlockFree = true
                    }
                    
                } else {
                    actionBlockFree = true
                }
            }
            
        case .submenu(let title, let style, let children):
            var options: UIMenu.Options = []
            if style.contains(.destructive) {
                options.insert(.destructive)
            }
            
            return UIMenu(title: title, options: options, children: children.map { $0.toMenuAction(presenter: presenter) })
        }
    }
}
