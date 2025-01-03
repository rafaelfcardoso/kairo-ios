//
//  ContentView.swift
//  ProjectZenith
//
//  Created by Rafael Cardoso on 18/12/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            VStack{
                ZStack{
                    RoundedRectangle(cornerRadius: 30)
                        .frame(width: 150, height: 150)
                        .foregroundStyle(.tint)
                    Image(systemName: "globe")
                        .renderingMode(.original)
                        .font(.system(size: 100))
                        .foregroundStyle(.white)
                }
                Text("Welcome to Zenith")
                    .font(.title)
                    .fontWeight(.semibold)
                VStack{
                    Text("Your Journey to Digital Wellbeing Starts Here")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}



//struct ContentView_Previews:
//    PreviewProvider{
//    static var previews: some View{
//        ContentView()
//    }
//}

#Preview {
    ContentView()
}


