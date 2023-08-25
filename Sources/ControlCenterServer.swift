//
//  ControlCenterServer.swift
//  ControlCenter
//
//  Created by 朱子骏 on 2023/8/22.
//

import Foundation
import ArgumentParser
import NIO
import GRPC
import Logging
import Puppy
import MySQLKit
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@main
struct ControlCenter: AsyncParsableCommand {
    #if DEBUG
    static let configDir: URL = {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("config")
    }()
    
    enum ConfigType: String {
        case db = "database.config"
        case importantInfoService = "important_info_service.config"
        
        var path: URL {
            ControlCenter.configDir.appendingPathComponent(self.rawValue)
        }
    }
    #endif
    
    @Option(name: [.short, .long], help: "监听IP")
    var host: String = "0.0.0.0"
    
    @Option(name: [.short, .long], help: "监听端口")
    var port: Int = 8000
    
    @Flag(help: "输出模式")
    var logLevel = Logger.Level.notice
    
    #if DEBUG
    @Option(name: [.long], help: "数据库配置文件路径", completion: .file(), transform: {try DatabaseConfig.fromFile(URL(fileURLWithPath: $0))})
    var dbConfig: DatabaseConfig = try! DatabaseConfig.fromFile(ConfigType.db.path)
    
    @Option(name: [.long], help: "重要信息服务配置文件路径", completion: .file(), transform: {try ImportantInfoServiceConfig.fromFile(URL(fileURLWithPath: $0))})
    var importantInfoServiceConfig: ImportantInfoServiceConfig = try! ImportantInfoServiceConfig.fromFile(ConfigType.importantInfoService.path)
    #else
    @Option(name: [.long], help: "数据库配置文件路径", completion: .file(), transform: {try DatabaseConfig.fromFile(URL(fileURLWithPath: $0))})
    var dbConfig: DatabaseConfig
    
    @Option(name: [.long], help: "重要信息服务配置文件路径", completion: .file(), transform: {try ImportantInfoServiceConfig.fromFile(URL(fileURLWithPath: $0))})
    var importantInfoServiceConfig: ImportantInfoServiceConfig
    #endif
    
    func validate() throws {
        guard !dbConfig.host.isEmpty else {
            throw ValidationError("数据库IP不能为空")
        }
        guard !dbConfig.username.isEmpty else {
            throw ValidationError("数据库用户名不能为空")
        }
        guard !dbConfig.password.isEmpty else {
            throw ValidationError("数据库密码不能为空")
        }
        guard !dbConfig.database.isEmpty else {
            throw ValidationError("数据库名不能为空")
        }
        guard !importantInfoServiceConfig.homepagePrefix.isEmpty else {
            throw ValidationError("首页轮播图前缀不能为空")
        }
    }
    
    func initLogger() {
        var puppy = Puppy()
        
        #if !DEBUG
        let console = ConsoleLogger("com.321cqu.control-center.console")
        puppy.add(console)
        #endif
        #if os(Linux)
        let syslog = SystemLogger("com.321cqu.control-center.syslog")
        puppy.add(syslog)
        #endif
        #if canImport(Darwin)
        let syslog = OSLogger("com.321cqu.control-center.syslog")
        puppy.add(syslog)
        #endif

        LoggingSystem.bootstrap {
            var handler = PuppyLogHandler(label: $0, puppy: puppy)
            handler.logLevel = logLevel
            return handler
        }
    }
    
    func initDB(loopGroup: EventLoopGroup) async -> EventLoopGroupConnectionPool<MySQLConnectionSource> {
        let configuration = MySQLConfiguration(
            hostname: dbConfig.host,
            port: dbConfig.port,
            username: dbConfig.username,
            password: dbConfig.password,
            database: dbConfig.database
        )
        return EventLoopGroupConnectionPool(
            source: MySQLConnectionSource(configuration: configuration),
            on: loopGroup
        )
    }

    mutating func run() async throws {
        initLogger()
        
        Logger.shared.notice("server starting with \(logLevel) log level")
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        defer {
            try! group.syncShutdownGracefully()
        }
        
        let db = await initDB(loopGroup: group)
        defer {
            try! db.syncShutdownGracefully()
        }

        let server = try await Server.insecure(group: group)
            .withServiceProviders([ImportantInfoServiceProvider(urlPrefix: "picture.321cqu.com", getDatabase: {db.database(logger: Logger(label: "com.321cqu.control-center.database")).sql()})])
            .bind(host: host, port: port)
            .get()

        Logger.shared.notice("server success started on port \(server.channel.localAddress!.port!)")

        try await server.onClose.get()
    }
}
