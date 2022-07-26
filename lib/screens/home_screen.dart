import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todo_app_using_hive/models/todo.dart';

enum Priority { week, normal, strong }

Priority? priority;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _myBox = Hive.box('todo');

  List<bool> checkboxList = [];

  // TextFields' controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _timingController = TextEditingController();

  bool checkboxStatus = false;

  StreamController<Priority> refreshRadioButtons = StreamController<Priority>.broadcast();

  @override
  void initState() {
    super.initState();
    _refreshItems(); // Load data when app starts
  }

  // Get all items from the database
  void _refreshItems() {
    setState(() {
      checkboxList = List.generate(_myBox.length, (index) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pioneers Hive Example'),
        actions: [
          IconButton(
            onPressed: () {
              bool itemToDelete = false;
              for (int i = 0; i < checkboxList.length; i++) {
                if (checkboxList[i]) {
                  _deleteItem(i);
                  itemToDelete = true;
                }
              }

              if (itemToDelete == false) {
                checkboxStatus = true;
              }

              setState(() {});
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: _myBox.isEmpty
          ? const Center(
              child: Text(
                'No Data',
                style: TextStyle(fontSize: 30),
              ),
            )
          : ListView.builder(
              // the list of items
              itemCount: _myBox.length,
              itemBuilder: (_, index) {
                Todo currentItem = _myBox.getAt(index);
                return Card(
                  color: Colors.orange.shade100,
                  margin: const EdgeInsets.all(10),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(currentItem.title),
                                Text(currentItem.desc),
                                Text(currentItem.timing),
                                Text(currentItem.priority),
                              ],
                            ),
                          ),
                          Expanded(
                              child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Edit button
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showForm(ctx: context, index: index);
                                },
                              ),
                              // Delete button
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteItem(index),
                              ),

                              checkboxStatus == true
                                  ? Checkbox(
                                      value: checkboxList[index],
                                      onChanged: (value) {
                                        checkboxList[index] = value!;
                                        setState(() {});
                                      },
                                    )
                                  : Container()
                            ],
                          ))
                        ],
                      ),
                    ),
                  ),
                );
              }),
      // Add new item button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(ctx: context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showForm({required BuildContext ctx, int? index}) async {
    showModalBottomSheet(
        context: ctx,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 15, left: 15, right: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'Title'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(hintText: 'Description'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _timingController,
                    decoration: const InputDecoration(hintText: 'Time'),
                  ),
                  StreamBuilder<Priority>(
                      stream: refreshRadioButtons.stream,
                      initialData: Priority.normal,
                      builder: (context, snapshot) {
                        return Row(
                          children: [
                            Radio<Priority>(
                              groupValue: priority,
                              value: Priority.week,
                              onChanged: (Priority? value) {
                                print("value");
                                print(value);

                                priority = value!;
                                refreshRadioButtons.sink.add(priority!);
                              },
                            ),
                            Text("Week"),
                            Radio<Priority>(
                              groupValue: priority,
                              value: Priority.normal,
                              onChanged: (Priority? value) {
                                priority = value!;
                                refreshRadioButtons.sink.add(priority!);
                              },
                            ),
                            Text("Normal"),
                            Radio<Priority>(
                              groupValue: priority,
                              value: Priority.strong,
                              onChanged: (Priority? value) {
                                priority = value!;
                                refreshRadioButtons.sink.add(priority!);
                              },
                            ),
                            Text("Strong"),
                          ],
                        );
                      }),
                  const SizedBox(
                    height: 50,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Save new item
                      if (_titleController.text.isNotEmpty &&
                          _descController.text.isNotEmpty &&
                          _timingController.text.isNotEmpty &&
                          priority != null) {
                        if (index == null) {
                          _createItem(Todo(
                              title: _titleController.text,
                              desc: _descController.text,
                              timing: _timingController.text,
                              priority: priority == Priority.week
                                  ? "week"
                                  : priority == Priority.normal
                                      ? "normal"
                                      : "strong"));
                        } else {
                          _updateItem(
                              index,
                              Todo(
                                  title: _titleController.text,
                                  desc: _descController.text,
                                  timing: _timingController.text,
                                  priority: priority == Priority.week
                                      ? "week"
                                      : priority == Priority.normal
                                          ? "normal"
                                          : "strong"));
                        }
                      } else {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('you have to fill all the fields')));
                        return;
                      }

                      // Clear the text fields
                      _titleController.text = "";
                      _descController.text = "";
                      _timingController.text = "";
                      priority = null;

                      Navigator.of(context).pop(); // Close the bottom sheet
                    },
                    child: Text(index != null ? 'Update Item' : 'Create New'),
                  ),
                  const SizedBox(
                    height: 15,
                  )
                ],
              ),
            )).then((value) {
      // Clear the text fields
      _titleController.text = "";
      _descController.text = "";
      _timingController.text = "";
      priority = null;
    });
  }

  Future<void> _deleteItem(int index) async {
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget confirmtionButton = TextButton(
      child: const Text("Confirm"),
      onPressed: () async {
        await _myBox.deleteAt(index);
        Navigator.of(context).pop();

        _refreshItems(); // update the UI
        // Display a snackbar
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An item has been deleted')));
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Are You Sure ?"),
      content: Text("Would you like to delete the item with id $index"),
      actions: [
        cancelButton,
        confirmtionButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> _createItem(Todo newItem) async {
    await _myBox.add(newItem);
    _refreshItems(); // update the UI
  }

  Future<void> _updateItem(int index, Todo item) async {
    await _myBox.putAt(index, item);
    _refreshItems(); // Update the UI
  }
}
