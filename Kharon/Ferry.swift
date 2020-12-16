//
//  Ferry.swift
//  Kharon
//
//  Created by Emily Atlee on 12/14/20.
//

import Foundation

struct Evaluation {
    
    init(input: String, type: EvaluationType) {
        self.input = input
        self.type = type
    }
    
    let input: String
    let type: EvaluationType
}

enum EvaluationType {
    case full, fast
}

enum EvaluationExit {
    case done, early, error
}

class Soul {
    
    let name: String
    private let path: String
    private let launcher: [String]
    
    init(name: String, path: String, launcher: [String]) {
        self.name = name
        self.path = path
        self.launcher = launcher
    }
    
    func run(input: String) -> SoulResult {
//        print("Running soul at \(path)")
        
        let task = Process()
        let pipeOut = Pipe()
        let pipeErr = Pipe()
        
        let allArgs = launcher + [String](arrayLiteral: self.path, input)
        
        task.launchPath = allArgs[0]
        task.arguments = Array(allArgs.dropFirst())
        
        task.standardOutput = pipeOut
        task.standardError = pipeErr
        
        task.launch()
        task.waitUntilExit()
        
        let status = task.terminationStatus
        let dataOut = pipeOut.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: dataOut, encoding: .utf8)!
        
        let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
        let error = String(data: dataErr, encoding: .utf8)!
        
        let result = SoulResult(
            output: output,
            error: error,
            status: status
        )
        
        return result
    }
}

struct SoulResult {
    var output: String
    var error: String
    var status: Int32
}

class SoulJob {
    init(result: SoulResult? = nil, job: DispatchWorkItem? = nil) {
        self.result = result
        self.job = job
    }
    
    var result: SoulResult?
    var job: DispatchWorkItem?
}


extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
}

class Ferry {
    
    private var souls = [(Soul, SoulJob)]();
    
    init() {
        loadSouls();
    }
    
    func loadSouls() {
        let fileManager = FileManager.default
        let path = Bundle.main.resourcePath!

        do {
            let items = try fileManager.contentsOfDirectory(atPath: path)

            print("Looking in \(path)")
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
                    
                    var launcher = [String]()
                    
                    if fileContents != nil && eol != nil && shebang != nil {
                        launcher = String(fileContents![shebang!.upperBound..<eol!.lowerBound]).components(separatedBy: " ")
                    }
                    
                    souls.append((Soul(
                        name: name,
                        path: filepath,
                        launcher: launcher
                    ), SoulJob()))
                }
            }
            
        } catch {
            print("Failed to read resources")
        }
        
        
        
    }
    
    func evaluate(evaluation: Evaluation, update: @escaping ([String]) -> Void) {
        
        for (soul, soulJob) in souls {
            
            var job: DispatchWorkItem!
                
            job = DispatchWorkItem { [self] in
                soulJob.result = soul.run(input: evaluation.input)
                
                if job === soulJob.job {
                    print("Finished Job \(soul.name)")
                    
                    let results = souls.map{String($0.1.result?.output ?? "")}
                    DispatchQueue.main.async {
                        update(results)
                    }
                }
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                soulJob.job = job
                job.perform()
            }
        }
        
    }
    
}
