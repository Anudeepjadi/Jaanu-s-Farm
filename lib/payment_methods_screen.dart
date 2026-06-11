import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, String>> _paymentMethods = [
    {"type": "Visa", "number": "**** **** **** 4582", "expiry": "05/26"},
    {"type": "UPI", "number": "jaanu.farms@upi", "expiry": ""},
  ];

  void _addPaymentMethod() {
    showDialog(
      context: context,
      builder: (context) {
        String methodType = "Card";
        String details = "";
        return AlertDialog(
          title: const Text("Add Payment Method"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: methodType,
                items: ["Card", "UPI", "Wallet"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) => setState(() => methodType = val!),
              ),
              TextField(
                onChanged: (value) => details = value,
                decoration: const InputDecoration(hintText: "Enter Card Number or UPI ID or Wallet"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (details.isNotEmpty) {
                  setState(() {
                    _paymentMethods.add({
                      "type": methodType,
                      "number": details,
                      "expiry": methodType == "Card" ? "12/29" : "",
                    });
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
      appBar: AppBar(
        title: const Text("Payment Methods"),
        centerTitle: true,
      ),
      body: _paymentMethods.isEmpty
          ? const Center(child: Text("No payment methods saved."))
          : ListView.builder(
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final method = _paymentMethods[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      method['type'] == "UPI" ? Icons.account_balance_wallet : Icons.credit_card,
                      color: Colors.green,
                    ),
                    title: Text("${method['type']} - ${method['number']}"),
                    subtitle: method['expiry']!.isNotEmpty ? Text("Expiry: ${method['expiry']}") : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _paymentMethods.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPaymentMethod,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
