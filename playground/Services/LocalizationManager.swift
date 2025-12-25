//
//  LocalizationManager.swift
//  CalCalculator
//
//  Manages app localization and language switching
//

import Foundation
import SwiftUI
import Combine

/// Manager for handling app localization and language switching
@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "app_language")
            UserDefaults.standard.synchronize()
            
            // Set AppleLanguages for system localization (takes effect after app restart)
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
    }
    
    private init() {
        // Load saved language or default to system language
        if let savedLanguage = UserDefaults.standard.string(forKey: "app_language") {
            self.currentLanguage = savedLanguage
        } else {
            // Get system language code (e.g., "en", "es", "fr")
            let systemLanguage = Locale.preferredLanguages.first ?? "en"
            let languageCode = String(systemLanguage.prefix(2))
            self.currentLanguage = languageCode
        }
        
        // Set AppleLanguages on init
        UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
    /// Get the current language code
    var languageCode: String {
        currentLanguage
    }
    
    /// Get the current locale
    var currentLocale: Locale {
        Locale(identifier: currentLanguage)
    }
    
    /// Set the app language
    func setLanguage(_ languageCode: String) {
        guard currentLanguage != languageCode else { return }
        
        currentLanguage = languageCode
        
        print("🌐 [LocalizationManager] Language set to: \(languageCode)")
        
        // Post notification to reload the app
        NotificationCenter.default.post(name: .languageChanged, object: languageCode)
    }
    
    /// Get localized string from the appropriate language bundle
    func localizedString(for key: String, comment: String = "") -> String {
        // Try to get from the selected language bundle
        if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let localized = bundle.localizedString(forKey: key, value: nil, table: nil)
            // If we got a different value than the key, return it
            if localized != key {
                return localized
            }
        }
        
        // Fallback to main bundle
        return NSLocalizedString(key, comment: comment)
    }
}

// MARK: - Language Code Mapping

extension LocalizationManager {
    /// Map language name to language code
    static func languageCode(from name: String) -> String {
        let mapping: [String: String] = [
            "English": "en",
            "Spanish": "es",
            "French": "fr",
            "German": "de",
            "Italian": "it",
            "Portuguese": "pt",
            "Chinese": "zh",
            "Japanese": "ja",
            "Korean": "ko",
            "Russian": "ru",
            "Arabic": "ar",
            "Hindi": "hi"
        ]
        return mapping[name] ?? "en"
    }
    
    /// Map language code to language name
    static func languageName(from code: String) -> String {
        let mapping: [String: String] = [
            "en": "English",
            "es": "Spanish",
            "fr": "French",
            "de": "German",
            "it": "Italian",
            "pt": "Portuguese",
            "zh": "Chinese",
            "ja": "Japanese",
            "ko": "Korean",
            "ru": "Russian",
            "ar": "Arabic",
            "hi": "Hindi"
        ]
        return mapping[code] ?? "English"
    }
}

// MARK: - SwiftUI Environment Support

private struct LocalizationKey: EnvironmentKey {
    static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    var localization: LocalizationManager {
        get { self[LocalizationKey.self] }
        set { self[LocalizationKey.self] = newValue }
    }
}

// MARK: - String Extension for Easy Localization

extension String {
    /// Get localized string using LocalizationManager
    var localized: String {
        LocalizationManager.shared.localizedString(for: self)
    }
    
    /// Get localized string with comment
    func localized(comment: String = "") -> String {
        LocalizationManager.shared.localizedString(for: self, comment: comment)
    }
}

// MARK: - Notification Names
// Note: languageChanged notification is defined in playgroundApp.swift
