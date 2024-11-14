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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSearchController()
        
        let btn = UIButton()
        btn.tintColor = UIColor.systemBlue
        btn.setTitle("More", for: .normal)
        btn.setTitleColor(UIColor.systemBlue, for: .normal)
        btn.addTarget(self, action: #selector(openActionSheet(_:)), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btn)
        
        if #available(iOS 14.0, *) {
            btn.showsMenuAsPrimaryAction = true
            btn.menu = .init(
                title: "Choose an option", options: [.displayInline], children: [
                    UIDeferredMenuElement({ [weak self, weak sender = navigationItem.leftBarButtonItem] resovle in
                        guard let self, let sender else {
                            return resovle([])
                        }
                        
                        return resovle(createActions(sender: sender).map({ $0.toMenuAction() }))
                    })
                ]
            )
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
    
    @objc func openActionSheet(_ sender: UIBarButtonItem) {
        present(createAlert(sender: sender), animated: true, completion: nil)
    }
    
    //as soon as UIAlertAction is added to UIAlertViewController, it's handler == nil, and it's broken
    func createActions(sender: UIBarButtonItem) -> [UIAlertAction] {
        var ac = [UIAlertAction]()
        
        ac.append(UIAlertAction(title: "🗑️ Clear", style: .default) { [weak self] _ in
            self?.clearRequests()
        })
        
        ac.append(UIAlertAction(title: "📤 Share", style: .default) { [weak self] _ in
            let alert = UIAlertController(title: "Share format", message: nil, preferredStyle: .alert)
            
            alert.addAction(.init(title: "Share as it is", style: .default, handler: { [weak self] _ in
                self?.shareContent(sender)
            }))
            
            alert.addAction(.init(title: "Share as cURL", style: .default, handler: { [weak self] _ in
                self?.shareContent(sender, requestExportOption: .curl)
            }))
            
            alert.addAction(.init(title: "Share as Postman", style: .default, handler: { [weak self] _ in
                self?.shareContent(sender, requestExportOption: .postman)
            }))
            
            self?.present(alert, animated: true)
        })
        
        for descriptor in Wormholy.additionalButtons {
            var buttonFree: Bool = true
            ac.append(.init(title: descriptor.title, style: .default, handler: { [weak self] action in
                guard buttonFree else { return }
                buttonFree = false
                if let controller = descriptor.block() {
                    switch descriptor.style {
                    case .present:
                        self?.present(controller, animated: true)
                    case .push:
                        self?.navigationController?.pushViewController(controller, animated: true)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1/3) {
                        buttonFree = true
                    }
                    
                } else {
                    buttonFree = true
                }
            }))
        }
        
        return ac
    }
    
    func createAlert(sender: UIBarButtonItem) -> UIAlertController {
        let ac = UIAlertController(title: "Wormholy", message: "Choose an option", preferredStyle: .actionSheet)
        
        for action in createActions(sender: sender) {
            ac.addAction(action)
        }
        
        ac.addAction(UIAlertAction(title: "Close", style: .cancel))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            ac.popoverPresentationController?.barButtonItem = sender
        }
        
        return ac
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
