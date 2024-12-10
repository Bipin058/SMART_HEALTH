import 'package:flutter/material.dart';
import 'video_call.dart';

class VideoCallHomePage extends StatefulWidget {
  const VideoCallHomePage({Key? key}) : super(key: key);

  @override
  State<VideoCallHomePage> createState() => _VideoCallHomePageState();
}

class _VideoCallHomePageState extends State<VideoCallHomePage> {
  final TextEditingController _channelController = TextEditingController();
  bool _validateError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora Video Call'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: _channelController,
                decoration: InputDecoration(
                  errorText:
                      _validateError ? 'Channel name is mandatory' : null,
                  border: const OutlineInputBorder(),
                  hintText: 'Enter Channel Name',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _channelController.text.isEmpty
                      ? _validateError = true
                      : _validateError = false;
                });
                if (!_validateError) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoCallPage(
                        channelName: _channelController.text,
                      ),
                    ),
                  );
                }
              },
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }
}
