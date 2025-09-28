//
//  AppModel.swift
//  ManyuW
//
//  Created by 木木 on 2025/9/28.
//

import Foundation
import AppKit
import Combine

// 应用信息数据模型
struct AppInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let path: String
    let icon: NSImage?
    let version: String?
    
    init(name: String, bundleIdentifier: String, path: String, icon: NSImage? = nil, version: String? = nil) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.icon = icon
        self.version = version
    }
}

// 应用管理器
class AppManager: ObservableObject {
    @Published var applications: [AppInfo] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    
    init() {
        loadApplications()
    }
    
    // 加载已安装的应用程序
    func loadApplications() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var apps: [AppInfo] = []
            
            // 扫描常见应用目录
            let appPaths = [
                "/Applications",
                "/System/Applications",
                "/System/Library/CoreServices",
                "/usr/local/bin"
            ]
            
            for appPath in appPaths {
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: appPath) {
                    for item in contents {
                        let fullPath = "\(appPath)/\(item)"
                        if item.hasSuffix(".app") {
                            if let appInfo = self?.getAppInfo(from: fullPath) {
                                apps.append(appInfo)
                            }
                        }
                    }
                }
            }
            
            // 按名称排序
            apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            
            DispatchQueue.main.async {
                self?.applications = apps
                self?.isLoading = false
            }
        }
    }
    
    // 获取应用信息
    private func getAppInfo(from path: String) -> AppInfo? {
        let bundle = Bundle(path: path)
        guard let bundle = bundle else { return nil }
        
        let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? 
                  bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? 
                  URL(fileURLWithPath: path).lastPathComponent.replacingOccurrences(of: ".app", with: "")
        
        let bundleIdentifier = bundle.bundleIdentifier ?? ""
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        
        // 获取应用图标
        var icon: NSImage?
        if let iconFile = bundle.object(forInfoDictionaryKey: "CFBundleIconFile") as? String {
            let iconPath = bundle.path(forResource: iconFile, ofType: nil) ?? 
                          bundle.path(forResource: iconFile, ofType: "icns")
            if let iconPath = iconPath {
                icon = NSImage(contentsOfFile: iconPath)
            }
        }
        
        return AppInfo(
            name: name,
            bundleIdentifier: bundleIdentifier,
            path: path,
            icon: icon,
            version: version
        )
    }
    
    // 启动应用程序
    func launchApplication(_ app: AppInfo) {
        print("准备启动应用: \(app.name)")
        print("应用路径: \(app.path)")
        print("Bundle ID: \(app.bundleIdentifier)")
        
        // 检查应用是否已经在运行
        let runningApps = NSWorkspace.shared.runningApplications
        let isAlreadyRunning = runningApps.contains { runningApp in
            runningApp.bundleIdentifier == app.bundleIdentifier
        }
        
        print("应用是否已在运行: \(isAlreadyRunning)")
        
        if isAlreadyRunning {
            print("应用 \(app.name) 已在运行，强制启动新实例...")
            // 使用open -n强制启动新实例
            launchApplicationViaOpen(app)
        } else {
            print("应用 \(app.name) 未运行，正常启动...")
            // 直接启动可执行文件
            launchApplicationDirectly(app)
        }
    }
    
    // 直接启动应用程序
    private func launchApplicationDirectly(_ app: AppInfo) {
        let executablePath = app.path + "/Contents/MacOS/" + app.name
        print("尝试启动可执行文件: \(executablePath)")
        
        // 检查可执行文件是否存在
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: executablePath) {
            print("可执行文件不存在: \(executablePath)")
            // 尝试使用open命令
            launchApplicationViaOpen(app)
            return
        }
        
        let task = Process()
        task.launchPath = executablePath
        task.arguments = []
        
        do {
            try task.run()
            print("已启动应用: \(app.name)")
        } catch {
            print("直接启动失败: \(error)")
            // 备用方法：使用open -n
            launchApplicationViaOpen(app)
        }
    }
    
    // 备用方法：使用open -n
    private func launchApplicationViaOpen(_ app: AppInfo) {
        print("使用open -n启动应用: \(app.name)")
        
        // 使用shell脚本强制多开
        let script = """
        #!/bin/bash
        # 强制启动新实例
        open -n "\(app.path)" 2>/dev/null
        """
        
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", script]
        
        do {
            try task.run()
            print("shell脚本启动成功: \(app.name)")
        } catch {
            print("shell脚本启动失败: \(error)")
            // 最后尝试NSWorkspace
            launchApplicationViaNSWorkspace(app)
        }
    }
    
    // 备用方法：使用NSWorkspace
    private func launchApplicationViaNSWorkspace(_ app: AppInfo) {
        let workspace = NSWorkspace.shared
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        
        workspace.openApplication(at: URL(fileURLWithPath: app.path), 
                                 configuration: configuration) { launchedApp, error in
            if let error = error {
                print("NSWorkspace启动失败: \(error)")
                // 最后尝试命令行
                self.launchApplicationViaCommand(app)
            } else {
                print("NSWorkspace启动成功: \(launchedApp?.localizedName ?? app.name)")
            }
        }
    }
    
    // 备用方法：使用命令行启动
    private func launchApplicationViaCommand(_ app: AppInfo) {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-n", app.path] // -n 参数强制启动新实例
        
        do {
            try task.run()
            print("命令行启动应用: \(app.name)")
        } catch {
            print("命令行启动失败: \(error)")
            // 最后尝试直接启动可执行文件
            launchApplicationDirectlyFallback(app)
        }
    }
    
    // 直接启动应用程序（备用方法）
    private func launchApplicationDirectlyFallback(_ app: AppInfo) {
        let task = Process()
        task.launchPath = app.path + "/Contents/MacOS/" + app.name
        
        do {
            try task.run()
            print("直接启动应用: \(app.name)")
        } catch {
            print("直接启动也失败: \(error)")
        }
    }
    
    // 过滤应用列表
    var filteredApplications: [AppInfo] {
        if searchText.isEmpty {
            return applications
        } else {
            return applications.filter { app in
                app.name.localizedCaseInsensitiveContains(searchText) ||
                app.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
