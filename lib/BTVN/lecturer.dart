import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class LecturerView extends StatefulWidget {
  const LecturerView({Key? key}) : super(key: key);
  final uuid = const Uuid();

  @override
  State<LecturerView> createState() => _LecturerViewState();
}

class _LecturerViewState extends State<LecturerView> {
  // text fields' controllers
  final TextEditingController _maGV = TextEditingController();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final CollectionReference _lecturer =
      FirebaseFirestore.instance.collection('lecturer');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Lecturer'),
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
                                'Id: ${documentSnapshot['magv']}',
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                  'Full name: ${documentSnapshot['fullname']}'),
                              const SizedBox(
                                height: 5,
                              ),
                              Text('Address: ${documentSnapshot['address']}'),
                              const SizedBox(
                                height: 5,
                              ),
                              Text('Phone: ${documentSnapshot['phone']}'),
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
                                  onPressed: () => _deleteLecturer(
                                      documentSnapshot.id,
                                      documentSnapshot['magv'])),
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
      _maGV.text = documentSnapshot['magv'].toString();
      _address.text = documentSnapshot['address'];
      _fullName.text = documentSnapshot['fullname'];
      _phone.text = documentSnapshot['phone'].toString();
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
                          controller: _maGV,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          ],
                          decoration:
                              const InputDecoration(labelText: 'Id Lecture'),
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
                          controller: _fullName,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Full Name';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _address,
                          keyboardType: TextInputType.text,
                          decoration:
                              const InputDecoration(labelText: 'Address'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Address';
                            }
                            // else if (!value.contains('@')) {
                            //   return 'Must have @';
                            // }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Phone'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Phone';
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
                    final int? id = int.tryParse(_maGV.text);
                    final String address = _address.text;
                    final String fullName = _fullName.text;
                    final int? phone = int.tryParse(_phone.text);
                    if (_formKey.currentState!.validate()) {
                      if (action == 'create') {
                        // Persist a new product to Firestore
                        await _lecturer.add({
                          'uuid': widget.uuid.v4(),
                          "magv": id,
                          "fullname": fullName,
                          "address": address,
                          "phone": phone
                        });
                      }
                      if (action == 'update') {
                        // Update the product

                        await _lecturer.doc(documentSnapshot!.id).update({
                          'uuid': widget.uuid.v4(),
                          "magv": id,
                          "fullname": fullName,
                          "address": address,
                          "phone": phone
                        });
                      }

                      // Clear the text fields
                      _maGV.text = '';
                      _address.text = '';
                      _phone.text = '';
                      _fullName.text = '';

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
  Future<void> _deleteLecturer(String lecturerId, int Id) async {
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
