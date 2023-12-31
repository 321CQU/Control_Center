//
//  ImportantInfoServiceProvider.swift
//  ControlCenter
//
//  Created by 朱子骏 on 2023/8/22.
//

import Foundation
import NIOCore
import NIOConcurrencyHelpers
import GRPC
import SwiftProtobuf
import SQLKit

actor HomepageCache {
    private var cache: [HomepageQueryResponse] = []
    private var lastUpdateTime: UInt32 = 0
    
    var hasCache: Bool {
        lastUpdateTime != 0
    }
    
    func update(homepageInfos: [HomepageQueryResponse], lastUpdateTime: UInt32) {
        self.cache = homepageInfos
        self.lastUpdateTime = lastUpdateTime
    }
    
    func getHomepageInfos() -> (homepageInfos: [ControlCenter_HomepageResponse.HomepageInfo], lastUpdateTime: UInt32) {
        return (cache.compactMap({item in item.toGRPC()}), lastUpdateTime)
    }
}

final class ImportantInfoServiceProvider: ControlCenter_ImportantInfoServiceAsyncProvider {
    private let scheduledTasksEventLoop: EventLoop
    private let getDatabase: @Sendable () async throws -> SQLDatabase
    private let homepageCache: HomepageCache = HomepageCache()
    
    init(scheduledTasksEventLoop: EventLoop, getDatabase: @escaping @Sendable () async throws -> SQLDatabase) throws {
        self.scheduledTasksEventLoop = scheduledTasksEventLoop
        self.getDatabase = getDatabase
        
        // 期望该重复任务在服务器运行期间持续执行，swift-nio会在程序关闭时取消该任务
        scheduledTasksEventLoop.scheduleRepeatedAsyncTask(initialDelay: .zero, delay: .hours(1)) {
            _ in
            return scheduledTasksEventLoop.submit {
                Task { [weak self] in
                    guard !Task.isCancelled else {return}
                    guard let self = self else {return}
                    do {
                        let (homepages, homepageLastUpdateTime) = try await getHomepageInfoFromDB()
                        await homepageCache.update(homepageInfos: homepages, lastUpdateTime: homepageLastUpdateTime)
                        Logger.shared.trace("Homepage Cache Updated")
                    } catch {
                        Logger.shared.error("Failed to update homepage cache: \(error)")
                    }
                }
            }
        }
    }
    
    private func getHomepageInfoFromDB() async throws -> (homepageInfos: [HomepageQueryResponse], lastUpdateTime: UInt32) {
        let database = try await getDatabase()
        // 降序排列最后更新时间，选择更新时间最晚的作为轮播图整体的最后更新时间
        let homepageLastUpdateTime = try await database.select()
            .column("update_time")
            .from("Homepage")
            .orderBy("update_time", .descending)
            .limit(1)
            .first()?
            .decode(column: "update_time", as: Date.self)
        
        Logger.shared.trace("Homepage Last Update Time: \(String(describing: homepageLastUpdateTime))")
        
        
        // TODO: Typesafe SQL Operation
        let homepageResponse = try await database.select()
            .columns(["homepage_type", "homepage_param", "jump_type", "jump_param", "force_show_pos"])
            .from("Homepage")
            .where("is_hidden", .equal, 0)
            .all(decoding: HomepageQueryResponse.self)
        
        Logger.shared.trace("Homepage Response: \(homepageResponse)")
        
        var homepages = homepageResponse.filter{$0.forceShowPos == nil}
        homepageResponse.filter{$0.forceShowPos != nil}.sorted{
            ($0.forceShowPos! >= 0 && $1.forceShowPos! >= 0) ? ($0.forceShowPos! < $1.forceShowPos!) : ($0.forceShowPos! > $1.forceShowPos!)
        }.forEach {
            item in
            guard let forceShowPos = item.forceShowPos else {return}
            homepages.insert(item, at: forceShowPos >= 0 ? min(forceShowPos, homepages.count) : max(0, homepages.count + forceShowPos + 1))
        }
        
        // 解码后时区为UTC，减去8小时以和实际时区时间匹配
        return (homepages, UInt32(homepageLastUpdateTime!.timeIntervalSince1970) - 3600 * 8)
    }
    
    func forceRefreshHomepageInfoCache(request: SwiftProtobuf.Google_Protobuf_Empty, context: GRPC.GRPCAsyncServerCallContext) async throws -> ControlCenter_HomepageResponse {
        let (homepages, homepageLastUpdateTime) = try await getHomepageInfoFromDB()
        await homepageCache.update(homepageInfos: homepages, lastUpdateTime: homepageLastUpdateTime)
        Logger.shared.info("Homepage Cache Force Updated")
        
        var result = ControlCenter_HomepageResponse()
        result.homepages = await homepageCache.getHomepageInfos().homepageInfos
        
        return result
    }
    
    func getHomepageInfos(request: SwiftProtobuf.Google_Protobuf_Empty, context: GRPC.GRPCAsyncServerCallContext) async throws -> ControlCenter_HomepageResponse {
        // 如果尚未初始化cache，从数据库中获取并返回
        // 否则直接返回cache内容
        if await homepageCache.hasCache {
            let (homepages, homepageLastUpdateTime) = try await getHomepageInfoFromDB()
            await homepageCache.update(homepageInfos: homepages, lastUpdateTime: homepageLastUpdateTime)
            Logger.shared.info("Homepage Cache Initialized")
        }
        
        var result = ControlCenter_HomepageResponse()
        result.homepages = await homepageCache.getHomepageInfos().homepageInfos
        
        return result
    }
}
