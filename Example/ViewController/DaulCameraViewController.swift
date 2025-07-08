//
//  ViewController.swift
//  DualCamera
//
//  Created by William.Weng on 2024/8/8.
//

import UIKit
import AVFoundation
import AVKit
import Photos
import WWDualCamera
import WWPrint
import WWCameraZoomOptionView

// MARK: - DaulCameraViewController
final class DaulCameraViewController: UIViewController {
    
    @IBOutlet weak var cameraLayerView: UIView!
    @IBOutlet weak var mainView: UIImageView!
    @IBOutlet weak var pipView: UIImageView!
    @IBOutlet weak var recorderTimeView: UIView!
    @IBOutlet weak var transitionImageView: UIImageView!
    @IBOutlet weak var zoomOptionView: WWCameraZoomOptionView!
    
    @IBOutlet weak var capacityLabel: UILabel!
    @IBOutlet weak var recorderTimeLabel: UILabel!
    
    @IBOutlet weak var videoRecorderButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var cameraFlashModeButton: UIButton!
    @IBOutlet weak var torchButton: UIButton!
    @IBOutlet weak var videoDefinitionButton: UIButton!
    
    @IBOutlet weak var pipViewWidthLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var pipViewHeightLayoutConstraint: NSLayoutConstraint!
    
    private let initZoomScale: CGFloat = 2.0
    private let videoScale: CGFloat = 16 / 9
    private let processingViedoQueue = DispatchQueue(label: "idv.william.Example.video", qos: .userInteractive)
    private let processingAudioQueue = DispatchQueue(label: "idv.william.Example.audio", qos: .userInteractive)
    private let cameraZoomRange = 1.0...16.0
    private let cameraLayerViewCornerRadius = 16.0
    
    private var takePhotoClosure: ((Result<AVCapturePhoto, Error>) -> Void)?
    private var swipeFunctions: [UInt: () -> Void] = [:]
    
    private var isInitialize = false
    private var isDisplay = true
    private var isMainLayerInBack = true
    private var isVideoRecording = false
    private var isAudioRecording = false
    private var isSessionStarted = false
    private var isUltraWideCamera = false
    private var isExchangeCamera = false
    private var isDoubleTap = false
    private var isTemporaryRecording = false
    
    private var hasPixelMainScale = false
    
    private var pipViewDiameter: CGFloat = 128.0
    private var zoomFactor: Constant.CameraZoomFactor = (main: 1.0, mainTemp: 1.0, pip: 1.0)
    private var torchLevel: Float = 0.0
    private var pixelMainScale: CGFloat = 1.0
    
    private var videoMainViewFrame: CGRect = .zero
    private var videoPipViewFrame: CGRect = .zero
    private var pipViewFrame: CGRect = .zero
    private var pipLayerCenter: CGPoint?
    private var temporaryVideoRecordingPoint: CGPoint?
    
    private var currentCameraFlashMode: AVCaptureDevice.FlashMode = .off
    private var currentPipLayerStyle: Constant.PipLayerStyle = .circle
    private var currentTorchMode: AVCaptureDevice.TorchMode = .off
    private var capacitytTimer: Timer?
    private var screenOrientation: Constant.ScreenOrientation = (.portrait, .up)
    
    private var sequenceZooms: [Double] = []
    private var pipLayerStyles: [Constant.PipLayerStyle] = []
    private var cameraInputs: Constant.CameraInputs = (nil, nil, nil)
    private var videoDataOutputs: Constant.VideoDataOutputs = (nil, nil, nil)
    private var audioDataOutput: AVCaptureAudioDataOutput?
    private var videoURL: URL?
    
    private var photoOutputs: [AVCapturePhotoOutput] = []
    private var _photoOutputs: [AVCapturePhotoOutput] = []
    private var photos: [AVCapturePhoto] = []
    
    private var assetWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var audioWriterInput: AVAssetWriterInput?
    private var videoDefinition: Constant.VideoDefinition = .FHD
    private var videoSize: Constant.VideoSize { videoDefinition.size(for: screenOrientation.item) }
    private var recorderTimeInterval: TimeInterval = 0
    private var playerViewController: AVPlayerViewController?
    
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var pixelBufferPool: CVPixelBufferPool?
    private var startTime: CMTime?
    private var videoPixelBuffers: (back: CVPixelBuffer?, front: CVPixelBuffer?)
    
    private var audioRecorder: AVAudioRecorder?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initViewSetting()
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        viewIsAppearingAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearAction()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearAction()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        previewViewControllerSetting(for: segue, sender: sender)
    }
    
    @IBAction func takePhoto(_ sender: UIButton) {
        takePhotoAction(flashMode: currentCameraFlashMode)
    }
    
    @IBAction func startRecoding(_ sender: UIButton) {
        videoRecodingAction()
    }
    
    @IBAction func switchCameraFlash(_ sender: UIButton) {
        switchCameraFlashAction()
    }
    
    @IBAction func toggleTorch(_ sender: UIButton) {
        toggleTorchAction()
    }
    
    @IBAction func videoDefinitionSetting(_ sender: UIButton) {
        videoDefinition.toggle()
        videoDefinitionAction(videoDefinition)
    }
    
    deinit {
        wwPrint("deinit")
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension DaulCameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error { takePhotoClosure?(.failure(error)); return }
        
        takePhotoClosure?(.success(photo))
        _photoOutputs.popLast()?._setting(quality: .speed)._capturePhoto(flashMode: currentCameraFlashMode, delegate: self)
    }
}

// MARK: - AVCaptureAudioDataOutputSampleBufferDelegate
extension DaulCameraViewController: AVCaptureAudioDataOutputSampleBufferDelegate {}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension DaulCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        captureDaulVideoAction(output: output, didOutput: sampleBuffer, from: connection)
    }
}

// MARK: - AVAudioRecorderDelegate
extension DaulCameraViewController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        wwPrint(flag)
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        wwPrint(error)
    }
}

// MARK: - WWCameraZoomOptionViewDelegate
extension DaulCameraViewController: WWCameraZoomOptionViewDelegate {
    
    func itemCount(with optionView: WWCameraZoomOptionView) -> Int {
        return sequenceZoomItemMaker().count
    }
    
    func labelText(with optionView: WWCameraZoomOptionView, index: Int) -> String? {
        guard let value = sequenceZoomItemMaker()[safe: index] else { return nil }
        return parseZoomFactorNumber(with: value)._zoomFormat()
    }
    
    func duration(with optionView: WWCameraZoomOptionView, index: Int) -> TimeInterval {
        return 0.25
    }
    
    func cameraZoomOptionView(_ optionView: WWCameraZoomOptionView, didSelected index: Int) {
        
        guard let value = sequenceZoomItemMaker()[safe: index] else { return }
        
        cameraZoomFactor(1.0, scale: value)
        zoomFactorValue(value)
    }
    
    func cameraZoomOptionView(_ optionView: WWCameraZoomOptionView, canTapWith index: Int) -> Bool {
        return true
    }
    
    func cameraZoomOptionView(_ optionView: WWCameraZoomOptionView, scaleWith index: Int) -> CGFloat {
        return 1.2
    }
}

// MARK: - @objc handle
@objc private extension DaulCameraViewController {
    
    func handleTapGesture(_ tap: UITapGestureRecognizer) {
        
        guard let tapView = tap.view,
              let tag = Constant.CameraViewTag(rawValue: tapView.tag)
        else {
            return
        }
        
        switch tag {
        case .main: singleTapViewAction(with: tap)
        case .mainTemp: wwPrint("mainTemp")
        case .pip: switchPipViewStyleAction()
        }
    }
    
    func handleVideoRecorderClick(_ button: UIButton) {
        temporaryVideoRecording(with: button, delayTime: 0.5)
    }
    
    func handleVideoRecorderPanGesture(_ pan: UIPanGestureRecognizer) {
        
        switch pan.state {
        case .began: break
        case .changed: temporaryVideoZoom(with: pan)
        case .ended, .cancelled: stopTemporaryVideoRecording()
        default: fatalError()
        }
    }
    
    func handleLongPressGesture(_ press: UILongPressGestureRecognizer) {
        resetPipView()
    }
    
    func handlePinchGesture(_ pinch: UIPinchGestureRecognizer) {
        
        guard let pinchView = pinch.view,
              let tag = Constant.CameraViewTag(rawValue: pinchView.tag)
        else {
            return
        }
        
        switch tag {
        case .main: cameraZoomAction(with: pinch)
        case .mainTemp: wwPrint("mainTemp")
        case .pip: pipViewScaleAction(with: pinch)
        }
    }
    
