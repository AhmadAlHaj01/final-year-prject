import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_gauges/gauges.dart';

void main() {
  runApp(ChatGPTApp());
}

class ChatGPTApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChatGPT Assistant',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _controller.clear();
      _isLoading = true;
    });

    const String backendUrl = 'http://127.0.0.1:8000/chat';

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add({'role': 'assistant', 'content': data['response']});
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': {'error': response.reasonPhrase}
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': {'error': e.toString()}});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser)
          CircleAvatar(
            backgroundColor: Colors.grey[400],
            child: Icon(Icons.chat, color: Colors.white),
          ),
        SizedBox(width: 8),
        Flexible(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 5),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue[100] : Colors.grey[300],
              borderRadius: BorderRadius.circular(15),
            ),
            child: isUser
                ? Text(
              message['content'] ?? '',
              style: TextStyle(fontSize: 16),
            )
                : _buildAssistantResponse(message['content']),
          ),
        ),
        if (isUser)
          SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAssistantResponse(dynamic response) {
    if (response is Map<String, dynamic>) {
      double sentimentScore = response['sentiment'][0]['score'];
      String sentimentLabel = response['sentiment'][0]['label'];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (response.containsKey('readability'))
            Card(
              margin: EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                title: Text("Readability Scores", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  "Flesch Reading Ease: ${response['readability']['flesch_reading_ease']}\n"
                      "Gunning Fog Index: ${response['readability']['gunning_fog_index']}",
                ),
              ),
            ),
          if (response.containsKey('sentiment'))
            Card(
              margin: EdgeInsets.symmetric(vertical: 5),
              child: Column(
                children: [
                  ListTile(
                    title: Text("Sentiment Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    height: 150,
                    child: SfRadialGauge(
                      axes: <RadialAxis>[
                        RadialAxis(
                          minimum: 0,
                          maximum: 1,
                          interval: 0.1, // Tick intervals for better scale visibility
                          pointers: <GaugePointer>[
                            NeedlePointer(
                              value: sentimentScore,
                              enableAnimation: true, // Smooth animation for updates
                              animationType: AnimationType.easeOutBack,
                            ),
                          ],
                          ranges: <GaugeRange>[
                            GaugeRange(startValue: 0.0, endValue: 0.4, color: Colors.red),
                            GaugeRange(startValue: 0.4, endValue: 0.7, color: Colors.yellow),
                            GaugeRange(startValue: 0.7, endValue: 1.0, color: Colors.green),
                          ],
                          annotations: <GaugeAnnotation>[
                            GaugeAnnotation(
                              widget: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${(sentimentScore * 100).toStringAsFixed(2)}% ($sentimentLabel)",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              positionFactor: 0.8,
                              angle: 90,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (response.containsKey('simplification'))
            ExpansionTile(
              title: Text("Simplification Suggestions", style: TextStyle(fontWeight: FontWeight.bold)),
              children: (response['simplification'] as List)
                  .map(
                    (item) => ListTile(
                  title: Text(item['sentence']),
                  subtitle: Text(
                    "Complex Words: ${item['complex_words'].join(', ')}\n"
                        "Recommendation: ${item['recommendation']}",
                  ),
                ),
              )
                  .toList(),
            ),
          if (response.containsKey('alternatives'))
            ExpansionTile(
              title: Text("Word Alternatives", style: TextStyle(fontWeight: FontWeight.bold)),
              children: (response['alternatives'] as Map<String, dynamic>).entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  subtitle: Text("Alternatives: ${entry.value.join(', ')}"),
                );
              }).toList(),
            ),
          if (response.containsKey('keywords'))
            Card(
              margin: EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                title: Text("Keywords", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  (response['keywords'] as Map<String, dynamic>)
                      .entries
                      .map((entry) => "${entry.key}: ${entry.value}")
                      .join("\n"),
                ),
              ),
            ),
        ],
      );
    } else {
      return Text(
        response.toString(),
        style: TextStyle(fontSize: 16),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Contant Enhancer"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          if (_isLoading) LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: "Type your message",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  child: Text("Analyze"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}