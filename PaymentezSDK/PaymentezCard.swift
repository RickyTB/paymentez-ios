//
//  File.swift
//  PaymentezSDKSample
//
//  Created by Gustavo Sotelo on 02/05/16.
//  Copyright © 2016 Paymentez. All rights reserved.
//

import Foundation
import UIKit

typealias ValidationCallback = (PaymentezBrand?) -> Void

@objcMembers open class PaymentezCard: NSObject {
    
    open var status:String?
    open var transactionId:String?
    open var token:String?
    open var cardHolder:String?
    open var fiscalNumber: String?
    open var termination:String?
    open var isDefault:Bool = false
    open var expiryMonth:String?
    open var expiryYear:String?
    open var bin:String?
    open var nip:String?
    open var msg:String?
    open var cardType:PaymentezCardType = .notSupported
    internal var cardNumber: String? {
        didSet {
            if let cardNumber = self.cardNumber {
                self.termination = String(cardNumber.suffix(4))
            }
        }
    }
    internal var cvc: String?
    open var type: String?
    {
        didSet
        {
            if self.type == "vi"
            {
                self.cardType = .visa
                
            }
            if self.type == "ax"
            {
                self.cardType = .amex
            }
            if self.type == "mc"
            {
                self.cardType = .masterCard
            }
            if self.type == "di"
            {
                self.cardType = .diners
            }
            if self.type == "al"
            {
                self.cardType = .alkosto
            }
            if self.type == "ex"
            {
                self.cardType = .exito
            }
        }
    }
    
    override open var description: String {
        return "\(status), \(transactionId), \(token), \(cardHolder), \(fiscalNumber), \(termination), \(isDefault), \(expiryMonth), \(expiryYear), \(bin), \(nip), \(msg), \(cardType), \(cardNumber) \(cvc), \(type)"
    }


    public static func createCard(cardHolder:String, cardNumber:String, expiryMonth:NSInteger, expiryYear:NSInteger, cvc:String) ->PaymentezCard? {
        let paymentezCard = PaymentezCard()
        if getTypeCard(cardNumber) == .notSupported { return nil }
        let today = Date()
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.month, .year], from: today)
        
        let todayMonth = components.month!
        let todayYear = components.year!
        
        if todayYear < expiryYear { return nil }
        if expiryYear == todayYear && todayMonth > expiryMonth { return nil }
        
        paymentezCard.cardNumber = cardNumber
        paymentezCard.cardHolder = cardHolder
        paymentezCard.expiryMonth = "\(expiryMonth)"
        paymentezCard.expiryYear = "\(expiryYear)"
        paymentezCard.cvc = cvc
        return paymentezCard
    }
    
    
    static func validateExpDate(_ expDate:String) -> Bool {
        let today = Date()
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.month, .year], from: today)
        
        let todayMonth = components.month!
        let todayYear = components.year! - 2000
        
        let valExp = expDate.components(separatedBy: "/")
        if valExp.count > 1
        {
            let expYear = Int(valExp[1])!
            let expMonth = Int(valExp[0])!
            if expYear > todayYear
            {
                return true
            }
            else if expYear == todayYear && expMonth > todayMonth && expMonth <= 12
            {
                return true
            }
        }
        
        return false
    }
    
    public func getJSONString() -> String? {
        if let json = try? JSONSerialization.data(withJSONObject: self.getDict(), options: .prettyPrinted) {
            let theJSONText = String(data: json, encoding: .ascii)
            return theJSONText
        }
        return nil
    }
    
    public func getDict() -> NSDictionary {
        let dict = [
            "bin" : self.bin,
            "status": self.status,
            "token": self.token,
            "expiry_year": self.expiryYear,
            "expiry_month": self.expiryMonth,
            "transaction_reference": self.transactionId,
            "holder_name": self.cardHolder,
            "type": self.type,
            "number": self.termination,
            "message": ""
        ]
        return dict as NSDictionary
    }
    
    public func getCardTypeAsset() -> UIImage?
    {
        let bundle = Bundle(for: PaymentezCard.self)
        if cardType == PaymentezCardType.amex
        {
            return UIImage(named:"stp_card_amex", in: bundle, compatibleWith: nil)
        }
        else if cardType == PaymentezCardType.masterCard
        {
            return UIImage(named:"stp_card_mastercard", in: bundle, compatibleWith: nil)
            
        }
        else if cardType == PaymentezCardType.visa
        {
            return UIImage(named:"stp_card_visa", in: bundle, compatibleWith: nil)
        }
        else if cardType == PaymentezCardType.diners
        {
            return UIImage(named:"stp_card_diners", in: bundle, compatibleWith: nil)
        }
        else if cardType == PaymentezCardType.discover
        {
            return UIImage(named:"stp_card_discover", in: bundle, compatibleWith: nil)
        }
        else if cardType == PaymentezCardType.jcb
        {
            return UIImage(named:"stp_card_jcb", in: bundle, compatibleWith: nil)
        }
        else {
            return UIImage(named: "stp_card_unknown", in: bundle, compatibleWith: nil)
        }

    }
    
    public static func getTypeCard(_ cardNumber:String) -> PaymentezCardType {
        if cardNumber.count < 14  || cardNumber.count > 16 {
            return .notSupported
        }
        
        let brand = BRANDS.first { (brand: PaymentezBrand) -> Bool in
            let predicateAmex = NSPredicate(format: "SELF MATCHES %@", brand.regex)
            return predicateAmex.evaluate(with: cardNumber)
        }
        
        return brand?.type ?? .notSupported
    }
    
    static func validate(cardNumber: String, callback: @escaping ValidationCallback){
        guard let brand = BRANDS.first(where: { $0.prefixes.contains { cardNumber.starts(with: $0) } }) else {
            callback(nil)
            return
        }
        callback(brand)
    }
    
}

@objcMembers open class PaymentezTransaction:NSObject
{
    open var authorizationCode:NSNumber?
    open var amount:NSNumber?
    open var paymentDate: Date?
    open var status:String?
    open var carrierCode:String?
    open var message:String?
    open var statusDetail:NSNumber?
    open var transactionId:String?
    open var carrierData:[String:Any]?
    
    static func parseTransaction(_ data:Any?) ->PaymentezTransaction
    {
        let data = data as! [String:Any]
        let trx = PaymentezTransaction()
        trx.amount = data["amount"] as? NSNumber
        trx.status = data["status"] as? String
        trx.statusDetail = data["status_detail"] as? Int as NSNumber?
        trx.transactionId = data["transaction_id"] as? String
        trx.carrierData = data["carrier_data"] as? [String:Any]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        if let paymentdate = (data["payment_date"] as? String)
        {
            trx.paymentDate = dateFormatter.date(from: paymentdate)
        }
        
        return trx
        
    }
    static func parseTransactionV2(_ data:Any?) ->PaymentezTransaction
    {
        let data = data as! [String:Any]
        let trx = PaymentezTransaction()
        trx.amount = data["amount"] as? NSNumber
        trx.status = data["status"] as? String
        trx.statusDetail = data["status_detail"] as? Int as NSNumber?
        trx.transactionId = data["id"] as? String
        trx.authorizationCode = data["authorization_code"] as? Int as NSNumber?
        trx.carrierCode = data["carrier_code"] as? String
        trx.message = data["message"] as? String
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        if let paymentdate = (data["payment_date"] as? String)
        {
            trx.paymentDate = dateFormatter.date(from: paymentdate)
        }
        
        return trx
    }
}
