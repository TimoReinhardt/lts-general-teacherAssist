//
//  URLSessionMTLSDelegate.swift
//  ATWatcher
//
//  Created by Timo Reinhardt on 20.06.25.
//


//
//  URLSessionMTLSDelegate.swift
//  HallwayHelper
//
//  Created by Timo Reinhardt on 12.02.25.
//

import Foundation



/// Custom URLSession delegate for handling mutual TLS authentication.
class URLSessionMTLSDelegate: NSObject, URLSessionDelegate {
    /// The SecIdentity representing the client's identity for client certificate authentication.
    let secIdentity: SecIdentity
    
    /// Initializes the URLSessionMTLSDelegate with a given SecIdentity.
    ///
    /// - Parameter secIdentity: The SecIdentity representing the client's identity.
    init(secIdentity: SecIdentity) {
        self.secIdentity = secIdentity
    }
    
    /// Handles URL authentication challenges, including server trust and client certificate challenges.
    ///
    /// - Parameters:
    ///   - session: The session containing the task that received the challenge.
    ///   - challenge: The authentication challenge.
    ///   - completionHandler: A closure to call to respond to the challenge.
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            // Server authentication challenge
            if let serverCertificate = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverCertificate)
                completionHandler(.useCredential, credential)
            }
            else {
                // Server certificate is not signed by our client certificate, so fail the challenge
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
            // Client authentication challenge
            let credential = URLCredential(identity: secIdentity, certificates: nil, persistence: .forSession)
            completionHandler(.useCredential, credential)
        } else {
            // Unsupported authentication challenge
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
