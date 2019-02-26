import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:intl/intl.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {

      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
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
            return new Text('loading...');
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
        title: new Text("フィード"),
      ),
      body: futureBuilder,
    );
  }

  Future<List<RssItem>> _getData() async {
    var feedUrls = [
      'https://feed43.com/1803128423885152.xml',
      'https://sneakerwars.jp/items.rss'
    ];
    var items = new List<RssItem>();
    for (var url in feedUrls) {
      var httpResponse = await http.get(url);
      var feed = new RssFeed.parse(httpResponse.body); // for parsing RSS feed
      items += feed.items;
    }
    items.sort((b,a) => parsePubDate(a.pubDate).compareTo(parsePubDate(b.pubDate)));
    return items;
  }

  DateTime parsePubDate(String pubDate) {
    var format = DateFormat('EEE, d MMM yyyy HH:mm:ss Z');
    var date = format.parse(pubDate);

    return date;
  }

  Widget createListView(BuildContext context, AsyncSnapshot snapshot) {
    List<RssItem> feedItems = snapshot.data;
    return new ListView.builder(
      itemCount: feedItems.length,
      itemBuilder: (BuildContext context, int index) {
//        return GestureDetector(
//          key: Key(menu[index]),
//          child: Text(menu[index]),
//          onTapUp: (details) {
//            Navigator.push(context, new MaterialPageRoute<Null>(
//                settings: const RouteSettings(name: "/hogefuga"),
//                builder: (BuildContext context) {
//                  switch (menu[index]) {
//                    default:
//                      return new HogeFuga();
//                  }
//                }
//            ));
//          },
//        );

        return Card(
          child: Column(
            children: <Widget>[
              Image.network(parseImageUrl(feedItems[index].description)),
              Container(
                  margin: EdgeInsets.all(10.0),
                  child: ListTile(
                    title: Text(feedItems[index].title),
                    subtitle: Text(parseDescription(feedItems[index].description)),
                    isThreeLine: true,
                  )),
            ],
          ),
        );
      },
    );
  }

  String parseImageUrl(String material) {
    RegExp exp = RegExp(r"http(s)?://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)?");
    Iterable<Match> matches = exp.allMatches(material);
    for (Match m in matches) {
      for (int i = 0; i < m.groupCount; i++) {
        if (m.group(i).contains('.png') || m.group(i).contains('.jpg') || m.group(i).contains('.jpeg')) {
          return m.group(i);
        }
      }
    }
    return 'http://hp.t-alive.com/wp-content/uploads/2013/11/oops.png';
  }

  String parseDescription(String material) {
    RegExp exp = new RegExp(r'^(.+)</a>(.+)$');
    var match = exp.firstMatch(material.replaceAll("<p><sub><i>-- Delivered by <a href=\"http://feed43.com/\">Feed43</a> service</i></sub></p>", '').replaceAll('\n', ''));
    if (match != null) {
      return match.group(2).substring(0, 50) + '...';
    }
    print(material);
    return '';
  }
}
