//
//  extensions.swift
//  webrtcClientTutorialpoint
//
//  Created by ajay singh thakur on 02/06/17.
//  Copyright © 2017 ajay singh thakur. All rights reserved.
//

import UIKit
extension Dictionary {
    
    var json: String {
        let invalidJson = "Not a valid JSON"
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
        } catch {
            return invalidJson
        }
    }
    
    func printJson() {
        print(json)
    }
    
}
extension String {
    var dictionary : [String : Any] {
    
        let dict: Dictionary<String, Any> = [:]
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return dict
    
        
    }
    func printDict() {
        print(dictionary)
    }
}
