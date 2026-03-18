//
//  ControlButton.swift
//  PitMissionController
//
//  Created by Quincy D on 8/9/25.
//

import SwiftUI

struct ControlButton<State: DisplayState>: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    enum Target: CustomStringConvertible {
        case left
        case right
        case sign
        case controller
        
        var description: String {
            switch self {
            case .left: "stateL"
            case .right: "stateR"
            case .sign: "stateSign"
            case .controller: "controller"
            }
        }
    }
    
    let title: String
    let action: State
    let screen: Target
    let popoverControl: Binding<Bool>?
    
    let buttonInteraction: (() -> Void)?
    
    init(title: String, action: State, screen: Target, popoverControl: Binding<Bool>? = nil, buttonInteraction: (() -> Void)? = nil) {
        self.title = title
        self.action = action
        self.screen = screen
        self.popoverControl = popoverControl
        self.buttonInteraction = buttonInteraction
    }
    
    @ObservedObject var state = sharedStates
    var selfId: State {
        switch screen {
        case .left:
            return state.stateL as! State
        case .right:
            return state.stateR as! State
        case .sign:
            return state.sign as! State
        case .controller:
            return state.controllerSleep as! State
        }
    }
    
    var body: some View {
        Text(title)
            .font(.title2)
            .foregroundColor(.white)
            .bold()
            .frame(width: 250, height: 100)

            .background(selfId == action ? Color.blue : Color.gray)
            .cornerRadius(50)
            .glassEffect(.regular.tint(colorScheme == .dark ? Color.black : Color.black.opacity(0.2)))
            .glassEffect(.regular.tint(selfId == action ? Color.blue : Color.white).interactive())
            .animation(.easeOut(duration: 0.1), value: selfId == action)

            .contentShape(Rectangle())

            .onTapGesture {
                buttonInteraction?()
                switch screen {
                case .left:
                    state.stateL = action as! CartStates
                    socket.sendMessage(type: screen.description, data: state.stateL.description)
                case .right:
                    state.stateR = action as! CartStates
                    socket.sendMessage(type: screen.description, data: state.stateR.description)
                case .sign:
                    state.sign = action as! SignStates
                    if let data = BluetoothCentralManager.shared.prepareData(type: screen.description, data: state.sign) {
                        BluetoothCentralManager.shared.sendData(data)
                    }
                case .controller:
                    state.controllerSleep = action as! ControllerSleepStates
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                popoverControl?.wrappedValue = true
            }
    }
}

#Preview {
    ControlButton(title: "Testing", action: ControllerSleepStates.MatchBoard, screen: .controller)
}
