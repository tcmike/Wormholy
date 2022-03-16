//
//  SwiftySelfAwareHelper.swift
//  Wormholy
//
//  Created by Kealdish on 2019/2/28.
//  Copyright © 2019 Wormholy. All rights reserved.
//

import Foundation
import UIKit

// The class used by StarterEnginer (objc) to start all the process.
class StarterEngine: NSObject {
    @objc static func appWillLaunch(_: Notification) {
        Wormholy.awake()
    }
}
