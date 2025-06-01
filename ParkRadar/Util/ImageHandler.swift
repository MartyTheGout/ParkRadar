//
//  ImageHandler.swift
//  ParkRadar
//
//  Created by marty.academy on 4/6/25.
//

import UIKit

final class ImageHandler {
    private let appGroupID = "group.parkRadar"
    private let subDirectory = "ParkingImages"

    private var imageDirectoryURL: URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            print("[Error] App Group container not found.")
            return nil
        }
        let imageDir = containerURL.appendingPathComponent(subDirectory)

        // Ensure the directory exists
        if !FileManager.default.fileExists(atPath: imageDir.path) {
            do {
                try FileManager.default.createDirectory(at: imageDir, withIntermediateDirectories: true)
            } catch {
                print("[Error] Failed to create image directory: \(error)")
                return nil
            }
        }

        return imageDir
    }

    func saveImageToDocument(image: UIImage, filename: String) {
        guard let imageDir = imageDirectoryURL else { return }
        let fileURL = imageDir.appendingPathComponent("\(filename).jpg")
        
        guard let data = image.jpegData(compressionQuality: 0.5) else { return }

        do {
            try data.write(to: fileURL)
        } catch {
            print("[Error] Failed to save image to AppGroup directory: \(error)")
        }
    }

    func loadImageFromDocument(filename: String) -> UIImage? {
        guard let imageDir = imageDirectoryURL else { return nil }
        let fileURL = imageDir.appendingPathComponent("\(filename).jpg")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            return UIImage(contentsOfFile: fileURL.path)
        } else {
            return UIImage(systemName: "car.circle")
        }
    }

    func removeImageFromDocument(filename: String) {
        guard let imageDir = imageDirectoryURL else { return }
        let fileURL = imageDir.appendingPathComponent("\(filename).jpg")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                print("removeImage", fileURL)
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("[Error] Failed to remove image: \(error)")
            }
        } else {
            print("[Error] Image does not exist at path: \(fileURL.path)")
        }
    }
}

