import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../database/stock_database.dart';
import '../models/stock_model.dart';

class AddEditScreen extends StatefulWidget {
  final StockMovement? movement; // The movement to edit, null for new item
  final Function refreshCallback; // Function to refresh data after adding/editing

  const AddEditScreen({Key? key, this.movement, required this.refreshCallback}) : super(key: key);

  @override
  _AddEditScreenState createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _operatorController = TextEditingController();
  String _selectedMovement = 'entrée';
  String _selectedLocation = 'AS-01';
  DateTime _selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.movement != null) {
      final movement = widget.movement!;
      _productController.text = movement.productName;
      _selectedMovement = movement.movementType;
      _selectedLocation = movement.storageLocation;
      _quantityController.text = movement.quantity.toString();
      _operatorController.text = movement.operatorName;
      _selectedDateTime = movement.dateTime;
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveMovement() async {
    if (_formKey.currentState!.validate()) {
      // If it's a new movement, generate the next ID
      final int newId = widget.movement == null ? await StockDatabase.getNextMovementId() : widget.movement!.id;

      final newMovement = StockMovement(
        id: newId, // Use existing ID for editing or generate new ID for adding
        productName: _productController.text,
        movementType: _selectedMovement,
        storageLocation: _selectedLocation,
        quantity: int.tryParse(_quantityController.text) ?? 0,
        operatorName: _operatorController.text,
        dateTime: _selectedDateTime,
      );

      try {
        if (widget.movement != null) {
          // Edit the existing movement
          await StockDatabase.editMovement(newMovement.id, newMovement);
        } else {
          // Add the new movement
          await StockDatabase.addMovement(newMovement);
        }

        widget.refreshCallback(); // Refresh the list of movements
        Navigator.pop(context); // Go back to the main screen
      } catch (e) {
        print("Error saving movement: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movement == null ? 'Ajouter un mouvement' : 'Modifier le mouvement'),
        backgroundColor: const Color.fromARGB(255, 227, 219, 250),
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _productController,
                decoration: const InputDecoration(labelText: 'Nom du produit'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un nom de produit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantité'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir une quantité';
                  } else if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un numéro valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMovement,
                decoration: const InputDecoration(labelText: 'Type de mouvement'),
                items: const ['entrée', 'sortie']
                    .map((movement) => DropdownMenuItem<String>(
                          value: movement,
                          child: Text(movement),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMovement = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: const InputDecoration(labelText: 'Emplacement de stockage'),
                items: const ['AS-01', 'AS-02', 'AS-03']
                    .map((location) => DropdownMenuItem<String>(
                          value: location,
                          child: Text(location),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _operatorController,
                decoration: const InputDecoration(labelText: 'Opérateur/Opératrice'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Date et Heure: ${DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime)}',
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.black),
                    onPressed: _pickDateTime,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveMovement,
                child: Text(widget.movement == null ? 'Ajouter' : 'Modifier',style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
