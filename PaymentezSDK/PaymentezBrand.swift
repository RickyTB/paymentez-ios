//
//  PaymentezBrand.swift
//  PaymentezSDK
//
//  Created by Ricardo Baquero on 11/14/19.
//  Copyright © 2019 Paymentez. All rights reserved.
//

import Foundation

public enum PaymentezCardType: String {
    case visa = "vi"
    case masterCard = "mc"
    case amex = "ax"
    case diners = "di"
    case discover = "dc"
    case jcb = "jb"
    case elo = "el"
    case credisensa = "cs"
    case solidario = "so"
    case exito = "ex"
    case alkosto = "ak"
    case notSupported = ""
}

struct PaymentezBrand {
    var type: PaymentezCardType
    var regex: String
    var prefixes: [String]
    var maxLength: Int
    var imagePath: String
}
