//
//  CCAPI.swift
//  PaymentezSDKSample
//
//  Created by Gustavo Sotelo on 02/05/16.
//  Copyright © 2016 Paymentez. All rights reserved.
//

import Foundation
import UIKit
import CommonCrypto

@objc(PaymentezSDKClient)
@objcMembers open class PaymentezSDKClient: NSObject {
    static var inProgress = false
    static var apiCode = ""
    static var secretKey = ""
    static var enableTestMode = true
    static var request = PaymentezRequest(testMode: true)
    static var kountHandler:PaymentezSecure = PaymentezSecure(testMode: true)
    static var scanner = PaymentezCardScan()
    
    @objc(setRiskMerchantId:)
    public static func setRiskMerchantId(_ merchantId:String) {
        self.kountHandler.merchantId = merchantId
    }
    
    
    @objc(setEnvironment:secretKey:testMode:)
    public static func setEnvironment(_ apiCode:String, secretKey:String, testMode:Bool) {
        self.apiCode = apiCode
        self.secretKey = secretKey
        self.enableTestMode = testMode
        self.request.testMode = testMode
        self.kountHandler = PaymentezSecure(testMode: testMode)
    }
    
    private static func showAddViewControllerForUser(_ uid:String, email:String, presenter:UIViewController, callback:@escaping (_ error:PaymentezSDKError?, _ closed:Bool, _ added:Bool) -> Void) {
        let vc = PaymentezAddViewController(callback: { (error, isClose, added) in
            
            callback(error, isClose, added)
            
        })
        presenter.present(vc, animated: true, completion: {
            DispatchQueue.main.sync
                {
                    
                    let sessionId = self.kountHandler.generateSessionId()
                    var parameters = ["application_code" : apiCode,
                                      "uid" : uid,
                                      "email" : email,
                                      "session_id": sessionId as Any]  as [String : Any]
                    let authTimestamp = generateAuthTimestamp()
                    let authToken = generateAuthToken(parameters, authTimestamp: authTimestamp)
                    parameters["auth_timestamp"] = authTimestamp
                    parameters["auth_token"] = authToken
                    
                    kountHandler.collect(sessionId!) { (err) in
                        
                        if err == nil
                        {
                            
                            
                            
                            let url = self.request.getUrl("/api/cc/add/", parameters:parameters as NSDictionary)
                            
                            vc.loadUrl(url)
                            
                        }
                        else
                        {
                            callback(PaymentezSDKError.createError(err!), false, false)
                            
                        }
                    }
                    
            }
            
        })
        
        
    }
    @objc
    public static func getSecureSessionId() -> String {
        return self.kountHandler.getSecureSessionId()
    }
    
