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
import MySQLKit

final class ImportantInfoServiceProvider: ControlCenter_ImportantInfoServiceAsyncProvider {
    private let getDatabase: @Sendable () async throws -> SQLDatabase
    
    init(getDatabase: @escaping @Sendable () async throws -> SQLDatabase) throws {
        self.getDatabase = getDatabase
    }
    
    func getHomepageInfos(request: SwiftProtobuf.Google_Protobuf_Empty, context: GRPC.GRPCAsyncServerCallContext) async throws -> ControlCenter_HomepageResponse {
        let database = try await getDatabase()
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
            .columns(["save_url", "save_pos", "jump_type", "jump_param", "force_show_pos"])
            .from("Homepage")
            .where("is_hidden", .equal, 0)
            .all(decoding: HomepageQueryResponse.self)
        
        Logger.shared.trace("Homepage Response: \(homepageResponse)")
        
        var homepages = homepageResponse.filter{$0.forceShowPos == nil}
        homepageResponse.filter{$0.forceShowPos != nil}.forEach {
            item in
            guard let forceShowPos = item.forceShowPos else {return}
            homepages.insert(item, at: forceShowPos >= 0 ? min(forceShowPos, homepages.count) : max(0, homepages.count + forceShowPos))
        }
        
        var homepageInfos = homepages.map({
            item in
            var temp = ControlCenter_HomepageResponse.HomepageInfo()
            temp.imgPos = item.savePos.toGRPCPos()
            temp.imgURL = item.saveUrl
            temp.jumpType = item.jumpType.toGRPCJumpType()
            
            if let jumpParam = item.jumpParam {
                temp.jumpParam = jumpParam
            }
            
            return temp
        })
        
        var result = ControlCenter_HomepageResponse()
        result.homepages = homepageInfos
        result.lastUpdateTime = UInt32(homepageLastUpdateTime!.timeIntervalSince1970) - 3600 * 8    // 解码后时区为UTC，减去8小时以和实际时区时间匹配
        
        return result
    }
}
