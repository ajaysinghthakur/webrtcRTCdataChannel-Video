//
//  ViewController.swift
//  webrtcClientTutorialpoint
//
//  Created by ajay singh thakur on 02/06/17.
//  Copyright © 2017 ajay singh thakur. All rights reserved.
//

import UIKit
import Starscream
class ViewController: UIViewController {

    //outlets
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var otherNameTextField: UITextField!
    @IBOutlet weak var msgTextField : UITextField!
    
    enum MsgType: String {
        case login = "login"
        case offer = "offer"
        case answer = "answer"
        case candidate = "candidate"
        case leave = "leave"
        
        var description: String {
            return self.rawValue
        }
    }

    
    
    //socket
    var socket : WebSocket?
    
    // initilizing webrtc
    var peerConnection : RTCPeerConnection?
    var webRtcClient : RTCPeerConnectionFactory?
    
    //data channle
    var rtcDataChannelRemote : RTCDataChannel?
    var rtcDataChannel : RTCDataChannel?
    
    //servers
    let stunServer : String = "stun:stun.l.google.com:19302"//stun:stun.1.google.com:19302
    let stunServer2 : String = "stun:global.stun.twilio.com:3478?transport=udp"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.socket = WebSocket(url: URL(string: "ws://localhost:9090")!)
        self.socket?.delegate = self
        self.socket?.connect()
        
        // webrtc initalization
        RTCPeerConnectionFactory.initializeSSL();
        self.webRtcClient = RTCPeerConnectionFactory.init()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
        
    }
    
    //button action
    @IBAction func loginButtonAction(_ sender: Any) {
        
        if (nameTextField.text?.count)! > 0 {
        
            let dict = ["type": "login",
                         "name": nameTextField.text!]
            
             if (socket?.isConnected)!{
            
                let jsonString = dict.json
                socket?.write(string: jsonString)
            }
            
            
        }
        
        
    }
    

    @IBAction func connectButtonAction(_ sender: Any) {
        
        
        if (otherNameTextField.text?.characters.count)! > 0 {
        
            self.peerConnection?.createOffer(with: self, constraints: nil)
        }
        
    }
    
    
    @IBAction func sendMsgButton(_ sender : Any){
    
        if (msgTextField.text?.characters.count)! > 0{
        
            let msg : String = msgTextField.text!
            let msgBuffer : RTCDataBuffer = RTCDataBuffer.init(data: msg.data(using: .utf8), isBinary: false)
            let suce  = self.rtcDataChannel!.sendData(msgBuffer);
            print(suce)
        }
        
    }
    
    

}
extension ViewController : WebSocketDelegate {

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
extension ViewController {

    //MARK: CASE AND ITS FUNCTIONS
    func onMessage(_ msg : String) -> Void {
        let dict = msg.dictionary
        if dict.isEmpty {
        
            return
        }
        let type = dict["type"] as! String
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
            print("client left")
            break
            
        }
    }
    
    func caseLogin(_ dict : [String : Any]) -> Void {
        let isSuceess = dict["success"] as! Bool
        if (isSuceess == false){
        
            //show alert 
            print(dict)
        }else {
        
            // new rtc peer connection
           self.newConnection()
            
        }
        
        
    }
    
    func caseOnOffer(_ dict : [String : Any]) -> Void {
        
        print(dict)
        let name = dict["name"] as! String
        let sdpDict = dict["offer"] as! [String : Any]
        let type = sdpDict["type"] as! String
        let sdp = sdpDict["sdp"] as! String
        let rtcSessionDesc = RTCSessionDescription.init(type: type, sdp: sdp)
        print(rtcSessionDesc.debugDescription)
        self.otherNameTextField.text = name
        self.peerConnection?.setRemoteDescriptionWith(self, sessionDescription: rtcSessionDesc!)
        self.peerConnection?.createAnswer(with: self, constraints: nil)
        
        
    }
    
    func caseOnAnswer(_ dict : [String : Any]) -> Void {
        
        print(dict)
        let sdpDict = dict["answer"] as! [String : Any]
        let type = sdpDict["type"] as! String
        let sdp = sdpDict["sdp"] as! String
        let rtcSessionDesc = RTCSessionDescription.init(type: type, sdp: sdp)
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
    
}
extension ViewController {

   
    //MARK: ice servers & webrtc helper
    func defaultStunServer() -> RTCICEServer {
        let url = URL.init(string: stunServer);
        let iceServer = RTCICEServer.init(uri: url, username: "", password: "")
        return iceServer!
    }
    
    
    func newConnection() -> Void {
     
        
        let stunServer = self.defaultStunServer()
        
        //let pairs
//        RTCPair* audio = [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"];
//        RTCPair* video = [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"false"];
//        //RTCPair *rtpDatachannels = [[RTCPair alloc] initWithKey:@"RtpDataChannels" value:@"true"];
//        RTCPair *sctpDatachannels = [[RTCPair alloc] initWithKey:@"internalSctpDataChannels" value:@"true"];
//        RTCPair *dtlsSrtpKeyAgreeement = [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"];

       
        //  let audio : RTCPair = RTCPair.init(key: "OfferToReceiveAudio", value: "true")
        // let video : RTCPair = RTCPair.init(key: "OfferToReceiveVideo", value: "true")
        
        let sctpDatachannels : RTCPair = RTCPair.init(key: "internalSctpDataChannels", value: "true")
        //  let rtpDataChannels : RTCPair = RTCPair.init(key: "RtpDataChannels", value: "true")
        let dtlsSrtpKeyAgreeement : RTCPair = RTCPair.init(key: "DtlsSrtpKeyAgreement", value: "true")
        
        
        let rtcMediaConstraints  : RTCMediaConstraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: [dtlsSrtpKeyAgreeement])
        
        
        
