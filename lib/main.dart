import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:webfeed/webfeed.dart';
import 'package:firebase_admob/firebase_admob.dart';

import 'detail_feed_post.dart';

void main() {
    FirebaseAdMob.instance.initialize(appId: 'ca-app-pub-3940256099942544~3347511713');
    runApp(MyApp());
}

class MyApp extends StatelessWidget {
    // This widget is the root of your application.
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
                primarySwatch: Colors.blue,
            ),
            home: MyHomePage(title: 'ニュース'),
        );
    }
}

class MyHomePage extends StatefulWidget {
    MyHomePage({Key key, this.title}) : super(key: key);

    final String title;

    @override
    _MyHomePageState createState() => _MyHomePageState(title: title);
}

class _MyHomePageState extends State<MyHomePage> {
    final String title;

    _MyHomePageState({Key key, this.title});

    List<RssItem> feedItems = List<RssItem>();

    InterstitialAd interstitialAd = InterstitialAd(
        // Replace the testAdUnitId with an ad unit id from the AdMob dash.
        // https://developers.google.com/admob/android/test-ads
        // https://developers.google.com/admob/ios/test-ads
        adUnitId: InterstitialAd.testAdUnitId,
        listener: (MobileAdEvent event) {
            print("InterstitialAd event is $event");
        },
    );

    Future<void> _refresh() async {
        if (await interstitialAd.isLoaded()) {
            interstitialAd.show();
        }
        setState(() {
            feedItems.clear();
        });
    }

    @override
    Widget build(BuildContext context) {
        var futureBuilder = new FutureBuilder(
            future: _getData(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
                switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                        return new Center(
                            child: CircularProgressIndicator(),
                        );
                    default:
                        if (snapshot.hasError)
                            return new Text('Error: ${snapshot.error}');
                        else
                            return createListView(context, snapshot);
                }
            },
        );

        return new Scaffold(
            appBar: new AppBar(
                title: new Text(title),
            ),
            body: futureBuilder,
        );
    }

    Future<List<RssItem>> _getData() async {
        interstitialAd.load();

        if (feedItems.isNotEmpty) {
            return feedItems;
        }

        var feedUrls = [
            'https://feed43.com/4867847448366306.xml',
            'https://sneakerwars.jp/items.rss'
        ];
        for (var url in feedUrls) {
            var httpResponse = await http.get(url);
            var feed = new RssFeed.parse(
                httpResponse.body); // for parsing RSS feed
            feedItems += feed.items;
        }
        feedItems.sort(
                (b, a) =>
                parsePubDate(a.pubDate).compareTo(parsePubDate(b.pubDate)));

        return feedItems;
    }

    DateTime parsePubDate(String pubDate) {
        var format = DateFormat('EEE, d MMM yyyy HH:mm:ss Z');
        var date = format.parse(pubDate);

        return date;
    }

    Widget createListView(BuildContext context, AsyncSnapshot snapshot) {
        List<RssItem> feedItems = snapshot.data;
        return new RefreshIndicator(
            child: ListView.builder(
                itemCount: feedItems.length,
                itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                        child: new Card(
                            child: Column(
                                children: <Widget>[
                                    Image.network(parseImageUrl(
                                        feedItems[index].description)),
                                    Container(
                                        margin: EdgeInsets.all(10.0),
                                        child: ListTile(
                                            title: Text(feedItems[index].title),
                                            subtitle:
                                            Text(parseDescription(
                                                feedItems[index].description)),
                                            isThreeLine: true,
                                        )),
                                ],
                            ),
                        ),
                        onTapUp: (details) {
                            interstitialAd.show();
                            Navigator.push(
                                context,
                                new MaterialPageRoute<Null>(
                                    settings: const RouteSettings(name: "/feeds"),
                                    builder: (BuildContext context) {
                                        return new DetailFeedPost(
                                            feedItems[index].title,
                                            feedItems[index].link
                                        );
                                    }));
                        },
                    );
                },
            ),
            onRefresh: _refresh,
        );
    }

    String parseImageUrl(String material) {
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

    String parseDescription(String material) {
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
