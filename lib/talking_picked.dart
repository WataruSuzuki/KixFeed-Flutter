import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TalkingPicked extends StatefulWidget {
    final String item;

    TalkingPicked(this.item);

    @override
    State createState() => _TalkingPickedState(item);
}

class _TalkingPickedState extends State<TalkingPicked> {
    final String item;

    _TalkingPickedState(this.item);

    @override
    void initState() {
        super.initState();
    }

    @override
    void dispose() {
        super.dispose();
    }

    Future<void> _refresh() async {
        setState(() {});
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text('(・∀・)')),
            body: streamBuilder(context),
//            floatingActionButton: FloatingActionButton(
//                onPressed: () {},
//                child: Icon(Icons.add),
//                backgroundColor: Colors.pink,
//            ),
        );
    }

    StreamBuilder<QuerySnapshot> streamBuilder(BuildContext context) {
        return StreamBuilder<QuerySnapshot>(
            stream: Firestore.instance.collection('picked').snapshots(),
            builder: (BuildContext context,
                AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError)
                    return new Text('Error: ${snapshot.error}');
                switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                        return new Center(
                            child: CircularProgressIndicator(),
                        );
                    default:
                        if (snapshot.hasError) {
                            return new Text('Error: ${snapshot.error}');
                        } else {
                            return createPickedList(
                                context, snapshot.data.documents);
                        }
                }
            },
        );
    }

    Widget createPickedList(BuildContext context, List<DocumentSnapshot> documents) {
        DocumentSnapshot document = documents.firstWhere((f) => f.documentID == item);
        Map<dynamic, dynamic> comments = document['comments'];
        List commentList = comments.values.toList();
        return new RefreshIndicator(
            child: commentList.isEmpty
                ? Center(
                child: Text(
                    'データがありません',
                    style: TextStyle(fontSize: 24),
                ))
                : ListView.builder(
                itemCount: commentList.length,
                itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                        child: Card(
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                    Image.network(
                                        'https://cdn2.iconfinder.com/data/icons/people-80/96/Picture1-512.png',
                                        height: 50,
                                        width: 50,
                                        fit: BoxFit.cover,
                                    ),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                                Container(
                                                    margin: EdgeInsets.all(
                                                        10.0),
                                                    child: ListTile(
                                                        title: Text(
                                                            commentList[index]['comment'],
                                                            style: TextStyle(
                                                                fontSize: 12.0)
                                                        ),
                                                        subtitle: Text(
                                                            (commentList[index]['datetime'] as Timestamp).toDate().toString(),
                                                            style: TextStyle(
                                                                fontSize: 10.0)
                                                        ),
                                                    )),
                                            ]),
                                    ),
                                ],
                            )),
                        onTapUp: (details) {},
                    );
                },
            ),
            onRefresh: _refresh,
        );
    }
}
