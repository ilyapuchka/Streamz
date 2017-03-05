import UIKit

class KeyboardObservingController: UIViewController {
    
    let scrollView: UIScrollView
    private var initialInset: UIEdgeInsets = .zero
    
    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        super.init(nibName: nil, bundle: nil)
        self.view.alpha = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardDidShow(notification: Notification) {
        guard let keyboardRect = notification.userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        initialInset = scrollView.contentInset
        let contentInset = UIEdgeInsets(top: initialInset.top,
                                        left: initialInset.left,
                                        bottom: initialInset.bottom + keyboardRect.height,
                                        right: initialInset.right)
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }
    
    func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = initialInset
        scrollView.scrollIndicatorInsets = initialInset
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // reset insets after rotaion is finished
        coordinator.animate(alongsideTransition: nil) { (_) in
            self.scrollView.contentInset = self.initialInset
            self.scrollView.scrollIndicatorInsets = self.initialInset
        }
    }
}
