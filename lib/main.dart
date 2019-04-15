import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:webfeed/webfeed.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'drawer_header.dart';
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
    Selection _selection = Selection.news;
    final String _textPosts = 'ピック＆トーク';
    final String _textNews = 'ニュース一覧';
    final String _textFavorites = 'ピック一覧';
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
            switch (_selection) {
                case Selection.posts:
                    break;
                case Selection.news:
                    _newsItems.clear();
                    break;
                case Selection.favorites:
                    _newsItems.clear();
                    _favoriteItems.clear();
            }
            _feedItems.clear();
        });
    }

    tapDrawerBody(Selection next) {
        Navigator.pop(context);
        setState(() {
            _selection = next;
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
        var popupMenu = List<PopupMenuEntry<String>>();

        var keys = [
            '(・∀・)',
            '更新',
            'ピックを端末から削除'
        ];
        var menuKey = keys[_selection.index];
        popupMenu.add(PopupMenuItem<String>(
            value: menuKey,
            key: Key(menuKey.toString()),
            child: Text(menuKey.toString()),)
        );
        var titles = [
            _textPosts,
            _textNews,
            _textFavorites
        ];

        return new Scaffold(
            appBar: new AppBar(
                title: new Text(titles[_selection.index]),
                actions: <Widget>[
                    PopupMenuButton<String>(
                        onSelected: (String key) {
                            switch (key) {
                                case '更新':
                                    _refresh();
                                    break;
                                case 'ピックを端末から削除':
                                    _favoriteKeys.forEach((key) {
                                        DetailFeedPost.deleteData(key);
                                    });
                                    _favoriteKeys.clear();
                                    setState(() {
                                        _favoriteItems.clear();
                                    });
                                    break;
                            }
                        },
                        itemBuilder: (BuildContext context) => popupMenu,
                        key: Key('PopupMenuButton'),
                    )
                ],
            ),
            body: futureBuilder,
            drawer: MainDrawer.instantiateDrawerHeader(
                context,
                _textPosts,
                _textFavorites,
                _textNews,
                tapDrawerBody
            ),
        );
    }

    Future<List<RssItem>> _getData() async {
        interstitialAd.load();

        switch (_selection) {
            case Selection.posts:
                break;
            case Selection.news:
                if (_newsItems.isEmpty) {
                    var feedUrls = [
                        'http://sneakerbucks.com/feed',
                        'https://sneakerwars.jp/items.rss'
                    ];
                    for (var url in feedUrls) {
                        var httpResponse = await http.get(url);
                        var feed = RssFeed.parse(httpResponse.body); // for parsing RSS feed
                        _newsItems += feed.items;
                    }
                }
                _feedItems = _newsItems;
                break;
            case Selection.favorites:
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
                        child: Card(
                            child: Column(
                                children: <Widget>[
                                    Image.network(DetailFeedPost.parseImageUrl(
                                        feedItems[index].content != null
                                            ? feedItems[index].content.images.first
                                            : feedItems[index].description)
                                    ),
                                    Container(
                                        margin: EdgeInsets.all(10.0),
                                        child: ListTile(
                                            title: Text(feedItems[index].title),
                                            subtitle:
                                            Text(DetailFeedPost.parseDescription(
                                                feedItems[index].description)
                                            ),
                                            isThreeLine: true,
                                        )),
                                ],
                            ),
                        ),
                        onTapUp: (details) {
                            interstitialAd.show();
                            Navigator.push(
                                context,
                                MaterialPageRoute<Null>(
                                    settings: const RouteSettings(name: "/feeds"),
                                    builder: (BuildContext context) {
                                        return new DetailFeedPost(
                                            feedItems[index]
                                        );
                                    })
                            );
                        },
                    );
                },
            ),
            onRefresh: _refresh,
        );
    }
}
