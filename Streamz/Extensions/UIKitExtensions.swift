import UIKit

extension UIViewController {
    
    func addChildViewControllerToView(_ viewController: UIViewController, addToView: ((UIViewController) -> Void)? = nil) {
        addChildViewController(viewController)
        if let addToView = addToView {
            addToView(viewController)
        } else {
            view.addSubview(viewController.view)
        }
        didMove(toParentViewController: self)
    }
    
}

extension UITableView {
    
    func batchUpdate(_ update: ()->()) {
        beginUpdates()
        update()
        endUpdates()
    }
    
}

protocol Reusable {
    static var reuseIdentifier: String { get }
}

extension UITableView {
    
    func dequeueReusableCell<T: Reusable>(for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as! T
    }
    
}

extension UIButton {
    
    func setTitle(_ title: String?, for state: UIControlState, animated: Bool) {
        if !animated {
            UIView.setAnimationsEnabled(false)
            setTitle(title, for: state)
            layoutIfNeeded()
            UIView.setAnimationsEnabled(true)
        } else {
            setTitle(title, for: state)
        }
    }
    
}
