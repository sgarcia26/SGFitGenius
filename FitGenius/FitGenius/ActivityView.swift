//
//  ActivityView.swift
//  FitGenius
//
//  Created by Arpa Hakopian on 1/31/25.
//

import SwiftUI
import Charts
enum ActivityType { case steps, distance, calories }
struct ActivityView: View {
    @EnvironmentObject var manager: HealthManager
    @State private var selectedActivity: ActivityType = .calories
    var body: some View {
        VStack {
            
            Image(systemName: "flame.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.customOrange)
                    .padding(.top, 10)
            
            Text("Your Activity")
                .font(.title2)
                .bold()
                .padding(.top, 20)
            Text(selectedValue())
                .font(.largeTitle)
                .bold()
                .padding(.top, 10)
            .padding(.top, 20)
            HStack(spacing: 20) {
                ActivityTile(
                    icon: "waveform.path",
                    title: "Distance",
                    value: "\(Int(manager.distance)) m",
                    color: .customGreen,
                    isSelected: selectedActivity == .distance
                )
                .onTapGesture { selectedActivity = .distance }
                ActivityTile(
                    icon: "figure.walk",
                    title: "Steps",
                    value: "\(Int(manager.steps))",
                    color: .customOrange,
                    isSelected: selectedActivity == .steps
                )
                .onTapGesture { selectedActivity = .steps }
                ActivityTile(
                    icon: "figure.run",
                    title: "Calories",
                    value: "\(Int(manager.calories)) Kcal",
                    color: .customPurple,
                    isSelected: selectedActivity == .calories
                )
                .onTapGesture { selectedActivity = .calories }
            }
    
            .padding(.top, 20)
           
            ActivityChartView(selected: selectedActivity)
                .padding(.top, 60)
        
            VStack(spacing: 2) {
                      Text("Rise to the occasion")
                          .font(.footnote)
                          .italic()
                          .multilineTextAlignment(.center)
                          .foregroundColor(.gray)
                          .padding(.top, 30)
                      Text("Built by Data. Driven by You.")
                          .font(.caption)
                          .foregroundColor(.gray)
                  }
        }
        
        .onAppear {
            manager.fetchTodayActivity()
        }
    }
    
    // Returns the display string for the currently selected activity (steps, distance, or calories).
    func selectedValue() -> String {
        switch selectedActivity {
        case .steps:
            return "\(Int(manager.steps)) Steps"
        case .distance:
            return "\(Int(manager.distance)) m"
        case .calories:
            return "\(Int(manager.calories)) Kcal"
        }
    }
}
struct ActivityStat: View {
    var title: String
    var value: String
    var body: some View {
        VStack {
            Text(value)
                .font(.title3)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
struct ActivityTile: View {
    var icon: String
    var title: String
    var value: String
    var color: Color
    var isSelected: Bool
    var body: some View {
        VStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .padding()
                .background(color)
                .clipShape(Circle())
            Text(value)
                .font(.headline)
                .bold()
                .padding(.top, 5)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(width: 100, height: 120)
        .background(isSelected ? color.opacity(0.3) : color.opacity(0.15)) // change opacity
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isSelected ? color : .clear, lineWidth: 2) // border if selected
        )
        .scaleEffect(isSelected ? 1.05 : 1.0) // optional scale-up
        .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 5, x: 0, y: 2) // optional shadow
    }
}
struct ActivityChartView: View {
    @EnvironmentObject var manager: HealthManager
    var selected: ActivityType
    var body: some View {
        VStack(alignment: .leading) {
            Text(title())
                .font(.headline)
                .padding(.bottom, 5)
            Chart {
                ForEach(Array(data().enumerated()), id: \.offset) { index, value in
                    BarMark(
                        x: .value("Day", weekdayString(for: index)),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(color())
                }
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding(.horizontal)
    }
    
    // Returns the chart title based on the selected activity.
    func title() -> String {
        switch selected {
        case .steps: return "Steps This Week"
        case .distance: return "Distance This Week"
        case .calories: return "Calories This Week"
        }
    }
    
    // Provides weekly data values for the selected activity to display in the chart.
    func data() -> [Double] {
        switch selected {
        case .steps: return manager.weeklySteps
        case .distance: return manager.weeklyDistance
        case .calories: return manager.weeklyCalories
        }
    }
    
    // Chooses the chart bar color corresponding to the selected activity.
    func color() -> Color {
        switch selected {
        case .steps: return .customOrange
        case .distance: return .customGreen
        case .calories: return .customPurple
        }
    }
    
    // Converts a day index into a weekday abbreviation for chart labels.
    func weekdayString(for index: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        if let date = Calendar.current.date(byAdding: .day, value: index - 6, to: .startOfDay) {
            return formatter.string(from: date)
        }
        return ""
    }
}
struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView()
    }
}
extension Color {
    static let customGreen = Color(red: 6/255, green: 208/255, blue: 1/255)
    static let customOrange = Color(red: 235/255, green: 90/255, blue: 60/255)
    static let customPurple = Color(red: 183/255, green: 113/255, blue: 229/255)
}


