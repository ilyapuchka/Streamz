import UIKit

class AuthViewController: UIViewController {
    
    var authService: AuthService!
    weak var flowController: AuthFlowController!
    
    @IBOutlet weak var continueAsButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startLoading()
        
        authService.restoreSession { [weak self] (credentials) in
            guard let strongSelf = self else { return }
            
            strongSelf.endLoading()
            
            if let username = credentials?.username {
                strongSelf.continueAsButton.isHidden = false
                strongSelf.continueAsButton.setTitle("Continue as \(username)", for: .normal, animated: false)
            } else {
                strongSelf.continueAsButton.isHidden = true
            }
        }
    }
    
    @IBAction func continueAsTapped(_ sender: UIButton) {
        flowController.authorised()
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        let continueAsButtonHidden = continueAsButton.isHidden
        startLoading()

        authService.authorise { [weak self] (cred, error) in
            guard let strongSelf = self else { return }
            
            strongSelf.endLoading()
            strongSelf.continueAsButton.isHidden = continueAsButtonHidden
            
            if let error = error {
                let alert = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: .alert)
                strongSelf.present(alert, animated: true, completion: nil)
                return
            }
            
            strongSelf.flowController.authorised()
        }
    }
    
    private func startLoading() {
        continueAsButton.isHidden = true
        loginButton.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func endLoading() {
        continueAsButton.isHidden = false
        loginButton.isHidden = false
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
}
