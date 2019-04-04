import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:webfeed/webfeed.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'detail_feed_post.dart';

const String admobAppId = 'ca-app-pub-3940256099942544~3347511713';
String admobInterstitialId = InterstitialAd.testAdUnitId;

void main() {
    FirebaseAdMob.instance.initialize(appId: admobAppId);
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
            home: MyHomePage(),
        );
    }
}

class MyHomePage extends StatefulWidget {
    MyHomePage({Key key}) : super(key: key);

    @override
    _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

    _MyHomePageState({Key key});

    List<RssItem> _feedItems = List<RssItem>();
    List<RssItem> _newsItems = List<RssItem>();
    List<RssItem> _favoriteItems = List<RssItem>();
    bool _isShowingFavorites = false;
    final String _textNews = 'ニュース一覧';
    final String _textFavorites = 'お気に入り一覧';
    Set<String> _favoriteKeys;

    InterstitialAd interstitialAd = InterstitialAd(
        adUnitId: admobInterstitialId,
        listener: (MobileAdEvent event) {
            print("InterstitialAd event is $event");
        },
    );

    Future<void> _refresh() async {
        if (await interstitialAd.isLoaded()) {
            interstitialAd.show();
        }
        setState(() {
            if (_isShowingFavorites) {
                _favoriteItems.clear();
            } else {
                _newsItems.clear();
            }
            _feedItems.clear();
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
                title: new Text(_isShowingFavorites ? _textFavorites : _textNews),
            ),
            body: futureBuilder,
            drawer: Drawer(
                child: ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                        DrawerHeader(
                            child: Text('メニュー'),
                            decoration: BoxDecoration(
                                color: Colors.blue,
                            ),
                        ),
                        ListTile(
                            title: Text(_textNews),
                            onTap: () {
                                setState(() {
                                    _isShowingFavorites = false;
                                });
                                Navigator.pop(context);
                            },
                        ),
                        ListTile(
                            title: Text('お気に入り一覧'),
                            onTap: () {
                                setState(() {
                                    _isShowingFavorites = true;
                                });
                                Navigator.pop(context);
                            },
                        ),
                    ],
                ),
            ),
        );
    }

    Future<List<RssItem>> _getData() async {
        interstitialAd.load();

        if (_isShowingFavorites) {
            if (_favoriteItems.isEmpty) {
                SharedPreferences pref = await SharedPreferences.getInstance();
                _favoriteKeys = pref.getKeys();

                _favoriteKeys.forEach((key) {
                    if (key.contains('link:')) {
                        var title = key.replaceAll('link:', '');
                        _favoriteItems.add(RssItem(
                            title: title,
                            description: pref.getString('description:$title'),
                            link: pref.getString(key)
                        ));
                    }
                });
            }
            _feedItems = _favoriteItems;
        } else {
            if (_newsItems.isEmpty) {
                var feedUrls = [
                    'https://feed43.com/4867847448366306.xml',
                    'https://sneakerwars.jp/items.rss'
                ];
                for (var url in feedUrls) {
                    var httpResponse = await http.get(url);
                    var feed = new RssFeed.parse(
                        httpResponse.body); // for parsing RSS feed
                    _newsItems += feed.items;
                }
            }

            _feedItems = _newsItems;
        }
        _feedItems.sort(
                (b, a) =>
                parsePubDate(a.pubDate).compareTo(parsePubDate(b.pubDate)));

        return _feedItems;
    }

    DateTime parsePubDate(String pubDate) {
        var format = DateFormat('EEE, d MMM yyyy HH:mm:ss Z');
        var date = format.parse(pubDate);

        return date;
    }

    Widget createListView(BuildContext context, AsyncSnapshot snapshot) {
        List<RssItem> feedItems = snapshot.data;
        return new RefreshIndicator(
            child: feedItems.isEmpty
                ? Center(child: Text('データがありません', style: TextStyle(fontSize: 24),))
                :ListView.builder(
                itemCount: feedItems.length,
                itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                        child: new Card(
                            child: Column(
                                children: <Widget>[
                                    Image.network(DetailFeedPost.parseImageUrl(
                                        feedItems[index].description)),
                                    Container(
                                        margin: EdgeInsets.all(10.0),
                                        child: ListTile(
                                            title: Text(feedItems[index].title),
                                            subtitle:
                                            Text(DetailFeedPost.parseDescription(
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
                                            feedItems[index]
                                        );
                                    }));
                        },
                    );
                },
            ),
            onRefresh: _refresh,
        );
    }
}
