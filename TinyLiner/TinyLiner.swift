

import Foundation

typealias Line = TinyLinerPackage.Line
typealias Point = TinyLinerPackage.Point

protocol TinyLinerLogStorage {
    func store(_ logs: [String])
}

@objc class TinyLiner: NSObject {
    @objc static let shared: TinyLiner = TinyLiner()
    
    private lazy var rwQueue = DispatchQueue(label: "readWriteQueue", attributes: .concurrent)
    
    private var lines = [Line]()
    
    private var linesCount = [String: Int]()
    
    private var logs = [String]()
    
    private var logsIndex = [String]()
    
    private var topLine: Line?
    
    private var ctxId: String = ""
    
    var storage: TinyLinerLogStorage?
    
    func changeContext(_ keys: String...) {
        ctxId = keys.joined().md5
    }
    
    @objc func sessionStart() {
        let time = Date().timeIntervalSince1970
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String
        let key = "\(time)\(version ?? "")\(build ?? "")"
        let sessionID = key.md5
        
        let preSessionID = UserDefaults.standard.value(forKey: UserDefaultsKeys.sessionID.rawValue) as? String
        addLine(sessionID, preId: preSessionID)
    }
    
    @objc func sessionEnd() {
        UserDefaults.standard.setValue(lines.first?.id, forKey: UserDefaultsKeys.sessionID.rawValue)
        dump { [weak self] array in
            if let array = array {
                self?.storage?.store(array)
            }
        }
    }
    
    @objc func line(_ id: String) {
        
        var id = id
        if let count = linesCount[id] {
            let index = count + 1
            linesCount[id] = index
            id += "." + "\(index)"
        } else {
            linesCount[id] = 1
        }
        
        getTopLine { [weak self] line in
            if let lastLine = line {
                self?.addLine(id, preId: lastLine.path)
            }
        }
    }
    
    @objc func lineDone(_ id: String) {
        
        rwQueue.async(flags: .barrier) { [weak self] in
            
            guard let lines = self?.lines, let logsIndex = self?.logsIndex else {
                return
            }
            var target: Line?
            var targetIndex = 0
            for (index, line) in lines.enumerated() {
                if line.id == id {
                    target = line
                    targetIndex = index
                    break
                }
            }
            var targetIndexInLogs = 0
            for (index, name) in logsIndex.enumerated() {
                if name == id {
                    targetIndexInLogs = index
                    break
                }
            }
            if let line = target {
                line.end()
                self?.lines[targetIndex] = line
                self?.logs[targetIndexInLogs] = line.description
                print(self!.logs)
            }
        }
    }
    
    @objc func point(_ id: String, ext: [String: String]? = nil) {
        getTopLine { [weak self] line in
            if let lastLine = line {
                self?.addPoint(id, preId: lastLine.id, ext: ext)
            }
        }
    }
    
    func clean() {
        rwQueue.async(flags: .barrier) { [weak self] in
            self?.lines.removeAll()
            self?.logs.removeAll()
            self?.logsIndex.removeAll()
            self?.linesCount.removeAll()
            self?.topLine = nil
            self?.ctxId = ""
        }
    }
    
    func dump(_ handler: @escaping ([String]?) -> Void) {
        rwQueue.async { [weak self] in
            handler(self?.logs)
            self?.clean()
        }
    }
        
    private func addLine(_ id: String, preId: String?) {
        let line = Line(id: id, preId: preId, ctxId: ctxId)
        rwQueue.async(flags: .barrier) { [weak self] in
            self?.lines.append(line)
            self?.topLine = line
            self?.logs.append(line.description)
            self?.logsIndex.append(line.id)
            print(self!.logs)
        }
    }
    
    private func addPoint(_ id: String, preId: String?, ext: [String: String]? = nil) {
        rwQueue.async { [weak self] in
            let point = Point(id: id, preId: preId, ext: ext, ctxId: self?.ctxId ?? "")
            self?.logs.append(point.description)
            self?.logsIndex.append(point.id)
            print(self!.logs)
        }
    }
    
    private func getTopLine(_ handler: @escaping (Line?) -> Void) {
        rwQueue.async { [weak self] in
            handler(self?.topLine)
        }
    }
}

@objc protocol Lineable {
    @objc func lineId() -> String
}

enum UserDefaultsKeys: String {
    case sessionID
}
