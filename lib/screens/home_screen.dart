import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _items = [];
  final _myBox = Hive.box('todo');

  List<bool> checkboxList = [];

  // TextFields' controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  bool checkboxStatus = false;

  @override
  void initState() {
    super.initState();
    _refreshItems(); // Load data when app starts
  }

  // Get all items from the database
  void _refreshItems() {
    final data = _myBox.keys.map((key) {
      final value = _myBox.get(key);
      return {"key": key, "name": value["name"], "quantity": value['quantity']};
    }).toList();

    setState(() {
      _items = data.reversed.toList();
      checkboxList = List.generate(_items.length, (index) => false);
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
                  _deleteItem(_items[i]['key']);
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
      body: _items.isEmpty
          ? const Center(
              child: Text(
                'No Data',
                style: TextStyle(fontSize: 30),
              ),
            )
          : ListView.builder(
              // the list of items
              itemCount: _items.length,
              itemBuilder: (_, index) {
                final currentItem = _items[index];
                return Card(
                  color: Colors.orange.shade100,
                  margin: const EdgeInsets.all(10),
                  elevation: 3,
                  child: ListTile(
                      title: Text(currentItem['name']),
                      subtitle: Text(currentItem['quantity'].toString()),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit button
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _nameController.text = currentItem['name'];
                              _quantityController.text =
                                  currentItem['quantity'].toString();

                              _showForm(
                                  ctx: context, itemKey: currentItem['key']);
                            },
                          ),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteItem(currentItem['key']),
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
                      )),
                );
              }),
      // Add new item button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(ctx: context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showForm({required BuildContext ctx, int? itemKey}) async {
    showModalBottomSheet(
        context: ctx,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  top: 15,
                  left: 15,
                  right: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Name'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: const InputDecoration(hintText: 'Quantity'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Save new item
                      if (itemKey == null) {
                        if (_nameController.text.isNotEmpty) {
                          if (_quantityController.text.isNotEmpty) {
                            _createItem({
                              "name": _nameController.text,
                              "quantity": _quantityController.text
                            });
                          } else {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('you have to fill the quantity')));
                            return;
                          }
                        } else {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('you have to fill the name')));
                          return;
                        }
                      } else {
                        _updateItem(itemKey, {
                          'name': _nameController.text.trim(),
                          'quantity': _quantityController.text.trim()
                        });
                      }

                      // Clear the text fields
                      _nameController.text = '';
                      _quantityController.text = '';

                      Navigator.of(context).pop(); // Close the bottom sheet
                    },
                    child: Text(itemKey != null ? 'Update Item' : 'Create New'),
                  ),
                  const SizedBox(
                    height: 15,
                  )
                ],
              ),
            )).then((value) {
      // Clear the text fields
      _nameController.text = '';
      _quantityController.text = '';
    });
  }

  Future<void> _deleteItem(int itemKey) async {
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget confirmtionButton = TextButton(
      child: const Text("Confirm"),
      onPressed: () async {
        await _myBox.delete(itemKey);
        Navigator.of(context).pop();

        _refreshItems(); // update the UI
        // Display a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An item has been deleted')));
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Are You Sure ?"),
      content: Text("Would you like to delete the item with id $itemKey"),
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

  Future<void> _createItem(Map<String, dynamic> newItem) async {
    await _myBox.add(newItem);
    _refreshItems(); // update the UI
  }

  Future<void> _updateItem(int itemKey, Map<String, dynamic> item) async {
    await _myBox.put(itemKey, item);
    _refreshItems(); // Update the UI
  }
}
