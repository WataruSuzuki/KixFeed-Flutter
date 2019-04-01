import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DetailFeedPost extends StatelessWidget {
    final String title;
    final String url;

    DetailFeedPost(this.title, this.url);

    @override
    Widget build(BuildContext context) {

        return Scaffold(
            appBar: AppBar(
                title: Text(title),
            ),
            body: WebView(
                initialUrl: url,
                javascriptMode: JavascriptMode.unrestricted,
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: () {
                    // Add your onPressed code here!
                },
                child: Icon(Icons.favorite),
                backgroundColor: Colors.pink,
            )
        );
    }
}
