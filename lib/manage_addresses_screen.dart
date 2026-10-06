import 'package:flutter/material.dart';

class ManageAddressesScreen extends StatefulWidget {
  const ManageAddressesScreen({super.key});

  @override
  State<ManageAddressesScreen> createState() => _ManageAddressesScreenState();
}

class _ManageAddressesScreenState extends State<ManageAddressesScreen> {
  final List<String> _addresses = [
    "Plot - 1,RoadNo - 1, Vaishnavi nagar, suraram, Hyderabad - 500055",
  ];

  void _addNewAddress() {
    showDialog(
      context: context,
      builder: (context) {
        String newAddress = "";
        return AlertDialog(
          title: const Text("Add New Address"),
          content: TextField(
            onChanged: (value) => newAddress = value,
            decoration: const InputDecoration(hintText: "Enter full address"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (newAddress.isNotEmpty) {
                  setState(() {
                    _addresses.add(newAddress);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Addresses"), centerTitle: true),
      body: _addresses.isEmpty
          ? const Center(child: Text("No addresses saved yet."))
          : ListView.builder(
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.green),
                    title: Text(_addresses[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _addresses.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAddress,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
