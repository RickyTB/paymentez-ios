//
//  PaymentezRequest.swift
//  PaymentezSDKSample
//
//  Created by Gustavo Sotelo on 03/05/16.
//  Copyright © 2016 Paymentez. All rights reserved.
//

import Foundation

@objcMembers open class PaymentezDebitParameters: NSObject {
    open var uid = ""
    open var token = ""
    open var productAmount = 0.0
    open var productDescription = ""
    open var devReference = ""
    open var vat = 0.0
    open var email = ""
    open var productDiscount = 0.0
    open var installments = 1
    open var buyerFiscalNumber = ""
    open var sellerId = ""
    open var shippingStreet = ""
    open var shippingHouseNumber = ""
    open var shippingCity = ""
    open var shippingZip = ""
    open var shippingState = ""
    open var shippingCountry = ""
    open var shippingDistrict = ""
    open var shippingAdditionalAddressInfo = ""
    
    func requiredUserDict() -> [String:Any] {
        var dic = [String:Any]()
        dic["id"] = self.uid
        dic["email"] = self.email
        if self.buyerFiscalNumber != ""{dic["fiscal_number"] = self.buyerFiscalNumber }
        return dic
    }
    
    func requiredProductDict() -> [String:Any] {
        var dic = [String:Any]()
        dic["amount"] = self.productAmount
        dic["description"] = self.productDescription
        dic["dev_reference"] = self.devReference
        dic["vat"] = self.vat
        
        
        if productDiscount > 0.0
        {
            dic["product_discount"] = String(format: "%.2f", self.productDiscount)
        }
        if self.installments > 1
        {
            dic["installments"] = self.installments
        }
        
        return dic
        
    }
    func requiredCardDict()->[String:Any]
    {
        var dic = [String:Any]()
        dic["token"] = self.token
        return dic
    }
    func requiredShippingInfoDict()->[String:Any]
    {
        var dic = [String:Any]()
        if self.shippingStreet != ""{dic["street"] = self.shippingStreet }
        if self.shippingHouseNumber != ""{dic["house_number"] = self.shippingHouseNumber }
        if self.shippingCity != ""{dic["city"] = self.shippingCity }
        if self.shippingZip != ""{dic["zip"] = self.shippingZip }
        if self.shippingState != ""{dic["state"] = self.shippingState }
        if self.shippingCountry != ""{dic["country"] = self.shippingCountry }
        if self.shippingDistrict != ""{dic["district"] = self.shippingDistrict }
        if self.shippingAdditionalAddressInfo != ""{dic["additional_address_info"] = self.shippingAdditionalAddressInfo }
        return dic
    }
    
    func requiredDict() -> [String:Any]
    {
        var dic = [String:Any]()
        dic["card_reference"] =  self.token
        dic["product_amount"] = String(format: "%.2f", self.productAmount)
        dic["product_description"] = self.productDescription
        dic["dev_reference"] = self.devReference
        dic["vat"] = String(format: "%.2f", self.vat)
        dic["email"] = self.email
        dic["uid"] = self.uid
        if productDiscount > 0.0
        {
            dic["product_discount"] = String(format: "%.2f", self.productDiscount)
        }
        if self.installments > 1
        {
            dic["installments"] = self.installments 
        }
        
        return dic
        
    }
    func allParamsDict() -> [String:Any]
    {
        var dic = [String:Any]()
        dic["card_reference"] =  self.token
        dic["product_amount"] = String(format: "%.2f", self.productAmount) 
        dic["product_description"] = self.productDescription 
        dic["dev_reference"] = self.devReference 
        dic["vat"] = String(format: "%.2f", self.vat) 
        dic["email"] = self.email 
        dic["uid"] = self.uid 
        if productDiscount > 0.0
        {
            dic["product_discount"] = String(format: "%.2f", self.productDiscount) 
        }
        if self.installments > 1
        {
            dic["installments"] = self.installments 
        }
        if self.buyerFiscalNumber != ""{dic["buyer_fiscal_number"] = self.buyerFiscalNumber }
        if self.sellerId != ""{dic["seller_id"] = self.sellerId }
        if self.shippingStreet != ""{dic["shipping_street"] = self.shippingStreet }
        if self.shippingHouseNumber != ""{dic["shipping_house_number"] = self.shippingHouseNumber }
        if self.shippingCity != ""{dic["shipping_city"] = self.shippingCity }
        if self.shippingZip != ""{dic["shipping_zip"] = self.shippingZip }
        if self.shippingState != ""{dic["shipping_state"] = self.shippingState }
        if self.shippingCountry != ""{dic["shipping_country"] = self.shippingCountry }
        if self.shippingDistrict != ""{dic["shipping_district"] = self.shippingDistrict }
        if self.shippingAdditionalAddressInfo != ""{dic["shipping_additional_address_info"] = self.shippingAdditionalAddressInfo }
        return dic
    }
 
}

