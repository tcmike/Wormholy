//
//  Wormholy+CustomButtons.swift
//  Wormholy-iOS
//
//  Created by Alexandr Sivash on 12.03.2024.
//  Copyright © 2024 Wormholy. All rights reserved.
//

import Foundation

public enum WormholyPresentationStyle {
    case push
    case present
}

extension Wormholy {
    
    public struct Style: OptionSet {
        public let rawValue: UInt8
        public static let `default` = Style([])
        public static let destructive = Style(rawValue: 1 << 0)
        public static let selected = Style(rawValue: 1 << 1)
        public static let cancel = Style(rawValue: 1 << 2)
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
    }
    
    ///Структура, описывающая кнопку в дополнительном меню вормхоли
    public indirect enum ButtonDescriptor {
        case action(title: String, style: Style = .default, handler: () -> (isPush: Bool, controller: UIViewController)?)
        case submenu(title: String, style: Style = .default, children: [ButtonDescriptor])
    }
    
    static var additionalButtonsBlock: () -> [ButtonDescriptor] = { [] }
    
    public static func setAdditionalButtons(buttons: @escaping () -> [ButtonDescriptor]) {
        additionalButtonsBlock = buttons
    }
}
