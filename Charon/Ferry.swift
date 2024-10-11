//
//  Ferry.swift
//  Charon
//
//  Created by Emily Atlee on 12/14/20.
//

import Foundation
import Combine
import SwiftUICore

//struct Evaluation {
//    
//    init(input: String) {
//        self.input = input
//    }
//    
//    let input: String
//}


//extension String {
//    func matches(_ regex: String) -> Bool {
//        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
//    }
//}

enum SetupStatus {
    case waiting, done, failed
}

class Ferry : ObservableObject {
    
//    let objectWillChange = ObservableObjectPublisher()
    
    let soulDispacher = DispatchQueue(label: "Soul Dispatcher", attributes: .concurrent)
    
    @Published var souls = [Soul]();
    
    @Published var setupMessage = "Initalizing..."
    @Published var setupStatus = SetupStatus.waiting
    @Published var setupSoul: Soul
    
    
    init() {
        setupSoul = Soul(
            name: "setup",
            path: "",
            launcher: [""]
        )
        appData.ferry = self
        loadSouls();
    }
    
    func loadSouls() {
        let fileManager = FileManager.default
        let path = Bundle.main.resourcePath!

        do {
            
            let launcherFilename = "\(path)/launch.sh"
            let setupFilename = "\(path)/setup.sh"
            
            let bashLauncher = [String](arrayLiteral: "/usr/bin/env", "bash")
            
            setupSoul = Soul(
                name: "setup",
                path: setupFilename,
                launcher: bashLauncher
            )
            
            runSetup(path)
            
            
            let items = try fileManager.contentsOfDirectory(atPath: path)

            print("Looking for souls in \(path)")
            for item in items {
//                print("Found \(item)")
                
                let soulIdentifier = item.range(of: ".soul")
                
                if soulIdentifier != nil {
                    
                    let name = String(item.prefix(upTo: soulIdentifier?.lowerBound ?? item.endIndex))
                    let filepath = "\(path)/\(item)"
                    
                    print("Found soul: \(name)")
                    
                    let launcher = [String](arrayLiteral: "/usr/bin/env", "bash", launcherFilename, path)
                    
//                    let fileContents = try? String(contentsOfFile: filepath, encoding: .ascii)
//                    let eol = fileContents?.range(of: "\n")
//                    let shebang = fileContents?.range(of: "#!")
//
//                    var launcher: [String]!
//
//                    if fileContents != nil && eol != nil && shebang != nil && shebang!.upperBound < eol!.lowerBound {
//                        launcher = String(fileContents![shebang!.upperBound..<eol!.lowerBound]).components(separatedBy: " ")
//                    } else {
//                        let pythonPath = path+"/python.sh"
//                        launcher = [String](arrayLiteral: "/usr/bin/env", "bash", pythonPath)
//                    }
                    
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
//        self.objectWillChange.send()
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
//        self.objectWillChange.send()
    }
    
    func evaluate(input: String) {
        
        for soul in souls {
            
            soul.run(input: input, force: false)
        }
        
    }
    
    func runSetup(_ input: String) {
        self.setupMessage = "Setup Running..."
//        self.objectWillChange.send()
        
        setupSoul.run(
                input: input,
                force: true,
                callback: { result in
            if (result.status == 0) {
                print("Finished Setup > \(result.output)")
                self.setupMessage = "Setup Complete"
                self.setupStatus = .done
//                    self.objectWillChange.send()
            } else {
                print("Setup failed > \(result.output)\(result.error)")
                self.setupMessage = "Setup Failed"
                self.setupStatus = .failed
//                    self.objectWillChange.send()
            }
        })
    }
    
    func appWillTerminate() {
        for soul in souls {
            soul.appWillTerminate()
        }
    }
    
}
