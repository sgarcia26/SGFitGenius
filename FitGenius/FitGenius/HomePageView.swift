//
//  HomePageView.swift
//  FitGenius
//
//  Created by Sergio Garcia on 2/3/25.
//  TEST BRANCH

/*
import SwiftUI

struct HomePageView: View {
    var body: some View {
        
        ZStack {
            // Background Image
            Image("ForestBackground")
                .resizable()
                .scaledToFill()
                .cornerRadius(15)
                .edgesIgnoringSafeArea(.all)

            VStack {
                
                VStack{
                    HStack{
                        // Left Side: Settings and Freinds
                        VStack(spacing: 15){
                            Button(action: {
                                print("Settings button tapped!")
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                            Button(action: {
                                print("Friends button tapped!")
                            }) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.leading, -100) // Adds space from the left edge
                        
                        Text("FitGenius")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                        
                    }// End of Hstack
                    
                    // Rewards Progression
                    HStack {
                            //Progress Bar
                            ProgressView(value: 0.5, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle())
                                .accentColor(.white)
                                .frame(width: 200, height: 10)
                                .padding(.leading, 20)
                                .padding(.trailing, 10)

                            // Chest Button
                            Button(action: {
                                print("Chest button tapped!")
                            }) {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                        }
                    
                }// End of VStack

            Spacer()
                
            }
            .padding()
        }
    }
}

struct HomePageView_Previews: PreviewProvider {
    static var previews: some View {
        HomePageView()
    }
}

*/
