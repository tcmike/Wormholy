//
//  Wormholy+CustomButtons.swift
//  Wormholy-iOS
//
//  Created by Alexandr Sivash on 12.03.2024.
//  Copyright © 2024 Wormholy. All rights reserved.
//

import Foundation

///Структура, описывающая кнопку в дополнительном меню вормхоли
public struct WormholyButtonDescriptor {
    
    public let title: String
    public let block: () -> UIViewController?
    
    public init(title: String, block: @escaping () -> UIViewController?) {
        self.title = title
        self.block = block
    }
}

extension Wormholy {
    
    static var additionalButtons: [WormholyButtonDescriptor] = []
    
    public static func setAdditionalButtons(buttons: [WormholyButtonDescriptor]) {
        additionalButtons = buttons
    }
    
    public static func adcAdditionalButton(button: WormholyButtonDescriptor) {
        additionalButtons.append(button)
    }
}
