//  ContentView.swift
//  DigiDash
//
//  Created by Rushil on 1/30/24.
// USE OPTION KEY TO ZOOM IN AND OUT ON IPHONE SIMULATOR
//TO DO: Audio

import SwiftUI
import MapKit
import CoreLocation
import AVFoundation


//Placemark for user location
var globalVariable: MKPlacemark?
var userLocation: CLLocation?
var lastUserLocation: CLLocation?



struct ContentView: View {
    
    @State var searchResults: [MKMapItem] = []
    @State private var position: MapCameraPosition = .automatic
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var selectedResult: MKMapItem?
    //@State var position: MapCameraPosition
    @State private var searchQuery: String = ""
    @State var mileCounter = 0.0
    
    @StateObject var viewModel = ContentViewModel()
    
    @State private var route: MKRoute?
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.331516, longitude: -121.89105), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
    
    
    @State var labelText = "Choose Destination for Directions"
    @State var count = 1
    @State var directionsArray: [String] = []
    @State var icon = "car.circle"

    
    //Pop up
    @State private var isShowingPopup = false
    
    
    
    @State var userLocation: CLLocationCoordinate2D? = nil
    @State var lastUserLocation: CLLocationCoordinate2D? = nil
    
    
    
    @State private var lastCheckTime = Date()
    
    
    let synthesizer = AVSpeechSynthesizer()

    func speakText(Voicetext: String) {
        let speechUtterance = AVSpeechUtterance(string: Voicetext)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechUtterance.rate = 0.5
        synthesizer.speak(speechUtterance)
    }
    
    
    var body: some View {
      
        
        //TOP DIRECTIONS INFO
        VStack(alignment: .center) {
            
            HStack {
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24) // Set the size of the icon to match the text
                    .padding(.trailing, 4) // Add padding to the trailing edge to separate the icon from the text
                Text(labelText)
            }
            
            Button(action: {
                self.updateLabelText()
                self.updateImage()
            }) {
                
                Text("Update")
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)) // Add padding around the text
                            
                    .background(Color.blue)
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
                
            }
            
            VStack {
                Button("Show DigiDash View") {
                    isShowingPopup = true
                }
            }
            .sheet(isPresented: $isShowingPopup, content: {
                LargePopupView(isShowingPopup: $isShowingPopup, labelText: $labelText, count: $count,  directionsArray: $directionsArray, icon: $icon, mileCounter: $mileCounter)
            })
        }
        
        
        //INITIALIZING MAP, MARKER, and ROUTE
        Map(position: $position, selection: $selectedResult) {
            
            ForEach(searchResults, id: \.self) { result in
                Marker(item: result)
            }
            
            .annotationTitles(.hidden)
            
            
            if let route {
                MapPolyline(route)
                    .stroke(.blue, lineWidth: 5)
            }
        }
        
        .accentColor(.pink
        )
        .onAppear {
            viewModel.checkIfLocationsServicesIsEnabled()
            
        }
        
        .mapStyle(.standard(elevation: .realistic))
        
        //BUTTONS AREA AND CALLING SEARCH RESULTS
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                
                VStack(spacing:0) {
                    if let selectedResult {
                        ItemInfoView(selectedResult: selectedResult, route: route)
                            .frame(height: 128)
                            .clipShape(RoundedRectangle (cornerRadius: 10))
                            .padding([.top, .horizontal])
                    }
                    
                    //Display search results or additional UI elements based on search state
                    if searchResults.isEmpty {
                        Text("No results found")
                            .foregroundColor(.secondary)
                    }
                    
                    BeantownButtons(searchResults: $searchResults, position: $position, visibleRegion: visibleRegion)
                    
                    //.padding(.top)
                }
                Spacer()
            }
            .background(.ultraThinMaterial)
            
            VStack {
                SearchBar(searchQuery: $searchQuery, onSearch: search)
                   .padding()
                
                // Display selected result if available
                if let selectedResult = selectedResult {
                    ItemInfoView(selectedResult: selectedResult, route: route)
                        .frame(height: 128)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding([.top, .horizontal])
                }
                
                BeantownButtons(searchResults: $searchResults, position: $position, visibleRegion: visibleRegion)
            }
            .background(.ultraThinMaterial)
        }
        
        .onChange(of: searchResults) {
            position = .automatic
        }
        
        .onChange(of: selectedResult) {
            getDirections()
        }
        
        .onMapCameraChange { context in
           visibleRegion = context.region
       }
        
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateLocation)) { _ in
            
            if selectedResult != nil {
                
                // Check if 1.5 seconds have passed since the last check
                let timeSinceLastCheck = Date().timeIntervalSince(lastCheckTime)
                if timeSinceLastCheck >= 1.5 {
                    // Perform the checkDirections() function if enough time has passed
                    checkDirections()
                    // Update last check time
                    lastCheckTime = Date()
                }
                

            }
            
        }
    
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        
        
    }
    
    func search(for query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.region = visibleRegion ?? MKCoordinateRegion(
            center: globalVariable!.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125)
        )
        
        Task {
            let search = MKLocalSearch(request: request)
            let response = try? await search.start()
            searchResults = response?.mapItems ?? []
        }
    }
    
    //UPDATE TEXT OF LABEL
    func updateLabelText() {
        
        if count < directionsArray.count {
            labelText = directionsArray[count]
            
        }
        
        count = count+1
        
    }
    
    // UPDATE ICON AT TOP OF THE SCREEN
    func updateImage() {
        

        if labelText.contains("Turn left") {
            // Update image to your desired image
            icon = "arrow.turn.up.left"
        } else if labelText.contains("Turn right") {
            // Update image to your desired image
            icon = "arrow.turn.up.right"
        } else if labelText.contains("right") {
            icon = "arrow.turn.up.right"
        } else if labelText.contains("left") {
            icon = "arrow.turn.up.left"
        } else if labelText.contains("destination") {
            icon = "mappin.circle.fill"
        } else if labelText.contains("Merge") {
            icon = "arrow.triangle.merge"
        } else if labelText.contains("Keep right") {
            icon = "arrow.triangle.pull"
        } else if labelText.contains("Take exit") || labelText.contains("Take the exit") {
            icon = "arrow.triangle.pull"
        }
        
    }
    
    //GET DIRECTIONS INFO AND FIND STEPS
    
    func getDirections() {

        route = nil
        count = 1
        directionsArray = []
        
        guard let selectedResult else { return }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: globalVariable!)
        request.destination = selectedResult
        
        Task {
            let directions = MKDirections(request: request)
            let response = try? await directions.calculate()
            route = response?.routes.first
            
            
            let currentStep = route!.steps.first!
            let nextStep = route!.steps[1]
            // Calculate distance between source and the starting point of the route
            let currentLocation = CLLocation(latitude: globalVariable!.coordinate.latitude, longitude: globalVariable!.coordinate.longitude)
            
            
            //let firstTurnLocation = CLLocation(latitude: route!.steps.first!.polyline.coordinate.latitude, longitude: route!.steps.first!.polyline.coordinate.longitude)
            
            
            //let currentStepEndLocation = CLLocation(latitude: currentStep.polyline.coordinate.latitude, longitude: currentStep.polyline.coordinate.longitude)
            
            let nextStepStartLocation = CLLocation(latitude: nextStep.polyline.coordinate.latitude, longitude: nextStep.polyline.coordinate.longitude)
                        
            
            
            let distanceInMeters = currentLocation.distance(from: nextStepStartLocation)
            
            let distanceInMiles = distanceInMeters * 0.000621371 // Convert meters to miles
            
            mileCounter = round(distanceInMiles * 100) / 100

            for step in route!.steps {
                
                directionsArray.append(step.instructions)
                labelText = step.instructions
                
            }

            updateLabelText()
            updateImage()
        }
        
    }
    
    
    //Update directions when location changes
    func checkDirections() {
        
        guard let selectedResult else { return }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: globalVariable!)
        request.destination = selectedResult
        
        Task {
            let directions = MKDirections(request: request)
            let response = try? await directions.calculate()
            let newRoute = response?.routes.first
            
            
            if newRoute != nil {
                // Variable `newroute` is not nil, perform actions here
                let updatedLabelText = newRoute!.steps[0].instructions
                
                
                let currentStep = route!.steps.first!
                let nextStep = route!.steps[1]
                
                let currentLocation = CLLocation(latitude: globalVariable!.coordinate.latitude, longitude: globalVariable!.coordinate.longitude)
                
                //let firstTurnLocation = CLLocation(latitude: route!.steps.first!.polyline.coordinate.latitude, longitude: route!.steps.first!.polyline.coordinate.longitude)
                
                
               // let currentStepEndLocation = CLLocation(latitude: currentStep.polyline.coordinate.latitude, longitude: currentStep.polyline.coordinate.longitude)
                
                let nextStepStartLocation = CLLocation(latitude: nextStep.polyline.coordinate.latitude, longitude: nextStep.polyline.coordinate.longitude)
                
                let distanceInMeters = currentLocation.distance(from: nextStepStartLocation)
                let distanceInMiles = distanceInMeters * 0.00062137 // Convert meters to miles
                
                mileCounter = round(distanceInMiles * 100) / 100

                
                if (updatedLabelText != labelText) {
                    
                    route = newRoute
                    directionsArray = []
                    count = 1
                    
                    for step in route!.steps {
                        
                        directionsArray.append(step.instructions)
                        labelText = step.instructions
                    }

                    updateLabelText()
                    updateImage()
                    // Call this function with the text you want to read aloud
                    //let spokenText = labelText
                    //speakText(Voicetext: spokenText)
                }
            }

        }
    }
    
}