    func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        movePipLayerAction(with: pan)
    }
        
    func handleShareMedia(_ item: UIBarButtonItem) {
        shareMediaAction()
    }
    
    func handleRemoveMedia(_ item: UIBarButtonItem) {
        Utility.shared.presentComfireAlertController(target: self, title: Constant.Message.reminder.output(), message: Constant.Message.deleteFile.output(), cancelhandler: nil, surehandler: {
            self.removeMediaAction()
        })
    }
}

// MARK: - 主工具
private extension DaulCameraViewController {
    
    /// 畫面出現後，僅做一次的設定
    func viewIsAppearingAction() {
        
        if (!isInitialize) {
            initSetting()
            swipeFunctions = swipeGestureFunctions(orientation: screenOrientation)
            // orientationDidChangeNotification()
            visualEffectAnimation(duration: 2.0)
            _ = checkAvailableCapacity(folderType: Constant.shared.folderType)
            CALayer._animations(isEnabled: true) { [unowned self] in pipLayerCenterSetting(pipView.center) }
        }
    }
    
    /// 初始化一些畫面的基本設定
    func initViewSetting() {
                
        view.backgroundColor = .black
        mainView.backgroundColor = .clear
        pipView.backgroundColor = .clear
        recorderTimeView.backgroundColor = .systemPink

        cameraLayerView.layer.cornerRadius = cameraLayerViewCornerRadius
        recorderTimeView.layer.cornerRadius = 8.0
        
        currentPipLayerStyle = pipLayerStyleMaker().last ?? .circle
        
        pipViewDiameter = UIScreen.main.bounds.width * 0.333
        
        initZoomOptionView()
    }
    
    /// 畫面旋轉後 => 修正PIP畫面的外形
    func orientationDidChangeNotification() {
        
        Center.UIDeviceManager.shared.screenOrientation { [unowned self] orientation in
            
            screenOrientation.current = orientation
            
            if (!isVideoRecording) {
                itemsOrientationImage(screenOrientation.current)
                exchangePipViewStyleAction(style: currentPipLayerStyle, orientation: screenOrientation)
            }
        }
    }
    
    /// 畫面旋轉後的手勢函式選項
    /// - Parameter orientation: Constant.ScreenOrientation
    /// - Returns: [UInt: () -> Void]
    func swipeGestureFunctions(orientation: Constant.ScreenOrientation) -> [UInt: () -> Void] {
        
        let functions: [UInt: () -> Void]
        
        switch orientation.current {
        case .portrait: functions = [UISwipeGestureRecognizer.Direction.left.rawValue: switchPipViewStyleAction]
        case .portraitUpsideDown: functions = [UISwipeGestureRecognizer.Direction.right.rawValue: switchPipViewStyleAction]
        case .landscapeLeft: functions = [UISwipeGestureRecognizer.Direction.up.rawValue: switchPipViewStyleAction]
        case .landscapeRight: functions = [UISwipeGestureRecognizer.Direction.down.rawValue: switchPipViewStyleAction]
        default: functions = [:]
        }
        
        return functions
    }
    
    /// 畫面旋轉後的Item圖示處理
    /// - Parameter orientation: UIDeviceOrientation
    func itemsOrientationImage(_ orientation: UIDeviceOrientation) {
        
        var imageOrientation: UIImage.Orientation?
        
        switch orientation {
        case .portrait: imageOrientation = .up
        case .portraitUpsideDown: imageOrientation = .down
        case .landscapeLeft: imageOrientation = .right
        case .landscapeRight: imageOrientation = .left
        default: break
        }
        
        let buttons = [cameraButton, videoRecorderButton, cameraFlashModeButton, torchButton, videoDefinitionButton]
        
        buttons.forEach { button in
            
            guard let button = button,
                  let imageOrientation = imageOrientation
            else {
                return
            }
            
            let image = button.imageView?.image?._flip(with: imageOrientation)?.withRenderingMode(.alwaysOriginal)
            button.setImage(image, for: .normal)
        }
        
        screenOrientation.item = imageOrientation ?? .up
    }
    
    /// 切換相機閃光燈模式
    func switchCameraFlashAction() {
        let flashMode = AVCaptureDevice.FlashMode(rawValue: (currentCameraFlashMode.rawValue + 1) % 3) ?? .auto
        switchCameraFlashMode(flashMode)
    }
    
    /// 錄影功能切換
    func videoRecodingAction() {
        
        if (!isVideoRecording) { videoStartRecording(); return }
        
        videoStopRecording { [unowned self] url in
            saveVideoAction(with: url)
        }
    }
    
    /// 拍照功能 => 一張一張照，然後合成同一張 (擷圖)
    /// - Parameter flashMode: 閃光燈設定
    func takePhotoAction(flashMode: AVCaptureDevice.FlashMode) {
        
        photos = []
        _photoOutputs = photoOutputs
        
        if isMainLayerInBack { _photoOutputs.reverse() }
        _photoOutputs.popLast()?._setting(quality: .speed)._capturePhoto(flashMode: flashMode, delegate: self)
    }
    
    /// 切換相機手電筒模式 (On / Off)
    func toggleTorchAction() {
        currentTorchMode = (currentTorchMode == .on) ? .off : .on
        toggleTorchMode(currentTorchMode)
    }
    
    /// 設定鏡頭的解析度
    /// - Parameters:
    ///   - videoDefinition: Constant.VideoDefinition
    func videoDefinitionAction(_ videoDefinition: Constant.VideoDefinition) {
        
        let inputs = smoothVideoDefinition(videoDefinition, isHighEfficiency: true)
        var errors: [Error] = []
        
        for input in inputs {
                        
            guard let input = input,
                  let device = input.device,
                  let format = device._formats(definition: input.definition).first
            else {
                errors.append(Constant.MyError.notSupports); continue
            }
            
            let result = device._activeFormat(format)
            
            switch result {
            case .failure(let error): errors.append(error)
            case .success(_): break
            }
        }
        
        if (!errors.isEmpty) {
            Utility.shared.presentAlertController(target: self, title: Constant.Message.error.output(), message: errors.debugDescription, handler: nil)
            return
        }
        
        disableButtonsForVideoRecorder(isVideoRecording, orientation: screenOrientation.current)
        toggleTorchMode(currentTorchMode)
    }
    
    /// 手動設定鏡頭對焦點
    /// - Parameters:
    ///   - device: AVCaptureDevice?
    ///   - tap: AVCaptureDevice?
    /// - Returns: Result<Bool, Error>
    func cameraFocusPoint(device: AVCaptureDevice?, withTap tap: UITapGestureRecognizer) -> Result<Bool, Error> {
        
        guard let device = device,
              let percentPoint = tap._percentPoint()
        else {
            return .success(false)
        }
        
        return device._focusMode(.autoFocus, point: percentPoint)
    }
    
    /// 流暢的切換錄影的解析度 (∵ 手機功能的不同 ∴ 不是所有的手機都能同時開4K的三鏡頭)
    /// - Parameters:
    /// - Parameter videoDefinition: Constant.VideoDefinition
    ///   - isHighEfficiency: 要不要設定成完整的解析度 (效能)
    /// - Returns: [Constant.CameraInput?]
    func smoothVideoDefinition(_ videoDefinition: Constant.VideoDefinition, isHighEfficiency: Bool) -> [Constant.CameraInput?] {
        
        if (!isHighEfficiency) {
            cameraInputs.main?.definition = videoDefinition
            return [cameraInputs.main, cameraInputs.pip]
        }
        
        cameraInputs.main?.definition = .FHD
        cameraInputs.pip?.definition = .FHD

        if (!isMainLayerInBack) { 
            cameraInputs.pip?.definition = videoDefinition
            return [cameraInputs.main, cameraInputs.pip]
        }
        
        cameraInputs.main?.definition = videoDefinition
        return [cameraInputs.pip, cameraInputs.main]
    }
    
    /// 處理放大倍率的顯示數字 => 1.0 -> 0.5x, 2.0 -> 1.0x, 6.0 -> 5.0x
    /// - Parameter value: CGFloat
    /// - Returns: NSString
    func parseZoomFactorString(with value: CGFloat, decimal: UInt = 1) -> NSString {
        return parseZoomFactorNumber(with: value)._decimalPoint(decimal)
    }
    
    /// 處理放大倍率的顯示數字 => 1.0 -> 0.5, 2.0 -> 1.0, 6.0 -> 5.0
    /// - Parameter value: CGFloat
    /// - Returns: NSString
    func parseZoomFactorNumber(with value: CGFloat) -> NSNumber {
        
        var factor = value
        
        switch factor {
        case 1.0...2.0: factor = factor * 0.5
        case 2.0...: factor = factor - 1
        default: break
        }
        
        return NSNumber(value: factor)
    }
    
