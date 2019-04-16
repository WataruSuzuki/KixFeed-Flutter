import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TalkingPicked extends StatefulWidget {
    final Map<dynamic, dynamic> item;

    TalkingPicked(this.item);

    @override
    State createState() => _TalkingPickedState(item);
}

class _TalkingPickedState extends State<TalkingPicked> {
    final Map<dynamic, dynamic> item;

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
            appBar: AppBar(title: Text('📮')),
            body: streamBuilder(context),
            floatingActionButton: FloatingActionButton(
                onPressed: () {},
                child: Icon(Icons.add),
                backgroundColor: Colors.pink,
            ),
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

    Widget createPickedList(BuildContext context,
        List<DocumentSnapshot> documents) {
        return new RefreshIndicator(
            child: documents.isEmpty
                ? Center(
                child: Text(
                    'データがありません',
                    style: TextStyle(fontSize: 24),
                ))
                : ListView.builder(
                itemCount: documents.length,
                itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                        child: Card(
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                    Image.network(
                                        'https://image.flaticon.com/icons/png/512/36/36601.png',
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
                                                            'hoge',
                                                            style: TextStyle(
                                                                fontSize: 12.0)),
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
