//
//  MapViewController.swift
//  MyPlaces
//
//  Created by ruslan on 25.04.2021.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    var place: Place!

    @IBOutlet var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPlacemark()
    }
    
    @IBAction func closeVC(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    private func setupPlacemark() {
        
        guard let location = place.location else { return }
        
        // создаем объект для работы с картой
        let geocoder = CLGeocoder()
        
        // данный метод позволяет получить координаты по названию, координаты записываются в placemarks, их может быть много
        // error — это ошибки, если не удалось получить координаты
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            
            // если получаем ошибку, то выводим в консоль и выходим из метода
            if let error = error {
                print(error)
                return
            }
            
            // если выходит получить массив меток, то идем дальше
            guard let placemarks = placemarks else { return }
            
            // берем только первую метку (первые координаты) места
            let placemark = placemarks.first
            
            // создаем аннотацию для метки
            let annotation = MKPointAnnotation()
            annotation.title = self.place.name
            annotation.subtitle = self.place.type
            
            // добавляем аннотацию к метке
            
            // если получается определить место, то присваиваем аннотацию места к аннотации метки
            guard let placemarkAnnotation = placemark?.location else { return }
            annotation.coordinate = placemarkAnnotation.coordinate
            // задаем видимую область карты таким образом, чтобы были видны все аннотации
            self.mapView.showAnnotations([annotation], animated: true)
            // и выделяем метку на карте
            self.mapView.selectAnnotation(annotation, animated: true)
        }
    }
}
