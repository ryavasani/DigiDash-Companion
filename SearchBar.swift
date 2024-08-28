//
//  SearchBar.swift
//  DigiDash
//
//  Created by Rushil on 3/26/24.
//

import SwiftUI
import MapKit

struct SearchBar: View {
    @Binding var searchQuery: String
    var onSearch: (String) -> Void
    
    var body: some View {
        HStack {
            TextField("Search", text: $searchQuery, onCommit: {
                onSearch(searchQuery)
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Search") {
                onSearch(searchQuery)
            }
            .padding(.horizontal)
        }
    }
}
