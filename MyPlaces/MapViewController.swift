//
//  MapViewController.swift
//  MyPlaces
//
//  Created by ruslan on 25.04.2021.
//

import UIKit
import MapKit
import CoreLocation

// для передачи адреса в другой вьюконтроллер
protocol MapViewControllerDelegate {
    func getAddress(_ address: String?)
}

class MapViewController: UIViewController {
    
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()
    let annotationIdentifier = "annotationIdentifier"
    let locationManager = CLLocationManager()
    let regionInMeters = 10_00.00
    var incomeSegueIdentifier = ""
    var placeCoordinate: CLLocationCoordinate2D?

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var mapPinImage: UIImageView!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var goButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addressLabel.text = ""
        mapView.delegate = self
        setupMapView()
        checkLocationServices()
    }
    
    @IBAction func centerViewInUserLocation() {
        showUserLocation()
    }
    
    @IBAction func closeVC(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func doneButtonPressed() {
        mapViewControllerDelegate?.getAddress(addressLabel.text)
        dismiss(animated: true)
    }
    
    @IBAction func goButtonPressed() {
        getDirections()
    }
    
    // MARK: - ПРОСМОТР МЕСТА НА КАРТЕ
    
    private func setupMapView() {
        
        goButton.isHidden = true
        
        if incomeSegueIdentifier == "showPlace" {
            setupPlacemark()
            mapPinImage.isHidden = true
            addressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
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
            self.placeCoordinate = placemarkAnnotation.coordinate
            // задаем видимую область карты таким образом, чтобы были видны все аннотации
            self.mapView.showAnnotations([annotation], animated: true)
            // и выделяем метку на карте
            self.mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    // MARK: - ПРОВЕРКА СЛУЖБ ГЕОЛОКАЦИИ
    
    // включены ли сервисы геолокации
    private func checkLocationServices() {
        
        // если включены, то отображаем геопозицию, если нет, то просим включить
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            // делаем отсрочку на 1 сек
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.requestToEnableLocationServices(title: "На вашем устройстве отключены службы геолокации!",
                                                    message: "Перейдите в Настройки - Приватность - Службы геолокации")
            }
        }
    }
    
    // настраиваем точность отображения геопозиции и делегируем полномочия
    private func setupLocationManager() {
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // запрос на включение служб геолокации
    private func requestToEnableLocationServices(title: String, message: String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        let goToSettingsAction = UIAlertAction(title: "Перейти", style: .default) { _ in
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(goToSettingsAction)
        present(alertController, animated: true)
    }
    
    // проверяем состояние сервиса геолокации и выполняем для каждого соответствующие действия
    private func checkLocationAuthorization() {
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if incomeSegueIdentifier == "getAddress" { showUserLocation() }
            break
        case .denied:
            if CLLocationManager.locationServicesEnabled() {
                requestToEnableLocationServices(title: "Для данного приложения отключены службы геолокации!",
                                               message: "Перейдите в Настройки - Приватность - Службы геолокации - MyPlaces")
            } else {
                requestToEnableLocationServices(title: "Отключены службы геолокации!",
                                               message: "Перейдите в Настройки - Приватность - Службы геолокации")
            }
            break
        case .notDetermined:
            // запрашиваем разрешение на включение сервиса геолокации
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            requestToEnableLocationServices(title: "Отключены службы геолокации!",
                                           message: "Перейдите в Настройки - Приватность - Службы геолокации")
            break
        case .authorizedAlways:
            break
        // для новых сосотоянии в будущих обновлениях
        @unknown default:
            print("New case is available")
        }
    }
    
    // MARK: - РАБОТА С КООРДИНАТАМИ
    
    // отображение текущего местоположения
    private func showUserLocation() {
        
        if let location = locationManager.location?.coordinate {
            
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    // получаем координаты центральной точки карты
    private func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // MARK: - РАБОТАМ С МАРШРУТОМ
    
    // метод для построения маршрута
    private func getDirections() {
        
        // проверяем, что можем получить координаты текущего местоположения
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Ошибка!", message: "Текущее местоположение не распознано")
            return
        }
        
        // проверяем, что можем получить координаты места назначения
        guard let request = createDirectionsRequest(from: location) else {
            showAlert(title: "Ошибка!", message: "Не удалось найти место назначения")
            return
        }
        
        // создаем маршруты
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let response = response else {
                self.showAlert(title: "Ошибка!", message: "Маршрут недоступен")
                return
            }
            
            // перебираем все доступные маршруты
            for route in response.routes {
                
                // добавляем подробную геометрию
                self.mapView.addOverlay(route.polyline)
                
                // фокусируем карту на всех маршрутах
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                // другая информация
                let distance = String(format: "%.1f", route.distance / 1000)
                let timeInterval = round(route.expectedTravelTime / 60)
                
                print("Расстояние составляет \(distance) км")
                print("Время в пути равно \(timeInterval) мин")
            }
        }
    }
    
    // запрос на построение маршрута
    private func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        
        guard let destinationCoordinte = placeCoordinate else { return nil }
        
        // задаем начальную точку маршрута
        let startingLocation = MKPlacemark(coordinate: coordinate)
        
        // задаем конечную точку маршрута
        let destination = MKPlacemark(coordinate: destinationCoordinte)
        
        // запрашиваем построение маршрута
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    // алерт контроллер
    private func showAlert(title: String, message: String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Ок", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
}

// MARK: - РАСШИРЕНИЯ


extension MapViewController: MKMapViewDelegate {
    
    // MARK: - ИЗМЕНЕНИЕ АННОТАЦИИ
    
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
    
    // MARK: - ПОЛУЧЕНИЕ АДРЕСА С КАРТЫ
    
    // при изменении позиции получаем название адреса
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let center = getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        // по координатам получаем название адреса
        geocoder.reverseGeocodeLocation(center) { (placemarks, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first
            let streetName = placemark?.thoroughfare
            let buildNumber = placemark?.subThoroughfare
            
            DispatchQueue.main.async {
                if streetName != nil && buildNumber != nil {
                    self.addressLabel.text = "\(streetName!), \(buildNumber!)"
                } else if streetName != nil {
                    self.addressLabel.text = "\(streetName!)"
                } else {
                    self.addressLabel.text = ""
                }
            }
        }
    }
    
    // MARK: - ОТОБРАЖЕНИЕ МАРШРУТА
    
    // рендеринг маршрута
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .green
        
        return renderer
    }
}

// MARK: - КОНТРОЛЬ ИЗМЕНЕНИЯ СЛУЖБ ГЕОЛОКАЦИИ

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationServices()
    }
}
