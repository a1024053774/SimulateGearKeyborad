//
//  AudioScheme.swift
//  SimulateGearKeyborad
//
//  音效包配置数据模型
//

import Foundation

/// 音效包配置，与 schemes.json 对应
struct AudioScheme: Codable, Identifiable, Hashable {
    let name: String
    let displayName: String
    let files: [String]
    let nonUniqueCount: Int
    let keyAudioMap: [String: Int]
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case files
        case nonUniqueCount = "non_unique_count"
        case keyAudioMap = "key_audio_map"
    }
    
    /// macOS 常用键码映射
    enum KeyCode: UInt16 {
        case enter = 36
        case space = 49
        case backspace = 51
        case tab = 48
        case escape = 53
    }
    
    /// 获取指定按键对应的音效文件索引
    func audioIndex(for keyCode: UInt16) -> Int? {
        if let mapped = keyAudioMap[String(keyCode)] {
            return mapped
        }
        // 非映射按键使用取模循环
        guard nonUniqueCount > 0 else { return nil }
        return Int(keyCode) % nonUniqueCount
    }
}

/// 音效包管理器
class SchemeLoader {
    static let shared = SchemeLoader()
    
    private init() {}
    
    /// 从 Bundle 加载所有音效包配置
    func loadSchemes() -> [AudioScheme] {
        // 查找 schemes.json（扁平结构 - 直接在 Resources 目录）
        if let url = Bundle.main.url(forResource: "schemes", withExtension: "json") {
            print("✅ Found schemes.json via Bundle API")
            return loadSchemes(from: url)
        }
        
        print("⚠️ schemes.json not found via Bundle API!")
        return []
    }
    
    private func loadSchemes(from url: URL) -> [AudioScheme] {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let schemes = try decoder.decode([AudioScheme].self, from: data)
            print("✅ Loaded \(schemes.count) schemes")
            return schemes
        } catch {
            print("❌ Failed to load schemes: \(error)")
            return []
        }
    }
}
