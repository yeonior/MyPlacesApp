//
//  RatingControlOnCells.swift
//  MyPlaces
//
//  Created by ruslan on 24.04.2021.
//

import UIKit

class RatingControlOnCells: UIStackView {
    
    var rating = 0 {
        didSet {
            setupImages()
        }
    }
    
    private var ratingImages = [UIImageView]()
    
    var starSize: CGSize = CGSize(width: 15.0, height: 15.0)
    var starCount: Int = 5
    
    private func setupImages() {
        
        for image in ratingImages {
            removeArrangedSubview(image)
            image.removeFromSuperview()
        }
        
        ratingImages.removeAll()
        
        for i in 0..<starCount{
            
            var star = UIImageView()
            let filledStar = UIImageView(image: #imageLiteral(resourceName: "filledStar"))
            let emptyStar = UIImageView(image: #imageLiteral(resourceName: "emptyStar"))
            
            if i < rating {
                star = filledStar
            } else {
                star = emptyStar
            }

            star.translatesAutoresizingMaskIntoConstraints = false
            star.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true
            star.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true
            
            addArrangedSubview(star)
            ratingImages.append(star)
        }
    }
}
