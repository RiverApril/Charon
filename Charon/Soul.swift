//
//  Soul.swift
//  Charon
//
//  Created by Emily Atlee on 9/29/24.
//

import Foundation
import Combine
import SwiftUI

class Soul : Identifiable, ObservableObject {
    
    let id = UUID()
    
    let name: String
    private let path: String
    private let launcher: [String]
    
    @Published var result: SoulResult? = nil
    @Published var lastGoodResult: SoulResult? = nil
    
    @Published var liveOutput: String = ""
    
    @Published var isRunning = false {
        didSet {
            if !isRunning {
                while !oneTimeDoneListeners.isEmpty {
                    oneTimeDoneListeners.popLast()!()
                }
            }
        }
    }
    
    private var lastInput: String? = nil
    
    private var newestInstance: Int = 0
    
    private var lastTask: Process?
    
    var oneTimeDoneListeners: [() -> Void] = []
    
    
    init(name: String, path: String, launcher: [String]) {
        self.name = name
        self.path = path
        self.launcher = launcher
    }
    
    func run(
            input: String,
            force: Bool,
            callback: ((SoulResult) -> Void)? = nil) {
                
        if !force {
            if input == lastInput {
                return
            }
        }
                
        lastInput = input
        
            
        let task = Process()
        let pipeOut = Pipe()
        let pipeErr = Pipe()
        
        let allArgs = launcher + [String](arrayLiteral: self.path, input)
        
        task.launchPath = allArgs[0]
        task.arguments = Array(allArgs.dropFirst())
        
        task.standardOutput = pipeOut
        task.standardError = pipeErr
        
        self.liveOutput = ""
        
        isRunning = true
        
        newestInstance += 1
        let instance = newestInstance
        
        if let lastTask = lastTask {
            lastTask.terminate()
        }
        lastTask = task
                
        pipeOut.fileHandleForReading.readabilityHandler = { [self] pipe in
            if instance == newestInstance {
                if let data = String(data: pipe.availableData, encoding: .utf8) {
                    if !data.isEmpty {
                        DispatchQueue.main.sync {
                            self.liveOutput.append(data)
                            self.result?.output = self.liveOutput // in case this resolves after termination handler, I think it'll be fine
//                            print("live \(name) \(self.liveOutput)")
                        }
                        return
                    }
                }
            }
            
            pipeOut.fileHandleForReading.readabilityHandler = nil
//            print("readabilityHandler removed from \(self.name)")
        }
        
        task.terminationHandler = { [self] process in
            
            if instance == newestInstance {
                let status = task.terminationStatus
                
                DispatchQueue.main.sync {
                    
                    let output = self.liveOutput
                    
                    let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
                    let error = String(data: dataErr, encoding: .utf8)!
                    
                    let result = SoulResult(
                        output: output,
                        error: error,
                        status: status
                    )
                    
                    callback?(result)
                    
                    self.result = result
                    
                    if result.status == 0 {
                        self.lastGoodResult = result
                    }
                    
                    isRunning = false
                    
//                    print("done \(name) \(output)")
                }
            }
        }
                
        task.launch()
    }
    
    func getDisplayText(isHovering: Bool, showErrors: Bool) -> (text: String, color: Color) {
        if isRunning && !liveOutput.isEmpty {
            if (isHovering) {
                return (text: liveOutput, color: .blue)
            } else {
                return (text: liveOutput, color: .cyan)
            }
        } else if let soulResult = result {
            if soulResult.status != 0 {
                if showErrors {
                    return (text: soulResult.error, color: .red)
                } else if lastGoodResult != nil {
                    return (text: lastGoodResult!.output, color: .yellow)
                } else {
                    return (text: "", color: .yellow)
                }
            } else {
                if (isHovering) {
                    return (text: soulResult.output, color: .blue)
                } else {
                    return (text: soulResult.output, color: .green)
                }
            }
        }
        return (text: "", color: .red)
    }
    
    func appWillTerminate() {
        if let lastTask = lastTask {
            lastTask.terminate()
        }
    }
}

struct SoulResult {
    var output: String
    var error: String
    var status: Int32
}
