
import UIKit

class TalkPageContainerViewController: ViewController {
    
    private var discussionListViewController: TalkPageDiscussionListViewController?
    let talkPageTitle: String
    let host: String
    let languageCode: String
    let titleIncludesPrefix: Bool
    let type: TalkPageType
    let dataStore: MWKDataStore!
    private var talkPage: TalkPage?
    
    private var talkPageController: TalkPageController!
    
    required init(title: String, host: String, languageCode: String, titleIncludesPrefix: Bool, type: TalkPageType, dataStore: MWKDataStore) {
        self.talkPageTitle = title
        self.host = host
        self.languageCode = languageCode
        self.titleIncludesPrefix = titleIncludesPrefix
        self.type = type
        self.dataStore = dataStore
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetch()
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(tappedAdd(_:)))
        navigationItem.rightBarButtonItem = addButton
        navigationBar.updateNavigationItems()
    }
    
    @objc func tappedAdd(_ sender: UIBarButtonItem) {
        
        guard let talkPage = talkPage else {

            assertionFailure("TalkPage is not populated yet.")
            return
        }
        
        let discussionNewVC = TalkPageUpdateViewController.init(type: .newDiscussion)
        discussionNewVC.delegate = self
        discussionNewVC.apply(theme: theme)
        navigationController?.pushViewController(discussionNewVC, animated: true)
    }
    
    private func fetch() {
        //todo: loading/error/empty states
        talkPageController = TalkPageController(dataStore: dataStore, title: talkPageTitle, host: host, languageCode: languageCode, titleIncludesPrefix: titleIncludesPrefix, type: type)
        talkPageController.fetchTalkPage { [weak self] (result) in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let talkPage):
                self.talkPage = talkPage
                self.setupDiscussionListViewControllerIfNeeded(with: talkPage)
            case .failure(let error):
                print("error! \(error)")
            }
        }
    }
    
    private func setupDiscussionListViewControllerIfNeeded(with talkPage: TalkPage) {
        if discussionListViewController == nil {
            discussionListViewController = TalkPageDiscussionListViewController(dataStore: dataStore, talkPage: talkPage)
            discussionListViewController?.apply(theme: theme)
            wmf_add(childController: discussionListViewController, andConstrainToEdgesOfContainerView: view, belowSubview: navigationBar)
            discussionListViewController?.delegate = self
        }
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
    }
}

extension TalkPageContainerViewController: TalkPageUpdateDelegate {
    func tappedPublish(updateType: TalkPageUpdateViewController.UpdateType, subject: String?, body: String, viewController: TalkPageUpdateViewController) {
        
        switch viewController.updateType {
        case .newDiscussion:
            navigationController?.popViewController(animated: true)
            
            guard let subject = subject,
            let talkPage = talkPage else {
                return
            }
            
            talkPageController.addDiscussion(to: talkPage, title: talkPageTitle, host: host, languageCode: languageCode, subject: subject, body: body) { (result) in
                switch result {
                case .success:
                    print("made it")
                case .failure:
                    print("failure")
                }
            }
            /*
        case .newReply(let discussion):
            dismiss(animated: true, completion: nil)
            
            talkPageController.addReply(to: discussion, title: talkPageTitle, host: host, languageCode: languageCode, body: body) { (result) in
                switch result {
                case .success:
                    print("made it")
                case .failure:
                    print("failure")
                }
            }
 */
            default: break
        }

        
    }
}

extension TalkPageContainerViewController: TalkPageDiscussionListDelegate {
    
    func tappedDiscussion(_ discussion: TalkPageDiscussion, viewController: TalkPageDiscussionListViewController) {
        
        let replyContainerVC = TalkPageReplyContainerViewController(dataStore: dataStore, discussion: discussion)
        replyContainerVC.delegate = self
        replyContainerVC.apply(theme: theme)
        navigationController?.pushViewController(replyContainerVC, animated: true)
    }
}

extension TalkPageContainerViewController: TalkPageReplyContainerViewControllerDelegate {

    func tappedLink(_ url: URL, viewController: TalkPageReplyContainerViewController) {
        let lastPathComponent = url.lastPathComponent
        
        //todo: fix for other languages
        let prefix = TalkPageType.user.prefix
        let underscoredPrefix = prefix.replacingOccurrences(of: " ", with: "_")
        let title = lastPathComponent.replacingOccurrences(of: underscoredPrefix, with: "")
        if lastPathComponent.contains(underscoredPrefix) && languageCode == "test" {
            let talkPageContainerVC = TalkPageContainerViewController(title: title, host: host, languageCode: languageCode, titleIncludesPrefix: false, type: .user, dataStore: dataStore)
            talkPageContainerVC.apply(theme: theme)
            navigationController?.pushViewController(talkPageContainerVC, animated: true)
        }
        
        //todo: else if User: prefix, show their wikitext editing page in a web view. Ensure edits there cause talk page to refresh when coming back.
        //else if no host, try prepending language wiki to components and navigate (openUrl, is it okay that this kicks them out of the app?)
        //else if it's a full url (i.e. a different host), send them to safari
    }
}
