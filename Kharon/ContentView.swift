//
//  ContentView.swift
//  Kharon
//
//  Created by Emily Atlee on 12/13/20.
//

import SwiftUI
import Introspect

var inputNSTextField: NSTextField? = nil

struct ContentView: View, LiveInputHandler {
    
    // Preferences
    // NSUserDefaults.standardUserDefaults()
    
    @ObservedObject private var ferry = Ferry()
    @ObservedObject private var input = LiveInput()
    
    @State private var showErrors: Bool = false
    @State private var quickNotify: String? = nil
    @State private var quickNotifyTimer: Timer? = nil
    
    init() {
        input.handler = self
    }
    
    func getOutput(liveInput: LiveInput,
                   input: String,
                   typing: Bool
    ) {
        self.ferry.evaluate(
            evaluation: Evaluation(
                input: input,
                type: typing ? EvaluationType.fast : EvaluationType.full
            )
        )
    }
    
    func moveSoul(from source: IndexSet, to destination: Int) {
        ferry.moveSoul(from: source, to: destination)
    }
    
    func performCopy (copyText: String) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(copyText, forType: .string)
        setQuickNotify(message: "Copied \"\(copyText)\"")
    }
    
    func setQuickNotify (message: String) {
        quickNotify = message
        
        if quickNotifyTimer != nil {
            quickNotifyTimer!.invalidate()
        }
        quickNotifyTimer = Timer.scheduledTimer(
            withTimeInterval: 1.5,
            repeats: false) { (nil) in
                quickNotify = nil
            }
    }
    
    func editCut() {
        inputNSTextField?.currentEditor()?.cut(self)
    }
    
    func editCopy() {
        inputNSTextField?.currentEditor()?.copy(self)
    }
    
    func editPaste() {
        inputNSTextField?.currentEditor()?.paste(self)
    }
    
    func editSelectAll() {
        inputNSTextField?.currentEditor()?.selectAll(self)
    }
    
    // Views //
    
    // Input
    var inputView: some View {
        TextField (
            "Input",
            text: $input.value,
            onEditingChanged: { isEditing in
                input.typing = isEditing
            },
            onCommit: {
                let firstNonEmptySoul: Soul? = ferry.souls.first(where: {!($0.result?.output.isEmpty ?? true)})
                
                if firstNonEmptySoul != nil {
                    performCopy(copyText: firstNonEmptySoul!.result!.output)
                }
            }
        )
        .introspectTextField { textField in
            inputNSTextField = textField
            textField.becomeFirstResponder()
        }
        .disableAutocorrection(true)
        .frame(width: 300, alignment: .center)
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 0)
    }
    
    // Output
    var outputView: some View {
        List {
            ForEach(ferry.souls) { soul in
                HStack {
                    Image(systemName: "line.horizontal.3")
                        .padding(0)
                    Button(action: {
                        //
                    }) {
                        Text(soul.name)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(0)
                    
                    if soul.result != nil {
                        let errored = soul.result!.status != 0
                        let display = showErrors && errored ? soul.result!.error : soul.result!.output
                        Button(action: {
                            performCopy(copyText: display)
                        }) {
                            Text(display)
                                .foregroundColor(errored ? .red : .green)
                                .lineLimit(nil)
                                .padding(0)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(0)
                    }
                }.padding(0)
            }
            .onMove(perform: moveSoul)
            .fixedSize() // to fix weird resizing issue
            .padding(0)
        }
    }
    
    // Close Button
    var closeView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    showErrors = !showErrors
                }) {
                    Image(systemName: "exclamationmark.circle")
                }
                .buttonStyle(PlainButtonStyle())
                .padding(2)
                
                Button(action: {
                    NSApplication.shared.terminate(self)
                }) {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(PlainButtonStyle())
                .padding(2)
            }
        }
    }
    
    // Quick Notify
    var quickNotifyView: some View {
        VStack {
            Spacer()
            HStack {
                if quickNotify != nil {
                    Text(quickNotify!)
                        .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .opacity(0.1)
                        )
                        .padding(6)
                        .animation(.easeInOut(duration: 0.25))
                        .transition(.move(edge: .leading))
                }
                Spacer()
            }
        }
        .allowsHitTesting(false)
    }
    
    // Body
    var body: some View {
        VStack {
            
            
            // Input
            inputView
            
            // Output
            outputView
            
            
            
        }.frame(alignment: .center)
        .overlay (
            closeView
        )
        .overlay(
            quickNotifyView
        )
        
    }
}


protocol LiveInputHandler {
    
    func getOutput(
        liveInput: LiveInput,
        input: String,
        typing: Bool
    )
}

class LiveInput: ObservableObject {
    
    var handler: LiveInputHandler!
    
    @Published var typing: Bool = false
    
    @Published var value: String = "" {
        didSet {
            if self.handler != nil {
                self.handler!.getOutput(
                    liveInput: self,
                    input: self.value,
                    typing: self.typing
                )
            }
        }
    }
}

extension View {
    
    @ViewBuilder func isHidden(_ hidden: Bool) -> some View {
        if hidden {
            self.hidden()
        } else {
            self
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            ContentView()
//        }
//    }
//}
