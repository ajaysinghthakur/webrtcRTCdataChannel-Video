//
//  RTCVideoViewController.swift
//  webrtcClientTutorialpoint
//
//  Created by ajay singh thakur on 08/06/17.
//  Copyright © 2017 ajay singh thakur. All rights reserved.
//

import UIKit
import Starscream
import AVFoundation

let TAG = "ajay"
class RTCVideoViewController: UIViewController {

    
    //local id's
   
    let VIDEO_TRACK_ID = TAG + "VIDEO"
    let AUDIO_TRACK_ID = TAG + "AUDIO"
    let LOCAL_MEDIA_STREAM_ID = TAG + "STREAM"
    
    //msg types
    enum MsgType: String {
        case login = "login"
        case offer = "offer"
        case answer = "answer"
        case candidate = "candidate"
        case leave = "leave"
        case error
        init(fromRawValue: String){
            self = MsgType(rawValue: fromRawValue) ?? .error
        }
        var description: String {
            return self.rawValue
        }
    }
    
    //containers
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var loginView: UIView!
    
    //login
    @IBOutlet weak var nameTextField: UITextField!
    
   
    //socket
    var socket : WebSocket?
    
    // initilizing webrtc
    var peerConnection : RTCPeerConnection?
    var webRtcClient : RTCPeerConnectionFactory?
    
    //stun server
    let stunServer : String = "stun:stun.l.google.com:19302"//stun:stun.1.google.com:19302
    
    //video view
    @IBOutlet weak var remoteVideoView: RTCEAGLVideoView!
    @IBOutlet weak var localVideoView: RTCEAGLVideoView!
    
    //streams
    var localMediaStream: RTCMediaStream!
    var localVideoTrack: RTCVideoTrack!
    var localAudioTrack: RTCAudioTrack!
    var remoteVideoTrack: RTCVideoTrack!
    var remoteAudioTrack: RTCAudioTrack!
    
    @IBOutlet weak var otherUserName: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //init socket
        //self.socket = WebSocket(url: URL(string: "ws://192.168.1.47:9090")!)
        self.socket = WebSocket(url: URL(string: "ws://127.0.0.1:9090")!)
        self.socket?.delegate = self
        self.socket?.connect()
        
        self.isHiddenLoginView(false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
       
        //remove everything
        socket?.disconnect()
        RTCPeerConnectionFactory.deinitializeSSL()
       
    }
    
    func isHiddenLoginView(_ bool : Bool) -> Void {
        self.loginView.isHidden = bool
        self.videoView.isHidden = !bool
    }

    //MARK: Button Actions
    
    @IBAction func loginButtonAction(_ sender: Any) {
        
        if (nameTextField.text?.characters.count)! > 0 {
            
            let dict = ["type": "login",
                        "name": nameTextField.text!]
            
            if (socket?.isConnected)!{
                
                let jsonString = dict.json
                socket?.write(string: jsonString)
            }
            
            
        }
        
    }
    
    @IBAction func audioButtonAction(_ sender: Any) {
        
    }
    
    @IBAction func videoButtonAction(_ sender: Any) {
        
        
    }
    
    @IBAction func hangUpButtonAction(_ sender: Any) {
        
        
    }
    
    @IBAction func callButtonAction(_ sender: Any) {
        
        
        // create Offer 
        //prepate connection and local stream
        let constraint = self.createAudioVideoConstraints()
        self.peerConnection?.add(localMediaStream)
        
        // create offer
        self.peerConnection?.createOffer(with: self, constraints: constraint)
        

        
        
    }
    
    
    
    
}
extension RTCVideoViewController {

    //MARK: WebRTC Custom Methods
    
    func initalizeWebRTC() -> Void {
        
        RTCPeerConnectionFactory.initializeSSL()
        self.webRtcClient  = RTCPeerConnectionFactory.init()
        let stunServer = self.defaultStunServer()
        let defaultConstraint = self.createDefaultConstraint()
        self.peerConnection = self.webRtcClient?.peerConnection(withICEServers: [stunServer], constraints: defaultConstraint, delegate: self)
        
        self.localVideoView.delegate = self
        self.remoteVideoView.delegate = self
        // webrtc initalized local rendering of video on
        self.addLocalMediaStrem()
        
    }
    
