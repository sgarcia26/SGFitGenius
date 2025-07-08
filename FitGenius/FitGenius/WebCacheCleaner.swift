//
//  WebCacheCleaner.swift
//  FitGenius
//
//  Created by Isai Flores on 31/5/21.
//

import Foundation
import WebKit

// Utility class for clearing web cache and cookies (used for Ready Player Me sessions or embedded WebViews)
final class WebCacheCleaner {
    
    // Clears all stored cookies and web data from WKWebView and shared HTTPCookieStorage
    class func clean() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
    
}
