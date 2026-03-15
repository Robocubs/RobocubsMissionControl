//
//  TextPopover.swift
//  RobocubsMissionControl
//
//  Created by Quincy D on 10/13/25.
//

import SwiftUI

private enum Field: Hashable {
    case textInput
}

struct TextFieldPopover: View {
    @State private var listName: String = "Test"

    @Binding var isPresented: Bool
    
    @State private var text: String = ""
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        NavigationStack {
            VStack {
                Group{
                    TextField("StringProtocol", text: $text)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray5))
                        .focused($focusedField, equals: .textInput)
                }
                .cornerRadius(30)
                .padding()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark") {
                            
                        }
                    }
                    
                    ToolbarItem(placement: .principal) {
                        Text("Twitch Channel")
                            .font(.title3.bold())
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark") {
                            
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .frame(width: 500, height: 150)
        .presentationDetents([.height(150)])
        .presentationSizing(.fitted)
        .onAppear {
                focusedField = .textInput
            }
    }
}

#Preview {
    VStack {}
        .sheet(isPresented: .constant(true)) {
            TextFieldPopover(isPresented: .constant(true))
        }
}
