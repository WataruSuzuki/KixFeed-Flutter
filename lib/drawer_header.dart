import 'package:flutter/material.dart';
import 'simple_show_web.dart';

typedef DrawerTapUpCallback = void Function(Selection selection);

enum Selection {
    posts,
    news,
    favorites,
}

class MainDrawer {

    static Drawer instantiateDrawerHeader(
        BuildContext context,
        String textPosts,
        String textFavorites,
        String textNews,
        DrawerTapUpCallback tap)
    {
        return Drawer(
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
                        title: Text(textPosts),
                        onTap: () {
                            tap(Selection.posts);
                        },
                    ),
                    ListTile(
                        title: Text(textNews),
                        onTap: () {
                            tap(Selection.news);
                        },
                    ),
                    ListTile(
                        title: Text(textFavorites),
                        onTap: () {
                            tap(Selection.favorites);
                        },
                    ),
                    ListTile(
                        title: Text('利用規約'),
                        onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute<Null>(
                                    settings: const RouteSettings(name: "/feeds"),
                                    builder: (BuildContext context) {
                                        return new SimpleShowWeb(
                                            '利用規約',
                                            'https://watarusuzuki.github.io/KixFeed-Flutter/terms.html'
                                        );
                                    })
                            );
                        },
                    ),
                    ListTile(
                        title: Text('プライバシーポリシー'),
                        onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute<Null>(
                                    settings: const RouteSettings(name: "/feeds"),
                                    builder: (BuildContext context) {
                                        return new SimpleShowWeb(
                                            'プライバシーポリシー',
                                            'https://watarusuzuki.github.io/KixFeed-Flutter/privacy_policy.html'
                                        );
                                    })
                            );
                        },
                    ),
                ],
            ),
        );
    }
}
