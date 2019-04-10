import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SimpleShowWeb extends StatelessWidget {
    final String title;
    final String url;

    SimpleShowWeb(this.title, this.url);

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
        );
    }
}
