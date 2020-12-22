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
    @State private var showErrorsHovering: Bool = false
    @State private var exitHovering: Bool = false
    
    @State private var quickNotify: String? = nil
    @State private var quickNotifyTimer: Timer? = nil
    
    @State private var soulHovering = [UUID : Bool]()
    @State private var soulResultHovering = [UUID : Bool]()
    
    init() {
        input.handler = self
    }
    
    func getOutput(liveInput: LiveInput,
                   input: String
    ) {
        self.ferry.evaluate(
            evaluation: Evaluation(
                input: input
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
    
    
    func getDisplayText(_ soul: Soul) -> (text: String, color: Color) {
        if soul.result!.status != 0 {
            if showErrors {
                return (text: soul.result!.error, color: .red)
            } else if soul.lastGoodResult != nil {
                return (text: soul.lastGoodResult!.output, color: .yellow)
            } else {
                return (text: "", color: .yellow)
            }
        } else {
            if (soulResultHovering[soul.id] ?? false) {
                return (text: soul.result!.output, color: .blue)
            } else {
                return (text: soul.result!.output, color: .green)
            }
        }
    }
    
    
    
    // Views //
    
    // Input
    var inputView: some View {
        InputTextField (
            placeHolder: "Input",
            text: $input.value,
            onEnter: {
                ferry.whenFirstNonEmptyResult(do: { result in
                    let output = result.output
                    let endIndex = output.firstIndex(of: "\n") ?? output.endIndex
                    let firstLine = output[..<endIndex]
                    
                    performCopy(copyText: String(firstLine))
                })
                ferry.clearAllLastGoodResults()
            },
            onInternalChange: { newNSTextField in
                inputNSTextField = newNSTextField
            }
        )
        .introspectTextField { textField in
            textField.becomeFirstResponder()
        }
        .disableAutocorrection(true)
        .frame(alignment: .center)
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 0)
    }
    
    // Output
    var outputView: some View {
        List {
            ForEach(ferry.souls) { soul in
                HStack {
//                    Image(systemName: "line.horizontal.3")
//                        .resizable()
//                        .frame(width: 5, height: 11)
//                        .opacity((soulHovering[soul.id] ?? false) ? 1.0 : 0.2)
//                        .padding(0)
                    Text(soul.name)
                        .opacity(((soulHovering[soul.id] ?? false) && !(soulResultHovering[soul.id] ?? false)) ? 1.0 : 0.5)
                        .padding(0)
                    
                    if soul.result != nil {
                        let display = getDisplayText(soul)
                        
                        Button(action: {
                            performCopy(copyText: display.text)
                        }) {
                            Text(display.text)
                                .foregroundColor(display.color)
                                .padding(0)
                        }
                        .lineLimit(nil)
                        .buttonStyle(PlainButtonStyle())
                        .padding(0)
                        .onHover(perform: { hovering in
                            soulResultHovering[soul.id] = hovering
                        })
                    }
                }
                .padding(0)
                .onHover(perform: { hovering in
                    soulHovering[soul.id] = hovering
                })
            }
            .onMove(perform: moveSoul)
            .fixedSize() // to fix weird resizing issue
            .padding(0)
        }
        .frame(width: 300)
    }
    
    let fadeGradient = Gradient(colors: [
        Color(NSColor.textBackgroundColor.withAlphaComponent(0)),
        Color(NSColor.textBackgroundColor.withAlphaComponent(1))
    ])
    
    //Buttons
    var buttonsView: some View {
        VStack {
            Spacer()
            HStack(spacing: 0, content: {
                Spacer()
                Button(action: {
                    showErrors = !showErrors
                }) {
                    Image(systemName: showErrorsHovering ? "exclamationmark.circle.fill" : "exclamationmark.circle")
                        .colorMultiply( showErrors ? .red : .white)
                }
                .onHover(perform: { hovering in
                    showErrorsHovering = hovering
                })
                .buttonStyle(PlainButtonStyle())
                .padding(2)
                
                Button(action: {
                    NSApplication.shared.terminate(self)
                }) {
                    Image(systemName: exitHovering ? "xmark.circle.fill" : "xmark.circle")
                }
                .onHover(perform: { hovering in
                    exitHovering = hovering
                })
                .buttonStyle(PlainButtonStyle())
                .padding(2)
            })
            .frame(height: 32, alignment: .bottom)
            .background(LinearGradient(gradient: fadeGradient, startPoint: .top, endPoint: .bottom))
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
            buttonsView
        )
        .overlay(
            quickNotifyView
        )
        
    }
}


protocol LiveInputHandler {
    
    func getOutput(
        liveInput: LiveInput,
        input: String
    )
}

class LiveInput: ObservableObject {
    
    var handler: LiveInputHandler!
    
    @Published var value: String = "" {
        didSet {            
            if self.handler != nil {
                self.handler!.getOutput(
                    liveInput: self,
                    input: self.value
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

struct InputTextField: NSViewRepresentable {
    @Binding var text: String
    
    let placeHolder: String
    let onEnter: () -> Void
    let onInternalChange: (NSTextField) -> Void
    
    init(placeHolder: String, text: Binding<String>,
         onEnter: @escaping () -> Void,
         onInternalChange: @escaping (NSTextField) -> Void) {
        
        self._text = text
        
        self.placeHolder = placeHolder
        self.onEnter = onEnter
        self.onInternalChange = onInternalChange
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textfield = NSTextField()
        textfield.stringValue = text
        textfield.placeholderString = placeHolder
        textfield.delegate = context.coordinator
        
        onInternalChange(textfield)
        
        return textfield
    }
    
    func updateNSView(_ textfield: NSTextField, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        
        let parent: InputTextField
        
        init(_ parent: InputTextField) {
            self.parent = parent
        }
        
        func updateText(_ notification: Notification) {
            guard let textView = notification.object as? NSTextField else {
                return
            }
            self.parent.text = textView.stringValue
            print("updateText", self.parent.text)
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                textView.selectAll(self)
                self.parent.onEnter()
                return true
            }
            return false
        }
        
        func controlTextDidBeginEditing(_ notification: Notification) {
            updateText(notification)
            print("Begin editing")
        }
        
        func controlTextDidChange(_ notification: Notification) {
            updateText(notification)
            print("Text did change")
        }
        
        func controlTextDidEndEditing(_ notification: Notification) {
            updateText(notification)
            print("End editing")
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
