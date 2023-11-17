

import Foundation
import CryptoKit

struct TinyLinerPackage {
    struct Util {
        static func toString(_ dict: [String: Any]) -> String? {
            if let data = try? JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions(rawValue: 0)),
               let string = String(data: data, encoding: .utf8) {
                return string
            }
            
            return nil
        }
    }
    
    class Obj {
        var id: String
        var preId: String?
        let ctxId: String
        
        init(id: String, preId: String? = nil, ctxId: String = "") {
            self.id = id
            self.preId = preId
            self.ctxId = ctxId
        }
    }
    
    class Point: Obj {
        private let timeStamp: TimeInterval
        private let ext: [String: String]?
        
        init(id: String, preId: String? = nil, ext: [String: String]? = nil, ctxId: String = "") {
            self.timeStamp = Date().timeIntervalSince1970
            self.ext = ext
            super.init(id: id, preId: preId, ctxId: ctxId)
        }
    }
    
    class Line: Obj {
        private var startTime: TimeInterval
        private var length: TimeInterval?
        private var endTime: TimeInterval?
        
        var path: String {
            (preId ?? "") + "@" + id
        }
        
        override init(id: String, preId: String? = nil, ctxId: String = "") {
            self.startTime = Date().timeIntervalSince1970
            super.init(id: id, preId: preId, ctxId: ctxId)
        }
        
        func end() {
            let time = Date().timeIntervalSince1970
            endTime = time
            length = time - startTime
        }
    }
}

extension TinyLinerPackage.Point: CustomStringConvertible {
    public var description: String {
        
        let dict: [String: Any] = [
            "preId": preId ?? "NULL",
            "id": id,
            "ctxId": ctxId,
            "ts": timeStamp,
            "ext": ext as Any
        ]
        return TinyLinerPackage.Util.toString(dict) ?? ""
    }
}

extension TinyLinerPackage.Line: CustomStringConvertible {
    public var description: String {
        let dict: [String: Any] = [
            "preId": preId ?? "NULL",
            "id": id,
            "ctxId": ctxId,
            "sTime": startTime,
            "length": length ?? "NULL",
            "eTime": endTime ?? Double.greatestFiniteMagnitude
        ]
        return TinyLinerPackage.Util.toString(dict) ?? ""
    }
}

extension String {
    var md5: String {
        
        guard let data = data(using: .utf8) else {
            return ""
        }
        
        return Insecure.MD5
            .hash(data: data)
            .map { String(format: "%02hhx", $0) }
            .joined()
    }
}
