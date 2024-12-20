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
            Color(red: 253/255, green: 241/255, blue: 217/255)
                .edgesIgnoringSafeArea(.all)
            VStack{
                Text("Zenith")
                    .font(.system(size:32, weight: .medium, design: .default))
                    .foregroundColor(.black)
                VStack{
                    Image(systemName: "globe")
                        .renderingMode(.original)
                        .resizable()
                        .frame(width: 180, height: 180)
                        .colorInvert()
                }
                Spacer()
                VStack{
                    Text("Your Journey to Digital Wellbeing Starts Here")
                        .font(.system(size:24, weight: .medium, design: .default))
                        .foregroundColor(.black)
                        .padding()
                        .multilineTextAlignment(.center)
                }
                Spacer()
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


