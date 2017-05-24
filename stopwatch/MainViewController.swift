import Foundation
import UIKit

protocol TimerDelegate
{
    func timerStarted()
    func timerReset()
    func timerSaved()
    func getSecondaryClockFaces() -> [ClockFace]
    func getSecondaryLabels() -> [UILabel]
    func getPrettySecondaryLabels() -> [UILabel]
    func showHistory()
}

protocol HistoryDelegate
{
    func showTimer()
}

class MainViewController: UIViewController, UIScrollViewDelegate
{
    @IBOutlet weak var scrollView: UIScrollView!

    var timerController: TimerViewController?

    var historyController: HistoryViewController?

    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.view.backgroundColor = AppDelegate.instance.colorScheme.backgroundColor
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        scrollView.contentSize = CGSize(width: view.frame.width * 2, height: view.frame.height)
        scrollView.delegate = self

        historyController = storyboard?.instantiateViewController(withIdentifier: "HistoryController")
            as? HistoryViewController
        historyController?.delegate = self
        addChildViewController(historyController!)
        historyController?.view.frame.origin.x = view.frame.size.width
        scrollView.addSubview((historyController?.view)!)
        historyController?.didMove(toParentViewController: self)

        timerController = storyboard?.instantiateViewController(withIdentifier: "TimerController")
            as? TimerViewController
        timerController?.delegate = self
        addChildViewController(timerController!)
        scrollView.addSubview((timerController?.view)!)
        timerController?.didMove(toParentViewController: self)

        scrollView.isScrollEnabled = UserSettings().hasReset
        timerController?.historyButton.isHidden = !UserSettings().hasReset
        
        if !UserSettings().didShowFeedbackUI
        {
            let timers = Datastore.instance.fetchTimers()
            guard
                timers.count >=  2,
                Set<Date>(timers.map { $0.date.ignoreTimeComponents() }).count >= 1
            else { return }
            
            UserSettings().didShowFeedbackUI = true
            showQuestions()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        if scrollView.contentOffset.x >= scrollView.frame.width * 0.9
                && timerController?.settings.showHistoryHint == true
        {
            timerController?.settings.showHistoryHint = false
            timerController?.refreshHistoryHint()
        }
    }

    override var prefersStatusBarHidden : Bool
    {
        return true
    }
}

extension MainViewController
{
    func showQuestions()
    {
        let firstPopup = QuestionViewController.instance(with: Questions.firstQuestion,
                                                         from: storyboard!,
                                                         negativeAction: { [weak self] in self?.showFeedbackQuestion() },
                                                         positiveAction: { [weak self] in self?.showAppStoreRateQuestion() })
        present(firstPopup, animated: true, completion: nil)
    }
    
    private func showAppStoreRateQuestion()
    {
        let appStoreRatePopup = QuestionViewController.instance(with: Questions.secondQuestion,
                                                                from: self.storyboard!,
                                                                negativeAction: { [weak self] in self?.dismiss(animated: true, completion: nil) },
                                                                positiveAction: { [weak self] in
                                                                    self?.dismiss(animated: true, completion: nil)
                                                                    self?.reviewInAppStore() })
        dismiss(animated: true, completion: {
            self.present(appStoreRatePopup, animated: true, completion: nil)
        })
    }
    
    private func showFeedbackQuestion()
    {
        let feedbackQuestionPopup = QuestionViewController.instance(with: Questions.thirdQuestion,
                                                                    from: self.storyboard!,
                                                                    negativeAction: { [weak self] in self?.dismiss(animated: true, completion: nil) },
                                                                    positiveAction: { [weak self] in self?.showFeedbackInput() })
        dismiss(animated: true, completion: {
            self.present(feedbackQuestionPopup, animated: true, completion: nil)
        })
    }
    
    private func showFeedbackInput()
    {
        let feedbackPopup = FeedbackViewController.instance(with: Feedbacks.feedback,
                                                            from: self.storyboard!,
                                                            negativeAction: { [weak self] in self?.dismiss(animated: true, completion: nil) },
                                                            positiveAction: { [weak self] text in
                                                                self?.send(feedback: text)
                                                                self?.dismiss(animated: true, completion: nil) })
        dismiss(animated: true, completion: {
            self.present(feedbackPopup, animated: true, completion: nil)
        })
    }
    
    private func reviewInAppStore()
    {
        let url = URL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1126783712&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software")!
        UIApplication.shared.openURL(url)
    }
    
    private func send(feedback: String)
    {
        NetworkManager.send(feedback: feedback)
    }
}

extension MainViewController: TimerDelegate
{
    func timerStarted()
    {
        historyController?.showCurrentTimerView()
    }

    func timerReset()
    {
        scrollView.isScrollEnabled = true
        timerController?.refreshHistoryHint()
        historyController?.hideCurrentTimerView()
        
        if !UserSettings().didShowFeedbackUI
        {
            let timers = Datastore.instance.fetchTimers()
            guard
                timers.count >=  10,
                Set<Date>(timers.map { $0.date.ignoreTimeComponents() }).count >= 3
                else { return }
            
            UserSettings().didShowFeedbackUI = true
            showQuestions()
        }
    }

    func timerSaved()
    {
        historyController?.loadData()
    }

    func getSecondaryClockFaces() -> [ClockFace]
    {
        return [(historyController?.clockFace)!]
    }

    func getSecondaryLabels() -> [UILabel]
    {
        return [(historyController?.currentDetailsLabel)!]
    }

    func getPrettySecondaryLabels() -> [UILabel]
    {
        return [(historyController?.currentDurationLabel)!]
    }

    func showHistory()
    {
        var rect = view.frame
        rect.origin.x = rect.width
        scrollView.scrollRectToVisible(rect, animated: true)
    }
}

extension MainViewController: HistoryDelegate
{
    func showTimer()
    {
        scrollView.scrollRectToVisible(view.frame, animated: true)
    }
}
