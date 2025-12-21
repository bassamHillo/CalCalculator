//
//  SelectionViews.swift
//  playground
//
//  Created by OpenCode on 21/12/2025.
//

import SwiftUI

// MARK: - Single Select View
struct SingleSelectView: View {
    let title: String?
    let options: [String]
    @Binding var selection: String

    var body: some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { opt in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = opt
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(selection == opt ? Color.accentColor : Color(uiColor: .systemGray4), lineWidth: 2)
                                .frame(width: 24, height: 24)
                            
                            if selection == opt {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 14, height: 14)
                                    .transition(.scale)
                            }
                        }
                        
                        Text(opt)
                            .font(.body)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .systemBackground))
                            .shadow(color: .black.opacity(selection == opt ? 0.1 : 0.05), radius: 10, x: 0, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selection == opt ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Multi Select View
struct MultiSelectView: View {
    let options: [String]
    @Binding var selected: Set<String>

    var body: some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { opt in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if selected.contains(opt) {
                            selected.remove(opt)
                        } else {
                            selected.insert(opt)
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(selected.contains(opt) ? Color.accentColor : Color(uiColor: .systemGray4), lineWidth: 2)
                                .frame(width: 24, height: 24)
                            
                            if selected.contains(opt) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.accentColor)
                                    .cornerRadius(6)
                                    .transition(.scale)
                            }
                        }
                        
                        Text(opt)
                            .font(.body)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .systemBackground))
                            .shadow(color: .black.opacity(selected.contains(opt) ? 0.1 : 0.05), radius: 10, x: 0, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selected.contains(opt) ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Previews
#Preview("Single Select") {
    SingleSelectView(
        title: "Choose one",
        options: ["Option A", "Option B", "Option C"],
        selection: .constant("Option A")
    )
    .padding()
}

#Preview("Multi Select") {
    MultiSelectView(
        options: ["Running", "Swimming", "Cycling", "Weightlifting"],
        selected: .constant(["Running", "Cycling"])
    )
    .padding()
}
