//
//  ParkedLocationWidgetView.swift
//  ParkRadarWidgetExtension
//
//  Created by marty.academy on 4/22/25.
//

import SwiftUI
import MapKit
import WidgetKit

struct ParkedLocationWidgetView: View {
    let entry: ParkedLocationEntry

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text(entry.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                Spacer()
                
                if entry.hasParkedLocation && (!entry.address.isEmpty || !entry.timeElapsedText.isEmpty) {
                    VStack(spacing: 4) {
                        if !entry.address.isEmpty {
                            HStack {
                                Text(entry.address)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                        
                        if !entry.timeElapsedText.isEmpty {
                            HStack {
                                Spacer()
                                Text(entry.timeElapsedText)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "car.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("주차 위치를 저장하지 않았습니다.")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

class MapSnapshotHelper {
    
    static func generateMapSnapshot(
           coordinate: CLLocationCoordinate2D,
           family: WidgetFamily = .systemMedium,
           completion: @escaping (UIImage?) -> Void
       ) {
           let options = MKMapSnapshotter.Options()
           
           options.region = MKCoordinateRegion(
               center: coordinate,
               span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
           )
           
           options.size = getWidgetSize(for: family)
           options.scale = UIScreen.main.scale
           
           let snapshotter = MKMapSnapshotter(options: options)
           
           snapshotter.start { snapshot, error in
               guard let snapshot = snapshot, error == nil else {
                   print("MapSnapshot 생성 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                   completion(nil)
                   return
               }
               
               let image = addMarkerToSnapshot(snapshot, coordinate: coordinate)
               completion(image)
           }
       }
       
       private static func getWidgetSize(for family: WidgetFamily) -> CGSize {
           let screenSize = UIScreen.main.bounds.size
           
           switch family {
           case .systemMedium:

               switch screenSize {
               case CGSize(width: 428, height: 926): // iPhone 14 Pro Max
                   return CGSize(width: 364, height: 170)
               case CGSize(width: 414, height: 896): // iPhone 14 Plus
                   return CGSize(width: 364, height: 170)
               case CGSize(width: 393, height: 852): // iPhone 15 Pro
                   return CGSize(width: 364, height: 170)
               case CGSize(width: 390, height: 844): // iPhone 14 Pro
                   return CGSize(width: 364, height: 170)
               case CGSize(width: 375, height: 812): // iPhone 13 Mini
                   return CGSize(width: 364, height: 170)
               case CGSize(width: 375, height: 667): // iPhone SE
                   return CGSize(width: 321, height: 148)
               case CGSize(width: 320, height: 568): // iPhone SE 1세대
                   return CGSize(width: 292, height: 141)
               default:
                   return CGSize(width: 364, height: 170) // 기본값
               }
           case .systemSmall:
               return CGSize(width: 170, height: 170) // 기본 small 크기
           case .systemLarge:
               return CGSize(width: 364, height: 382) // 기본 large 크기
           default:
               return CGSize(width: 364, height: 170)
           }
       }
    
    private static func addMarkerToSnapshot(
        _ snapshot: MKMapSnapshotter.Snapshot,
        coordinate: CLLocationCoordinate2D
    ) -> UIImage {
        let image = snapshot.image
        
        let pinPoint = snapshot.point(for: coordinate)
        
        UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
        
        image.draw(at: .zero)
        
        let pinSize: CGFloat = 20
        let pinRect = CGRect(
            x: pinPoint.x - pinSize/2,
            y: pinPoint.y - pinSize,
            width: pinSize,
            height: pinSize
        )
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.orange.cgColor)
        context?.fillEllipse(in: pinRect)
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return finalImage
    }
}
