# webrtcRTCdataChannel-Video
#### Signaling serer
please configure signaling server from url -https://github.com/ajaysinghthakur/video-demo-tutorialpoint

#### ios
after running singaling server go to RTCVideoViewController.swift file 

```
override func viewDidLoad(){
  self.socket = WebSocket(url: URL(string: "ws://127.0.0.1:9090")!)
}
```
change url of websocket to your mac ip address or server ip address