    func addLocalMediaStrem() -> Void {
    
        var device: AVCaptureDevice! = nil
        if #available(iOS 10.0, *) {
             device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front)
        } else {
            // Fallback on earlier versions
            for captureDevice in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
                if ((captureDevice as AnyObject).position == AVCaptureDevicePosition.front) {
                    device = captureDevice as! AVCaptureDevice
                }
            }
            
        }
        
        // let audioDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInMicrophone, mediaType: AVMediaTypeAudio, position: .unspecified)
        if (device != nil) {
            let capturer = RTCVideoCapturer(deviceName: device.localizedName)
            
//            let videoConstraints = RTCMediaConstraints()
//            var audioConstraints = RTCMediaConstraints()
            
            let videoSource = self.webRtcClient?.videoSource(with: capturer, constraints: nil)
            localVideoTrack = self.webRtcClient?.videoTrack(withID: VIDEO_TRACK_ID, source: videoSource)
            // to implemet audio source in future
            //  let audioSource = self.webRtcClient?.aud
            localAudioTrack = self.webRtcClient?.audioTrack(withID: AUDIO_TRACK_ID)
            
            localMediaStream = self.webRtcClient?.mediaStream(withLabel: LOCAL_MEDIA_STREAM_ID)
            localMediaStream.addVideoTrack(localVideoTrack)
            localMediaStream.addAudioTrack(localAudioTrack)
            
            // local video view added stream
            localVideoTrack.add(localVideoView)
            
            //
            //self.peerConnection?.add(localMediaStream)
        }
    
        
    }
    
    
    //MARK: WebRTC Helper
    
    
    
    func defaultStunServer() -> RTCICEServer {
        let url = URL.init(string: stunServer);
        let iceServer = RTCICEServer.init(uri: url, username: "", password: "")
        return iceServer!
    }

    func createAudioVideoConstraints() -> RTCMediaConstraints{
        let audioOffer : RTCPair = RTCPair(key: "OfferToReceiveAudio", value: "true")
        let videoOffer : RTCPair = RTCPair(key: "OfferToReceiveVideo", value: "true")
        let dtlsSrtpKeyAgreement : RTCPair = RTCPair(key: "DtlsSrtpKeyAgreement", value: "true")
       
        let connectConstraints : RTCMediaConstraints = RTCMediaConstraints.init(mandatoryConstraints: [audioOffer,videoOffer], optionalConstraints: [dtlsSrtpKeyAgreement])
        
        return connectConstraints
    }
    
    func createDefaultConstraint() -> RTCMediaConstraints {
          let dtlsSrtpKeyAgreement : RTCPair = RTCPair(key: "DtlsSrtpKeyAgreement", value: "true")
        let connectConstraints : RTCMediaConstraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: [dtlsSrtpKeyAgreement])
        
        return connectConstraints
    }

}

extension RTCVideoViewController {
    
    //MARK: CASE AND ITS FUNCTIONS
    
    func onMessage(_ msg : String) -> Void {
        let dict = msg.dictionary
        if dict.isEmpty {
            
            return
        }
        guard let type = dict["type"] as? String else {
            
            return
        }
        // let success = dict["success"] as! String
        let msgType : MsgType = MsgType.init(rawValue: type)!
        switch msgType {
        case .login:
            self.caseLogin(dict)
            break
        case .offer:
            self.caseOnOffer(dict)
            break
        case .answer:
            self.caseOnAnswer(dict)
            break
        case . candidate:
            self.caseOnCandidate(dict)
            break
            
        case .leave:
            self.caseOnLeave(dict)
            print("client left")
            break
            
        case .error:
            print("error")
            break
            
        }
    }
    
