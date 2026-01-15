//
//  SubscriptionManager.swift
//  playground
//
//  Native StoreKit subscription manager to replace SDK webview
//

import Foundation
import StoreKit
import Combine
#if canImport(WidgetKit)
import WidgetKit
#endif

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var subscriptionStatus: Bool = false
    @Published var products: [Product] = []
    @Published var isLoading: Bool = false
    @Published var loadError: String? = nil
    
    // Product IDs from StoreKitConfig.storekit
    private let productIDs = [
        "calCalculator.weekly.premium",
        "calCalculator.monthly.premium",
        "calCalculator.yearly.premium"
    ]
    
    private var updateListenerTask: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load products and check subscription status
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        loadError = nil
        
        do {
            print("📦 [SubscriptionManager] Loading products for IDs: \(productIDs)")
            print("📦 [SubscriptionManager] Requesting products from StoreKit...")
            
            let storeProducts = try await Product.products(for: productIDs)
            
            print("📦 [SubscriptionManager] StoreKit returned \(storeProducts.count) products")
            
            // Check if no products returned (configuration issue)
            if storeProducts.isEmpty {
                print("⚠️ [SubscriptionManager] No products returned! Check App Store Connect configuration:")
                print("   - Product IDs must match exactly")
                print("   - Products must be in 'Ready to Submit' status")
                print("   - Paid Apps Agreement must be signed")
                
                await MainActor.run {
                    self.loadError = "Subscription plans are currently unavailable. Please try again later."
                    self.isLoading = false
                }
                return
            }
            
            await MainActor.run {
                self.products = storeProducts.sorted { product1, product2 in
                    // Sort by price: weekly, monthly, yearly
                    let order1 = productIDs.firstIndex(of: product1.id) ?? Int.max
                    let order2 = productIDs.firstIndex(of: product2.id) ?? Int.max
                    return order1 < order2
                }
                self.loadError = nil
                self.isLoading = false
            }
            print("✅ [SubscriptionManager] Loaded \(storeProducts.count) products successfully")
            
            // Log each product for debugging
            for product in storeProducts {
                print("   📱 Product: \(product.id) - \(product.displayName) - \(product.displayPrice)")
            }
        } catch {
            print("❌ [SubscriptionManager] Failed to load products: \(error)")
            print("❌ [SubscriptionManager] Error details: \(error.localizedDescription)")
            
            // Provide more specific error message
            let errorMessage: String
            if let storeKitError = error as? StoreKitError {
                switch storeKitError {
                case .networkError:
                    errorMessage = "Network error. Please check your internet connection."
                case .systemError:
                    errorMessage = "System error. Please restart the app."
                case .userCancelled:
                    errorMessage = "Request cancelled."
                case .notAvailableInStorefront:
                    errorMessage = "Subscriptions not available in your region."
                default:
                    errorMessage = "Unable to load subscription plans. Please try again."
                }
            } else {
                errorMessage = "Unable to load subscription plans. Please check your internet connection."
            }
            
            await MainActor.run {
                self.loadError = errorMessage
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Subscription Status
    
    func checkSubscriptionStatus() async {
        var isSubscribed = false
        
        // Check current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if productIDs.contains(transaction.productID) {
                    isSubscribed = true
                    break
                }
            } catch {
                print("⚠️ [SubscriptionManager] Failed to verify transaction: \(error)")
            }
        }
        
        await MainActor.run {
            self.subscriptionStatus = isSubscribed
            // Update UserDefaults for persistence
            UserDefaults.standard.set(isSubscribed, forKey: "subscriptionStatus")
            // Sync to widget
            syncSubscriptionStatusToWidget(isSubscribed)
            // Post notification for app updates
            NotificationCenter.default.post(name: .subscriptionStatusUpdated, object: nil)
        }
        
        print("📱 [SubscriptionManager] Subscription status: \(isSubscribed ? "Subscribed" : "Not Subscribed")")
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            // Transaction is verified, update subscription status
            await checkSubscriptionStatus()
            // Finish the transaction
            await transaction.finish()
            return transaction
        case .userCancelled:
            print("⚠️ [SubscriptionManager] User cancelled purchase")
            return nil
        case .pending:
            print("⚠️ [SubscriptionManager] Purchase is pending")
            return nil
        @unknown default:
            print("⚠️ [SubscriptionManager] Unknown purchase result")
            return nil
        }
    }
    
    // MARK: - Transaction Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.checkSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("⚠️ [SubscriptionManager] Failed to process transaction update: \(error)")
                }
            }
        }
    }
    
    // MARK: - Widget Sync
    
    private func syncSubscriptionStatusToWidget(_ isSubscribed: Bool) {
        let appGroupIdentifier = "group.CalCalculatorAiPlaygournd.shared"
        let isSubscribedKey = "widget.isSubscribed"
        
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("⚠️ Failed to access shared UserDefaults for widget subscription sync")
            return
        }
        
        sharedDefaults.set(isSubscribed, forKey: isSubscribedKey)
        print("📱 Widget subscription status synced: \(isSubscribed)")
        
        // Reload widget timelines
        #if canImport(WidgetKit)
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        try? await AppStore.sync()
        await checkSubscriptionStatus()
    }
}
