//
//  ThemeManager.swift
//  SimulateGearKeyborad
//
//  主题管理器 - 协调音效包加载和切换
//

import Foundation
import Combine

/// 主题管理器 - 单例模式
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var schemes: [AudioScheme] = []
    @Published var currentScheme: AudioScheme?
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let lastSchemeKey = "lastSelectedScheme"
    
    // MARK: - Initialization
    
    private init() {
        loadSchemes()
        restoreLastScheme()
    }
    
    // MARK: - Scheme Loading
    
    /// 加载所有音效包配置
    func loadSchemes() {
        schemes = SchemeLoader.shared.loadSchemes()
        print("📦 ThemeManager: Loaded \(schemes.count) audio schemes")
    }
    
    /// 切换音效包（扁平资源结构）
    func selectScheme(_ scheme: AudioScheme) {
        currentScheme = scheme
        
        // 使用扁平资源加载
        AudioEngineManager.shared.loadSchemeFlat(scheme)
        
        // 保存选择
        userDefaults.set(scheme.name, forKey: lastSchemeKey)
    }
    
    /// 恢复上次选择的音效包
    private func restoreLastScheme() {
        let lastSchemeName = userDefaults.string(forKey: lastSchemeKey)
        
        if let name = lastSchemeName,
           let scheme = schemes.first(where: { $0.name == name }) {
            selectScheme(scheme)
        } else if let firstScheme = schemes.first {
            selectScheme(firstScheme)
        }
    }
}
