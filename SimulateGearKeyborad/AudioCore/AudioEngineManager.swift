//
//  AudioEngineManager.swift
//  SimulateGearKeyborad
//
//  高性能音频引擎，基于 AVAudioEngine 实现低延迟音效播放
//

import AVFoundation
import Foundation

/// 音频引擎管理器 - 单例模式
/// 实现 plan.md Phase 2 要求：预加载 Buffer、对象池、防爆音
final class AudioEngineManager {
    static let shared = AudioEngineManager()
    
    // MARK: - Properties
    
    private let engine = AVAudioEngine()
    private var playerNodes: [AVAudioPlayerNode] = []
    private var audioBuffers: [AVAudioPCMBuffer] = []
    private let maxPolyphony = 6  // 最大并发数
    private var currentPlayerIndex = 0
    
    private var currentScheme: AudioScheme?
    private var schemePath: String?
    
    private let audioQueue = DispatchQueue(label: "com.barsound.audio", qos: .userInteractive)
    
    /// 音量 (0.0 - 1.0)
    var volume: Float = 0.7 {
        didSet {
            audioQueue.async { [weak self] in
                self?.playerNodes.forEach { $0.volume = self?.volume ?? 0.7 }
            }
        }
    }
    
    /// 音调基准偏移
    var pitchBase: Float = 1.0
    
    /// 是否启用随机音调变化
    var enablePitchVariance = true
    
    /// 静音状态
    var isMuted = false
    
    // MARK: - Initialization
    
    private init() {
        setupEngine()
    }
    
    private func setupEngine() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 创建播放节点池
            for _ in 0..<self.maxPolyphony {
                let player = AVAudioPlayerNode()
                self.engine.attach(player)
                self.engine.connect(player, to: self.engine.mainMixerNode, format: nil)
                player.volume = self.volume
                self.playerNodes.append(player)
            }
            
            // 启动引擎
            do {
                try self.engine.start()
                print("✅ AudioEngine started")
            } catch {
                print("❌ Failed to start AudioEngine: \(error)")
            }
        }
    }
    
    // MARK: - Scheme Loading
    
    /// 加载音效包，将音频文件预解码为 PCMBuffer 常驻内存
    func loadScheme(_ scheme: AudioScheme, path: String) {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 停止当前播放
            self.playerNodes.forEach { $0.stop() }
            self.audioBuffers.removeAll()
            
            self.currentScheme = scheme
            self.schemePath = path
            
            // 预加载所有音频文件
            for fileName in scheme.files {
                let filePath = "\(path)/\(fileName)"
                if let buffer = self.loadAudioBuffer(from: filePath) {
                    self.audioBuffers.append(buffer)
                } else {
                    print("⚠️ Failed to load: \(fileName)")
                }
            }
            
            print("✅ Loaded scheme: \(scheme.name) with \(self.audioBuffers.count) sounds")
        }
    }
    
    /// 加载音效包（扁平化资源结构 - 文件直接在 Resources 目录）
    func loadSchemeFlat(_ scheme: AudioScheme) {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 停止当前播放
            self.playerNodes.forEach { $0.stop() }
            self.audioBuffers.removeAll()
            
            self.currentScheme = scheme
            
            // 预加载所有音频文件（从 Bundle 直接查找）
            for fileName in scheme.files {
                let baseName = (fileName as NSString).deletingPathExtension
                
                if let path = Bundle.main.path(forResource: baseName, ofType: "wav") {
                    if let buffer = self.loadAudioBuffer(from: path) {
                        self.audioBuffers.append(buffer)
                        print("  ✓ Loaded: \(fileName)")
                    } else {
                        print("  ✗ Failed to load buffer: \(fileName)")
                    }
                } else {
                    print("  ✗ Not found in bundle: \(fileName)")
                }
            }
            
            print("✅ Loaded scheme '\(scheme.name)' with \(self.audioBuffers.count)/\(scheme.files.count) sounds")
        }
    }
    
    private func loadAudioBuffer(from path: String) -> AVAudioPCMBuffer? {
        let url = URL(fileURLWithPath: path)
        
        guard let file = try? AVAudioFile(forReading: url) else {
            print("❌ Cannot open audio file: \(path)")
            return nil
        }
        
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("❌ Cannot create buffer for: \(path)")
            return nil
        }
        
        do {
            try file.read(into: buffer)
            return buffer
        } catch {
            print("❌ Failed to read audio: \(error)")
            return nil
        }
    }
    
    // MARK: - Playback
    
    /// 触发按键音效
    func playSound(for keyCode: UInt16) {
        guard !isMuted else { return }
        guard let scheme = currentScheme else { return }
        guard let index = scheme.audioIndex(for: keyCode) else { return }
        
        playBuffer(at: index)
    }
    
    /// 播放指定索引的音效 (用于试听)
    func playPreview(index: Int = 0) {
        guard !audioBuffers.isEmpty else { return }
        let safeIndex = index % audioBuffers.count
        playBuffer(at: safeIndex)
    }
    
    private func playBuffer(at index: Int) {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            guard index < self.audioBuffers.count else { return }
            
            let buffer = self.audioBuffers[index]
            let player = self.playerNodes[self.currentPlayerIndex]
            
            // 循环使用播放节点
            self.currentPlayerIndex = (self.currentPlayerIndex + 1) % self.maxPolyphony
            
            // 停止当前播放（防爆音）
            player.stop()
            
            // 应用音调变化
            if self.enablePitchVariance {
                let variance = Float.random(in: -0.05...0.05)
                player.rate = self.pitchBase + variance
            }
            
            // 播放
            player.scheduleBuffer(buffer, at: nil, options: .interrupts)
            player.play()
        }
    }
    
    // MARK: - Engine Control
    
    /// 暂停引擎（省电）
    func pause() {
        audioQueue.async { [weak self] in
            self?.engine.pause()
        }
    }
    
    /// 恢复引擎
    func resume() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.engine.isRunning {
                try? self.engine.start()
            }
        }
    }
    
    /// 获取当前音效包
    func getCurrentScheme() -> AudioScheme? {
        return currentScheme
    }
}
