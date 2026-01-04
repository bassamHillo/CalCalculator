//
//  MainTabView.swift
//  playground
//
//  Created by Bassam-Hillo on 16/12/2025.
//

import SwiftUI
import SwiftData
import SDK
import UIKit
import ObjectiveC

struct MainTabView: View {
    var repository: MealRepository
    @ObservedObject private var localizationManager = LocalizationManager.shared

    @State private var selectedTab = 0
    @State private var scrollHomeToTopTrigger = UUID()
    @StateObject private var networkMonitor = NetworkMonitor.shared

    @State var homeViewModel: HomeViewModel
    @State var scanViewModel: ScanViewModel
    @State var historyViewModel: HistoryViewModel
    @State var progressViewModel: ProgressViewModel
    @State var settingsViewModel: SettingsViewModel
    
    @Environment(\.isSubscribed) private var isSubscribed
    @Query(filter: #Predicate<DietPlan> { $0.isActive == true }) private var activeDietPlans: [DietPlan]
    
    private var hasActiveDiet: Bool {
        !activeDietPlans.isEmpty && isSubscribed
    }
    
    init(repository: MealRepository) {
        let initStart = Date()
        self.repository = repository
        _homeViewModel = State(
            initialValue: HomeViewModel(
                repository: repository,
                imageStorage: .shared
            )
        )
        _scanViewModel = State(
            initialValue: ScanViewModel(
                repository: repository,
                analysisService: CaloriesAPIService(),
                imageStorage: .shared
            )
        )
        _historyViewModel = State(
            initialValue: HistoryViewModel(
                repository: repository
            )
        )
        _progressViewModel = State(
            initialValue: ProgressViewModel(
                repository: repository
            )
        )
        _settingsViewModel = State(
            initialValue: SettingsViewModel(
                repository: repository,
                imageStorage: .shared
            )
        )
        let initTime = Date().timeIntervalSince(initStart)
        if initTime > 0.1 {
            print("⚠️ [MainTabView] Initialization took \(String(format: "%.3f", initTime))s")
        }
    }
    
    var body: some View {
        // Explicitly reference currentLanguage to ensure SwiftUI tracks the dependency
        let _ = localizationManager.currentLanguage
        
        return ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
            HomeView(
                viewModel: homeViewModel,
                repository: repository,
                scanViewModel: scanViewModel,
                scrollToTopTrigger: scrollHomeToTopTrigger,
                onMealSaved: {
                    Task {
                        await homeViewModel.refreshTodayData()
                        // Update Live Activity after data refresh
                        homeViewModel.updateLiveActivityIfNeeded()
                        await historyViewModel.loadData()
                        await progressViewModel.loadData()
                    }
                }
            )
            .tabItem {
                Label(localizationManager.localizedString(for: AppStrings.Home.title), systemImage: "house.fill")
            }
            .tag(0)
            
            ProgressDashboardView(viewModel: progressViewModel)
                .tabItem {
                    Label(localizationManager.localizedString(for: AppStrings.Progress.title), systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)
            
            HistoryOrDietView(
                viewModel: historyViewModel,
                repository: repository,
                tabName: hasActiveDiet ? localizationManager.localizedString(for: AppStrings.DietPlan.myDiet) : localizationManager.localizedString(for: AppStrings.History.title)
            )
                .tabItem {
                    Label(hasActiveDiet ? localizationManager.localizedString(for: AppStrings.DietPlan.myDiet) : localizationManager.localizedString(for: AppStrings.History.title), systemImage: "calendar")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label(localizationManager.localizedString(for: AppStrings.Profile.title), systemImage: "person.fill")
                }
                .tag(3)
            }
            
            // Offline banner
            if !networkMonitor.isConnected {
                VStack {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.white)
                        Text(localizationManager.localizedString(for: AppStrings.Main.noInternetConnection))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.red)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: networkMonitor.isConnected)
        .onChange(of: selectedTab) { oldValue, newValue in
            // When home tab (0) is selected, trigger scroll to top
            if newValue == 0 {
                // Small delay to ensure view is ready, then scroll
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    scrollHomeToTopTrigger = UUID()
                }
            }
        }
        .background(TabBarTapDetector(onHomeTabTapped: {
            // Home tab was tapped (even if already selected)
            scrollHomeToTopTrigger = UUID()
        }))
        // No need for onChange - SwiftUI automatically re-evaluates views when
        // @ObservedObject properties change. Since localizationManager.currentLanguage
        // is @Published, all views using localizationManager will update automatically.
    }
}

// MARK: - TabBar Tap Detector

struct TabBarTapDetector: UIViewControllerRepresentable {
    let onHomeTabTapped: () -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let tabBarController = window.rootViewController as? UITabBarController ?? findTabBarController(in: window.rootViewController) {
                let delegate = TabBarTapDelegate(onHomeTabTapped: onHomeTabTapped)
                // Store delegate to keep it alive
                objc_setAssociatedObject(tabBarController, "tabBarTapDelegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                tabBarController.delegate = delegate
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    private func findTabBarController(in viewController: UIViewController?) -> UITabBarController? {
        guard let viewController = viewController else { return nil }
        if let tabBarController = viewController as? UITabBarController {
            return tabBarController
        }
        for child in viewController.children {
            if let tabBarController = findTabBarController(in: child) {
                return tabBarController
            }
        }
        return nil
    }
}

// MARK: - TabBar Tap Delegate

class TabBarTapDelegate: NSObject, UITabBarControllerDelegate {
    let onHomeTabTapped: () -> Void
    private var lastSelectedIndex: Int = 0
    
    init(onHomeTabTapped: @escaping () -> Void) {
        self.onHomeTabTapped = onHomeTabTapped
        super.init()
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let newIndex = tabBarController.viewControllers?.firstIndex(of: viewController) ?? -1
        
        // If home tab (index 0) is tapped and it was already selected, trigger scroll
        if newIndex == 0 && lastSelectedIndex == 0 {
            onHomeTabTapped()
        }
        
        lastSelectedIndex = newIndex
        return true
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [Meal.self, MealItem.self, DaySummary.self, WeightEntry.self],
            inMemory: true
        )
}
