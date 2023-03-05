import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class Students extends StatefulWidget {
  Students({Key? key}) : super(key: key);
  List<String> list = <String>['Male', 'Female'];
  final uuid = const Uuid();

  @override
  State<Students> createState() => _StudentsState();
}

class _StudentsState extends State<Students> {
  // text fields' controllers
  final TextEditingController _idSVController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _homeTownController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final CollectionReference _students =
      FirebaseFirestore.instance.collection('students');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Flutter connect to Firebase'),
        ),

        // Using StreamBuilder to display all products from Firestore in real-time
        body: StreamBuilder(
          stream: _students.snapshots(),
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
                                'ID: ${documentSnapshot['idsv']}',
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text('Date: ${documentSnapshot['date']}'),
                              const SizedBox(
                                height: 5,
                              ),
                              Text('Gender: ${documentSnapshot['gender']}'),
                              const SizedBox(
                                height: 5,
                              ),
                              Text('Hometown: ${documentSnapshot['hometown']}'),
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
                                  onPressed: () => _deleteProduct(
                                      documentSnapshot.id,
                                      documentSnapshot['idsv'])),
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
    String dropdownValue = widget.list.first;

    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _idSVController.text = documentSnapshot['idsv'].toString();
      _genderController.text = documentSnapshot['gender'];
      _dateOfBirthController.text = documentSnapshot['date'];
      _homeTownController.text = documentSnapshot['hometown'];
    }

    await _buildBottomSheet(dropdownValue, action, documentSnapshot);
  }

  Future<dynamic> _buildBottomSheet(String dropdownValue, String action,
      DocumentSnapshot<Object?>? documentSnapshot) {
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
                          controller: _idSVController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          ],
                          decoration:
                              const InputDecoration(labelText: 'Id students'),
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
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          controller: _dateOfBirthController,
                          decoration: const InputDecoration(
                            labelText: 'Date of birth',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Date of birth';
                            }
                            return null;
                          },
                        ),
                        // TextFormField(
                        //   controller: _genderController,
                        //   keyboardType: TextInputType.text,
                        //   decoration:
                        //       const InputDecoration(labelText: 'Gender'),
                        //   validator: (value) {
                        //     if (value == null || value.isEmpty) {
                        //       return 'Please enter your gender';
                        //     } else if (value.contains('male') ||
                        //         value.contains('female')) {
                        //       return 'Male or Female';
                        //     }
                        //     // else if (!value.contains('@')) {
                        //     //   return 'Must have @';
                        //     // }
                        //     return null;
                        //   },
                        // ),
                        DropdownButton<String>(
                          value: dropdownValue,
                          icon: const Icon(Icons.arrow_downward),
                          elevation: 16,
                          style: const TextStyle(color: Colors.deepPurple),
                          underline: Container(
                            height: 2,
                            color: Colors.deepPurpleAccent,
                          ),
                          onChanged: (String? value) {
                            // This is called when the user selects an item.
                            print('change $value');
                            setState(() {
                              dropdownValue = value!;
                            });
                          },
                          items: widget.list
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        // const DropdownButtonExample(),
                        TextFormField(
                          controller: _homeTownController,
                          keyboardType: TextInputType.text,
                          decoration:
                              const InputDecoration(labelText: 'Hometown'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Hometown';
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
                    final int? idSv = int.tryParse(_idSVController.text);
                    final String gender = dropdownValue;
                    // final String gender = _genderController.text;
                    final String dateOfBirth = _dateOfBirthController.text;
                    final String homeTown = _homeTownController.text;
                    if (_formKey.currentState!.validate()) {
                      if (action == 'create') {
                        // Persist a new product to Firestore
                        await _students.add({
                          'uuid': widget.uuid.v4(),
                          "idsv": idSv,
                          "date": dateOfBirth,
                          "gender": gender,
                          "hometown": homeTown
                        });
                      }
                      if (action == 'update') {
                        // Update the product

                        await _students.doc(documentSnapshot!.id).update({
                          "idsv": idSv,
                          "date": dateOfBirth,
                          "gender": gender,
                          "hometown": homeTown
                        });
                      }

                      // Clear the text fields
                      _idSVController.text = '';
                      _genderController.text = '';
                      // _genderController.text = '';
                      _dateOfBirthController.text = '';

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

  // Deleteing a product by id
  Future<void> _deleteProduct(String productId, int Id) async {
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
                    _students.doc(productId).delete();
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