struct MirrorImageHorizontally: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}


extension View {
    func mirrorHorizontally() -> some View {
        self.modifier(MirrorImageHorizontally())
    }
}


struct LargePopupView: View {
    @Binding var isShowingPopup: Bool
    
    
    @Binding var labelText: String
    @Binding var count: Int
    @Binding var directionsArray: [String]
    @Binding var icon: String
    
    @Binding var mileCounter: Double
    
    
    let contentView = ContentView()
    
    var body: some View {
        
        HStack {
            
            // Add your content for the large popup here
            
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .center) {
                
                    Text(labelText)
                        .font(.title)
                        .rotationEffect(.degrees(270))
                        .padding(.bottom, 125)
                        .mirrorHorizontally()
                    
                    Image(systemName: icon)  
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 75, height: 75) // Set the size of the icon to match the text
                        .rotationEffect(.degrees(270))
                        .mirrorHorizontally()
                    
                }
                
                Text(String(mileCounter) + " miles to next turn")
                    .mirrorHorizontally()
                    .rotationEffect(.degrees(90))
                    .padding(.trailing, 30) // Adjust top padding to decrease space
                    .font(.system(size: 24))
                
                
                Button(action: {
                    isShowingPopup = false
                }) {
                    Text("Close")
                        .rotationEffect(.degrees(90)) // Rotate the text by 90 degrees
                }
                
            }
            
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
    }
    
    //UPDATE TEXT OF LABEL
    func updateLabelText() {
        
        if count < directionsArray.count {
            labelText = directionsArray[count]
        }
        
        count = count+1
        
        
    }
    
    // UPDATE ICON AT TOP OF THE SCREEN
    func updateImage() {
        
        if labelText.contains("Turn left") {
            // Update image to your desired image
            icon = "arrow.turn.up.left"
        } else if labelText.contains("Turn right") {
            // Update image to your desired image
            icon = "arrow.turn.up.right"
        } else if labelText.contains("right") {
            icon = "arrow.turn.up.right"
        } else if labelText.contains("left") {
            icon = "arrow.turn.up.left"
        } else if labelText.contains("destination") {
            icon = "mappin.circle.fill"
        } else if labelText.contains("Merge") {
            icon = "arrow.triangle.merge"
        } else if labelText.contains("Keep right") {
            icon = "arrow.triangle.pull"
        } else if labelText.contains("Take exit") || labelText.contains("Take the exit") {
            icon = "arrow.triangle.pull"
        }
        
        
        
    }
}

