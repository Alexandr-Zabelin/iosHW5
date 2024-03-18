//
//  ViewController.swift
//  MapKitApp
//  Created by Студент on 29.11.2023.
//
import UIKit
import CoreLocation
import MapKit
// in info.plist:
// NSLocationWhenInUseUsageDescription
// Privacy - Location When In Use Usage Description
// or
// NSLocationAlwaysUsageDescription

class MapVC: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, MKMapViewDelegate
{
    let locationManager = CLLocationManager()
    var coordinatesArray = [CLLocationCoordinate2D]()
    var annotationsArray = [MKAnnotation]()
    var overlaysArray = [MKOverlay]()
    
    let mapView: MKMapView = {
        let control = MKMapView()
        control.layer.cornerRadius = 15
        control.layer.masksToBounds = true
        control.clipsToBounds = false
        control.translatesAutoresizingMaskIntoConstraints = false
        control.showsScale = true
        control.showsCompass = true
        control.showsTraffic = true
        control.showsBuildings = true
        control.showsUserLocation = true
        return control
    }()
    
    
    let startLocation: UITextField = {
        let control = UITextField()
        control.backgroundColor = UIColor.gray
        control.textColor = UIColor.white
        control.placeholder = "From"
        control.layer.cornerRadius = 2
        control.clipsToBounds = false
        control.translatesAutoresizingMaskIntoConstraints = false
        control.font = UIFont.systemFont(ofSize: 15)
        control.borderStyle = UITextField.BorderStyle.roundedRect
        control.autocorrectionType = UITextAutocorrectionType.yes
        control.keyboardType = UIKeyboardType.default
        control.returnKeyType = UIReturnKeyType.go
        control.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        return control
    }()
    
    let intermediateLocation: UITextField = {
        let control = UITextField()
        control.backgroundColor = UIColor.gray
        control.textColor = UIColor.white
        control.placeholder = "Intermediate"
        control.layer.cornerRadius = 2
        control.clipsToBounds = false
        control.translatesAutoresizingMaskIntoConstraints = false
        control.font = UIFont.systemFont(ofSize: 15)
        control.borderStyle = UITextField.BorderStyle.roundedRect
        control.autocorrectionType = UITextAutocorrectionType.yes
        control.keyboardType = UIKeyboardType.default
        control.returnKeyType = UIReturnKeyType.go
        control.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        return control
    }()
    
