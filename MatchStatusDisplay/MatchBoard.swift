//
//  MatchBoard.swift
//  MatchStatusDisplay
//
//  Created by Quincy D on 8/3/25.
//

import SwiftUI

struct MatchBoard: View {
    @ObservedObject var matchPackage = MatchStore.shared
    
    init() {
        _ = BluetoothPeripheralManager.shared
    }
    
    private let fontSizeBase: CGFloat = 30
    @Environment(\.colorScheme) var colorScheme
    
    private static let matchDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // Time with AM/PM
        return formatter
    }()
    
    var body: some View {
        HStack {
            Image(colorScheme == .dark ? "Wordmark - Dark" : "Wordmark - Light")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 600)
                .padding(20)
                .padding(.leading, 20)
            ScrollView {
                LazyVStack(spacing: 14) {
                    Color.clear.frame(height: 13)
                    ForEach(matchPackage.matches) { matchPackage in
                        ZStack {
                            ZStack {
                                HStack {
                                    RoundedRectangle(cornerRadius: 20, style: .circular)
                                        .fill(
                                            (matchPackage.win == nil)
                                            ? Color.yellow.opacity(0.7)
                                            : ((matchPackage.win ?? false) ? Color.green : Color.red)
                                        )
                                        .padding(.leading, 5)
                                }
                                HStack {
                                    Spacer()
                                    if (matchPackage.win != nil) {
                                        Text("+\(matchPackage.rp ?? 0)")
                                            .font(.system(size: fontSizeBase + 5, weight: .bold, design: .default))
                                            .foregroundStyle(Color.black.opacity(0.6))
                                            .multilineTextAlignment(.trailing)
                                            .padding(.horizontal, 35)
                                    } else {
                                        let formatted = MatchBoard.matchDateFormatter.string(from: Date(timeIntervalSince1970: matchPackage.time))
                                        let comps = formatted.split(separator: " ")
                                        let timeText = comps.first ?? ""
                                        let ampmLetter = comps.count > 1 ? comps[1].lowercased().prefix(1) : ""
                                        Text("\(timeText)\(ampmLetter)")
                                            .font(.system(size: fontSizeBase - 10, weight: .medium, design: .default))
                                            .foregroundStyle(Color.black.opacity(0.9))
                                            .multilineTextAlignment(.trailing)
                                            .padding(.horizontal, 25)
                                    }
                                }
                            }
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 20, style: .circular)
                                    .fill(Color.white)
                                    .padding(.trailing, 100)
                                    .padding(.leading, 5)
                                RoundedRectangle(cornerRadius: 20, style: .circular)
                                    .fill(colorScheme == .dark ? Color.black.opacity(0.90) : Color.white)
                                    .padding(.trailing, 100)
                            }
                            
                            HStack {
                                Text(matchPackage.matchId)
                                    .font(.system(size: fontSizeBase + 10, weight: .bold, design: .default))
                                
                                Spacer()
                                
                                HStack {
                                    ForEach(matchPackage.red, id: \.self) { team in
                                        Text(String(team))
                                            .font(.system(size: fontSizeBase, weight: .medium, design: .default))
                                            .foregroundColor(team == 1701 ? Color.white : Color(red: 237/255.0, green: 28/255.0, blue: 36/255.0))
                                            .padding(5)
                                            .background(team == 1701 ? Color(red: 126/255.0, green: 43/255.0, blue: 53/255.0) : Color.clear)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .circular))
                                            .padding(.leading, team == 1701 ? 41 : 35)
                                    }
                                }
                                
                                HStack {
                                    ForEach(matchPackage.blue, id: \.self) { team in
                                        Text(String(team))
                                            .font(.system(size: fontSizeBase, weight: .medium, design: .default))
                                            .foregroundColor(team == 1701 ? Color.white : Color(red: 0/255.0, green: 101/255.0, blue: 179/255.0))
                                            .padding(5)
                                            .background(team == 1701 ? Color(red: 126/255.0, green: 43/255.0, blue: 53/255.0) : Color.clear)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .circular))
                                            .padding(.leading, team == 1701 ? 41 : 35)
                                    }
                                }
                            }
                            .padding(.leading, 35)
                            .padding(.trailing, 130)
                            .padding(.vertical, 10)
                        }
                    }
                    .padding(.horizontal, 30)
                }
            }
            .shadow(color: colorScheme == .dark ? Color.clear :  Color.gray.opacity(0.25), radius: colorScheme == .dark ? 0 : 5)
        }
        .statusBar(hidden: true)
    }
}

#Preview {
    MatchBoard()
}
