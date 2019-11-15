//
//  PaymentezConstants.swift
//  PaymentezSDK
//
//  Created by Gustavo Sotelo on 07/09/18.
//  Copyright © 2018 Paymentez. All rights reserved.
//

import Foundation
import UIKit

class PaymentezStyle {
    static let baseBaseColor = UIColor(red:0.30, green:0.69, blue:0.31, alpha:1.0)
    static let baseFontColor: UIColor = .white
    static let font = UIFont.systemFont(ofSize: 16)
    static let fontSmall = UIFont.systemFont(ofSize: 14)
    static let fontExtraSmall = UIFont.systemFont(ofSize: 12)
}

// Based on http://en.wikipedia.org/wiki/Bank_card_number#Issuer_identification_number_.28IIN.29
let BRANDS = [
    PaymentezBrand(type: .visa, regex: "^4[0-9]{6,}$", prefixes: ["4"], maxLength: 16, imagePath: "stp_card_visa"),
    PaymentezBrand(type: .amex, regex: "^3[47][0-9]{5,}$", prefixes: ["34", "37"], maxLength: 15, imagePath: "stp_card_amex"),
    PaymentezBrand(type: .masterCard, regex: "^5[1-5][0-9]{5,}$", prefixes: ["2221", "2222", "2223", "2224", "2225", "2226", "2227", "2228", "2229", "223", "224", "225", "226", "227", "228", "229", "23", "24", "25", "26", "270", "271", "2720", "50", "51", "52", "53", "54", "55"], maxLength: 16, imagePath: "stp_card_mastercard"),
    PaymentezBrand(type: .diners, regex: "^3(?:0[0-5]|[68][0-9])[0-9]{4,}$", prefixes: ["300", "301", "302", "303", "304", "305", "309", "36", "38", "39"], maxLength: 14, imagePath: "stp_card_diners"),
    PaymentezBrand(type: .discover, regex: "^65[4-9][0-9]{13}|64[4-9][0-9]{13}|6011[0-9]{12}|(622(?:12[6-9]|1[3-9][0-9]|[2-8][0-9][0-9]|9[01][0-9]|92[0-5])[0-9]{10})$", prefixes: ["60", "62", "64", "65"], maxLength: 16, imagePath: "stp_card_discover"),
    PaymentezBrand(type: .jcb, regex: "^(?:2131|1800|35[0-9]{3})[0-9]{11}$", prefixes: ["35"], maxLength: 16, imagePath: "stp_card_jcb")
]