    func caseLogin(_ dict : [String : Any]) -> Void {
        let isSuceess = dict["success"] as! Bool
        if (isSuceess == false){
            
            //show alert
            print(dict)
        }else {
            
            self.isHiddenLoginView(true)
            // on login sucess initalize webrtc and on local src of video
            self.initalizeWebRTC()
            
            
        }
        
        
    }
    
    func caseOnOffer(_ dict : [String : Any]) -> Void {
        
        print(dict)
        //parse dict and make sdp
        let name = dict["name"] as! String
        let sdpDict = dict["offer"] as! [String : Any]
        let type = sdpDict["type"] as! String
        let sdp = sdpDict["sdp"] as! String
        let rtcSessionDesc = RTCSessionDescription.init(type: type, sdp: sdp)
        print(rtcSessionDesc.debugDescription)
        
        //set remote description
       self.otherUserName.text = name
        self.peerConnection?.setRemoteDescriptionWith(self, sessionDescription: rtcSessionDesc!)
        
        //prepate connection
        let constraint = self.createAudioVideoConstraints()
        self.peerConnection?.add(localMediaStream)
        
        //send answer
        self.peerConnection?.createAnswer(with: self, constraints: constraint)
        
        
    }
    
    func caseOnAnswer(_ dict : [String : Any]) -> Void {
        
        print(dict)
        //parse dict
        let sdpDict = dict["answer"] as! [String : Any]
        let type = sdpDict["type"] as! String
        let sdp = sdpDict["sdp"] as! String
        let rtcSessionDesc = RTCSessionDescription.init(type: type, sdp: sdp)
        
        // set remote description
        self.peerConnection?.setRemoteDescriptionWith(self, sessionDescription: rtcSessionDesc!)
    }
    
    func caseOnCandidate(_ dict : [String : Any]) -> Void {
        
        let candidateDict = dict["candidate"] as! [String : Any]
        let mid = candidateDict["sdpMid"] as! String
        let index = candidateDict["sdpMLineIndex"] as! Int
        let sdp = candidateDict["candidate"] as! String // check what tag it is coming
        let candidate : RTCICECandidate = RTCICECandidate.init(mid: mid, index: index, sdp: sdp)
        self.peerConnection?.add(candidate)
    }
    
    
    func caseOnLeave(_ dic : [String : Any]) -> Void {
        
        remoteVideoTrack = nil
        remoteVideoTrack.setEnabled(false)
        
        
        self.peerConnection?.remove(localMediaStream);
        let iceCandidate : RTCICECandidate? = nil
        // self.peerConnection?.add(iceCandidate)

        self.peerConnection?.close()
    
    }
    
}

extension RTCVideoViewController : WebSocketDelegate {
    
    //MARK: WebSocketDelegate
    func websocketDidConnect(socket: WebSocket){
        
        print("connected")
        
    }
    func websocketDidDisconnect(socket: WebSocket, error: NSError?){
        
        
        print(String(describing: error?.localizedDescription))
    }
    func websocketDidReceiveMessage(socket: WebSocket, text: String){
        
         print(text)
         self.onMessage(text)
        
    }
    func websocketDidReceiveData(socket: WebSocket, data: Data){
        
        
        print(data)
    }
 
}
extension RTCVideoViewController : RTCPeerConnectionDelegate {
    
