import AVFoundation
import XCTest

@testable import SwiftAudioEx


class AVPlayerWrapperTests: XCTestCase {
    
    var wrapper: AVPlayerWrapper!
    var holder: AVPlayerWrapperDelegateHolder!
    
    override func setUp() {
        super.setUp()
        wrapper = AVPlayerWrapper()
        wrapper.volume = 0.0
        wrapper.automaticallyWaitsToMinimizeStalling = false
        holder = AVPlayerWrapperDelegateHolder()
        wrapper.delegate = holder
    }
    
    override func tearDown() {
        wrapper = nil
        holder = nil
        super.tearDown()
    }
    
    // MARK: - State tests
    
    func test_AVPlayerWrapper__state__should_be_idle() {
        XCTAssert(wrapper.state == AVPlayerWrapperState.idle)
    }
    
    func test_AVPlayerWrapper__state__when_loading_a_source__should_be_loading() {
        wrapper.load(from: Source.url, playWhenReady: false)
        XCTAssertEqual(wrapper.state, AVPlayerWrapperState.loading)
    }
    
    func test_AVPlayerWrapper__state__when_loading_a_source__should_eventually_be_ready() {
        let expectation = XCTestExpectation()
        holder.stateUpdate = { state in
            if state == .ready {
                expectation.fulfill()
            }
        }
        wrapper.load(from: Source.url, playWhenReady: false)
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_AVPlayerWrapper__state__when_playing_a_source__should_be_playing() {
        let expectation = XCTestExpectation()
        holder.stateUpdate = { state in
            if state == .playing {
                expectation.fulfill()
            }
        }
        wrapper.load(from: Source.url, playWhenReady: true)
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_AVPlayerWrapper__state__when_pausing_a_source__should_be_paused() {
        let expectation = XCTestExpectation()
        holder.stateUpdate = { state in
            switch state {
            case .playing: self.wrapper.pause()
            case .paused: expectation.fulfill()
            default: break
            }
        }
        wrapper.load(from: Source.url, playWhenReady: true)
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_AVPlayerWrapper__state__when_toggling_from_play__should_be_paused() {
        let expectation = XCTestExpectation()
        holder.stateUpdate = { state in
            switch state {
            case .playing: self.wrapper.togglePlaying()
            case .paused: expectation.fulfill()
            default: break
            }
        }
        wrapper.load(from: Source.url, playWhenReady: true)
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_AVPlayerWrapper__state__when_stopping__should_be_stopped() {
        let expectation = XCTestExpectation()
        holder.stateUpdate = { state in
            switch state {
            case .playing: self.wrapper.stop()
            case .stopped: expectation.fulfill()
            default: break
            }
        }
        wrapper.load(from: Source.url, playWhenReady: true)
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_AVPlayerWrapper__state__loading_with_intial_time__should_be_playing() {
        let expectation = XCTestExpectation()
        holder.stateUpdate = { state in
            switch state {
            case .playing: expectation.fulfill()
            default: break
            }
        }
        wrapper.load(from: LongSource.url, playWhenReady: true, initialTime: 4.0)
        wait(for: [expectation], timeout: 20.0)
    }
    
    // MARK: - Duration tests
    
    func test_AVPlayerWrapper__duration__should_be_0() {
        XCTAssert(wrapper.duration == 0.0)
    }
    
    func test_AVPlayerWrapper__duration__loading_a_source__should_not_be_0() {
        let expectation = XCTestExpectation()
        holder.stateUpdate = { _ in
            if self.wrapper.duration > 0 {
                expectation.fulfill()
            }
        }
        wrapper.load(from: Source.url, playWhenReady: false)
        wait(for: [expectation], timeout: 20.0)
    }
    
    // MARK: - Current time tests
    
    func test_AVPlayerWrapper__currentTime__should_be_0() {
        XCTAssert(wrapper.currentTime == 0)
    }
    
    // MARK: - Seeking
    
    func test_AVPlayerWrapper__seeking__should_seek() {
        let seekTime: TimeInterval = 5.0
        let expectation = XCTestExpectation()
        holder.stateUpdate = { state in
            self.wrapper.seek(to: seekTime)
        }
        holder.didSeekTo = { seconds in
            expectation.fulfill()
        }
        wrapper.load(from: Source.url, playWhenReady: false)
        wait(for: [expectation], timeout: 20.0)
    }

    func test_AVPlayerWrapper__seeking__should_seek_while_not_yet_loaded() {
        let seekTime: TimeInterval = 5.0
        let expectation = XCTestExpectation()
        holder.didSeekTo = { seconds in
            expectation.fulfill()
        }
        wrapper.load(from: Source.url, playWhenReady: false)
        wrapper.seek(to: seekTime)
        wait(for: [expectation], timeout: 20.0)
    }

    func test_AVPlayerWrapper__seek_by__should_seek() {
        let seekTime: TimeInterval = 5.0
        let expectation = XCTestExpectation()
        holder.stateUpdate = { state in
            self.wrapper.seek(by: seekTime)
        }
        holder.didSeekTo = { seconds in
            expectation.fulfill()
        }
        wrapper.load(from: Source.url, playWhenReady: false)
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_AVPlayerWrapper__loading_source_with_initial_time__should_seek() {
        let expectation = XCTestExpectation()
        holder.didSeekTo = { seconds in
            expectation.fulfill()
        }
        wrapper.load(from: LongSource.url, playWhenReady: false, initialTime: 4.0)
        wait(for: [expectation], timeout: 20.0)
    }
    
    // MARK: - Rate tests
    
    func test_AVPlayerWrapper__rate__should_be_1() {
        XCTAssert(wrapper.rate == 1)
    }
    
    func test_AVPlayerWrapper__rate__playing_a_source__should_be_1() {
        let expectation = XCTestExpectation()
        holder.stateUpdate = { state in
            if self.wrapper.rate == 1.0 {
                expectation.fulfill()
            }
        }
        wrapper.load(from: Source.url, playWhenReady: true)
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_AVPlayerWrapper__timeObserver__when_updated__should_update_the_observers_periodicObserverTimeInterval() {
        wrapper.timeEventFrequency = .everySecond
        XCTAssert(wrapper.playerTimeObserver.periodicObserverTimeInterval == TimeEventFrequency.everySecond.getTime())
        wrapper.timeEventFrequency = .everyHalfSecond
        XCTAssert(wrapper.playerTimeObserver.periodicObserverTimeInterval == TimeEventFrequency.everyHalfSecond.getTime())
    }

}

class AVPlayerWrapperDelegateHolder: AVPlayerWrapperDelegate {
    private let lockQueue = DispatchQueue(
        label: "AVPlayerWrapperDelegateHolder.lockQueue",
        target: .global()
    )

    func AVWrapperItemPlaybackStalled() {

    }
    
    func AVWrapperItemFailedToPlayToEndTime() {

    }
    
    func AVWrapper(didChangePlayWhenReady playWhenReady: Bool) {

    }
    
    func AVWrapper(didReceiveMetadata metadata: [AVTimedMetadataGroup]) {
        
    }

    func AVWrapperDidRecreateAVPlayer() {
        
    }
    
    func AVWrapperItemDidPlayToEndTime() {
        
    }
    
    private var _state: AVPlayerWrapperState? = nil
    var state: AVPlayerWrapperState? {
        get {
            return lockQueue.sync {
                return _state
            }
        }

        set {
            lockQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                if let newValue = newValue {
                    let changed = self._state != newValue;
                    if (changed) {
                        self._state = newValue
                        self.stateUpdate?(newValue)
                    }
                }
            }
        }
    }

    var stateUpdate: ((_ state: AVPlayerWrapperState) -> Void)?
    var didUpdateDuration: ((_ duration: Double) -> Void)?
    var didSeekTo: ((_ seconds: Double) -> Void)?
    var itemDidComplete: (() -> Void)?
    
    func AVWrapper(didChangeState state: AVPlayerWrapperState) {
        self.state = state
    }
    
    func AVWrapper(secondsElapsed seconds: Double) {
        
    }
    
    func AVWrapper(failedWithError error: Error?) {
        
    }
    
    func AVWrapper(seekTo seconds: Double, didFinish: Bool) {
         didSeekTo?(seconds)
    }
    
    func AVWrapper(didUpdateDuration duration: Double) {
        if let state = self.state {
            self.stateUpdate?(state)
        }
        didUpdateDuration?(duration)
    }
    
}
