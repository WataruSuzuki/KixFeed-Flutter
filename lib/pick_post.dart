import 'package:flutter/material.dart';
import 'package:webfeed/webfeed.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'detail_feed_post.dart';

class PickPost extends StatefulWidget {
    final RssItem item;

    PickPost(this.item);

    @override
    State createState() => _PickPostState(item);
}

class _PickPostState extends State<PickPost> {
    final RssItem item;
    _PickPostState(this.item);

    FocusNode _focusNode = FocusNode();
    final myController = TextEditingController();

    saveData() async {
        SharedPreferences pref = await SharedPreferences.getInstance();
        await pref.setString('link:' + item.title, item.link);
        await pref.setString('description:' + item.title, item.description);
    }

    @override
    void initState() {
        super.initState();
    }

    @override
    void dispose() {
        _focusNode.unfocus();
        super.dispose();
    }

    String generateMd5(String data) {
        var content = new Utf8Encoder().convert(data);
        var md5 = crypto.md5;
        var digest = md5.convert(content);
        return hex.encode(digest.bytes);
    }

    void commentToPickedFeed(String comment) {
        var ref = Firestore.instance.collection("picked")
            .document(generateMd5(item.link));
        Map<String, dynamic> data = {
            'title': item.title,
            'description': DetailFeedPost.parseDescription(item.description),
            'image': DetailFeedPost.parseImageUrl(
                item.content != null
                    ? item.content.images.first
                    : item.description),
            'link': item.link,
            'comments': {
                'user001': {
                    'userId': 'user001',
                    'comment': comment,
                    'datetime': DateTime.now()
                }
            }
        };
        ref.setData(data, merge: true);
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text('📮')),
            body: Column(children: <Widget>[
                Padding(
                    padding: EdgeInsets.all(4.0),
                    child: TextFormField(
                        autovalidate: true,
                        decoration: InputDecoration(
                            labelText: 'この記事についてコメント',
                        ),
                        maxLines: 10,
                        controller: myController,
                        validator: (String value) {
                            return value.isEmpty ? '入力必須です' : null;
                        },
                        onFieldSubmitted: (String value) {
                            _focusNode.unfocus();
                        },
                    ),
                ),
                Card(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                            Image.network(DetailFeedPost.parseImageUrl(
                                item.content != null
                                    ? item.content.images.first
                                    : item.description),
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                            ),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                        Container(
                                            margin: EdgeInsets.all(10.0),
                                            child: ListTile(
                                                title: Text(
                                                    item.title,
                                                    style: TextStyle(fontSize: 12.0)
                                                ),
                                                subtitle:
                                                Text(
                                                    DetailFeedPost.parseDescription(item.description),
                                                    style: TextStyle(fontSize: 10.0)
                                                ),
                                            )),
                                    ],
                                ),
                            ),
                        ],
                    )
                )
            ],),
            floatingActionButton: FloatingActionButton(
                onPressed: () {
                    if (myController.text.isNotEmpty) {
                        commentToPickedFeed(myController.text);
                        saveData();
                        Navigator.pop(context);
                    }
                },
                child: Icon(Icons.send),
                backgroundColor: Colors.pink,
            ),
        );
    }
}