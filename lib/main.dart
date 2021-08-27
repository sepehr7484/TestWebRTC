import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'test.dart';

void main() {
  return runApp(MaterialApp(
    home: TestRTC(),
    title: 'WEBRTC',
    debugShowCheckedModeBanner: false,
  ));
}