    /// 顯示當前的放大倍率 for ZoomOptionView
    /// - Parameter value: CGFloat
    func zoomFactorValue(_ value: CGFloat) {
        
        let zooms = Array(sequenceZoomItemMaker().reversed())
        let _index = zooms.firstIndex { Int(value) >= Int($0) } ?? zooms.count
        let index = zooms.count - _index - 1
        let fixValue = parseZoomFactorString(with: value)
        
        zoomOptionView.selectItem(with: index)
        zoomOptionView.optionLabelText("\(fixValue)x", withIndex: index)
    }
    
    /// 處理雙鏡頭影像合成 + 聲音
    /// - Parameters:
    ///   - output: AVCaptureOutput
    ///   - sampleBuffer: CMSampleBuffer
    ///   - connection: AVCaptureConnection
    func captureDaulVideoAction(output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard isVideoRecording, !isExchangeCamera else { return }
        
        let timestamp = sampleBuffer.presentationTimeStamp
        
        if (startTime == nil) {
            startTime = timestamp
            assetWriter?.startSession(atSourceTime: timestamp)
            isSessionStarted = true
        }
        
        if (!isUltraWideCamera && output == videoDataOutputs.back) { (isMainLayerInBack) ? processMainVideo(sampleBuffer: sampleBuffer, from: connection) : processPipVideo(sampleBuffer: sampleBuffer, from: connection); return }
        if (isUltraWideCamera && output == videoDataOutputs.backTemp) { (isMainLayerInBack) ? processMainVideo(sampleBuffer: sampleBuffer, from: connection) : processPipVideo(sampleBuffer: sampleBuffer, from: connection); return }
        if (output == videoDataOutputs.front) { (!isMainLayerInBack) ? processMainVideo(sampleBuffer: sampleBuffer, from: connection) : processPipVideo(sampleBuffer: sampleBuffer, from: connection); return }
        if (output == audioDataOutput) { processAudio(sampleBuffer: sampleBuffer); return }
    }
    
    /// 流暢的切換主鏡頭 (廣角 <=> 超廣角)
    func exchangeCameraAction() {
        
        guard let camera1 = cameraInputs.main?.device,
              let camera2 = cameraInputs.mainTemp?.device
        else {
            return
        }
        
        exchangeCameraSetting {
            cameraInputs.main?.device = camera2
            cameraInputs.mainTemp?.device = camera1
            isUltraWideCamera = !(camera1.deviceType == .builtInUltraWideCamera)
        }
                
        _ = videoDataOutOrientationSetting()
        videoDefinitionAction(videoDefinition)
        cameraFocusMode(cameraInputs.main?.device)
        toggleTorchMode(currentTorchMode)
    }
    
    /// 切換主鏡頭的設定 => isExchangeCamera
    /// - Parameter action: () -> Void
    func exchangeCameraSetting(action: () -> Void) {
        isExchangeCamera = true
        defer { isExchangeCamera = false }
        action()
    }
    
    /// 畫面將要出現的功能處理
    func viewWillAppearAction() {
        
        navigationController?.isNavigationBarHidden = true
        navigationController?.isToolbarHidden = true
        
        startDualCameraAction()
        toggleTorchMode(currentTorchMode)
        
        playerViewController?.player?.pause()
        playerViewController?.removeFromParent()
        playerViewController = nil
    }
    
    /// 畫面將要消失的功能處理
    func viewWillDisappearAction() {
        navigationController?.isNavigationBarHidden = false
        startDualCameraAction()
    }
}

// MARK: - 手勢功能
private extension DaulCameraViewController {
    
    /// 鏡頭雙指縮放功能
    /// - Parameter pinch: UIPinchGestureRecognizer
    func cameraZoomAction(with pinch: UIPinchGestureRecognizer) {
        
        cameraZoomAction(scale: pinch.scale)
        
        switch pinch.state {
        case .began, .changed: pinch.scale = 1.0
        case .ended, .cancelled, .possible, .failed: break
        @unknown default: fatalError()
        }
    }
    
    /// PipView尺寸縮放功能
    /// - Parameter pinch: UIPinchGestureRecognizer
    func pipViewScaleAction(with pinch: UIPinchGestureRecognizer) {
        
        guard let view = pinch.view else { return }
        
        if pinch.state == .began || pinch.state == .changed {
            view.transform = view.transform.scaledBy(x: pinch.scale, y: pinch.scale)
            pinch.scale = 1.0
        }
        
        CALayer._animations(isEnabled: false) { [unowned self] in
            exchangePipViewStyleAction(style: currentPipLayerStyle, orientation: screenOrientation)
        }
    }
    
    /// 回復pipView的大小
    func resetPipView() {
        
        pipView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        pipViewFrame = pipView.frame
        
        CALayer._animations(isEnabled: false) { [unowned self] in
            exchangePipViewStyleAction(style: currentPipLayerStyle, orientation: screenOrientation)
        }
    }
    
    /// 移動Pip鏡頭畫面
    /// - Parameter pan: UIPanGestureRecognizer
    func movePipLayerAction(with pan: UIPanGestureRecognizer) {
        
        guard let panLocation = Optional.some(pan.translation(in: pipView)),
              let view = pan.view
        else {
            return
        }
        
        let newCenter = view.center + panLocation * view.transform.a
        
        CALayer._animations(isEnabled: false) { [unowned self] in
            pipLayerCenterSetting(newCenter)
        }
        
        pan.setTranslation(.zero, in: pan.view)
    }
    
    /// 切換PipView的外型 (圓形 / 正方形 / 長方形)
    func switchPipViewStyleAction() {
        
        if (pipLayerStyles.isEmpty) { pipLayerStyles = pipLayerStyleMaker() }
        
        currentPipLayerStyle = pipLayerStyles.popLast() ?? .circle
        exchangePipViewStyleAction(style: currentPipLayerStyle, orientation: screenOrientation)
    }
    
    /// 切換前後鏡頭 => PreviewLayer層對調 => 順序參考initSettingDaulCamera()
    func exchangeDualCameraAction() {
        
        guard let lastLayer1 = cameraLayerView.layer.sublayers?.popLast() as? AVCaptureVideoPreviewLayer,
              let lastLayer2 = cameraLayerView.layer.sublayers?.popLast() as? AVCaptureVideoPreviewLayer
        else {
            return
        }
        
        isMainLayerInBack.toggle()
        
        UIView._animations(isEnabled: false) { [unowned self] in
            
            lastLayer1.frame = mainView.frame
            lastLayer2.frame = pipView.frame
            
            lastLayer1.cornerRadius = mainView.layer.cornerRadius
            lastLayer2.cornerRadius = pipView.layer.cornerRadius
            
            cameraLayerView.layer.addSublayer(lastLayer1)
            cameraLayerView.layer.addSublayer(lastLayer2)
        }
    }
    
    /// 單指點擊畫面的設定 (防單點 / 雙點)
    /// - Parameter tap: UITapGestureRecognizer
    func singleTapViewAction(with tap: UITapGestureRecognizer) {
        
        if (tap.numberOfTapsRequired == 2) {
            isDoubleTap = true
            exchangeDualCameraAction()
            return
        }
        
        if (tap.numberOfTapsRequired == 1) {
            
            if (!isMainLayerInBack) { return }
            
            isDoubleTap = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [unowned self] in
                if (isDoubleTap) { return }
                _ = cameraFocusPoint(device: cameraInputs.main?.device, withTap: tap)
            }
        }
    }
    
    /// 主鏡頭畫面放大縮小功能 (比原來的比例大一點)
    /// - Parameter scale: CGFloat
    func cameraZoomAction(scale: CGFloat) {
        cameraZoomFactor(zoomFactor.main, scale: scale)
    }
    
    /// 暫時錄影功能
    /// - Parameters:
    ///   - pan: UIPanGestureRecognizer
    ///   - delayTime: TimeInterval
    func temporaryVideoRecording(with button: UIButton, delayTime: TimeInterval) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) { [unowned self] in
            if (isVideoRecording) { return }
            isTemporaryRecording = true
            videoRecodingAction()
        }
    }
    
    /// 暫時錄影功能的鏡頭縮放處理
    /// - Parameter pan: UIPanGestureRecognizer
    func temporaryVideoZoom(with pan: UIPanGestureRecognizer) {
        
        if (!isTemporaryRecording) { return }
        
        let _point = temporaryVideoRecordingPoint
        let point = pan.translation(in: view)
        
        temporaryVideoRecordingPoint = point
        
        if let _point = _point {
            
            let diffY = _point.y - point.y
            let factor = (diffY < 1.0) ? 2.0 : 1.5
            let scale = 1.0 + diffY / view.bounds.width * factor
            
            cameraZoomAction(scale: scale)
        }
    }
    
    /// 停止暫時錄影 (直接存)
    func stopTemporaryVideoRecording() {
        
        if (!isTemporaryRecording) { return }
        
        isTemporaryRecording = false
        temporaryVideoRecordingPoint = nil
        
        stopRecordingAction { [unowned self] url in saveVideoAction(with: url) }
    }
}

