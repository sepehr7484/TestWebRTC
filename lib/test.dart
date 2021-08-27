import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

class TestRTC extends StatefulWidget {
  @override
  _TestRTCState createState() => _TestRTCState();
}

class _TestRTCState extends State<TestRTC> {
  final _localRender = RTCVideoRenderer();
  final _remoteRenderer = new RTCVideoRenderer();
  final sdpController = TextEditingController();
  bool _offer = false;
  late RTCPeerConnection _peerConnection;
  late MediaStream _localStream;

  @override
  void dispose() {
    // TODO: implement dispose
    _localRender.dispose();
    _remoteRenderer.dispose();
    sdpController.dispose();
    super.dispose();
  }

  void initState() {
    // TODO: implement initState
    initRenderers();
    getUserMedia();
    _createPeerConnect().then((pc) {
      _peerConnection = pc;
    });
    super.initState();
  }

  _createPeerConnect() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };
    final Map<String, dynamic> offersdpconstain = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": []
    };
    _localStream = await getUserMedia();
    RTCPeerConnection pc =
        await createPeerConnection(configuration, offersdpconstain);
    pc.addStream(_localStream);
    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        print(json.encode({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMlineIndex,
        }));
      }
    };
    pc.onIceConnectionState = (e) {
      print(e);
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      _remoteRenderer.srcObject = stream;
    };

    return pc;
  }

  getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': {'facingMode': 'user'}
    };
    MediaStream stream = await navigator.getUserMedia(mediaConstraints);
    _localRender.srcObject = stream;
    _localRender.muted = true;
    return stream;
  }

  initRenderers() async {
    await _localRender.initialize();
    await _remoteRenderer.initialize();
  }

  _createOffer() async {
    RTCSessionDescription description =
        await _peerConnection.createOffer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp.toString());
    print(json.encode(session));
    _offer = true;

    _peerConnection.setLocalDescription(description);
  }

  void _createAnswer() async {
    RTCSessionDescription description =
        await _peerConnection.createAnswer({'offerToReceiveVideo': 1});

    var session = parse(description.sdp.toString());
    print(json.encode(session));
    // print(json.encode({
    //       'sdp': description.sdp.toString(),
    //       'type': description.type.toString(),
    //     }));

    _peerConnection.setLocalDescription(description);
  }

  void _setRemoteDescription() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode('$jsonString');

    String sdp = write(session, null);

    // RTCSessionDescription description =
    //     new RTCSessionDescription(session['sdp'], session['type']);
    RTCSessionDescription description =
        new RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
    print(description.toMap());

    await _peerConnection.setRemoteDescription(description);
  }

  void _addCandidate() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode('$jsonString');
    print(session['candidate']);
    dynamic candidate = new RTCIceCandidate(
        session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
    await _peerConnection.addCandidate(candidate);
  }

  // -------------------call method-------------
  SizedBox vedioRenderers() {
    return SizedBox(
      height: 210,
      child: Row(
        children: [
          Flexible(
              child: Container(
            key: Key('local'),
            margin: EdgeInsets.all(5.0),
            decoration: BoxDecoration(color: Colors.black),
            child: RTCVideoView(_localRender),
          )),
          Flexible(
              child: Container(
            key: Key('local'),
            margin: EdgeInsets.all(5.0),
            decoration: BoxDecoration(color: Colors.black),
            child: RTCVideoView(_remoteRenderer),
          )),
        ],
      ),
    );
  }

  Row offerAndAnswerButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RaisedButton(
          onPressed: () {
            setState(() {
              _createOffer();
            });
          },
          child: Text('Offer'),
          color: Colors.blue,
        ),
        RaisedButton(
          onPressed: () {
            setState(() {
              _createAnswer();
            });
          },
          child: Text('Answer'),
          color: Colors.blue,
        ), //_createAnswer
      ],
    );
  }

  Padding sdpCandidateTF() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: TextField(
        controller: sdpController,
        keyboardType: TextInputType.multiline,
        maxLines: 4,
        maxLength: TextField.noMaxLength,
      ),
    );
  }

  Row sdpCandidateButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RaisedButton(
          onPressed: () {
            setState(() {
              _setRemoteDescription();
            });
          }, // _setRemoteDescription,
          child: Text('Set Remote Desc.'),
          color: Colors.orange,
        ),
        RaisedButton(
          onPressed: () {
            setState(() {
              _addCandidate();
            });
          }, // _setCandidate,
          child: Text('Set Candidate.'),
          color: Colors.orange,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('WebRtc'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          child: Column(
            children: [
              vedioRenderers(),
              offerAndAnswerButtons(),
              sdpCandidateTF(),
              sdpCandidateButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
