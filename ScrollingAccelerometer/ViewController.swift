//
//  ViewController.swift
//  ScrollingAccelerometer
//
//  Created by Allan Alves on 01/01/18.
//  Copyright © 2018 Allan Alves. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UITableViewController {

    // MARK: - Properties -

    let manager = CMMotionManager()
    var startAttitude: CMAttitude?

    var yDelta: CGFloat = 0
    var refDelta: CGFloat = 0

    var lock = true {
        didSet {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: lock ? #imageLiteral(resourceName: "unlock") : #imageLiteral(resourceName: "lock"), style: .done,
                                                                target: self,
                                                                action: #selector(toggleAutoScrolling(_:)))
        }
    }

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { (_) in self.scroll(self.yDelta) }

        let unlockLongPress = UILongPressGestureRecognizer.init(target: self,
                                                                action: #selector(manageLongPress(_:)))
        tableView.addGestureRecognizer(unlockLongPress)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lock = true
        //Show tip and adjust scroll to demonstrate
        tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: tableView.contentSize.height / 2), animated: true)
        showTip(self)
    }

    // MARK: - Device Motion -

    @objc func handleDeviceMotion(_ motion: CMDeviceMotion) {
        let attitude = motion.attitude
        if startAttitude == nil { startAttitude = attitude }
        attitude.multiply(byInverseOf: startAttitude!)
        if refDelta == 0 && yDelta > 0 { refDelta = yDelta }
        yDelta = CGFloat(attitude.pitch * 40 / Double.pi) - refDelta
    }

    // MARK: - Table View -

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "Cell")!
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }

    // MARK: - Actions -

    @IBAction func toggleAutoScrolling(_ sender: Any) {
        lock ? unlockAutoScroll() : lockAutoScroll()
    }

    @IBAction func showTip(_ sender: Any) {
        let alert = UIAlertController(title: "Tip", message: "Long press to start auto scrolling. \nRelease to stop.",
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Auto Scrolling -

    @objc func manageLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            unlockAutoScroll()
        } else if gesture.state == .ended {
            lockAutoScroll()
        }
    }

    func lockAutoScroll() {
        if lock { return }
        lock = true
        manager.stopDeviceMotionUpdates()
        startAttitude = nil
        UISelectionFeedbackGenerator().selectionChanged()
    }

    @objc func unlockAutoScroll() {
        if !lock { return }
        lock = false
        refDelta = 0
        yDelta = 0
        manager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: OperationQueue.current!) { (motion, error) in
            self.performSelector(onMainThread: #selector(self.handleDeviceMotion(_:)), with: motion, waitUntilDone: true)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    fileprivate func scroll(_ delta: CGFloat) {
        if lock || refDelta == 0 { return }
        DispatchQueue.main.async {
            let offset = self.tableView.contentOffset
            if delta < 0 && offset.y <= 0 { return }
            if delta > 0 {
                let limit = self.tableView.contentSize.height - self.tableView.bounds.height
                if abs(offset.y) >= limit { return }
            }
            self.tableView.setContentOffset(CGPoint(x: offset.x, y: offset.y + delta), animated: false)
        }
    }

}