    @objc public static func add(_ card:PaymentezCard, uid:String, email:String,  callback:@escaping (_ error:PaymentezSDKError?, _ cardAdded:PaymentezCard?)->Void)
    {
        inProgress = true
        
        if card.cardType == .notSupported{
            callback(PaymentezSDKError.createError(403, description: "Card Not Supported", help: "Change Number", type:nil) , nil)
            return
        }
        
        let sessionId = self.kountHandler.generateSessionId()
        
        let userParameters = ["email": email, "id": uid, "fiscal_number": card.fiscalNumber ?? "" as Any]
        
        var auth_type = "AUTH_CVC"
        if card.cardType == .alkosto || card.cardType == .exito {
            auth_type = "AUTH_NIP"
            if card.nip == nil{
                auth_type = "AUTH_OTP"
            }
        }
        
        let cardParameters = ["number": card.cardNumber!, "holder_name": card.cardHolder!, "expiry_month": Int(card.expiryMonth ?? "0")! as Any, "expiry_year": Int(card.expiryYear ?? "0")! as Any, "cvc":card.cvc ?? "" as Any, "type": card.cardType.rawValue, "nip": card.nip ?? "" as Any, "card_auth" : auth_type] as [String : Any]
        
        let parameters = ["session_id": sessionId!,
                          "user": userParameters,
                          "card": cardParameters
            ] as [String : Any]
        
        kountHandler.collect(sessionId!) { (err) in
            
            
        }
        inProgress = true
        let token = generateAuthTokenV2()
        self.request.makeRequestV2("/v2/card/add", parameters: parameters as NSDictionary, token:token) { (error, statusCode, responseData) in
            
            inProgress = false
            if error == nil
            {
                
                if statusCode! != 200
                {
                    let responseD = responseData as! [String:Any]
                    let dataR = responseD["error"] as! [String:Any]
                    
                    let err = PaymentezSDKError.createError(statusCode!, description: dataR["description"] as! String, help: dataR["help"] as? String, type: dataR["type"] as? String)
                    callback(err, nil)
                    
                }
                else
                {
                    let dataR = responseData as! [String:Any]
                    let cardData = dataR["card"] as! [String:Any]
                    let cardAdded = PaymentezCard()
                    cardAdded.bin = cardData["bin"] as? String
                    cardAdded.termination = cardData["number"] as? String
                    cardAdded.token = cardData["token"] as? String
                    cardAdded.expiryYear = card.expiryYear
                    cardAdded.expiryMonth = card.expiryMonth
                    cardAdded.cardHolder = card.cardHolder
                    cardAdded.transactionId = cardData["transaction_reference"] as? String
                    cardAdded.status = cardData["status"] as? String
                    cardAdded.type = cardData["type"] as? String
                    cardAdded.msg = cardData["message"] as? String
                    
                    
                    if cardAdded.status == "rejected"
                    {
                        let error = PaymentezSDKError.createError(statusCode!, description: (cardData["message"] as? String ?? "")!, help: "", type:nil)
                        callback(error, cardAdded)
                    }
                    else if cardAdded.status == "review"
                    {
                        
                        let error = PaymentezSDKError.createError(statusCode!, description: (cardData["message"] as? String ?? "")!, help: "", type:nil)
                        callback(error, cardAdded)
                    }
                    else
                    {
                        callback(nil, cardAdded)
                    }
                    
                }
            }
            else
            {
                callback(PaymentezSDKError.createError(error!), nil)
            }
            
        }
    }
    
    
    private static func addCardForUser(_ uid:String,
                                       email:String,
                                       expiryYear:Int,
                                       expiryMonth:Int,
                                       holderName:String,
                                       cardNumber:String,
                                       cvc:String,
                                       callback:@escaping (_ error:PaymentezSDKError?, _ added:Bool)->Void)
    {
        addCard(uid, email: email, expiryYear: expiryYear, expiryMonth: expiryMonth, holderName: holderName, cardNumber: cardNumber, cvc: cvc) { (error, added) in
            if error == nil{
                callback(nil, added)
            }
            
            
            
        }
    }
    
    static func addCard(_ uid:String!,
                        email:String!,
                        expiryYear:Int!,
                        expiryMonth:Int!,
                        holderName:String!,
                        cardNumber:String!,
                        cvc:String!,
                        callback:@escaping (_ error:PaymentezSDKError?, _ added:Bool)->Void
        
        
        
        
        
        )
    {
        DispatchQueue.global().sync
            {
                var typeCard = ""
                switch PaymentezCard.getTypeCard(cardNumber)
                {
                case .amex:
                    typeCard = "ax"
                case .visa:
                    typeCard = "vi"
                case .masterCard:
                    typeCard = "mc"
                case .diners:
                    typeCard = "di"
                default:
                    // (typeError:PaymentezSDKTypeAddError.insuficientParams, code: 0, description: "Card Not Supported", details: "number")
                    callback(PaymentezSDKError.createError(0, description: "Card Not Supported", help: "number", type:nil) , false)
                }
                
                let sessionId = self.kountHandler.generateSessionId()
                var parameters = ["application_code" : apiCode,
                                  "uid" : uid,
                                  "email" : email,
                                  "session_id": sessionId as Any] as [String : Any]
                let authTimestamp = generateAuthTimestamp()
                let authToken = generateAuthToken(parameters , authTimestamp: authTimestamp)
                parameters["auth_timestamp"] = authTimestamp
                parameters["auth_token"] = authToken
                parameters["expiryYear"] = "\(String(describing: expiryYear))"
                parameters["expiryMonth"] = "\(String(describing: expiryMonth))"
                parameters["holderName"] = holderName
                parameters["number"] = cardNumber
                parameters["cvc"] = cvc
                parameters["card_type"] = typeCard
                
                kountHandler.collect(sessionId!) { (err) in
                    
                    if err == nil
                    {
                        self.request.makeRequest("/api/cc/add/creditcard", parameters: parameters as NSDictionary) { (error, statusCode, responseData) in
                            
                            
                            if error == nil
                            {
                                
                                if statusCode! != 200
                                {
                                    let dataR = responseData as! [String:Any]
                                    
                                    let err = PaymentezSDKError.createError(statusCode!, description: dataR["description"] as! String, help: dataR["details"] as? String, type:nil)
                                    callback(err, false)
                                    
                                }
                                else
                                {
                                    callback(nil, true)
                                }
                            }
                            else
                            {
                                callback(PaymentezSDKError.createError(error!), false)
                            }
                            
                        }
                    }
                    else
                    {
                        callback(PaymentezSDKError.createError(err!), false)
                        
                    }
                }
                
        }
        
        
    }
    
