//
//  WalkingViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/19.
//
import UIKit
import MapKit
import CoreLocation

class WalkingViewController: UIViewController {
    var locationManager: CLLocationManager?
    var initialLocation: CLLocationCoordinate2D?
    var startLocation: CLLocation?
    var totalDistance: CLLocationDistance = 0.0
    var pathPoints: [CLLocationCoordinate2D] = []
    var isFirstLoad = true

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var distanceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager?.distanceFilter = 10
        self.locationManager?.requestWhenInUseAuthorization()
        self.locationManager?.startUpdatingLocation()
        
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.userTrackingMode = .follow
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? WalkDoneViewController {
            destination.distance = String(format: "%.2f", self.totalDistance)
        }
    }
    
    @IBAction func walkDone(_ sender: Any) {
        self.performSegue(withIdentifier: "WalkDone", sender: self)
    }
}

extension WalkingViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        let newCoordinate = location.coordinate
        
        if self.initialLocation == nil {
            self.initialLocation = newCoordinate
        }
        
        if self.startLocation == nil {
            self.startLocation = location
        } else {
            let distance = location.distance(from: self.startLocation!)
            self.totalDistance += distance
            self.startLocation = location
            
            self.distanceLabel.text = "目前行徑長度：\(String(format: "%.2f", self.totalDistance)) 公尺"
        }
        
        self.pathPoints.append(newCoordinate)
        
        self.updateMap()
    }
    
    private func updateMap() {
        self.mapView.removeOverlays(self.mapView.overlays)
        
        let polyline = MKPolyline(coordinates: self.pathPoints, count: self.pathPoints.count)
        self.mapView.addOverlay(polyline)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let region = MKCoordinateRegion(center: self.pathPoints.last!, span: span)
        
        self.mapView.setRegion(region, animated: true)
    }
}

extension WalkingViewController: MKMapViewDelegate {
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        guard let initialLocation = self.initialLocation else {
            return
        }
        
        if self.isFirstLoad {
            let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            let region = MKCoordinateRegion(center: initialLocation, span: span)
            
            mapView.setRegion(region, animated: false)
            
            self.isFirstLoad = false
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.red
            renderer.lineWidth = 3
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
}
