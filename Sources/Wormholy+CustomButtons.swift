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
    public let style: WormholyPresentationStyle
    public let block: () -> UIViewController?
    
    public init(title: String, style: WormholyPresentationStyle = .push, block: @escaping () -> UIViewController?) {
        self.title = title
        self.style = style
        self.block = block
    }
}

public enum WormholyPresentationStyle {
    case push
    case present
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