    internal static func listCards(_ uid:String!, callback:@escaping (_ error:PaymentezSDKError?, _ cardList:[PaymentezCard]?) ->Void)
    {
        listCardsV2(uid) { (error, cards) in
            callback(error,cards)
        }
    }
    internal static func listCardsV2(_ uid:String!, callback:@escaping (_ error:PaymentezSDKError?, _ cardList:[PaymentezCard]?) ->Void)
    {
        
        let parameters = ["uid": uid] as [String:Any]
        let token = generateAuthTokenV2()
        self.request.makeRequestGetV2("/v2/transaction/list/", parameters: parameters as NSDictionary, token: token) { (error, statusCode, responseData) in
            
            
            
            if error == nil
            {
                let responseObj = responseData as! NSDictionary
                let cardsArray = responseObj["cards"] as! [[String:Any]]
                var responseCards = [PaymentezCard]()
                
                for card in cardsArray
                {
                    let pCard = PaymentezCard()
                    let expiration_date = (card["expiration_date"] as! String).components(separatedBy: "/")
                    pCard.bin = "\(card["bin"]!)"
                    pCard.token = "\(card["token"]!)"
                    pCard.cardHolder = "\(card["name"]!)"
                    pCard.expiryMonth = expiration_date[0]
                    pCard.expiryYear = expiration_date[1]
                    pCard.termination = "\(card["number"]!)"
                    pCard.type = "\(card["type"]!)"
                    pCard.status = "\(card["status"]!)"
                    responseCards.append(pCard)
                }
                
                callback(nil,responseCards)
                
            }
            else
            {
                callback(PaymentezSDKError.createError(error!),nil)
            }
            
        }
    }
    
    internal static func deleteCard(_ uid:String, cardReference:String, callback:@escaping (_ error:PaymentezSDKError?, _ wasDeleted:Bool) ->Void)
    {
        
        
        
        
        /*
         var parameters = ["application_code" : apiCode,
         "card_reference" : cardReference,
         "uid" : uid]
         let authTimestamp = generateAuthTimestamp()
         let authToken = generateAuthToken(parameters as [String : Any], authTimestamp: authTimestamp)
         parameters["auth_token"] = authToken
         parameters["auth_timestamp"] = authTimestamp
         
         self.request.makeRequest("/api/cc/delete/", parameters:parameters as NSDictionary) { (error, statusCode, responseData) in
         
         if error == nil
         {
         if statusCode! != 200
         {
         let dataR = (responseData as! [String:Any])["errors"] as! [[String:Any]]
         callback(PaymentezSDKError.createError(dataR[0]["code"] as! Int, description: dataR[0]["description"] as! String, details: dataR[0]["details"] as! String), false)
         }
         else
         {
         callback(nil, true)
         }
         }
         else
         {
         if statusCode! == 200
         {
         callback(nil, true)
         }
         else
         {
         callback(PaymentezSDKError.createError(error!), false)
         }
         }
         }*/
    }
    internal static func deleteCard(_ uid:String, card:PaymentezCard, callback:@escaping (_ error:PaymentezSDKError?, _ wasDeleted:Bool) ->Void)
    {
        if card.token == nil {
            callback(PaymentezSDKError.createError(400, description: "Incorrect Token", help: nil, type:nil), false)
        }
        else
        {
            
            let userparams = ["id" : uid]
            let cardparams = ["token": card.token!]
            let parameters = ["user": userparams, "card": cardparams] as [String:Any]
            let token = generateAuthTokenV2()
            self.request.makeRequestV2("/v2/transaction/delete/", parameters: parameters as NSDictionary, token: token) { (error, statusCode, responseData) in
                
                
                
                if error == nil
                {
                    if statusCode == 200
                    {
                        callback(nil,true)
                    }
                    else
                    {
                        callback(PaymentezSDKError.createError(403, description: "", help: nil, type:nil), false)
                    }
                    
                }
                else
                {
                    callback(PaymentezSDKError.createError(error!),false)
                }
                
            }
        }
        
        
    }
    