// MARK: - 小工具
private extension DaulCameraViewController {
    
    /// [初始化設定](https://www.swiftwithvincent.com/tips)
    func initSetting() {
        
        cleanVideoRecordingParameters()
        closeRecorderTimer()
        
        initSettingDaulCamera()
        initSettingAudio()
        initTakePhotoSetting()
        initGestureRecognizerSetting()
        initTransitionImageViewSetting()
        
        isInitialize = true
        
        videoMainViewFrame = mainView.frame
        videoPipViewFrame = pipView.frame
        pipViewFrame = pipView.frame
    }
    
    /// 初始化縮放項選設定
    func initZoomOptionView() {
        let option: WWCameraZoomOptionView.OptionViewInformation = (UIFont.systemFont(ofSize: 8), .white, .gray.withAlphaComponent(0.7))
        zoomOptionView.configure(with: self, optionViewInformation: option)
    }
    
    /// 註冊手勢功能
    /// - 單指點2下 (主畫面) => 切換前後鏡頭
    /// - 雙指捏合  (主畫面) => 切換鏡頭放大率
    /// - 單指移動  (子畫面) => 移動子視窗畫面功能
    /// - 單指點擊  (子畫面) => 切換子視窗大小 (圓形 / 正方形 / 長方形)
    /// - 單指長按  (子畫面) => 回復PIP的原始尺寸
    /// - 單指移動  (主按鍵) => 切換鏡頭放大率
    /// - 單指按下  (主按鍵) => 及時錄影
    func initGestureRecognizerSetting() {
        
        let tapGesture = UITapGestureRecognizer._build(target: self, action: #selector(Self.handleTapGesture(_:)))
        let doubleTapGesture = UITapGestureRecognizer._build(target: self, numberOfTapsRequired: 2, action: #selector(Self.handleTapGesture(_:)))
        let pinchGesture = UIPinchGestureRecognizer._build(target: self, action: #selector(Self.handlePinchGesture(_:)))
        
        let pipLongPressGesture = UILongPressGestureRecognizer._build(target: self, action: #selector(Self.handleLongPressGesture(_:)))
        let pipTapGesture = UITapGestureRecognizer._build(target: self, action: #selector(Self.handleTapGesture(_:)))
        let pipPanGesture = UIPanGestureRecognizer._build(target: self, action: #selector(Self.handlePanGesture(_:)))
        let pipPinchGesture = UIPinchGestureRecognizer._build(target: self, action: #selector(Self.handlePinchGesture(_:)))
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleVideoRecorderPanGesture))
        
        pipView._addGestureRecognizers([pipPanGesture, pipPinchGesture, pipLongPressGesture, pipTapGesture])
        mainView._addGestureRecognizers([tapGesture, doubleTapGesture, pinchGesture])
        view.addGestureRecognizer(panGesture)
        videoRecorderButton.addTarget(self, action: #selector(handleVideoRecorderClick), for: .touchDown)
    }
    
    /// 初始化設定多鏡頭參數
    func initSettingDaulCamera() {
        
        let inputs: [WWDualCamera.CameraSessionInput] = [
            (frame: mainView.frame, deviceType: .builtInDualWideCamera, position: .back),
            (frame: pipView.frame, deviceType: .builtInWideAngleCamera, position: .front),
        ]
        
        let sessionOutputs = WWDualCamera.shared.sessionOutputs(delegate: self, inputs: inputs, stabilizationMode: .cinematicExtended)
        
        sessionOutputs.forEach { info in
            
            guard let input = info.input,
                  let output = info.output,
                  let previewLayer = info.previewLayer
            else {
                return
            }
            
            switch input.device.position {
            case .back:
                videoDataOutputs.back = output
                cameraInputs.main = (input.device, .FHD)
                
            case .front:
                videoDataOutputs.front = output
                cameraInputs.pip = (input.device, .FHD)
            default:
                break
            }
            
            cameraFocusMode(input.device)
            cameraWhiteBalanceMode(input.device)
            cameraLayerView.layer.addSublayer(previewLayer)
        }
        
        switchPipViewStyleAction()
        cameraZoomAction(scale: initZoomScale)
    }
    
    /// 初始化聲音參數
    func initSettingAudio() {
        
        guard let audio = AVCaptureDevice._default(for: .audio),
              let audioInput = try? audio._captureInput().get()
        else {
            return
        }
        
        if (WWDualCamera.shared.addInputs([audioInput])) {
            
            let audioDataOutput = AVCaptureAudioDataOutput()
            let queue = DispatchQueue(label: "\(Date().timeIntervalSince1970)")
            
            audioDataOutput.setSampleBufferDelegate(self, queue: queue)
            self.audioDataOutput = audioDataOutput
            
            _ = WWDualCamera.shared.addOutputs([audioDataOutput])
        }
    }
    
    /// 初始化擷圖相關的設定
    func initTakePhotoSetting() {
        
        photoOutputs = [AVCapturePhotoOutput(), AVCapturePhotoOutput()]
        _ = WWDualCamera.shared.addOutputs(photoOutputs)
        
        takePhotoClosure = { [unowned self] result in
            
            switch result {
            case .failure(let error): Utility.shared.presentAlertController(target: self, title: Constant.Message.error.output(), message: error.localizedDescription, handler: nil)
            case .success(let photo):
                
                DispatchQueue.main.async { [unowned self] in
                    photos.append(photo)
                    if (photos.count > (photoOutputs.count - 1)) { savePhoto(with: photos, pipLayerStyle: currentPipLayerStyle, screen: .main) }
                }
            }
        }
    }
    
    /// 初始化霧化轉場功能的View
    func initTransitionImageViewSetting() {
        
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        
        transitionImageView.addSubview(blurView)
        transitionImageView.alpha = 0.0
    }
    
    /// 啟動雙鏡頭
    func startDualCameraAction() {
        _ = (!WWDualCamera.shared.isRunning) ? WWDualCamera.shared.start() : WWDualCamera.shared.stop()
    }
    
    /// 設定videoRecorderButton的圖示
    func videoRecorderButtonIcon() {
        
        let image = (!isVideoRecording) ? UIImage(named: "VideoRecoderOn") : UIImage(named: "VideoRecoder_Live")
        videoRecorderButton.setImage(image, for: .normal)
    }
    
    /// 主鏡頭畫面放大縮小功能 (直接設定比例 - 0.5x / 1x / 2x / 5x)
    /// - Parameters:
    ///   - zoomFactor: zoomFactor
    ///   - scale: scale
    func cameraZoomFactor(_ zoomFactor: CGFloat, scale: CGFloat) {
        
        guard let backCamera = cameraInputs.main?.device else { return }
        
        self.zoomFactor.main = zoomFactor * scale
        
        let result = backCamera._zoom(rate: 0.5, factor: self.zoomFactor.main, range: cameraZoomRange)
        
        switch result {
        case .failure(let error):
            
            if let error = error as? Constant.MyError {
                
                switch error {
                case .isTooLarge: self.zoomFactor.main = cameraZoomRange.upperBound
                case .isTooSmall: self.zoomFactor.main = cameraZoomRange.lowerBound
                default: break
                }
            }
            
        case .success(let factor):
            self.zoomFactor.main = factor ?? cameraZoomRange.lowerBound
        }
        
        wwPrint(self.zoomFactor.main)
        zoomFactorValue(self.zoomFactor.main)
    }
        
    /// 儲存影片的相關動作
    /// - Parameter url: URL?
    func saveVideoAction(with url: URL?) {
        
        hasPixelMainScale = false
        
        saveVideo(with: url) { result in
            
            switch result {
            case .failure(let error): wwPrint(error)
            case .success(let isSuccess): wwPrint(isSuccess)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [unowned self] in
                videoRecorderButtonIcon()
                disableButtonsForVideoRecorder(isVideoRecording, orientation: screenOrientation.current)
                UIApplication.shared._awake(isVideoRecording)
            }
        }
    }
    
    /// 儲存圖片 (∵ 前鏡頭的照片會左右相反 ∴ 翻轉再儲存)
    /// - Parameters:
    ///   - photos: [AVCapturePhoto]
    ///   - pipLayerStyle: Constant.PipLayerStyle
    ///   - screen: UIScreen
    func savePhoto(with photos: [AVCapturePhoto], pipLayerStyle: Constant.PipLayerStyle, screen: UIScreen) {
        
        let photo = combinePhotos(photos, pipLayerStyle: pipLayerStyle, screen: screen)
        
        saveImage(with: photo) { result in
            switch result {
            case .failure(let error): wwPrint(error)
            case .success(let isSuccess): wwPrint(isSuccess)
            }
        }
    }
    
    /// 設定圖片預覽
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func previewViewControllerSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? PreviewImageViewController,
              let model = sender as? FileItemModel
        else {
            return
        }
        
        viewController.model = model
    }
    
    /// 將[AVCapturePhoto] => Image (∵ 前鏡頭的照片會左右相反 ∴ 水平翻轉再儲存)
    /// - Parameters:
    ///   - photos: [AVCapturePhoto]
    ///   - pipLayerStyle: Constant.PipLayerStyle
    ///   - screen: UIScreen
    /// - Returns: UIImage?
    func combinePhotos(_ photos: [AVCapturePhoto], pipLayerStyle: Constant.PipLayerStyle, screen: UIScreen) -> UIImage? {
        
        guard let firstPhoto = photos.first?._image(),
              let middlePhoto = photos[safe: 1]?._image(),
              let lastPhoto = photos.last?._image(),
              let mainPicture = (isMainLayerInBack) ? firstPhoto : firstPhoto._flip(with: .leftMirrored),
              let mainTempPicture = (isMainLayerInBack) ? middlePhoto : firstPhoto._flip(with: .leftMirrored),
              let pipPhoto = (!isMainLayerInBack) ? lastPhoto : lastPhoto._flip(with: .leftMirrored)
        else {
            return nil
        }
        
        let mainPhoto = (isUltraWideCamera) ? mainTempPicture : mainPicture
        let pipPhotoRate = mainPhoto.size.width / pipPhoto.size.width
        let mainViewRate = videoPipViewFrame.width / videoMainViewFrame.width
        let mainWidthRate = mainPhoto.size.width / videoMainViewFrame.width
        let pipViewPosition = mainView._point(from: pipView)
        
        let pipSize = pipPhoto.size * mainViewRate * pipPhotoRate
        let scale = screen.scale
        let fixHeight = (pipSize.height - pipSize.width) * 0.5
        
        var pipPosition = pipViewPosition * mainWidthRate
        var pipImage = pipPhoto
        var radius = 0.0
        
        switch pipLayerStyle {
        case .circle:
            radius = pipSize.width * 0.5 * scale
            pipImage = pipImage.squareMasked(cornerRadius: radius)
            pipPosition = CGPoint(x: pipPosition.x, y: pipPosition.y - fixHeight)
            
        case .square(let _radius):
            radius = _radius * mainWidthRate * scale
            pipImage = pipImage.squareMasked(cornerRadius: radius)
            pipPosition = CGPoint(x: pipPosition.x, y: pipPosition.y - fixHeight)
            
        case .rectangle(_, let _radius):
            radius = _radius * mainWidthRate * scale
            pipImage = pipImage._roundedCorners(radius: radius) ?? pipImage
        }
        
        return mainPhoto._combinePipImage(pipImage, pipRect: CGRect(origin: pipPosition, size: pipSize))
    }
    
    /// 儲存圖片到相簿
    /// - Parameters:
    ///   - image: UIImage?
    ///   - result: (Result<Bool, Error>) -> Void)
    func saveImage(with image: UIImage?, result: @escaping ((Result<Bool, Error>) -> Void)) {
        
        PHPhotoLibrary.shared()._saveImage(image) { _result in
            switch _result {
            case .failure(let error): result(.failure(error))
            case .success(let isSuccess): result(.success(isSuccess))
            }
        }
    }
    
    /// 設定子畫面的中點位置
    /// - Parameter center: CGPoint?
    func pipLayerCenterSetting(_ center: CGPoint?) {
        
        guard let center = center,
              let sublayers = cameraLayerView.layer.sublayers
        else {
            return
        }
        
        pipLayerCenter = center
        pipView.center = center
        pipViewFrame = pipView.frame
        
        sublayers.last?.frame = pipViewFrame
    }
    
    /// 切換PipView的外型 (圓形 / 正方形 / 長方形)
    /// - Parameters:
    ///   - style: Constant.PipLayerStyle
    ///   - orientation: Constant.ScreenOrientation
    func exchangePipViewStyleAction(style: Constant.PipLayerStyle, orientation: Constant.ScreenOrientation) {
        
        guard let count = cameraLayerView.layer.sublayers?.count else { return }
        
        switch style {
        case .circle:
            pipViewWidthLayoutConstraint.constant = pipViewDiameter
            pipViewHeightLayoutConstraint.constant = pipViewDiameter
            pipView.layer.cornerRadius = pipViewFrame.width * 0.5
            
        case .square(let cornerRadius):
            pipViewWidthLayoutConstraint.constant = pipViewDiameter + 0.001
            pipViewHeightLayoutConstraint.constant = pipViewDiameter + 0.001
            pipView.layer.cornerRadius = cornerRadius
            
        case .rectangle(let scale, let cornerRadius):
            
            let _orientation = orientation.item
            
            switch _orientation {
            case .up, .down:
                pipViewWidthLayoutConstraint.constant = pipViewDiameter
                pipViewHeightLayoutConstraint.constant = pipViewDiameter * scale
                
            case .left, .right:
                pipViewWidthLayoutConstraint.constant = pipViewDiameter * scale
                pipViewHeightLayoutConstraint.constant = pipViewDiameter
            
            default:
                                
                switch screenOrientation.item {
                
                case .up, .down, .upMirrored, .downMirrored:
                    pipViewWidthLayoutConstraint.constant = pipViewDiameter
                    pipViewHeightLayoutConstraint.constant = pipViewDiameter * scale
                    
                case .left, .right, .leftMirrored, .rightMirrored:
                    pipViewWidthLayoutConstraint.constant = pipViewDiameter * scale
                    pipViewHeightLayoutConstraint.constant = pipViewDiameter
                    
                @unknown default: fatalError()
                }
            }
            
            pipView.layer.cornerRadius = cornerRadius
        }
        
        cameraLayerView.layoutIfNeeded()
        cameraLayerView.layer.sublayers?[safe: count - 1]?.frame = pipView.frame
        cameraLayerView.layer.sublayers?[safe: count - 1]?.cornerRadius = pipView.layer.cornerRadius

        pipLayerCenterSetting(pipLayerCenter)
        fixVideoPipViewFrame()
    }
    
    /// 設定SubLayer的外形選項 => 圓形 / 正方形 / 長方形
    /// - Returns: [Constant.SubLayerStyle]
    func pipLayerStyleMaker() -> [Constant.PipLayerStyle] {
        
        let styles: [Constant.PipLayerStyle] = [
            .circle,
            .square(cornerRadius: 16.0),
            .rectangle(scale: videoScale, cornerRadius: 16.0),
        ]
        
        return styles
    }
    
    /// 自訂放大率選單的選項 => 0.5x / 1.0x / 2.0x / 5.0x
    /// - Returns: [Double]
    func sequenceZoomItemMaker() -> [Double] {
        let sequenceZooms = [1.0, 2.0, 3.0, 6.0]
        return sequenceZooms
    }
    
    /// 修正因為pipView縮放造成的影響
    func fixVideoPipViewFrame() {
        
        let fixPipViewSize = CGSize(width: pipViewFrame.width, height: pipViewFrame.width * videoScale)
        videoPipViewFrame = CGRect(origin: pipViewFrame.origin, size: fixPipViewSize)
    }
    
    /// 切換相機閃光燈模式
    /// - Parameter flashMode: AVCaptureDevice.FlashMode
    func switchCameraFlashMode(_ flashMode: AVCaptureDevice.FlashMode) {
        
        currentCameraFlashMode = flashMode
        cameraFlashIcon(flashMode: currentCameraFlashMode)
    }
    
    /// 閃光燈的圖示設定
    /// - Parameter flashMode: AVCaptureDevice.FlashMode
    func cameraFlashIcon(flashMode: AVCaptureDevice.FlashMode) {
        
        let image = switch flashMode {
            case .on: UIImage(named: "FlashOn")
            case .off: UIImage(named: "FlashOff")
            default: UIImage(named: "FlashAuto")
        }
        
        cameraFlashModeButton.setImage(image, for: .normal)
    }
    
    /// 切換相機手電筒模式
    /// - Parameter torchMode: AVCaptureDevice.TorchMode
    func toggleTorchMode(_ torchMode: AVCaptureDevice.TorchMode) {
        
        guard let device = cameraInputs.main?.device else { return }
        
        switch device._torchMode(torchMode) {
        case .failure(_): break
        case .success(let torchMode): 
            currentTorchMode = torchMode
            torchIcon(torchMode: torchMode)
        }
    }
    
    /// 相機手電筒的圖示設定
    /// - Parameter torchMode: AVCaptureDevice.TorchMode
    func torchIcon(torchMode: AVCaptureDevice.TorchMode) {
        
        let image = switch torchMode {
        case .on, .auto: UIImage(named: "TorchOn")
        case .off: UIImage(named: "TorchOff")
        @unknown default: fatalError()
        }
        
        torchButton.setImage(image, for: .normal)
    }
        
    /// 錄影開始後，禁止使用的按鍵設定
    /// - Parameters:
    ///   - isDisable: Bool
    ///   - orientation: UIDeviceOrientation
    func disableButtonsForVideoRecorder(_ isDisable: Bool, orientation: UIDeviceOrientation) {
        
//        let isEnabled = !isDisable
//        let audioRecorderImageName = isEnabled ? "AudioRecorderOn" : "AudioRecorderOff"
//        audioRecorderButton.isEnabled = isEnabled
//        audioRecorderButton.setImage(UIImage(named: audioRecorderImageName), for: .normal)
        
        disableButtons(isDisable, orientation: orientation)
    }
    
    /// 錄音開始後，禁止使用的按鍵設定
    /// - Parameters:
    ///   - isDisable: Bool
    ///   - orientation: UIDeviceOrientation
    func disableButtonsForAudioRecorder(_ isDisable: Bool, orientation: UIDeviceOrientation) {
        
        let isEnabled = !isDisable
        let videoRecorderImageName = isEnabled ? "VideoRecoderOn" : "VideoRecoderOff"
        
        videoRecorderButton.isEnabled = isEnabled
        videoRecorderButton.setImage(UIImage(named: videoRecorderImageName), for: .normal)
        
        disableButtons(isDisable, orientation: orientation)
    }
    
    /// 共同禁止使用的按鍵設定
    /// - Parameters:
    ///   - isDisable: Bool
    ///   - orientation: UIDeviceOrientation
    func disableButtons(_ isDisable: Bool, orientation: UIDeviceOrientation) {
        
        let isEnabled = !isDisable
        let cameraImageName = isEnabled ? "CameraOn" : "CameraOff"
        let cameraFlashMode = isEnabled ? currentCameraFlashMode : .off
        let videoDefinitionImageName: String
        
        switch videoDefinition {
        case .FHD: videoDefinitionImageName = isEnabled ? "FHD" : "FHD_Lock"
        case .UHD: videoDefinitionImageName = isEnabled ? "UHD" : "UHD_Lock"
        }
        
        videoDefinitionButton.isEnabled = isEnabled
        cameraButton.isEnabled = isEnabled
        cameraFlashModeButton.isEnabled = isEnabled
        capacityLabel.isEnabled = isEnabled
        
        videoDefinitionButton.setImage(UIImage(named: videoDefinitionImageName), for: .normal)
        cameraButton.setImage(UIImage(named: cameraImageName), for: .normal)
                
        cameraFlashIcon(flashMode: cameraFlashMode)
        itemsOrientationImage(orientation)
    }
        
    /// 動態模糊效果
    /// - Parameter duration: TimeInterval
    func visualEffectAnimation(duration: TimeInterval) {
        
        let effectView = UIVisualEffectView._build(frame: view.bounds, style: .systemThickMaterialDark)
        let animator = UIViewPropertyAnimator(duration: duration, curve: .linear) { effectView.alpha = 0.0 }
        
        view.addSubview(effectView)
        effectView.alpha = 1.0
        
        animator.addCompletion { _ in effectView.removeFromSuperview() }
        animator.startAnimation()
    }
    
    /// 設定鏡頭的自動對焦功能
    /// - Parameter device: AVCaptureDevice?
    func cameraFocusMode(_ device: AVCaptureDevice?) {
        
        guard let device = device else { return }
        _ = device._focusMode(Constant.shared.focusMode, point: Constant.shared.focusPointOfInterestPoint)
    }
    
    /// 設定鏡頭的白平衡模式
    /// - Parameter device: AVCaptureDevice?
    func cameraWhiteBalanceMode(_ device: AVCaptureDevice?) {
        
        guard let device = device else { return }
        _ = device._whiteBalanceMode(.continuousAutoWhiteBalance)
    }
}

// MARK: - 錄音功能
private extension DaulCameraViewController {
    
    /// 錄音功能切換
    func audioRecodingAction() {
        
        if (!isAudioRecording) { audioStartRecording(); return }
        audioStopRecording()
    }
    
    /// 開始錄音
    func audioStartRecording() {
        
        guard let url = Utility.shared.audioUrl() else { return }
        
        let result = AVAudioRecorder._build(recordURL: url, delegate: self)
        
        switch result {
        case .failure(let error): Utility.shared.presentAlertController(target: self, title: Constant.Message.error.output(), message: error.localizedDescription, handler: nil)
        case .success(let audioRecorder):
            
            switch audioRecorder._record() {
            case .failure(let error): Utility.shared.presentAlertController(target: self, title: Constant.Message.error.output(), message: error.localizedDescription, handler: nil)
            case .success(let isSuccess): wwPrint(isSuccess)
            }
            
            self.audioRecorder = audioRecorder
            isAudioRecording = true
            startRecoderTimer(backgroundColor: UIColor(red: 0, green: 204 / 255, blue: 153 / 255, alpha: 1.0))
            
            disableButtonsForAudioRecorder(isAudioRecording, orientation: screenOrientation.current)
            
            UIApplication.shared._awake(isAudioRecording)
        }
    }
    
    /// 停止錄音
    func audioStopRecording() {
        
        isAudioRecording = false
        
        _ = audioRecorder?._stop()
        audioRecorder = nil
        
        closeRecorderTimer()
        disableButtonsForAudioRecorder(isAudioRecording, orientation: screenOrientation.current)
        UIApplication.shared._awake(isAudioRecording)
    }
}

// MARK: - 雙鏡頭錄影功能
private extension DaulCameraViewController {
        
    /// [開始錄影 + 建立緩衝池](https://developer.apple.com/documentation/avfoundation/capture_setup/avmulticampip_capturing_from_multiple_cameras)
    func videoStartRecording() {
        
        let outputURL = Utility.shared.videoUrl()
        let result = AVAssetWriter._build(outputURL: outputURL, fileType: Constant.shared.fileType.video)
        
        _ = videoDataOutOrientationSetting()
        
        switch result {
        case .failure(let error): Utility.shared.presentAlertController(target: self, title: Constant.Message.error.output(), message: error.localizedDescription, handler: nil)
        case .success(let assetWriter):
            
            let videoWriterInput = AVAssetWriterInput._buildVideo(size: videoSize, codec: .hevc)
            let audioWriterInput = AVAssetWriterInput._buildAudio(format: kAudioFormatMPEG4AAC)
            
            self.assetWriter = assetWriter
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor._build(videoWriterInput: videoWriterInput, vedioSize: videoSize)
            
            if assetWriter._canAdd(input: videoWriterInput) { self.videoWriterInput = videoWriterInput }
            if assetWriter._canAdd(input: audioWriterInput) { self.audioWriterInput = audioWriterInput }
            
            assetWriter.startWriting()
            startRecoderTimer(backgroundColor: .systemPink)
            
            isVideoRecording = true
            isSessionStarted = false
        }
        
        pixelBufferPool = CVPixelBufferPool._build(minimumBufferCount: Constant.shared.minimumVideoBufferPoolCount, videoSize: videoSize)
        pipViewFrame = pipView.frame
        pipLayerCenter = pipView.center
        
        videoRecorderButtonIcon()
        disableButtonsForVideoRecorder(isVideoRecording, orientation: screenOrientation.current)
        
        UIApplication.shared._awake(true)
    }
    
    /// 根據當時的手機畫面方向設定影片輸出的方向 (直的 / 橫的)
    /// - Parameter `default`: AVCaptureVideoOrientation
    /// - Returns: [Bool]?
    func videoDataOutOrientationSetting(`default`: AVCaptureVideoOrientation = .portrait) -> [Bool]? {
        
        guard let backOutout = videoDataOutputs.back,
              let frontOutout = videoDataOutputs.front
        else {
            return nil
        }
        
        let orientation = screenOrientation.current._videoOrientation() ?? `default`
        var isSuccesses: [Bool] = []

        [backOutout, frontOutout].forEach { output in
            let isSuccess = output._videoOrientation(orientation)
            isSuccesses.append(isSuccess)
        }
        
        return isSuccesses
    }
    
    /// 手機剩餘空間測試
    /// - Parameters:
    ///   - folderType: 哪個資料夾
    ///   - minCapacity: 最少剩餘空間
    func checkAvailableCapacity(folderType: Constant.FileManagerDirectoryType, minCapacity: Int = 200_000_000) -> Bool {
        
        let result = FileManager.default._availableCapacity(type: folderType)
        
        var isCapacityTooSmall = false
        
        switch result {
        case .failure(let error): Utility.shared.presentAlertController(target: self, title: Constant.Message.error.output(), message: error.localizedDescription, handler: nil)
        case .success(let capacity):
            
            isCapacityTooSmall = capacity < minCapacity
            
            if (isCapacityTooSmall) { capacityLabel.textColor = .red }
            capacityLabel.text = capacity._bytes(units: .useMB)
        }
        
        return isCapacityTooSmall
    }
    
    /// 開始定時取得手機剩餘空間 + 計時
    /// - Parameters:
    ///   - timeInterval: TimeInterval
    ///   - backgroundColor: UIColor?
    func startRecoderTimer(withTimeInterval timeInterval: TimeInterval = 1.0, backgroundColor: UIColor?) {
        
        closeRecorderTimer()
        recorderTimeView.isHidden = false
        recorderTimeView.backgroundColor = backgroundColor
        
        capacitytTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { [unowned self] _ in
            _ = checkAvailableCapacity(folderType: Constant.shared.folderType)
            recorderTimeLabel.text = recorderTimeInterval._time()
            recorderTimeInterval += timeInterval
        })
        
        capacitytTimer?.fire()
    }
    
    /// 停止取得手機剩餘空間 + 計時
    func closeRecorderTimer() {
        
        capacitytTimer?.invalidate()
        capacitytTimer = nil
        
        recorderTimeInterval = 0.0
        recorderTimeLabel.text = recorderTimeInterval._time()
        recorderTimeLabel._monoSystemFont(weight: .bold)
        
        recorderTimeView.isHidden = true
    }
    
    /// 停止錄影提示框
    /// - Parameter action: (URL?) -> Void
    func videoStopRecording(action: @escaping (URL?) -> Void) {
        
        Utility.shared.presentComfireAlertController(target: self, title: Constant.Message.reminder.output(), message: Constant.Message.stopRecording.output()) { [unowned self] in
            isVideoRecording = true
        } surehandler: { [unowned self] in
            stopRecordingAction(action)
        }
    }
    
    /// 停止錄影
    /// - Parameter action: (URL?) -> Void
    func stopRecordingAction(_ action: @escaping (URL?) -> Void) {
        
        isVideoRecording = false
        
        videoWriterInput?.markAsFinished()
        audioWriterInput?.markAsFinished()
        
        assetWriter?.finishWriting { [unowned self] in
            action(assetWriter?.outputURL)
            DispatchQueue.main.async { [unowned self] in closeRecorderTimer() }
        }
    }
    
    /// 清除錄影參數
    func cleanVideoRecordingParameters() {
        
        isSessionStarted = false
        isVideoRecording = false

        startTime = nil
        assetWriter = nil
        videoWriterInput = nil
        audioWriterInput = nil
        pixelBufferAdaptor = nil
    }
    
    /// 處理取到的聲音Buffer
    /// - Parameters:
    ///   - sampleBuffer: CMSampleBuffer
    func captureAudioAction(sampleBuffer: CMSampleBuffer) {
        
        guard let assetWriter = assetWriter,
              isVideoRecording,
              assetWriter.status == .writing
        else {
            return
        }
        
        if (isSessionStarted) { appendAudioBuffer(sampleBuffer) }
    }
    
    /// 處理取到的影片Buffer
    /// - Parameters:
    ///   - output: AVCaptureOutput
    ///   - sampleBuffer: CMSampleBuffer
    ///   - connection: AVCaptureConnection
    func captureVideoAction(output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let assetWriter = assetWriter,
              isVideoRecording,
              assetWriter.status == .writing
        else {
            return
        }
        
        if (!isSessionStarted) {
            let startTime = sampleBuffer.presentationTimeStamp
            assetWriter._startSession(at: startTime) { isSessionStarted = true }
        } else {
            _ = appendSampleBuffer(sampleBuffer)
        }
    }
    
    /// [加入sampleBuffer到audioWriterInput中 <=> assetWriter](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/zed-ide-的基本操作和-ai-功能初體驗-961657f549d3)
    /// - Parameter sampleBuffer: CMSampleBuffer
    func appendAudioBuffer(_ sampleBuffer: CMSampleBuffer) {
        
        guard let audioWriterInput = audioWriterInput,
              audioWriterInput.isReadyForMoreMediaData
        else {
            return
        }
        
        audioWriterInput.append(sampleBuffer)
    }
    
    /// 加入CMSampleBuffer到pixelBufferAdaptor中 <=> assetWriter
    /// - Parameter sampleBuffer: CMSampleBuffer
    func appendSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> Bool {
        
        let pixelBuffer = sampleBuffer.imageBuffer
        let startTime = sampleBuffer.presentationTimeStamp
        
        return appendPixelBuffer(pixelBuffer, startTime: startTime)
    }
    
    /// 加入CVPixelBuffer到pixelBufferAdaptor中 <=> assetWriter
    /// - Parameters:
    ///   - pixelBuffer: CVPixelBuffer?
    ///   - startTime: CMTime
    /// - Returns: Bool
    func appendPixelBuffer(_ pixelBuffer: CVPixelBuffer?, startTime: CMTime) -> Bool {
        
        guard let pixelBuffer = pixelBuffer,
              let videoWriterInput = videoWriterInput,
              videoWriterInput.isReadyForMoreMediaData
        else {
            return false
        }
        
        self.startTime = startTime
        pixelBufferAdaptor?.append(pixelBuffer, withPresentationTime: startTime)
        
        return true
    }
}

// MARK: - 處理圖片遮罩
private extension DaulCameraViewController {
    
    /// 依照比例去求出在影片上的Frame => 座標 (UIKit => CoreVideo) / 尺寸轉換 (414,736 => 1080,1920)
    /// => 鏡頭錄的都是16:9，後面再用遮罩去處理 (mainPipViewFrameSize)
    /// - Parameters:
    ///   - pixelBuffer:  CVPixelBuffer?
    ///   - pipLayerStyle: Constant.PipLayerStyle
    ///   - mainFrame: CGRect
    ///   - orientation: UIImage.Orientation
    /// - Returns: CGRect?
    func pipVideoFrameConvert(pixelBuffer: CVPixelBuffer?, pipLayerStyle: Constant.PipLayerStyle, for mainFrame: CGRect, with orientation: UIImage.Orientation) -> CGRect? {
        
        guard let pixelBuffer = pixelBuffer else { return nil }
        
        let pipPosition = mainView._point(from: pipView)
        let newSize = videoPipViewFrame.size * pixelMainScale
        
        var newPosition = pipVideoPosition(pixelBuffer: pixelBuffer, position: pipPosition, size: newSize, orientation: orientation)
        
        switch pipLayerStyle {
        case .circle, .square(_): newPosition.y += newSize.width * 0.5
        case .rectangle(_, _): break
        }
        
        return CGRect(origin: newPosition, size: newSize)
    }
    
    /// 轉換Pip在影片中的真實位置
    /// - Parameters:
    ///   - pixelBuffer: CVPixelBuffer
    ///   - position: CGPoint
    ///   - size: CGSize
    ///   - orientation: UIImage.Orientation
    /// - Returns: CGPoint
    func pipVideoPosition(pixelBuffer: CVPixelBuffer, position: CGPoint, size: CGSize, orientation: UIImage.Orientation) -> CGPoint {
        
        let pixelBufferSize = pixelBuffer._size()
        var newPosition: CGPoint
        
        switch orientation {
        case .up, .upMirrored:
            let x = position.x * pixelMainScale
            let y = pixelBufferSize.height - position.y * pixelMainScale - size.height
            newPosition = CGPoint(x: x, y: y)
            
        case .down, .downMirrored:
            let x = pixelBufferSize.width - position.x * pixelMainScale - size.width
            let y = position.y * pixelMainScale
            newPosition = CGPoint(x: x, y: y)
            
        case .left, .leftMirrored:
            let x = position.y * pixelMainScale
            let y = position.x * pixelMainScale
            newPosition = CGPoint(x: x, y: y)
            
        case .right, .rightMirrored:
            let x = pixelBufferSize.width - position.y * pixelMainScale - size.width
            let y = pixelBuffer._size().height - position.x * pixelMainScale - size.height
            newPosition = CGPoint(x: x, y: y)
            
        @unknown default: fatalError()
        }
        
        return newPosition
    }
    
    /// 計算出影像跟手機畫面的尺寸比例值 (寬度為準 => 滿版 / 寬 <=> 高)
    /// - Parameters:
    ///   - pixelBuffer: CVPixelBuffer?
    ///   - view: UIView
    ///   - orientation: UIDeviceOrientation
    /// - Returns: CGFloat
    func pixelBufferScale(_ pixelBuffer: CVPixelBuffer?, for viewFrame: CGRect, orientation: UIImage.Orientation) -> CGFloat {
        
        guard let pixelBuffer = pixelBuffer else { return videoScale }
        
        let scale: CGFloat
        
        switch orientation {
        case .up, .upMirrored, .down, .downMirrored: scale = pixelBuffer._size().width / viewFrame.width
        case .left, .leftMirrored, .right, .rightMirrored: scale = pixelBuffer._size().width / viewFrame.height
        default: scale = videoScale
        }
                
        return scale
    }
    
    /// 處理遮罩的影像圖形 => 圓角 / 圓形
    /// - Parameters:
    ///   - ciImage: CIImage
    ///   - pixelScale: UIKit跟CoreVideo上的圖像比例
    ///   - layerStyle: PIP的外觀類型
    /// - Returns: CIImage?
    func maskedImageMaker(ciImage: CIImage, pixelScale: CGFloat, layerStyle: Constant.PipLayerStyle) -> CIImage? {
        
        guard let pipLayerCenter = pipLayerCenter else { return nil }
        
        switch layerStyle {
        case .rectangle(_, let radius): return ciImage._roundedCorners(radius: radius * pixelScale)
        case .square(let radius): return squareMaskedImage(from: ciImage, viedoLayerCenter: pipLayerCenter * pixelScale, radius: radius * pixelScale)
        case .circle: return circleMaskedImage(from: ciImage, viedoLayerCenter: pipLayerCenter * pixelScale)
        }
    }
    
    /// 處理正方形遮罩圖片
    /// - Parameters:
    ///   - inputImage: 原圖片
    ///   - viedoLayerCenter: 在影片上的中點位置
    ///   - radius: 圓角半徑
    /// - Returns: CIImage?
    func squareMaskedImage(from inputImage: CIImage, viedoLayerCenter: CGPoint, radius: CGFloat) -> CIImage? {
        
        guard let shorterSide = Optional.some(inputImage.extent.size._shorterSide()),
              let squareSize = Optional.some(CGSize(width: shorterSide, height: shorterSide)),
              let squareMask = CIImage._roundedRectangle(radius: radius, extent: CGRect(origin: .zero, size: squareSize))
        else {
            return nil
        }
        
        let centerPoint = CGPoint(
            x: viedoLayerCenter.x - shorterSide * 0.5,
            y: CGFloat(videoSize.height) - viedoLayerCenter.y - shorterSide * 0.5
        )
        
        let centerMaskImage = squareMask.transformed(by: CGAffineTransform(translationX: centerPoint.x, y: centerPoint.y))
        let outputImage = inputImage._maskImage(with: centerMaskImage)
        
        return outputImage?.cropped(to: CGRect(origin: CGPoint(x: centerPoint.x, y: centerPoint.y), size: squareSize))
    }
    
    /// 處理圓形遮罩圖片
    /// - Parameters:
    ///   - inputImage: 原圖片
    ///   - viedoLayerCenter: 在影片上的中點位置
    /// - Returns: CIImage?
    func circleMaskedImage(from inputImage: CIImage, viedoLayerCenter: CGPoint) -> CIImage? {
        return squareMaskedImage(from: inputImage, viedoLayerCenter: viedoLayerCenter, radius: inputImage.extent.width * 0.5)
    }
}

// MARK: - 處理影音流
private extension DaulCameraViewController {
        
    /// 儲存影片到相簿
    /// - Parameters:
    ///   - url: URL?
    ///   - result: (Result<Bool, Error>) -> Void
    func saveVideo(with url: URL?, result: @escaping ((Result<Bool, Error>) -> Void)) {
        
        cleanVideoRecordingParameters()
        
        PHPhotoLibrary.shared()._saveVideo(at: url) { _result in
            
            switch _result {
            case .failure(let error): result(.failure(error))
            case .success(let isSuccess): result(.success(isSuccess))
            }
        }
    }
    
    /// 開始播放 / 分享影片 (AVPlayerViewController)
    /// - Parameters:
    ///   - videoURL: URL
    ///   - shareAction: Selector?
    ///   - removeAction: Selector?
    func pushVideoPlayerViewController(videoURL: URL, shareAction: Selector?, removeAction: Selector?) {
        
        guard let playerViewController = Utility.shared.shareVideoPlayerViewController(target: self, videoURL: videoURL, shareAction: shareAction, removeAction: removeAction) else { return }
        
        self.videoURL = videoURL
        self.playerViewController = playerViewController
        
        navigationController?.isToolbarHidden = false
        navigationController?.pushViewController(playerViewController, animated: true)
    }
    
    /// 分享選到的影音檔 (UIActivityViewController)
    func shareMediaAction() {
        
        guard let videoURL = videoURL,
              let playerViewController = playerViewController
        else {
            return
        }
        
        let activityViewController = UIActivityViewController._build(activityItems: [videoURL])
        present(activityViewController, animated: true) { playerViewController.player?.pause() }
    }
    
    /// 移除選到的影音檔 (FileManager)
    func removeMediaAction() {
        
        guard let videoURL = videoURL else { return }
        
        let result = FileManager.default._removeFile(at: videoURL)
        
        switch result {
        case .failure(let error): Utility.shared.presentAlertController(target: self, title: Constant.Message.error.output(), message: error.localizedDescription, handler: nil)
        case .success(let isSuccess):
            
            if (isSuccess) {
                self.videoURL = nil
                navigationController?.popViewController(animated: true)
            }
        }
    }
    
    /// 處理主畫面的CMSampleBuffer + 鏡射 => 後鏡頭
    /// - Parameters:
    ///   - sampleBuffer: CMSampleBuffer
    ///   - connection: AVCaptureConnection
    func processMainVideo(sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = sampleBuffer.imageBuffer,
              connection._videoMirror(!isMainLayerInBack)
        else {
            return
        }
        
        let presentationTimeStamp = sampleBuffer.presentationTimeStamp
        videoPixelBuffers.back = pixelBuffer
        
        if (!hasPixelMainScale) {
            pixelMainScale = pixelBufferScale(pixelBuffer, for: videoMainViewFrame, orientation: screenOrientation.item)
            hasPixelMainScale = true
        }
        
        DispatchQueue.main.async { [unowned self] in
            
            guard let pipImageFrame = pipVideoFrameConvert(pixelBuffer: sampleBuffer.imageBuffer, pipLayerStyle: currentPipLayerStyle, for: videoMainViewFrame, with: screenOrientation.item) else { return }
            
            processingViedoQueue.async { [unowned self] in
                _ = processOutputVideo(startTime: presentationTimeStamp, pipImageFrame: pipImageFrame)
            }
        }
    }
    
    /// 處理PIP畫面的CMSampleBuffer + 鏡射 => 前鏡頭
    /// - Parameters:
    ///   - sampleBuffer: CMSampleBuffer
    ///   - connection: AVCaptureConnection
    func processPipVideo(sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = sampleBuffer.imageBuffer,
              connection._videoMirror(isMainLayerInBack)
        else {
            return
        }
        
        videoPixelBuffers.front = pixelBuffer
    }
    
    /// 處理聲音
    /// - Parameter sampleBuffer: CMSampleBuffer
    func processAudio(sampleBuffer: CMSampleBuffer) {
        
        processingAudioQueue.async { [unowned self] in
            captureAudioAction(sampleBuffer: sampleBuffer)
        }
    }
    
    /// 處理雙鏡頭影像合成輸出
    /// - Parameters:
    ///   - startTime: CMTime
    ///   - pipImageFrame: CGRect
    func processOutputVideo(startTime: CMTime, pipImageFrame: CGRect) -> Bool {
        
        guard let mainPixelBuffer = videoPixelBuffers.back,
              let outputPixelBuffer = CVPixelBuffer._build(pixelBufferPool: pixelBufferPool),
              var outputImage = mainPixelBuffer._ciImage()._roundedCorners(radius: cameraLayerViewCornerRadius * pixelMainScale)
        else {
            return false
        }
        
        let context = CIContext()
        
        if let pipPixelBuffer = videoPixelBuffers.front {
            
            let mainImage = outputImage
            let transformedPipImage = mainPixelBuffer._transformPipImage(buffer: pipPixelBuffer, imageFrame: pipImageFrame)
            let maskedImage = maskedImageMaker(ciImage: transformedPipImage, pixelScale: pixelMainScale, layerStyle: currentPipLayerStyle)
            
            if let combineImage = CIFilter._combine(sourceOverCompositing: mainImage, pipImage: maskedImage ?? transformedPipImage) {
                outputImage = combineImage
            }
        }
        
        context.render(outputImage, to: outputPixelBuffer)
        return appendPixelBuffer(outputPixelBuffer, startTime: startTime)
    }
}