    //MARK: RTCPeerConnectionDelegate
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, signalingStateChanged stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, addedStream stream: RTCMediaStream!) {
        if (peerConnection == nil) {
            return
        }
        if (stream.audioTracks.count > 1 || stream.videoTracks.count > 1) {
            //Log(value: "Weird-looking stream: " + stream.description)
            return
        }
        if (stream.videoTracks.count == 1) {
            remoteVideoTrack = stream.videoTracks[0] as! RTCVideoTrack
            remoteVideoTrack.setEnabled(true)
            remoteVideoTrack.add(remoteVideoView);
        }
        
    }
    
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, removedStream stream: RTCMediaStream!) {
        
        remoteVideoTrack = nil
        remoteAudioTrack = nil
        
    }
    
    func peerConnection(onRenegotiationNeeded peerConnection: RTCPeerConnection!) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, iceConnectionChanged newState: RTCICEConnectionState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, iceGatheringChanged newState: RTCICEGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, gotICECandidate candidate: RTCICECandidate!) {
        
        //to be implemented when ice candiate use case known
        
        DispatchQueue.main.async {
            if (candidate != nil) {
                
                let candidate = ["candidate" : candidate.sdp,
                                 "sdpMid" : candidate.sdpMid,
                                 "sdpMLineIndex" : candidate.sdpMLineIndex] as [String : Any]
                let candidateJson = ["type" : "candidate",
                                     "candidate" : candidate,
                                     "name" : "testiOS"] as [String : Any]
                 self.socket?.write(string: candidateJson.json)
                
            }
        }
        
        
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, didOpen dataChannel: RTCDataChannel!) {
//        print("remote data channel name \(dataChannel.label)")
//        dataChannel.delegate = self
//        self.rtcDataChannelRemote = dataChannel
        
    }
}
extension RTCVideoViewController : RTCSessionDescriptionDelegate {
    
    //MARK:RTCSessionDescriptionDelegate
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: Error!) {
        
        if sdp.type == "offer" {
            
            self.peerConnection?.setLocalDescriptionWith(self, sessionDescription: sdp)
            let sdpDict : [String : String] = ["type" : sdp.type,
                                               "sdp" : sdp.description]
            //let sdpString = sdpDict.json
            let offerDict =  ["type" : "offer",
                              "offer" : sdpDict,
                              "name" : (otherUserName.text)!] as [String : Any]
            socket?.write(string: offerDict.json)
            
            
        }else if sdp.type == "answer" {
            
            self.peerConnection?.setLocalDescriptionWith(self, sessionDescription: sdp)
            let sdpDict : [String : String] = ["type" : sdp.type,
                                               "sdp" : sdp.description]
            // let sdpString = sdpDict.json
            let offerDict =  ["type" : "answer",
                              "answer" : sdpDict,
                              "name" : (otherUserName.text)!] as [String : Any]
            
            socket?.write(string: offerDict.json)
            
            
            
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, didSetSessionDescriptionWithError error: Error!) {
        
        if error != nil {
            
            print(error.localizedDescription)
        }
    }
    
    
}
extension RTCVideoViewController : RTCDataChannelDelegate {
    
    //MARK:RTCDataChannelDelegate
    
    func channelDidChangeState(_ channel: RTCDataChannel!) {
        //  RTCDataChannelState
//        if channel == rtcDataChannel {
//            
//            switch channel.state {
//            case kRTCDataChannelStateConnecting:
//                break
//            case kRTCDataChannelStateOpen:
//                print("send open")
//                break
//            case kRTCDataChannelStateClosing:
//                break
//            case kRTCDataChannelStateClosed:
//                print("send close")
//                break
//            default:
//                break
//                
//            }
//            
//        }else {// data channle receive
//            
//            
//            
//            if channel.state == kRTCDataChannelStateOpen {
//                
//                print("receive open")
//            }
//            if channel.state == kRTCDataChannelStateClosed{
//                
//                print("receive closed")
//            }
//            
//        }
    }
    
    func channel(_ channel: RTCDataChannel!, didReceiveMessageWith buffer: RTCDataBuffer!) {
        
//        let strData : String = String.init(data: buffer.data, encoding: .utf8)!
//        print(strData)
        
    }
    
    func channel(_ channel: RTCDataChannel!, didChangeBufferedAmount amount: UInt) {
        
        print("send buffered data")
    }
    
}
extension RTCVideoViewController : RTCEAGLVideoViewDelegate {

    //MARK:RTCEAGLVideoViewDelegate
    func videoView(_ videoView: RTCEAGLVideoView!, didChangeVideoSize size: CGSize) {
        
    }
    
}