    internal static func debitCard(_ parameters:PaymentezDebitParameters, callback: @escaping (_ error:PaymentezSDKError?, _ transaction:PaymentezTransaction?) ->Void)
    {
        if inProgress
        {
            callback(PaymentezSDKError.createError(500, description: "Request in Progress", help: "", type:nil),nil)
            return
        }
        inProgress = true
        inProgress = false
        
        let userParams = parameters.requiredUserDict()
        let cardParams = parameters.requiredCardDict()
        let productParams =  parameters.requiredProductDict()
        let shippingParams = parameters.requiredShippingInfoDict()
        let sessionId = self.kountHandler.generateSessionId()
        let parametersDic = ["user": userParams, "card": cardParams, "product":productParams, "shipping_info": shippingParams, "session_id": sessionId as Any] as [String : Any]
        
        inProgress = true
        kountHandler.collect(sessionId!) { (err) in
            
            inProgress = false
            if err == nil
            {
                inProgress = true
                self.request.makeRequestV2("/v2/transaction/debit/", parameters: parametersDic as NSDictionary, token: generateAuthTokenV2(), responseCallback: { (error, statusCode, responseData) in
                    
                    inProgress = false
                    if error == nil
                    {
                        if statusCode == 200
                        {
                            let responseD = responseData as! [String:Any]
                            
                            let response = PaymentezTransaction.parseTransactionV2(responseD["transaction"] as! [String:Any])
                            if response.statusDetail == 11
                            {
                                callback(nil, response)
                            }
                            else if response.statusDetail != 3
                            {
                                let error = PaymentezSDKError.createError(response.statusDetail as! Int, description: response.message!, help: "", type:nil)
                                callback(error, response)
                            }
                            else
                            {
                                callback(nil, response)
                            }
                            
                            
                        }
                        else
                        {
                            do {
                                var dataR = (responseData as! [String:Any])
                                if dataR["error"] != nil
                                {
                                    dataR = dataR["error"] as! [String:Any]
                                }
                                let errorPa =  PaymentezSDKError.createError(statusCode!, description: dataR["description"] as! String, help: dataR["help"] as? String, type: dataR["type"] as? String)
                                
                                callback(errorPa, nil)
                            }
                            
                        }
                    }
                    else
                    {
                        callback(PaymentezSDKError.createError(error!), nil)
                    }
                    
                    
                })
            }
            else
            {
                
                callback(PaymentezSDKError.createError(err!), nil)
            }
        }
    }
    internal static func refund(_ transactionId:String, callback:@escaping (_ error:PaymentezSDKError?,_ refunded:Bool)->Void)
        
    {
        let transactionparams = ["id": transactionId]
        let parameters = ["transaction": transactionparams] as [String:Any]
        let token = generateAuthTokenV2()
        self.request.makeRequestV2("/v2/transaction/refund/", parameters: parameters as NSDictionary, token: token) { (error, statusCode, responseData) in
            
            
            
            if error == nil
            {
                if statusCode == 200
                {
                    var dataR = (responseData as! [String:String])
                    if dataR["status"] == "success"
                    {
                        callback(nil,true)
                    }
                    else
                    {
                        callback(nil,false)
                    }
                    
                }
                else
                {
                    do {
                        var dataR = (responseData as! [String:Any])
                        if dataR["error"] != nil
                        {
                            dataR = dataR["error"] as! [String:Any]
                        }
                        let errorPa =  PaymentezSDKError.createError(statusCode!, description: dataR["description"] as! String, help: dataR["help"] as? String, type:dataR["type"] as? String)
                        
                        callback(errorPa, false)
                    }
                }
            }
            else
            {
                callback(PaymentezSDKError.createError(error!), false)
            }
            
        }
    }
    
    
    
    internal static func verifyWithCode(_ transactionId:String, uid:String, verificationCode:String, callback:@escaping (_ error:PaymentezSDKError?, _ attemptsRemaining:Int, _ transaction:PaymentezTransaction?)->Void)
        
    {
        let userparams = ["id": uid]
        let transactionparams = ["id": transactionId]
        let parameters = ["user": userparams, "transaction": transactionparams, "type": "BY_AUTH_CODE", "value":verificationCode] as [String:Any]
        let token = generateAuthTokenV2()
        self.request.makeRequestV2("/v2/transaction/verify/", parameters: parameters as NSDictionary, token: token) { (error, statusCode, responseData) in
            
            
            
            if error == nil
            {
                if statusCode == 200
                {
                    let transaction = PaymentezTransaction.parseTransaction(responseData)
                    callback(nil, 0, transaction)
                }
                else
                {
                    do {
                        var dataR = (responseData as! [String:Any])
                        if dataR["error"] != nil
                        {
                            dataR = dataR["error"] as! [String:Any]
                        }
                        let errorPa =  PaymentezSDKError.createError(statusCode!, description: dataR["description"] as! String, help: dataR["help"] as? String, type: dataR["type"] as? String)
                        
                        callback(errorPa, 0 , nil)
                    }
                }
            }
            else
            {
                callback(PaymentezSDKError.createError(error!), 0 , nil)
            }
            
        }
    }
    
