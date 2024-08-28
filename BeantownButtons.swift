//
//  BeantownButtons.swift
//  DigiDash
//
//  Created by Rushil on 2/14/24.
//

import SwiftUI
import MapKit


struct BeantownButtons: View {
    
    @Binding var searchResults: [MKMapItem]
    @Binding var position: MapCameraPosition
    
    var visibleRegion: MKCoordinateRegion?
    
    var body: some View {
        HStack {
            Button {
                search(for: "park")
            } label: {
                Label("Parks", systemImage: "figure.and.child.holdinghands")
            }
            .buttonStyle(.borderedProminent)
            
            Button {
                search(for: "beach")
            } label: {
                Label("Beaches", systemImage: "beach.umbrella")
            }
            .buttonStyle(.borderedProminent)
            
            Button {
                search(for: "food")
            } label: {
                Label("Food", systemImage: "takeoutbag.and.cup.and.straw")
            }
            .buttonStyle(.borderedProminent)
                
            Button {
                search(for: "shop")
            } label: {
                Label("Shop", systemImage: "bag")
            }
            .buttonStyle(.borderedProminent)
        }
        .labelStyle(.iconOnly)
    }
    
    func search(for query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.region = visibleRegion ?? MKCoordinateRegion(
            center: globalVariable!.coordinate,
            span: MKCoordinateSpan (latitudeDelta: 0.0125, longitudeDelta: 0.0125)
        )
        
        Task {
            let search = MKLocalSearch(request: request)
            let response = try? await search.start()
            searchResults = response?.mapItems ?? []
        }
    }

}
