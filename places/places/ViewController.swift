//
//  ViewController.swift
//  places
//
//  Created by WSR on 6/23/19.
//  Copyright © 2019 WSR. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class Artwork: NSObject, MKAnnotation {
    let title: String?
    let locationName: String
    let discipline: String
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.locationName = locationName
        self.discipline = discipline
        self.coordinate = coordinate
        
        super.init()
    }
    
    var subtitle: String? {
        return locationName
    }
}

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.delegate = self
            let location = mapView.userLocation
            location.title = "Я здесь"
        } else {
            locationManager.requestAlwaysAuthorization()
        }

        
        
        let location = CLLocationCoordinate2D(latitude: 51.50007773,
                                              longitude: -0.1246402)
        
        // 2
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        
        //3
        let annotation = Artwork(title: "Big Ben",
                                 locationName: "Главная достопримечательность Лондона",
                                 discipline: "Building",
                                 coordinate: location)
        
        mapView.addAnnotation(annotation)
    }

    internal func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        // проверяю, является ли метка экземпляром класса Artwork
        guard let annotation = annotation as? Artwork else { return nil }
        
        let identifier = "marker"
        var view: MKMarkerAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKMarkerAnnotationView {
            // сюда не заходит
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            // 5
//            view = MKMarkerAnnotationView(frame: CGRect(origin: CGPoint.zero,
//                                                        size: CGSize(width: 400, height: 300)))
//            view.annotation = annotation
//            view.canShowCallout = true
//            view.calloutOffset = CGPoint(x: -5, y: 5)
//
//
//            let mapsButton = UIButton(frame: CGRect(origin: CGPoint.zero,
//                                                    size: CGSize(width: 200, height: 200)))
//
//            mapsButton.setBackgroundImage(UIImage(named: "bigban"), for: UIControl.State())
//            view.rightCalloutAccessoryView = mapsButton
//
//
//            let detailLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 400))
//            detailLabel.numberOfLines = 0
//            detailLabel.font = detailLabel.font.withSize(12)
//            detailLabel.text = annotation.subtitle! + "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
//            view.detailCalloutAccessoryView = detailLabel
        
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "marker")
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -150, y: 5)
            
            let xib = Bundle.main.loadNibNamed("AnnotationView", owner: self, options: nil)?.first as! AnnotationView
            xib.imageView.image = UIImage(named: "bigban")
            xib.title.text = annotation.title!
            
            //view.addSubview(xib)
            view.detailCalloutAccessoryView = xib
            
            view.glyphText = "🚗"
            view.markerTintColor = .blue
        }
        return view
        
    }
}

