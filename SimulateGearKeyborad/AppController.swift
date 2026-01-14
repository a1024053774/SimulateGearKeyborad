//
//  AppController.swift
//  SimulateGearKeyborad
//
//  应用控制器 - 协调各模块初始化和运行
//

import Foundation
import Combine

/// 应用控制器 - 单例模式
/// 负责应用生命周期和各模块的协调
final class AppController: ObservableObject {
    static let shared = AppController()
    
    // MARK: - Published Properties
    
    @Published var isEnabled = true {
        didSet {
            updateMonitorState()
        }
    }
    
    @Published var volume: Double = 0.7 {
        didSet {
            AudioEngineManager.shared.volume = Float(volume)
        }
    }
    
    @Published var hasPermission = false
    @Published var isSecureMode = false
    
    // MARK: - Managers
    
    let themeManager = ThemeManager.shared
    let keyboardMonitor = KeyboardMonitor.shared
    let audioEngine = AudioEngineManager.shared
    
    // MARK: - Private
    
    private var cancellables = Set<AnyCancellable>()
    private var idleTimer: Timer?
    private var lastKeyTime: Date = Date()
    private let idleTimeout: TimeInterval = 10.0  // 10秒无操作休眠
    
    // MARK: - Initialization
    
    private init() {
        setupBindings()
        setupKeyboardCallback()
    }
    
    private func setupBindings() {
        // 监听权限状态
        keyboardMonitor.$hasAccessibilityPermission
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasPermission in
                self?.hasPermission = hasPermission
            }
            .store(in: &cancellables)
        
        // 监听安全输入状态
        keyboardMonitor.$isSecureInputEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSecure in
                self?.isSecureMode = isSecure
                self?.audioEngine.isMuted = isSecure
            }
            .store(in: &cancellables)
    }
    
    private func setupKeyboardCallback() {
        keyboardMonitor.onKeyDown = { [weak self] keyCode in
            self?.handleKeyDown(keyCode)
        }
    }
    
    // MARK: - Lifecycle
    
    /// 启动应用
    func start() {
        // 加载保存的设置
        loadSettings()
        
        // 启动键盘监听
        if isEnabled {
            keyboardMonitor.start()
        }
        
        // 启动空闲检测
        startIdleTimer()
    }
    
    /// 停止应用
    func stop() {
        keyboardMonitor.stop()
        audioEngine.pause()
        idleTimer?.invalidate()
    }
    
    // MARK: - Settings
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        isEnabled = defaults.bool(forKey: "isEnabled")
        volume = defaults.double(forKey: "volume")
        
        // 默认值处理
        if volume == 0 && !defaults.bool(forKey: "hasSetVolume") {
            volume = 0.7
        }
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isEnabled, forKey: "isEnabled")
        defaults.set(volume, forKey: "volume")
        defaults.set(true, forKey: "hasSetVolume")
    }
    
    // MARK: - Key Handling
    
    private func handleKeyDown(_ keyCode: UInt16) {
        lastKeyTime = Date()
        
        // 唤醒引擎
        audioEngine.resume()
        
        // 播放音效
        audioEngine.playSound(for: keyCode)
    }
    
    // MARK: - Monitor State
    
    private func updateMonitorState() {
        if isEnabled {
            keyboardMonitor.start()
            audioEngine.resume()
        } else {
            keyboardMonitor.stop()
            audioEngine.pause()
        }
        saveSettings()
    }
    
    // MARK: - Idle Management
    
    private func startIdleTimer() {
        idleTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkIdle()
        }
    }
    
    private func checkIdle() {
        let idleTime = Date().timeIntervalSince(lastKeyTime)
        if idleTime > idleTimeout {
            // 超时，暂停引擎节省资源
            audioEngine.pause()
        }
    }
    
    // MARK: - Theme Selection
    
    /// 选择主题并播放试听
    func selectTheme(_ scheme: AudioScheme, preview: Bool = true) {
        themeManager.selectScheme(scheme)
        if preview {
            // 延迟播放试听，等待加载完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.audioEngine.playPreview()
            }
        }
    }
}
