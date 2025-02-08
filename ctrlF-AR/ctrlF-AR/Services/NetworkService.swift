//
//  NetworkService.swift
//  ctrlF-AR
//
//  Created by Emily Xie on 2/8/25.
//

import Foundation

class NetworkService {
    static func fetchObjects(completion: @escaping ([[String: Any]]) -> Void) {
        let url = URL(string: "http://192.168.0.101:5000/get-objects")!

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let objects = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
                print("❌ Error fetching objects: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            completion(objects)
        }.resume()
    }
    
    static func fetchObjectNames(completion: @escaping ([String]) -> Void) {
        let urlString = "http://192.168.0.101:5000/get-objects"  // Change to correct API if needed
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let objects = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
                print("❌ Error fetching objects: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }

            // Extract unique object names
            let objectNames = Set(objects.compactMap { $0["name"] as? String })
            completion(Array(objectNames))
        }.resume()
    }
    
    
}