    internal static func verifyWithAmount(_ transactionId:String, uid:String, amount:Double, callback:@escaping (_ error:PaymentezSDKError?, _ attemptsRemaining:Int, _ transaction:PaymentezTransaction?)->Void)
        
    {
        let userparams = ["id": uid]
        let transactionparams = ["id": transactionId]
        let parameters = ["user": userparams, "transaction": transactionparams, "type": "BY_AMOUNT", "value":String(amount)] as [String:Any]
        let token = generateAuthTokenV2()
        self.request.makeRequestV2("/v2/transaction/verify/", parameters: parameters as NSDictionary, token: token) { (error, statusCode, responseData) in
            
            
            
            if error == nil
            {
                if statusCode == 200
                {
                    let transaction = PaymentezTransaction.parseTransaction(responseData)
                    callback(nil, 0, transaction)
                }
                else
                {
                    do {
                        var dataR = (responseData as! [String:Any])
                        if dataR["error"] != nil
                        {
                            dataR = dataR["error"] as! [String:Any]
                        }
                        let errorPa =  PaymentezSDKError.createError(statusCode!, description: dataR["description"] as! String, help: dataR["help"] as? String, type: dataR["type"] as? String)
                        
                        callback(errorPa, 0 , nil)
                    }
                }
            }
            else
            {
                callback(PaymentezSDKError.createError(error!), 0 , nil)
            }
            
        }
    }
    
    
    static fileprivate func generateAuthTimestamp() -> String {
        let timestamp = Date().timeIntervalSince1970 * 1000
        return "\(Int(timestamp))"
    }
    
    static fileprivate func generateAuthTokenV2() -> String {
        let timestamp = self.generateAuthTimestamp()
        let uniqueString = secretKey + timestamp
        let uniqueToken = uniqueString.sha256()
        let tokenPlain = apiCode + ";" + timestamp + ";" + uniqueToken
        return tokenPlain.base64Encoded()!
    }
    
    static fileprivate func generateAuthToken(_ parameters:[String:Any], authTimestamp:String!) -> String {
        let paramsDict = Array(parameters.keys).sorted(by: {$0 < $1})
        var paramsString = ""
        for paramName in paramsDict
        {
            let value = (parameters[paramName] as! String).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            paramsString += "\(paramName)=\(value!)&"
        }
        
        paramsString = paramsString + authTimestamp + "&" + secretKey
        
        let dataIn = paramsString.data(using: String.Encoding.utf8)!
        let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256((dataIn as NSData).bytes, CC_LONG(dataIn.count), res?.mutableBytes.assumingMemoryBound(to: UInt8.self))
        var hash:String = res!.description
        hash = hash.replacingOccurrences(of: " ", with: "")
        hash = hash.replacingOccurrences(of: "<", with: "")
        hash = hash.replacingOccurrences(of: ">", with: "")
        //print(hash)
        return hash
        
    }
    
    @objc public static func scanCard(_ presenterViewController:UIViewController, callback:@escaping (_ userCancelled:Bool, _ number:String?, _ expiry:String?, _ cvv:String?,_ card:PaymentezCard?) ->Void)
        
    {
        self.scanner.showScan(presenterViewController) { (infoCard) in
            
            if infoCard == nil
            {
                callback(true, nil, nil, nil, nil)
            }
            else
            {
                let card = PaymentezCard()
                
                card.cardNumber = infoCard!.cardNumber
                card.cvc = infoCard!.cvv
                card.expiryYear = "\(infoCard!.expiryYear)"
                card.expiryMonth = String(format: "%02i",infoCard!.expiryMonth)
                callback(false, infoCard!.cardNumber, String(format: "%02i/%i",infoCard!.expiryMonth, infoCard!.expiryYear), infoCard!.cvv, card)
                
            }
            
        }
        
    }
    
}

extension String {
    //: ### Base64 encoding a string
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    //: ### Base64 decoding a string
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func sha256() -> String {
        if let stringData = self.data(using: String.Encoding.utf8) {
            return hexStringFromData(input: digest(input: stringData as NSData))
        }
        return ""
    }

    private func digest(input : NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }

    private  func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)

        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }

        return hexString
    }
}
