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
import Alamofire
import SwiftyJSON

/*

Сразу отмечу, что делал не по тексту лекции, а по этому туториалу: 
https://www.raywenderlich.com/548-mapkit-tutorial-getting-started

*/

// описываю структуру для хранения данных одной достопримечательности
struct place {
    var title: String
    var desc: String
    var coord: CLLocationCoordinate2D
    var imgName: String
}

// класс, потомок MKAnnotation, практически цельнотянут из туториала, только убрал одно поле
class Artwork: NSObject, MKAnnotation {
    let title: String?
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let imgName: String
    
    // конструтор (описывает какие параметры нужны классу при создании)
    init(title: String, locationName: String, coordinate: CLLocationCoordinate2D, imgName: String) {
        self.title = title
        self.locationName = locationName
        self.coordinate = coordinate
        self.imgName = imgName
        
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
        
        // назначаем свой класс, как обработчик событий карты 
        // (для этого наш класс должен наследоваться от MKMapViewDelegate)
        mapView.delegate = self

        // разрешаем показывать позицию пользователя на карте
        mapView.showsUserLocation = true
        
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            // аналогично назначаем свой класс обработчиком событий локатора (CLLocationManagerDelegate)
            locationManager.delegate = self
            let location = mapView.userLocation
            location.title = "Я здесь"
            
            // загружаем список достопримечательностей с сервера
            loadArts()
        } else {
            locationManager.requestAlwaysAuthorization()
        }
    }

    // при включении CLLocationManager перехватываем управление и запрашиваем текущую позицию
    override func viewWillAppear(_ animated: Bool) {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
     }

    // регион для отображения задаем при обновлении текущей локации
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        let radius = CLLocationDistance(10000)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude), latitudinalMeters: radius, longitudinalMeters: radius)
        self.mapView.setRegion(region, animated: false)
    }

    //грузим достопримечательности с сервера
    func loadArts(){
        let url = "http://cars.areas.su/arts"
        // посылаем запрос
        Alamofire.request(url).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                //если запрос выполнен успешно, то разбираем ответ и вытаскиваем нужные данные
                let json = JSON(value)
                
                for item in json.arrayValue {
                    let aw = Artwork(title: item["title"].stringValue,
                                     locationName: item["subTitle"].stringValue,
                                     coordinate: CLLocationCoordinate2D(latitude: item["lat"].doubleValue, longitude: item["long"].doubleValue),
                                     imgName: item["image"].stringValue)
                    
                    self.mapView.addAnnotation( aw )
                }
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // функция вызывается для каждой показываемой точки
    internal func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        // проверяю, является ли метка экземпляром класса Artwork (т.е. метка с текущей позицией вылетит без обработки)
        guard let annotation = annotation as? Artwork else { return nil }
        
        let identifier = "marker"
        var view: MKMarkerAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKMarkerAnnotationView {
            // сюда не заходит
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            // Создаю метку геолокации
            // я использую класс MKMarkerAnnotationView, т.к. он по клику на метке может разворачивать
            // дополнительную информацию
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)

            // переопределяю символ и цвет фона геометки (можно поменять и форму геометки - в туториале это есть)
            view.glyphText = "🚗"
            view.markerTintColor = .blue

            // разрешаем показ дополнительной информации
            view.canShowCallout = true
            view.isDraggable = true
            view.calloutOffset = CGPoint(x: -5, y: 5)

            // класс MKMarkerAnnotationView поддерживает отображение 3-х блоков: 
            // leftCalloutAccessoryView, detailCalloutAccessoryView, rightCalloutAccessoryView 

            // в правом блоке я вывожу изображение достопримечательности 
            // (тут опять же нужно бы грузить изображение с сервера, пока берется одно, вложенное в проект)
            let mapsButton = UIButton(  frame: CGRect(origin: CGPoint.zero,
                                        size: CGSize(width: 200, height: 200)))
            
            // в имени картинки могут быть русские буквы - перекодируем
            let urlStr = annotation.imgName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            
            if let url = URL(string: urlStr!) {
                if let data = try? Data(contentsOf: url){
                    mapsButton.setBackgroundImage( UIImage(data: data), for: UIControl.State())
                }
            }
            
            // добавляем событие для нашей кнопки - вернулся к классическому варианту
            //mapsButton.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)

            
            view.rightCalloutAccessoryView = mapsButton

            // по идее класс MKMarkerAnnotationView отображает title и subtite из нашей метки
            // но при этом обрезает окно дополнительной информации по содержимому
            // и если описание короткое, то изображение, которое мы добавили выше, обрезается

            // чтобы этого избежать, создается новый Label
            let detailLabel = UILabel()
            detailLabel.numberOfLines = 0
            detailLabel.font = detailLabel.font.withSize(12)
            detailLabel.text = annotation.subtitle

            // и в нем жестко прописывается минимальный размер по высоте картинки
            detailLabel.heightAnchor.constraint(equalToConstant: 200).isActive = true
            
            // созданный Label прописывается как центральный блок нашей метки 
            view.detailCalloutAccessoryView = detailLabel
        }
        return view
        
    }
    
    // обработка события клика по детальной информации - строим маршрут от пользователя к выбранной точке
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        let location = view.annotation as! Artwork
        
        
        //очищаю старые пути
        self.mapView.removeOverlays(self.mapView.overlays)
        
        let srcCoord = mapView.userLocation.coordinate,
            targetCoord = location.coordinate
        
        let src = MKPlacemark(coordinate: srcCoord),
            target = MKPlacemark(coordinate: targetCoord)
        
        let req = MKDirections.Request()
        
        req.source = MKMapItem(placemark: src)
        req.destination = MKMapItem(placemark: target)
        req.transportType = .walking
        
        let direction = MKDirections(request: req)
        
        direction.calculate{
            (response, error) in
            guard let directionResonse = response else {
                if let error = error {
                    print("we have error getting directions==\(error.localizedDescription)")
                }
                return
            }
            
            let route = directionResonse.routes[0]
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
//    // событие возникает при клике на картинку в детальном описании геометки - убрал
//    @objc func buttonClicked(_ sender: UIButton) {
//
//    }
    
    // срабатывает при добавлении оверлея
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay)
        render.strokeColor = UIColor.blue
        render.lineWidth = 4.0
        return render
        
    }
    
    // этой функцией можно получить событие клика по геометке
    // но так как по клику у нас показывается доп. информация, то используется другой метод
//    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//        print(view.annotation?.title!! ?? "unknown")
//    }
}


