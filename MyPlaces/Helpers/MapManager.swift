//
//  MapManager.swift
//  MyPlaces
//
//  Created by ruslan on 03.05.2021.
//

import UIKit
import MapKit

class MapManager {
    
    let locationManager = CLLocationManager()
    
    private let regionInMeters = 1000.00
    private var placeCoordinate: CLLocationCoordinate2D?
    private var directionsArray: [MKDirections] = []
    
    // MARK: - ПРОСМОТР МЕСТА НА КАРТЕ
    
    func setupPlacemark(place: Place, mapView: MKMapView) {
        
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
            annotation.title = place.name
            annotation.subtitle = place.type
            
            // добавляем аннотацию к метке
            
            // если получается определить место, то присваиваем аннотацию места к аннотации метки
            guard let placemarkAnnotation = placemark?.location else { return }
            annotation.coordinate = placemarkAnnotation.coordinate
            self.placeCoordinate = placemarkAnnotation.coordinate
            // задаем видимую область карты таким образом, чтобы были видны все аннотации
            mapView.showAnnotations([annotation], animated: true)
            // и выделяем метку на карте
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    // перед отрисовкой новых маршрутов, удаляем прежние
    func resetMapView(withNew directions: MKDirections, mapView: MKMapView) {
        
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        // отменяем каждый маршрут в массиве
        let _ = directionsArray.map { $0.cancel() }
        // удаляем все элементы массива
        directionsArray.removeAll()
    }
    
    // MARK: - ПРОВЕРКА СЛУЖБ ГЕОЛОКАЦИИ
    
    // включены ли сервисы геолокации
    func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: () -> ()) {
        
        // если включены, то отображаем геопозицию, если нет, то просим включить
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationAuthorization(mapView: mapView, segueIdentifier: segueIdentifier)
            closure()
        } else {
            // делаем отсрочку на 1 сек
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.requestToEnableLocationServices(title: "На вашем устройстве отключены службы геолокации!",
                                                    message: "Перейдите в Настройки - Приватность - Службы геолокации")
            }
        }
    }
    
    // проверяем состояние сервиса геолокации и выполняем для каждого соответствующие действия
    func checkLocationAuthorization(mapView: MKMapView, segueIdentifier: String) {
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if segueIdentifier == "getAddress" { showUserLocation(mapView: mapView) }
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
    
    // запрос на включение служб геолокации
    func requestToEnableLocationServices(title: String, message: String) {
        
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
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alertController, animated: true)
    }
    
    // MARK: - РАБОТА С КООРДИНАТАМИ
    
    // отображение текущего местоположения
    func showUserLocation(mapView: MKMapView) {
        
        if let location = locationManager.location?.coordinate {
            
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    // получаем координаты центральной точки карты
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // отслеживание текущего местоположения
    func startTrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation: CLLocation) -> ()) {
        
        guard let location = location else { return }
        let center = getCenterLocation(for: mapView)
        
        // если расстояние от предыдушего места до текущего больше 50 м
        guard center.distance(from: location) > 50 else { return }
        // то обновляем предыдущее место (передаем через клоужер)
        closure(center)
    }
    
    // MARK: - РАБОТАМ С МАРШРУТОМ
    
    // метод для построения маршрута
    func getDirections(for mapView: MKMapView, previousLocation: (CLLocation) -> ()) {
        
        // проверяем, что можем получить координаты текущего местоположения
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Ошибка!", message: "Текущее местоположение не распознано")
            return
        }
        
        locationManager.startUpdatingLocation()
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
        
        // проверяем, что можем получить координаты места назначения
        guard let request = createDirectionsRequest(from: location) else {
            showAlert(title: "Ошибка!", message: "Не удалось найти место назначения")
            return
        }
        
        // создаем маршруты
        let directions = MKDirections(request: request)
        // перед отрисовкой новых маршрутов, удаляем прежние
        resetMapView(withNew: directions, mapView: mapView)
        
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
                mapView.addOverlay(route.polyline)
                
                // фокусируем карту на всех маршрутах
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                // другая информация
                let distance = String(format: "%.1f", route.distance / 1000)
                let timeInterval = round(route.expectedTravelTime / 60)
                
                print("Расстояние составляет \(distance) км")
                print("Время в пути равно \(timeInterval) мин")
            }
        }
    }
    
    // запрос на построение маршрута
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        
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
    func showAlert(title: String, message: String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Ок", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alertController, animated: true)
    }
}
