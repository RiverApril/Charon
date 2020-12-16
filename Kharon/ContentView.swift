//
//  ContentView.swift
//  Kharon
//
//  Created by Emily Atlee on 12/13/20.
//

import SwiftUI

struct ContentView: View, LiveInputHandler {
    
    // Preferences
    // NSUserDefaults.standardUserDefaults()
    
    private let ferry = Ferry()
    
    @ObservedObject private var primaryInput = LiveInput()
    
    init() {
        primaryInput.handler = self
    }
    
    func getOutput(liveInput: LiveInput,
                   input: String,
                   typing: Bool,
                   update: @escaping ([String]) -> Void
    ) {
        self.ferry.evaluate(
            evaluation: Evaluation(
                input: input,
                type: typing ? EvaluationType.fast : EvaluationType.full
            ),
            update: update
        )
    }

    var body: some View {
        VStack {
            
            
            // Input
            TextField(
                "Input",
                text: $primaryInput.input,
                onEditingChanged: { isEditing in
                    self.primaryInput.typing = isEditing
                },
                onCommit: {
                    
                }
            )
            .disableAutocorrection(true)
            .frame(width: 200, alignment: .center)
            .padding(12)
            
            // Output
            List(
                self.primaryInput.outputs
            ) { output in
                Text (
                    output.output
                )
                .foregroundColor(self.primaryInput.typing ? .green : .blue)
                .lineLimit(nil)
            }
            
            
            
        }.frame(alignment: .center)
        .overlay (
            HStack{
                Spacer()
                VStack{
                    Button(action: {
                        NSApplication.shared.terminate(self)
                    }) {
                        Image(systemName: "xmark.circle")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(2)
                    Spacer()
                }
            }
        )
    }
}


protocol LiveInputHandler {
    
    func getOutput(
        liveInput: LiveInput,
        input: String,
        typing: Bool,
        update: @escaping ([String]) -> Void
    )
}

struct IdentifiableOutput: Identifiable {
    let id = UUID()
    let output: String
}

class LiveInput: ObservableObject {
    
    var handler: LiveInputHandler?
    
    @Published var typing: Bool = false
    @Published var outputs: [IdentifiableOutput] = [IdentifiableOutput]()
    
    @Published var input: String = "" {
        didSet {
            if self.handler != nil {
                self.handler!.getOutput(
                    liveInput: self,
                    input: self.input,
                    typing: self.typing,
                    update: { newOuputs in
                        self.outputs = newOuputs.map{IdentifiableOutput(output: $0)}
                    }
                )
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
