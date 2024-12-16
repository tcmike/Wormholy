//
//  ShareUtils.swift
//  Wormholy-iOS
//
//  Created by Daniele Saitta on 15/02/2020.
//  Copyright © 2020 Wormholy. All rights reserved.
//

import Foundation

final class ShareUtils {

    static func shareRequests(presentingViewController: UIViewController, sender: UIBarButtonItem, requests: [RequestModel], requestExportOption: RequestResponseExportOption = .flat){
         var text = ""
         switch requestExportOption {
         case .flat, .flatFile:
             text = getTxtText(requests: requests)
         case .curl:
             text = getCurlText(requests: requests)
         case .postman:
            text = getPostmanCollection(requests: requests) ?? "{}"
            text = text.replacingOccurrences(of: "\\/", with: "/")
        }
         
        let customItem = CustomActivity(title: "Save to the desktop", image: UIImage(named: "activity_icon", in: WHBundle.getBundle(), compatibleWith: nil)) { (sharedItems) in
            guard let sharedString = sharedItems.first(where: { $0 is String }) as? String else { return }
            
            let fileName = exportNameForFile(requestExportOption: requestExportOption)            
            FileHandler.writeTxtFileOnDesktop(text: sharedString, fileName: fileName)
        }
        
        var activityItems: [Any]
        var applicationActivities: [UIActivity]?
        if case .flatFile = requestExportOption {
            let fileName = exportNameForFile(requestExportOption: requestExportOption)
            let url = FileHandler.writeTxtFileToTempDirectory(text: text, fileName: fileName)
            activityItems = [NSURL.fileURL(withPath: url.path)]
            
        } else {
            activityItems = [text]
            applicationActivities = [customItem]
        }
        
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        presentingViewController.present(activityViewController, animated: true, completion: nil)
     }
        
    private static func exportNameForFile(requestExportOption: RequestResponseExportOption) -> String {
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyyMMdd_HHmmss_SSS"
        let suffix: String
        switch requestExportOption {
        case .flat, .flatFile:
            suffix = "-wormholy.txt"
        case .curl:
            suffix = "-wormholy.txt"
        case .postman:
            suffix = "-postman_collection.json"
        }
        
        let filename = "\(appName)_\(dateFormatterGet.string(from: Date()))\(suffix)"
        return filename
    }
    
    private static func getTxtText(requests: [RequestModel]) -> String {
        var text: String = ""
        for request in requests{
            text = text + RequestModelBeautifier.txtExport(request: request)
        }
        return text
    }
    
    private static func getCurlText(requests: [RequestModel]) -> String {
        var text: String = ""
        for request in requests{
            text = text + RequestModelBeautifier.curlExport(request: request)
        }
        return text
    }
    
    private static func getPostmanCollection(requests: [RequestModel]) -> String? {
        var items: [PMItem] = []
        
        for request in requests {
            guard let postmanItem = request.postmanItem else { continue }
            items.append(postmanItem)
        }
        
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyyMMdd_HHmmss_SSS"
        
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        
        let collectionName = "\(appName) \(dateFormatterGet.string(from: Date()))"

        let info = PMInfo(postmanID: collectionName, name: collectionName, schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json")
        
        let postmanCollectionItem = PMItem(name: collectionName, item: items, request: nil, response: nil)
        
        let postmanCollection = PostmanCollection(info: info, item: [postmanCollectionItem])
        
        let encoder = JSONEncoder()
        
        if let data = try? encoder.encode(postmanCollection), let string = String(data: data, encoding: .utf8) {
            return string
        }
        else {
            return nil
        }
    }
}
