//
//  FeatureCard.swift
//  ProjectZenith
//
//  Created by Rafael Cardoso on 03/01/25.
//

import SwiftUI

struct FeatureCard: View {
    let iconName: String
    let description: String
    
    var body: some View {
        HStack{
            Image(systemName: iconName)
                .font(.largeTitle)
        }
    }
}

#Preview {
    FeatureCard(iconName: "person.2.crop.square.stack.fill",
                description:"A multiline description about a feature paired with the image on the left."
    )
}
