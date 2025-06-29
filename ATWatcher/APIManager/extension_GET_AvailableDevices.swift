//
//  extension_ListFetcher.swift
//  ATWatcher
//
//  Created by Timo Reinhardt on 19.06.25.
//

import Foundation

extension APIManager {
    
    func fetchAvailableDevicesFromBackend() async {
        
        do {
            print("[APIManager DeviceFetch] Updating available devices...")
            try await attemptDeviceRetrieval()
        } catch {
            print("[APIManager DeviceFetch] Unable to complete fetching of available devices: " + error.localizedDescription)
        }
        
    }
    
    
    fileprivate func attemptDeviceRetrieval() async throws {
        
        guard let url = URL(string: "https://192.168.26.43/api/atvunlock/list") else {
            print("[APIManager DeviceFetch] Internal error while creating URL")
            throw NSError(domain: "An internal error occurred while creating the URL", code: -99)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let session = URLSessionMTLS.shared
        
        do {
            let (retrievedData, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[APIManager DeviceFetch] Unknown api error")
                throw NSError(domain: "Unknown api error", code: -1)
            }
            
            switch httpResponse.statusCode {
            case 200:
                loadDevices(from: retrievedData)
                print("[APIManager DeviceFetch] Device list updated successfully")
            default:
                print("[APIManager DeviceFetch] Unknown api error")
                throw NSError(domain: "Unknown api error", code: -1)
            }
        }
        
    }
    
    
    /// Decodes device data from the provided JSON and updates available devices.
    ///
    /// - Parameter data: The raw JSON data returned from the API representing all available Apple TVs.
    /// - Note: If decoding fails, an error message is printed and no devices are updated.
    fileprivate func loadDevices(from data: Data) {
        do {
            let response = try JSONDecoder().decode(APIResponse.self, from: data)
            availableDevicePool = response.devices
        } catch {
            print("Failed to decode response: \(error)")
        }
    }
    
    
}
