import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class SubjectsView extends StatefulWidget {
  const SubjectsView({Key? key}) : super(key: key);
  final uuid = const Uuid();

  @override
  State<SubjectsView> createState() => _SubjectsViewState();
}

class _SubjectsViewState extends State<SubjectsView> {
  // text fields' controllers
  final TextEditingController _idSubject = TextEditingController();
  final TextEditingController _nameSubject = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final CollectionReference _lecturer =
      FirebaseFirestore.instance.collection('subjects');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Class'),
        ),

        // Using StreamBuilder to display all products from Firestore in real-time
        body: StreamBuilder(
          stream: _lecturer.snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
            if (streamSnapshot.hasData) {
              return ListView.builder(
                itemCount: streamSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final DocumentSnapshot documentSnapshot =
                      streamSnapshot.data!.docs[index];
                  return Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          border: Border.all(width: 1, color: Colors.black),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ma subject: ${documentSnapshot['idsubject']}',
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                  'Subject Title: ${documentSnapshot['subjecttitle']}'),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                  'Description: ${documentSnapshot['description']}'),
                              const SizedBox(
                                height: 5,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Press this button to edit a single product
                              IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      _createOrUpdate(documentSnapshot)),
                              // This icon button is used to delete a single product
                              IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteSubject(
                                      documentSnapshot.id,
                                      documentSnapshot['idsubject'])),
                            ],
                          ),
                        ],
                      ));
                },
              );
            }

            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
        // Add new product
        floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(),
          onPressed: () => _createOrUpdate(),
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat);
  }

  // This function is triggered when the floatting button or one of the edit buttons is pressed
  // Adding a product if no documentSnapshot is passed
  // If documentSnapshot != null then update an existing product
  // [DocumentSnapshot? documentSnapshot] is optional positional parameters its should be last position
  // when functions have >= 2 parameters.

  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _idSubject.text = documentSnapshot['idsubject'].toString();
      _description.text = documentSnapshot['description'];
      _nameSubject.text = documentSnapshot['subjecttitle'];
    }

    await _buildBottomSheet(action, documentSnapshot);
  }

  Future<dynamic> _buildBottomSheet(
      String action, DocumentSnapshot<Object?>? documentSnapshot) {
    return showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                // prevent the soft keyboard from covering text fields
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _idSubject,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          ],
                          decoration:
                              const InputDecoration(labelText: 'Id Class'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Id';
                            } else if (value.length >= 6) {
                              return 'Only 5 characters';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          keyboardType: TextInputType.text,
                          controller: _nameSubject,
                          decoration: const InputDecoration(
                            labelText: 'Class name',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Class name';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _description,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Amount'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Amount';
                            }
                            // else if (!value.contains('@')) {
                            //   return 'Must have @';
                            // }
                            return null;
                          },
                        ),
                        TextFormField(
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Id Lecturer'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Lecturer';
                            }
                            return null;
                          },
                        ),
                      ],
                    )),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    final int? id = int.tryParse(_idSubject.text);
                    final String description = _description.text;
                    final String subjecttitle = _nameSubject.text;
                    if (_formKey.currentState!.validate()) {
                      if (action == 'create') {
                        // Persist a new product to Firestore
                        await _lecturer.add({
                          'uuid': widget.uuid.v4(),
                          "idclass": id,
                          "subjecttitle": subjecttitle,
                          "description": description,
                        });
                      }
                      if (action == 'update') {
                        // Update the product

                        await _lecturer.doc(documentSnapshot!.id).update({
                          'uuid': widget.uuid.v4(),
                          "idclass": id,
                          "subjecttitle": subjecttitle,
                          "description": description,
                        });
                      }

                      // Clear the text fields
                      _idSubject.text = '';
                      _description.text = '';
                      _nameSubject.text = '';

                      // Hide the bottom sheet
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          duration: const Duration(seconds: 2),
                          content: Text(
                            '${action == 'create' ? 'Create' : 'Update'} information successfully',
                            style: const TextStyle(
                                color: Color.fromARGB(255, 0, 255, 8),
                                fontSize: 18),
                          )));
                    }
                  },
                )
              ],
            ),
          );
        });
  }

  // Deleteing a lecturer by id
  Future<void> _deleteSubject(String lecturerId, int Id) async {
    await showDialog(
        context: context,
        // Can't GestureDetector outside dialog
        barrierDismissible: false,
        builder: (builder) => AlertDialog(
              actions: [
                TextButton(
                  child: const Text('Oke'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    _lecturer.doc(lecturerId).delete();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        elevation: 20,
                        duration: Duration(seconds: 2),
                        content: Text(
                          'Deleted information successfully',
                          style: TextStyle(
                              color: Color.fromARGB(255, 0, 255, 8),
                              fontSize: 18),
                        )));
                  },
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
              ],
              content: Text("ID: $Id"),
              title: const Text('Do you want to delete this ID?'),
            ));

    // Show a snackbar
  }
}
