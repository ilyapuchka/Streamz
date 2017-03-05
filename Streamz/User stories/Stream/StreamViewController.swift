import UIKit

class StreamViewController: UIViewController, UITableViewDataSource, UISearchBarDelegate {

    var streamService: StreamService!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.estimatedRowHeight = 60
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.tableFooterView = UIView()
        }
    }
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    private(set) var model: TweetStreamViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Using child view controllers we can have nice separation of concerns
        // for different UIKit related behaviours
        addChildViewControllerToView(KeyboardObservingController(scrollView: tableView!))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        searchBar.becomeFirstResponder()
    }
    
    func handleIncommingTweet(_ tweet: Tweet) {
        tableView.batchUpdate {
            model?.append(tweet: tweet, onInsert: { index in
                tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            }, onDelete: { index in
                tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            })
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as TweetCell
        cell.update(with: model![indexPath.row])
        return cell
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }
        searchBar.endEditing(true)

        let keywords = searchText.components(separatedBy: CharacterSet.punctuationCharacters.union(.whitespaces))
        
        model = TweetStreamViewModel(capacity: 5)
        tableView.reloadData()
        
        streamService.startStream(keywords: keywords, progress: { [weak self] (tweet, error) in
            guard let tweet = tweet else { return }
            self?.handleIncommingTweet(tweet)
        })
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)

        streamService.stopStream()

        model = nil
        tableView.reloadData()
    }
    
}
