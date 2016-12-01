//
// MariaDbTaler: MariaDbDriver.swift
// Created by tottokotkd on 2016/11/26.
//

import Foundation
import Sterntaler
import CMariaDB


public struct MariaDB: Driver {
    public typealias P = MariaDbPool
    public static func get(host: String, user: String, password: String, database: String, port: Int = 3306) -> MariaDbPool {
        return MariaDbPool(host: host, user: user, password: password, database: database, port: port)
    }
}

public struct MariaDbPool: Pool {
    public typealias C = MariaDbConnection
    
    private let host: String
    private let user: String
    private let password: String
    private let database: String
    private let port: Int
    
    init(host: String, user: String, password: String, database: String, port: Int) {
        self.host = host
        self.user = user
        self.password = password
        self.database = database
        self.port = port
    }
    
    public func execute(sql: String) -> [Row] {
        let result = connect().execute(sql: sql)
        return result
    }
    
    public func connect() -> C {
        return MariaDbConnection(mysql: mysql_real_connect(mysql_init(nil), host, user, password, database, UInt32(port), nil, 0)!)
    }
}

public class MariaDbConnection: Connection {
    
    let mysql: UnsafeMutablePointer<MYSQL>
    init(mysql: UnsafeMutablePointer<MYSQL>) {
        self.mysql = mysql
    }
    deinit {
        // TODO: back to pool?
        mysql_close(mysql)
    }
    private func realQuery(sql: String, info: MariaDbInfo?) -> [Row] {
        guard mysql_real_query(mysql, sql, UInt(sql.utf8.count)) == 0 else { fatalError() }
        let store = mysql_store_result(mysql)
        var result = [MariaDbRow]()
        while true {
            if let row = mysql_fetch_row(store) {
                result.append(MariaDbRow(r: row, info: info))
            } else {
                break
            }
        }
        return result
    }
    
    public func execute(sql: String) -> [Row] {
        return realQuery(sql: sql, info: getInfo())
    }
    public func execute(sql: String, info: MariaDbInfo?) -> [Row] {
        return realQuery(sql: sql, info: info)
    }
    public func getInfo() -> MariaDbInfo? {
        func getSystemTimeZone() -> TimeZone? {
            let r = realQuery(sql: "SELECT @@session.time_zone, @@global.system_time_zone", info: nil)[0]
            let session = r[0].asString!
            let system = r[1].asString!
            let zoneId = session == "SYSTEM" ? system : session
            return TimeZone(identifier: zoneId)
        }
        
        if let systemTimeZone = getSystemTimeZone() {
            return MariaDbInfo(systemTimeZone: systemTimeZone)
        }

        return nil
    }
}

public struct MariaDbInfo {
    let systemTimeZone: TimeZone
}
public struct MariaDbRow: Row {
    let r: MYSQL_ROW
    let info: MariaDbInfo?
    public subscript(i: Int) -> RowItem {
        return MariaDbRowItem(p: r[i], info: info)
    }
}

public struct MariaDbRowItem: RowItem {
    let p: UnsafePointer<Int8>?
    let info: MariaDbInfo?
    public var isEmpty: Bool {
        return p == nil
    }
    public var asString: String? {
        return p.map{ String(cString: $0) }
    }
    public var asInt: Int? {
        return asString.map{Int($0)!}
    }
    public var asDate: Date? {
        return (info?.systemTimeZone).flatMap {zone -> Date? in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = zone
            return asString.flatMap{ dateFormatter.date(from: $0) }
        }
    }
}

