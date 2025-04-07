//
//  CustomPresentationController.swift
//  ParkRadar
//
//  Created by marty.academy on 4/5/25.
//

import UIKit

class CustomPresentationController: UIPresentationController {
    private let dimmedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.alpha = 0
        return view
    }()
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        
        dimmedView.frame = containerView.bounds
        containerView.addSubview(dimmedView)
        
        presentedView?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        presentedView?.alpha = 0
        
        presentedView?.layer.cornerRadius = 12
        presentedView?.clipsToBounds = true
        
        // Animate the dimmed view during presentation
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmedView.alpha = 1
            presentedView?.transform = .identity
            presentedView?.alpha = 1
            return
        }
        
        coordinator.animate(alongsideTransition: { _ in
            self.dimmedView.alpha = 1
            self.presentedView?.transform = .identity
            self.presentedView?.alpha = 1
        })
    }
    
    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmedView.alpha = 0
            presentedView?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            presentedView?.alpha = 0
            return
        }
        
        coordinator.animate(alongsideTransition: { _ in
            self.dimmedView.alpha = 0
            self.presentedView?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.presentedView?.alpha = 0
        })
    }
    
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {
            return .zero
        }
        
        let width = containerView.bounds.width * 0.8
        let height = containerView.bounds.height * 0.7
        
        return CGRect(
            x: (containerView.bounds.width - width) / 2,  // 중앙 정렬
            y: (containerView.bounds.height - height) / 2,  // 중앙 정렬
            width: width,
            height: height
        )
    }
    
    //MARK: - Action : TapGesture to Close modal
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        
        if dimmedView.gestureRecognizers == nil {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            dimmedView.addGestureRecognizer(tapGesture)
        }
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        presentedViewController.dismiss(animated: true)
    }
}
