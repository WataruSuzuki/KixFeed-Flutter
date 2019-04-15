import 'package:flutter/material.dart';
import 'package:webfeed/webfeed.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:flutter/cupertino.dart';

import 'pick_post.dart';

class DetailFeedPost extends StatelessWidget {
    final RssItem item;

    DetailFeedPost(this.item);

    @override
    Widget build(BuildContext context) {

        return Scaffold(
            appBar: AppBar(
                title: Text(item.title),
            ),
            body: WebView(
                initialUrl: item.link,
                javascriptMode: JavascriptMode.unrestricted,
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute<Null>(
                            settings: const RouteSettings(name: "/feeds"),
                            builder: (BuildContext context) {
                                return PickPost(item);
                            },
                            fullscreenDialog: true,
                        )
                    );
                },
                child: Icon(Icons.thumb_up),
                backgroundColor: Colors.pink,
            )
        );
    }

    static deleteData(String removeKey) async {
        SharedPreferences pref = await SharedPreferences.getInstance();
        await pref.remove(removeKey);
    }

    static String parseImageUrl(String material) {
        RegExp exp = RegExp(r"http(s)?://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)?");
        Iterable<Match> matches = exp.allMatches(material);
        for (Match m in matches) {
            for (int i = 0; i < m.groupCount; i++) {
                if (m.group(i).contains('.png') ||
                    m.group(i).contains('.jpg') ||
                    m.group(i).contains('.jpeg')) {
                    return m.group(i);
                }
            }
        }
        return 'http://hp.t-alive.com/wp-content/uploads/2013/11/oops.png';
    }

    static String parseDescription(String material) {
        RegExp exp = new RegExp(r'^(.+)</a>(.+)$');
        var match = exp.firstMatch(material
            .replaceAll(
            "<p><sub><i>-- Delivered by <a href=\"http://feed43.com/\">Feed43</a> service</i></sub></p>",
            '')
            .replaceAll('\n', ''));
        if (match != null) {
            return match.group(2).substring(0, 50) + '...';
        }
        print(material);
        return '';
    }
}