class PaymentezRequest
{
    let testUrl = "https://ccapi-stg.paymentez.com"
    let prodUrl = "https://ccapi.paymentez.com"
    var testMode = false
    init(testMode:Bool!)
    {
        
    }
    func getUrl(_ base:String, parameters:NSDictionary) -> String
    {
        var completeUrl = self.testUrl + base
        if !testMode{
            completeUrl = self.prodUrl + base
        }
        completeUrl += "?" + encodeParamsGet(parameters)
        return completeUrl
    }
    func encodeParamsJson(_ parameters:NSDictionary) -> Data? {
        return try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
    }
    
    func encodeParams(_ parameters:NSDictionary) ->Data?
    {
        var bodyData = ""
        for (key,value) in parameters{
            let scapedKey = (key as! String).addingPercentEncoding(
                withAllowedCharacters: .urlHostAllowed)!
            let scapedValue = (value as! String).addingPercentEncoding(
                withAllowedCharacters: .urlHostAllowed)!
            bodyData += "\(scapedKey)=\(scapedValue)&"
        }
        return bodyData.data(using: String.Encoding.utf8, allowLossyConversion: true)
    }
    func encodeParamsGet(_ parameters:NSDictionary) -> String!
    {
        var bodyData = ""
        for (key,value) in parameters{
            let scapedKey = (key as! String).addingPercentEncoding(
                withAllowedCharacters: .urlHostAllowed)!
            let scapedValue = (value as! String).addingPercentEncoding(
                withAllowedCharacters: .urlHostAllowed)!
            bodyData += "\(scapedKey)=\(scapedValue)&"
        }
        
        return bodyData
    }
    func makeRequest(_ urlToRequest:String, parameters:NSDictionary, responseCallback:@escaping (_ error:NSError?, _ statusCode:Int?,_ responseData:Any?) ->Void)
    {
        var completeUrl = self.testUrl + urlToRequest
        if !testMode{
            completeUrl = self.prodUrl + urlToRequest
        }
        
        let url:URL? = URL(string: completeUrl)
        let session = URLSession.shared
        
        var request = URLRequest(url:url!)
        request.httpMethod = "POST"
        request.httpBody = encodeParams(parameters)
        
        let task = session.dataTask(with: request){
            data, resp, err in
            if err == nil
            {
                var json:Any? = nil
                
                do{
                    json = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves)
                    //print(json as Any)
                }
                catch {
                    
                }
                
                if json == nil{
                    let error = NSError(domain: "JSON", code: 400, userInfo: ["parsing" : false])
                    print ("parsing json error")
                    if resp != nil
                    {
                        
                        responseCallback(error, (resp as! HTTPURLResponse).statusCode,nil)
                    }
                    else
                    {
                        responseCallback(error, 400,nil)
                    }
                }
                else
                {
                    
                    //print(json as Any)
                    responseCallback(err as NSError?, (resp as! HTTPURLResponse).statusCode, json)
                }
            }
            else
            {
                responseCallback(err as NSError?, 400, nil)
            }
        }
        task.resume()
    }
    func makeRequestGet(_ urlToRequest:String, parameters:NSDictionary, responseCallback:@escaping (_ error:NSError?, _ statusCode:Int?,_ responseData:Any?) ->Void)
    {
        var completeUrl = self.testUrl + urlToRequest
        if !testMode{
            completeUrl = self.prodUrl + urlToRequest
        }
        completeUrl += "?" + encodeParamsGet(parameters)
        let url:URL? = URL(string: completeUrl)
        let session = URLSession.shared
        
        var request = URLRequest(url:url!)
        /*
         */
        request.httpMethod = "GET"
        
        
        
        let task = session.dataTask(with: request){ data, resp, err in
            
            if err == nil
            {
                var json:Any? = nil
                
                do{
                    json = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves)
                }
                catch {
                    
                }
                
                if json == nil{
                    let error = NSError(domain: "JSON", code: 400, userInfo: ["parsing" : false])
                    print ("parsing json error")
                    responseCallback(error, 400,nil)
                }
                else
                {
                    
                    
                    responseCallback(err as NSError?, (resp as! HTTPURLResponse).statusCode, json)
                }
            }
            else
            {
                responseCallback(err as NSError?, 400, nil)
            }
        }
        task.resume()
    }
    
    func makeRequestV2(_ urlToRequest:String, parameters:NSDictionary, token:String, responseCallback:@escaping (_ error:NSError?, _ statusCode:Int?,_ responseData:Any?) ->Void)
    {
        var completeUrl = self.testUrl + urlToRequest
        if !testMode{
            completeUrl = self.prodUrl + urlToRequest
        }
        
        let url:URL? = URL(string: completeUrl)
        let session = URLSession.shared
        
        var request = URLRequest(url:url!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Auth-Token")
        
 
        request.httpMethod = "POST"
        request.httpBody = encodeParamsJson(parameters)
        
        let task = session.dataTask(with: request){
            data, resp, err in
            //print(data as Any)
            if err == nil
            {
                var json:Any? = nil
                
                do{
                    json = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves)
                   // print(json as Any)
                }
                catch {
                    
                }
                
                if json == nil{
                    let error = NSError(domain: "JSON", code: 400, userInfo: ["parsing" : false])
                    print ("parsing json error")
                    if resp != nil
                    {
                        
                        responseCallback(error, (resp as! HTTPURLResponse).statusCode,nil)
                    }
                    else
                    {
                        responseCallback(error, 400,nil)
                    }
                }
                else
                {
                    
                    //print(json as Any)
                    responseCallback(err as NSError?, (resp as! HTTPURLResponse).statusCode, json)
                }
            }
            else
            {
                responseCallback(err as NSError?, 400, nil)
            }
        }
        task.resume()
    }
    func makeRequestGetV2(_ urlToRequest:String, parameters:NSDictionary, token:String, responseCallback:@escaping (_ error:NSError?, _ statusCode:Int?,_ responseData:Any?) ->Void)
    {
        var completeUrl = self.testUrl + urlToRequest
        if !testMode{
            completeUrl = self.prodUrl + urlToRequest
        }
        completeUrl += "?" + encodeParamsGet(parameters)
        let url:URL? = URL(string: completeUrl)
        let session = URLSession.shared
        
        var request = URLRequest(url:url!)
        /*do
         {
         
         let data = try NSJSONSerialization.dataWithJSONObject(parameters, options: .PrettyPrinted)
         request.HTTPBody = data
         }
         catch {
         
         }
         */
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Auth-Token")
        
        
        let task = session.dataTask(with: request){ data, resp, err in
            
            if err == nil
            {
                var json:Any? = nil
                //print(json)
                do{
                    json = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves)
                }
                catch  {
                     print("Unexpected error: \(error).")
                }
                
                if json == nil{
                    let error = NSError(domain: "JSON", code: 400, userInfo: ["parsing" : false])
                    print ("parsing json error")
                    responseCallback(error, 400,nil)
                }
                else
                {
                    
                    
                    responseCallback(err as NSError?, (resp as! HTTPURLResponse).statusCode, json)
                }
            }
            else
            {
                responseCallback(err as NSError?, 400, nil)
            }
        }
        task.resume()
    }
    
    
    
    
}
