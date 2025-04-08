import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TaskScreen(title: 'Task Management'),
    );
  }
}

class TaskScreen extends StatefulWidget {
  TaskScreen({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  TaskScreenState createState() => TaskScreenState();
}

class TaskScreenState extends State<TaskScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final TextEditingController taskName = TextEditingController();

  User? user;

  @override
  void initState() {
    super.initState();
    user = auth.currentUser;
  }

  void addTask() {
    if (taskName.text.isNotEmpty) {
      firestore.collection('tasks').add({
        'name': taskName.text,
        'isDone': false,
        'userID': user!.uid,
      });
      taskName.clear();
    }
  }

  void updateTask(String taskId, bool isDone) {
    firestore.collection('tasks').doc(taskId).update({'isDone': isDone});
  }

  void removeTask(String taskId) {
    firestore.collection('tasks').doc(taskId).delete();
  }

  void logOut() async {
    await auth.signOut();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => MyApp()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [IconButton(icon: Icon(Icons.exit_to_app), onPressed: logOut)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: taskName,
              decoration: InputDecoration(
                labelText: 'Task Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(onPressed: addTask, child: Text('Add Task')),
          Expanded(
            child: StreamBuilder(
              stream:
                  firestore
                      .collection('tasks')
                      .where('userID', isEqualTo: user!.uid)
                      .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                ;
                var tasks = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    bool isDone = task['isDone'];
                    return ListTile(
                      title: Text(
                        task['name'],
                        style: TextStyle(
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: isDone,
                            onChanged: (value) {
                              updateTask(task.id, value!);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              removeTask(task.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}