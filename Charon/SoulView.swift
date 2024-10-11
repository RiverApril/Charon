//
//  SoulView.swift
//  Charon
//
//  Created by Emily Atlee on 9/29/24.
//

import Foundation
import Combine
import SwiftUICore
import SwiftUI

struct SoulView : View {
    
    @ObservedObject var soul: Soul
    @Binding var showErrors: Bool
    
    @State var multiline: Bool = false
    @State private var soulNameHovering = false
    @State private var soulResultHovering = false
    
    var performCopy: (String) -> Void
    
    @ViewBuilder
    var body: some View {
        HStack(alignment: .top) {
            Button(action: {
                multiline = !multiline
            }) {
                Text(soul.name)
                    .opacity(soulNameHovering ? 1.0 : 0.5)
                    .padding(0)
            }
            .onHover(perform: { hovering in
                soulNameHovering = hovering
            })
            .buttonStyle(PlainButtonStyle())
            .padding(0)
            
            let display = soul.getDisplayText(isHovering: soulResultHovering, showErrors: showErrors)
            
            Button(action: {
                performCopy(display.text)
            }) {
                Text(display.text)
                    .foregroundColor(display.color)
                    .padding(0)
                    .lineLimit(multiline ? 100 : 1)
            }
            .lineLimit(nil)
            .buttonStyle(PlainButtonStyle())
            .padding(0)
            .onHover(perform: { hovering in
                soulResultHovering = hovering
            })
            .frame(maxHeight: .infinity)
        }
        .padding(0)
    }
}