    let finishLocation: UITextField = {
        let control = UITextField()
        control.backgroundColor = UIColor.gray
        control.textColor = UIColor.white
        control.placeholder = "To"
        control.layer.cornerRadius = 2
        control.clipsToBounds = false
        control.translatesAutoresizingMaskIntoConstraints = false
        control.font = UIFont.systemFont(ofSize: 15)
        control.borderStyle = UITextField.BorderStyle.roundedRect
        control.autocorrectionType = UITextAutocorrectionType.yes
        control.keyboardType = UIKeyboardType.default
        control.returnKeyType = UIReturnKeyType.go
        control.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        return control
    }()
    
    
    let goButton: UIButton = {
        let control = UIButton()
        control.addTarget(self, action: #selector(getYourRoute), for: .touchUpInside)
        control.setTitle("Go!", for: .normal)
        control.backgroundColor = UIColor.blue
        control.titleLabel?.textColor = UIColor.white
        control.layer.cornerRadius = 4
        control.clipsToBounds = false
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    let clearFormsButton: UIButton = {
        let button = UIButton()
        button.setTitle("Clear", for: .normal)
        button.backgroundColor = UIColor.gray
        button.titleLabel?.textColor = UIColor.white
        button.layer.cornerRadius = 4
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(clearMap), for: .touchUpInside)
        return button
    }()
    
    @objc func clearMap() {
        coordinatesArray.removeAll()
        annotationsArray.removeAll()
        overlaysArray.removeAll()
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        startLocation.text = ""
        intermediateLocation.text = ""
        finishLocation.text = ""
        
        if let userLocation = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: userLocation, latitudinalMeters: 0, longitudinalMeters: 0)
            
            mapView.setRegion(region, animated: true)
        }
    }
    
    
    @objc
    func getYourRoute(_ sender: UIButton) {
        self.view.endEditing(true)
        
        if self.mapView.annotations.count > 0 {
            self.mapView.removeAnnotations(self.annotationsArray)
            self.annotationsArray = []
        }
        
        if self.overlaysArray.count > 0 {
            self.mapView.removeOverlays(self.overlaysArray)
            self.overlaysArray = []
        }
        
        self.coordinatesArray = []
        
        guard let startText = self.startLocation.text, !startText.isEmpty,
              let finishText = self.finishLocation.text, !finishText.isEmpty else {
            return
        }
        
        if startText.count == 0 {
            if let sourceCoordinate = locationManager.location?.coordinate {
                self.coordinatesArray.append(sourceCoordinate)
                processIntermediatePoint()
            }
        } else {
            self.findLocation(location: startText, showRegion: false) {
                self.processIntermediatePoint()
            }
        }
    }
    
    private func processIntermediatePoint() {
        if let intermediateText = self.intermediateLocation.text, !intermediateText.isEmpty {
            self.findLocation(location: intermediateText, showRegion: false) {
                self.processFinishPoint()
            }
        } else {
            self.processFinishPoint()
        }
    }
    
    private func processFinishPoint() {
        if let finishText = self.finishLocation.text, !finishText.isEmpty {
            self.findLocation(location: finishText, showRegion: true) {
                self.findLocations()
            }
        }
    }
    
    private func findLocation(location: String, showRegion: Bool = false, completion: @escaping () -> Void ) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            if let placemark = placemarks?.first {
                let coordinates = placemark.location!.coordinate
                self.coordinatesArray.append(coordinates)
                
                let customAnnotation = CustomMapPoint(coordinate: coordinates, title: location, subtitle: "")
                
                if let country = placemark.country {
                    customAnnotation.subtitle = country
                }
                
                self.mapView.addAnnotation(customAnnotation)
                self.annotationsArray.append(customAnnotation)
                
                if showRegion {
                    self.mapView.centerCoordinate = coordinates
                    let span = MKCoordinateSpan(latitudeDelta: 0.9, longitudeDelta: 0.9)
                    let region = MKCoordinateRegion(center: coordinates, span: span)
                    self.mapView.setRegion(region, animated: showRegion)
                }
            } else {
                print(String(describing: error))
            }
            completion()
        }
    }
    
    
    private func showCurrent(coordinates: CLLocationCoordinate2D, showRegion: Bool = false, completion: @escaping () -> Void ) {
        
        self.coordinatesArray.append(coordinates)
        let point = MKPointAnnotation(__coordinate: coordinates, title: "", subtitle: "")
        
        self.mapView.addAnnotation(point)
        self.annotationsArray.append(point)
        
        if showRegion {
            self.mapView.centerCoordinate = coordinates
            let span = MKCoordinateSpan(latitudeDelta: 0.9, longitudeDelta: 0.9)
            let region = MKCoordinateRegion(center: coordinates, span: span)
            self.mapView.setRegion(region, animated: showRegion)
        }
        completion()
    }
    
    
    private func doAfterOne() {
        let completion2 = findLocations
        DispatchQueue.global(qos: .utility).async {
            self.findLocation(location: self.finishLocation.text!, showRegion: true, completion: completion2)
        }
    }
    
    
    private func findLocations() {
        guard self.coordinatesArray.count >= 2 else {
            return
        }
        
        var previousCoordinate = self.coordinatesArray.first!
        let group = DispatchGroup()
        
        for index in 1..<self.coordinatesArray.count {
            let coordinate = self.coordinatesArray[index]
            let markLocationOne = MKPlacemark(coordinate: previousCoordinate)
            let markLocationTwo = MKPlacemark(coordinate: coordinate)
            let directionRequest = MKDirections.Request()
            
            directionRequest.source = MKMapItem(placemark: markLocationOne)
            directionRequest.destination = MKMapItem(placemark: markLocationTwo)
            directionRequest.transportType = .automobile
            
            let directions = MKDirections(request: directionRequest)
            
            group.enter()
            directions.calculate { response, error in
                defer { group.leave() }
                if let route = response?.routes.first {
                    self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                    self.overlaysArray.append(route.polyline)
                    let rect = route.polyline.boundingMapRect
                    self.mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: true)
                }
            }
            previousCoordinate = coordinate
        }
        
        group.notify(queue: .main) {}
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        startMap()
    }
    
    
    private func startMap() {
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0] as CLLocation
        manager.stopUpdatingLocation()
        
        let location = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    
    private func setupUI() {
        startLocation.delegate = self
        finishLocation.delegate = self
        locationManager.delegate = self
        mapView.delegate = self
        
        self.view.addSubview(startLocation)
        self.view.addSubview(finishLocation)
        self.view.addSubview(goButton)
        self.view.addSubview(mapView)
        self.view.addSubview(intermediateLocation)
        self.view.addSubview(clearFormsButton)
        
        locationManager.startUpdatingLocation()
        
        goButton.pinRight(to: view)
        goButton.pinTop(to: view, 50)
        goButton.setHeight(39)
        goButton.setWidth(78)
        
        startLocation.pinLeft(to: view)
        startLocation.pinTop(to: view, 50)
        startLocation.pinRight(to: goButton, 88)
        startLocation.setHeight(33)
        
        finishLocation.pinLeft(to: view)
        finishLocation.pinTop(to: startLocation.bottomAnchor,  43)
        finishLocation.pinRight(to: goButton, 88)
        finishLocation.setHeight(33)
        
        mapView.pinLeft(to: view)
        mapView.pinTop(to: finishLocation, 45)
        mapView.pinRight(to: view)
        mapView.pinBottom(to: view)
        
        clearFormsButton.pinTop(to: goButton.bottomAnchor, 5)
        clearFormsButton.pinRight(to: view)
        clearFormsButton.setWidth(78)
        clearFormsButton.setHeight(39)
        
        intermediateLocation.pinTop(to: startLocation.bottomAnchor, 5)
        intermediateLocation.pinRight(to: goButton, 88)
        intermediateLocation.setHeight(33)
        intermediateLocation.pinLeft(to: view)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        if overlay is MKPolyline {
            polylineRenderer.strokeColor = UIColor.green
            polylineRenderer.lineWidth = 4
        }
        return polylineRenderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "customAnnotationView"
        
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if view == nil {
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            view?.canShowCallout = true
            
            if let pinImage = UIImage(systemName: "person.circle") {
                
                let resizedImage = resizeImage(image: pinImage, targetSize: CGSize(width: 30, height: 30))
                view?.image = resizedImage
            }
        } else {
            view?.annotation = annotation
        }
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        UIView.animate(withDuration: 0.3) {
            view.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        UIView.animate(withDuration: 0.3) {
            view.transform = CGAffineTransform.identity
        }
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        var newSize: CGSize
        
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
}
