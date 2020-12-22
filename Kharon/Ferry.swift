//
//  Ferry.swift
//  Kharon
//
//  Created by Emily Atlee on 12/14/20.
//

import Foundation
import Combine

struct Evaluation {
    
    init(input: String) {
        self.input = input
    }
    
    let input: String
}

enum EvaluationType {
    case full, fast
}

enum EvaluationExit {
    case done, early, error
}

class Soul : Identifiable {
    
    let id = UUID()
    
    let name: String
    private let path: String
    private let launcher: [String]
    
    var result: SoulResult? = nil
    var lastGoodResult: SoulResult? = nil
    
    var isRunning = false {
        didSet {
            if !isRunning {
                while !oneTimeDoneListeners.isEmpty {
                    oneTimeDoneListeners.popLast()!()
                }
            }
        }
    }
    
    private var newestInstance: Int = 0
    
    private var lastTask: Process?
    
    var oneTimeDoneListeners: [() -> Void] = []
    
    
    init(name: String, path: String, launcher: [String]) {
        self.name = name
        self.path = path
        self.launcher = launcher
    }
    
    func run(input: String, callback: @escaping (SoulResult) -> Void) {
        let task = Process()
        let pipeOut = Pipe()
        let pipeErr = Pipe()
        
        let allArgs = launcher + [String](arrayLiteral: self.path, input)
        
        task.launchPath = allArgs[0]
        task.arguments = Array(allArgs.dropFirst())
        
        task.standardOutput = pipeOut
        task.standardError = pipeErr
        
        isRunning = true
        
        task.launch()
        
        newestInstance += 1
        let instance = newestInstance
        
        if lastTask != nil {
            lastTask?.terminate()
        }
        lastTask = task
        
        task.terminationHandler = { [self] process in
            
            if instance == newestInstance {
                let status = task.terminationStatus
                let dataOut = pipeOut.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: dataOut, encoding: .utf8)!
                
                let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
                let error = String(data: dataErr, encoding: .utf8)!
                
                let result = SoulResult(
                    output: output.trimmingCharacters(in: .whitespacesAndNewlines),
                    error: error.trimmingCharacters(in: .whitespacesAndNewlines),
                    status: status
                )
                
                self.result = result
                
                if self.result!.status == 0 {
                    self.lastGoodResult = result
                }
                
                isRunning = false
                
                callback(result)
            }
        }
    }
}

struct SoulResult {
    var output: String
    var error: String
    var status: Int32
}


extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
}

class Ferry: ObservableObject {
    
    let objectWillChange = ObservableObjectPublisher()
    
    let soulDispacher = DispatchQueue(label: "Soul Dispatcher", attributes: .concurrent)
    
    @Published var souls = [Soul]();
    
    init() {
        loadSouls();
    }
    
    func loadSouls() {
        let fileManager = FileManager.default
        let path = Bundle.main.resourcePath!

        do {
            let items = try fileManager.contentsOfDirectory(atPath: path)

            print("Looking for souls in \(path)")
            for item in items {
//                print("Found \(item)")
                
                let soulIdentifier = item.range(of: ".soul")
                
                if soulIdentifier != nil {
                    
                    let name = String(item.prefix(upTo: soulIdentifier?.lowerBound ?? item.endIndex))
                    let filepath = "\(path)/\(item)"
                    
                    print("Found soul: \(name)")
                    
                    let fileContents = try? String(contentsOfFile: filepath, encoding: .ascii)
                    let eol = fileContents?.range(of: "\n")
                    let shebang = fileContents?.range(of: "#!")
                    
                    var launcher: [String]!
                    
                    if fileContents != nil && eol != nil && shebang != nil && shebang!.upperBound < eol!.lowerBound {
                        launcher = String(fileContents![shebang!.upperBound..<eol!.lowerBound]).components(separatedBy: " ")
                    } else {
                        launcher = [String](arrayLiteral: "/usr/bin/env", "bash")
                    }
                    
                    souls.append(Soul(
                        name: name,
                        path: filepath,
                        launcher: launcher
                    ))
                }
            }
            
        } catch {
            print("Failed to read resources")
        }
        
        loadSoulOrder()
        saveSoulOrder()
    }
    
    func saveSoulOrder() {
        let orderedSouls = souls.map({$0.name})
        UserDefaults.standard.set(orderedSouls, forKey: "LoadedSouls")
    }
    
    func loadSoulOrder() {
        let orderedSouls: [String] = (UserDefaults.standard.stringArray(forKey: "LoadedSouls") ?? [String]())
        
        souls.sort() {
            return orderedSouls.firstIndex(of: $0.name) ?? Int.max <
                   orderedSouls.firstIndex(of: $1.name) ?? Int.max
        }
    }
    
    func moveSoul(from source: IndexSet, to destination: Int) {
        souls.move(fromOffsets: source, toOffset: destination)
        self.objectWillChange.send()
        saveSoulOrder()
    }
    
    func whenFirstNonEmptyResult(do foundFirstNonEmptyResult: @escaping (SoulResult) -> Void) {
        
        var done = false
        
        let checker: () -> Void = { [self] in
            if !done {
                for soul in souls {
                    if soul.isRunning {
                        break
                    } else {
                        if soul.result != nil {
                            if !soul.result!.output.isEmpty {
                                foundFirstNonEmptyResult(soul.result!)
                                break
                            }
                        }
                        continue
                    }
                }
                done = true
            }
        }
        
        for soul in souls {
            soul.oneTimeDoneListeners.append(checker)
        }
        
        checker()
        
    }
    
    func clearAllLastGoodResults() {
        for soul in souls {
            soul.lastGoodResult = nil
        }
        self.objectWillChange.send()
    }
    
    func evaluate(evaluation: Evaluation) {
        
        for soul in souls {
            
            soul.run(input: evaluation.input, callback: { result in
                DispatchQueue.main.sync {
                    print("Finished Soul \(soul.name) > \(result.output)")
                    self.objectWillChange.send()
                }
            })
        }
        
    }
    
}
