//
//  MapCoordinator.swift
//  ParkRadar
//
//  Created by marty.academy on 3/26/25.
//

import MapKit

class MapCoordinator: NSObject, MKMapViewDelegate {
    
    private let zoneRadius: CLLocationDistance = 100 // meters
    
    func setupAnnotations(on mapView: MKMapView) {
        let points: [(lat: Double, lng: Double, title: String, subtitle: String, isDanger: Bool)] = [
            (37.5133, 127.0587, "초안산공원", "주차장 구역", false),
            (37.5142, 127.0611, "강남한신병원", "불법주정차 감시구역", true),
            (37.5150, 127.0599, "강남파출소", "불법주정차 감시구역", true)
        ]
        
        for point in points {
            let coordinate = CLLocationCoordinate2D(latitude: point.lat, longitude: point.lng)
            
            // Annotation
            let annotation = ParkingAnnotation(coordinate: coordinate,
                                               title: point.title,
                                               subtitle: point.subtitle)
            mapView.addAnnotation(annotation)
            
            // Overlay (zone)
            let circle = MKCircle(center: coordinate, radius: zoneRadius)
            mapView.addOverlay(circle)
        }
    }
    
    // MARK: - Annotation View
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKClusterAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: CircleClusterView.reuseIdentifier)
            ?? CircleClusterView(annotation: annotation, reuseIdentifier: CircleClusterView.reuseIdentifier)
            view.annotation = annotation
            return view
        }
        
        // 개별 annotation 처리
        return nil
    }
    
    
    //    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    //        guard !(annotation is MKUserLocation) else { return nil }
    //
    //        let identifier = "clusterAnnotation"
    //        var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
    //
    //        if view == nil {
    //            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
    //            view?.canShowCallout = true
    //            view?.clusteringIdentifier = "zone"
    //            view?.markerTintColor = .systemGreen
    //            view?.glyphText = "P"
    //        } else {
    //            view?.annotation = annotation
    //        }
    //        return view
    //    }
    
    // MARK: - Overlay View
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circle = overlay as? MKCircle {
            //            let renderer = MKCircleRenderer(circle: circle)
            //            renderer.fillColor = UIColor.red.withAlphaComponent(0.2)
            //            renderer.strokeColor = UIColor.red
            //            renderer.lineWidth = 1
            
            let renderer = BlinkingCircleRenderer(circle: circle)
            return renderer
        }
        return MKOverlayRenderer()
    }
}

