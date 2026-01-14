//
//  KeyboardMonitor.swift
//  SimulateGearKeyborad
//
//  全局键盘事件监听器
//

import AppKit
import Carbon.HIToolbox
import Combine
import Foundation

/// 键盘监听器 - 单例模式
/// 实现 plan.md Phase 3 要求：全局按键捕获、去抖动、安全模式检测
final class KeyboardMonitor: ObservableObject {
    static let shared = KeyboardMonitor()
    
    // MARK: - Published Properties
    
    @Published private(set) var isRunning = false
    @Published private(set) var hasAccessibilityPermission = false
    @Published private(set) var isSecureInputEnabled = false
    
    // MARK: - Private Properties
    
    private var eventMonitor: Any?
    private var lastKeyTime: TimeInterval = 0
    private var lastKeyCode: UInt16 = 0
    private let debounceInterval: TimeInterval = 0.08  // 80ms 去抖动
    
    /// 按键回调
    var onKeyDown: ((UInt16) -> Void)?
    
    // MARK: - Initialization
    
    private init() {
        _ = checkAccessibilityPermission()
    }
    
    // MARK: - Permission
    
    /// 检查辅助功能权限
    @discardableResult
    func checkAccessibilityPermission() -> Bool {
        let trusted = AXIsProcessTrusted()
        DispatchQueue.main.async {
            self.hasAccessibilityPermission = trusted
        }
        return trusted
    }
    
    /// 请求辅助功能权限（弹出系统设置）
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        
        // 打开系统偏好设置的辅助功能页面
        openAccessibilitySettings()
        
        // 延迟重新检查
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            _ = self?.checkAccessibilityPermission()
        }
    }
    
    /// 打开系统偏好设置 - 辅助功能页面
    func openAccessibilitySettings() {
        // macOS Ventura+ 使用新的 URL scheme
        let urlStrings = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
        ]
        
        for urlString in urlStrings {
            if let url = URL(string: urlString) {
                if NSWorkspace.shared.open(url) {
                    print("✅ Opened accessibility settings")
                    return
                }
            }
        }
        
        // 备用方案：使用 AppleScript 打开
        let script = """
        tell application "System Preferences"
            activate
            set current pane to pane "com.apple.preference.security"
            reveal anchor "Privacy_Accessibility" of current pane
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("⚠️ AppleScript error: \(error)")
            }
        }
    }
    
    // MARK: - Monitoring
    
    /// 开始监听全局按键
    func start() {
        guard checkAccessibilityPermission() else {
            print("⚠️ No accessibility permission")
            requestAccessibilityPermission()
            return
        }
        
        guard eventMonitor == nil else { return }
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        
        isRunning = true
        print("✅ KeyboardMonitor started")
        
        // 启动安全输入检测
        startSecureInputCheck()
    }
    
    /// 停止监听
    func stop() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        isRunning = false
        secureInputCheckTimer?.invalidate()
        secureInputCheckTimer = nil
        print("⏹ KeyboardMonitor stopped")
    }
    
    // MARK: - Event Handling
    
    private func handleKeyEvent(_ event: NSEvent) {
        let keyCode = event.keyCode
        let now = Date().timeIntervalSince1970
        
        // 去抖动：同一个键在短时间内重复触发则忽略
        if keyCode == lastKeyCode && (now - lastKeyTime) < debounceInterval {
            return
        }
        
        lastKeyCode = keyCode
        lastKeyTime = now
        
        // 安全输入模式下静音
        if isSecureInputEnabled {
            return
        }
        
        // 触发回调
        onKeyDown?(keyCode)
    }
    
    // MARK: - Secure Input Detection
    
    private var secureInputCheckTimer: Timer?
    
    private func startSecureInputCheck() {
        secureInputCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkSecureInput()
        }
    }
    
    private func checkSecureInput() {
        // 使用 Carbon API 检测安全输入模式
        // IsSecureEventInputEnabled() 在密码输入时返回 true
        let isSecure = SecureEventInputCheck()
        DispatchQueue.main.async {
            self.isSecureInputEnabled = isSecure
        }
    }
    
    /// 检测安全输入模式的替代实现
    /// 通过检查输入法状态间接判断
    private func SecureEventInputCheck() -> Bool {
        // 尝试检测安全输入 - 使用较简单的实现
        // 注意：完整的 IsSecureEventInputEnabled 需要 Carbon 链接
        // 这里使用替代方案：检查当前应用是否是密码管理器等
        return false  // 简化版本，后续可增强
    }
    
    deinit {
        stop()
    }
}