        self.peerConnection = self.webRtcClient?.peerConnection(withICEServers: [stunServer], constraints: nil, delegate: self)
        self.openDataChannel()
    }
    
    
    func openDataChannel() -> Void {
        
//        {
//            ordered: false, // do not guarantee order
//            maxRetransmitTime: -1,// in milliseconds
//            maxRetransmits : 0,
//            negotiated : false,
//            id : 25
//        }
        
//        let channelInit = RTCDataChannelInit.init()
//        channelInit.isNegotiated = false;
//        channelInit.isOrdered = true;
//        channelInit.maxRetransmits = 0;
//        channelInit.maxRetransmitTimeMs = -1;
//         channelInit.streamId = 25;  //important setting
        let dataChannel : RTCDataChannel =  (self.peerConnection?.createDataChannel(withLabel: "myDataChannel", config: nil))!
        dataChannel.delegate = self
        print(dataChannel)
        self.rtcDataChannel = dataChannel
    }
    
}
extension ViewController : RTCPeerConnectionDelegate {

    //MARK: RTCPeerConnectionDelegate

    func peerConnection(_ peerConnection: RTCPeerConnection!, signalingStateChanged stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, addedStream stream: RTCMediaStream!) {
        
    }
    
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, removedStream stream: RTCMediaStream!) {
        
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
        print("remote data channel name \(dataChannel.label)")
        dataChannel.delegate = self
        self.rtcDataChannelRemote = dataChannel
        
    }
}
extension ViewController : RTCSessionDescriptionDelegate {

    //MARK:RTCSessionDescriptionDelegate
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: Error!) {
        
        if sdp.type == "offer" {
            
            self.peerConnection?.setLocalDescriptionWith(self, sessionDescription: sdp)
            let sdpDict : [String : String] = ["type" : sdp.type,
                           "sdp" : sdp.description]
            //let sdpString = sdpDict.json
            let offerDict =  ["type" : "offer",
                              "offer" : sdpDict,
                              "name" : (otherNameTextField.text)!] as [String : Any]
            socket?.write(string: offerDict.json)
           
            
        }else if sdp.type == "answer" {
            
            self.peerConnection?.setLocalDescriptionWith(self, sessionDescription: sdp)
            let sdpDict : [String : String] = ["type" : sdp.type,
                           "sdp" : sdp.description]
            // let sdpString = sdpDict.json
            let offerDict =  ["type" : "answer",
            "answer" : sdpDict,
            "name" : (otherNameTextField.text)!] as [String : Any]
            
            socket?.write(string: offerDict.json)
           
            
            
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, didSetSessionDescriptionWithError error: Error!) {
      
        if error != nil {
        
            print(error.localizedDescription)
        }
    }

    
}
extension ViewController : RTCDataChannelDelegate {

    //MARK:RTCDataChannelDelegate

    func channelDidChangeState(_ channel: RTCDataChannel!) {
        //  RTCDataChannelState
        if channel == rtcDataChannel {
            
            switch channel.state {
            case kRTCDataChannelStateConnecting:
                break
            case kRTCDataChannelStateOpen:
                print("send open")
                break
            case kRTCDataChannelStateClosing:
                break
            case kRTCDataChannelStateClosed:
                print("send close")
                break
            default:
                break
                
            }
            
        }else {// data channle receive
            
            
           
            if channel.state == kRTCDataChannelStateOpen {
                
                print("receive open")
            }
            if channel.state == kRTCDataChannelStateClosed{
                
                print("receive closed")
            }
            
        }
    }
    
    func channel(_ channel: RTCDataChannel!, didReceiveMessageWith buffer: RTCDataBuffer!) {
        
        let strData : String = String.init(data: buffer.data, encoding: .utf8)!
        print(strData)
       
    }
    
    func channel(_ channel: RTCDataChannel!, didChangeBufferedAmount amount: UInt) {
        
        print("send buffered data")
    }

}
