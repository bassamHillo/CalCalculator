//
//  ProgressBar.swift
//  playground
//
//  Created by OpenCode on 21/12/2025.
//

import SwiftUI

struct ProgressBar: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray5))
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * value)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: value)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBar(value: 0.25)
            .frame(height: 4)
            .padding()
        
        ProgressBar(value: 0.5)
            .frame(height: 4)
            .padding()
        
        ProgressBar(value: 0.75)
            .frame(height: 4)
            .padding()
        
        ProgressBar(value: 1.0)
            .frame(height: 4)
            .padding()
    }
}
