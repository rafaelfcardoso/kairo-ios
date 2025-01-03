//
//  MainView.swift
//  ProjectZenith
//
//  Created by Rafael Cardoso on 02/01/25.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        VStack {
            Text("Focus Now")
                .font(.title)
                .fontWeight(.semibold)
            Text("This is your main page")
                .font(.title2)
            RoundedRectangle(cornerRadius:30)
                .frame(height:190)
                .foregroundStyle(Color.secondary)
            Spacer()
            
            Button {
                print("Focus Session Started")
            } label:{
                Text("Start a Focus Session")
                    .foregroundColor(.black)
                    .frame(width:370, height:45)
                    .background(Color.white)
                    .font(.system(size: 18, weight:.bold,design:.default))
                    .cornerRadius(15.0)
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

