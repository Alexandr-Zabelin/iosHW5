//
//  CustomMapPoint.swift
//  MapKitApp
//
//  Created by Забелин Александр Сергеевич on 18.03.2024.
//

import Foundation
import MapKit

class CustomMapPoint: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?

    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}
