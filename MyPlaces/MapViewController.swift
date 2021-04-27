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
    let annotationIdentifier = "annotationIdentifier"

    @IBOutlet var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
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

extension MapViewController: MKMapViewDelegate {
    
    // метод отображения аннотации
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        // если маркер на карте — текущая геопозиция пользователя, то ничего не создаем
        guard !(annotation is MKUserLocation) else { return nil }
        
        // для работы с новой аннотацией берем и используем ранее созданную аннотацию
        // для отображения булавки, приводим объект к типу MKPinAnnotationView
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView
        
        // если аннотацию не удалось найти (не удалось отобразить), то инициализируем ее
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            // включаем дополнительное отображение информации
            annotationView?.canShowCallout = true
        }
        
        // отобразим изображение объекта в аннотации
        if let imageData = place.imageData {
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 8
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            
            // добавляем изображение в правую область аннотации
            annotationView?.rightCalloutAccessoryView = imageView
        }

        return annotationView
    }
}
