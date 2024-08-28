//
//  ItemInfoView.swift
//  DigiDash
//
//  Created by Rushil on 2/19/24.
//

import SwiftUI
import MapKit


struct ItemInfoView: View {

    // ItemInfoView.swift - Fetch a Look Around scene
    @State private var lookAroundScene: MKLookAroundScene?
    
    var selectedResult: MKMapItem
    var route: MKRoute?
    
    func getLookAroundScene () {
        lookAroundScene = nil
        Task {
            let request = MKLookAroundSceneRequest(mapItem: selectedResult)
            lookAroundScene = try? await request.scene
        }
    }
    
    var body: some View {
        LookAroundPreview(initialScene: lookAroundScene)
            .overlay(alignment: .bottomTrailing) {
                HStack {
                    Text ("\(selectedResult.name ?? "")")
                    if let travelTime {
                        Text(travelTime)
                    }
                }
                .font(.caption)
                .foregroundStyle(.white)
                .padding (10)
            }
            .onAppear {
                getLookAroundScene()
            }
            .onChange(of: selectedResult) {
                getLookAroundScene()
            }
    }
    
    
    
    //ItemInfoView.swift - Format travel time for display
    private var travelTime: String? {
        guard let route else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: route.expectedTravelTime)
    }
    
    
}