extension CLLocationCoordinate2D {
    static let parking = CLLocationCoordinate2D(
        latitude: 40.8898, longitude: -74.5292
    )
}



//https://www.youtube.com/watch?v=hWMkimzIQoU
//ATTEMPT TO GET LOCATION INFORMATION
final class ContentViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
//    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.331516, longitude: -121.89105), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    
    var locationManager: CLLocationManager?
    //var userLocation: CLLocation?

    
    func checkIfLocationsServicesIsEnabled () {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager!.delegate = self
            checkLocationAuthorization()
            
            
            
        } else {
            print("Show an alert letting them know this is off and to go turn it on.")
        }
        
        // Request location authorization asynchronously
        DispatchQueue.main.async {
            self.locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    private func checkLocationAuthorization() {
        guard let locationManager = locationManager else {return}
        
        switch locationManager.authorizationStatus {
            
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                print("Your location is restricted likely due to parental controls.")
            case .denied:
                print("You have denied this app location permission. Go into settings to change it")
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager.startUpdatingLocation()
//                region = MKCoordinateRegion(center: locationManager.location!.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                break
            
            @unknown default:
                break
            
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.checkLocationAuthorization()
        }
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            userLocation = location
            
            NotificationCenter.default.post(name: .didUpdateLocation, object: nil)
        }
        
        // Create MKPlacemark using the user's current location
        // Create MKPlacemark using the user's current location
        globalVariable = MKPlacemark(coordinate: location.coordinate)
        // Use the map item as needed
        // For example, assign it to a variable or use it in navigation
        // request.source = mapItem
    }
}

extension Notification.Name {
    static let didUpdateLocation = Notification.Name("didUpdateLocation")
}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
    
}
