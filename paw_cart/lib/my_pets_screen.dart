
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color petPink = Color(0xFFFF6F9F);
const Color petPalePink = Color(0xFFFFE7EF);
const Color petCream = Color(0xFFFFFAF7);
const Color petInk = Color(0xFF382B32);
const Color petMuted = Color(0xFF8E7D85);

class MyPetsScreen extends StatefulWidget {
  const MyPetsScreen({super.key});

  @override
  State<MyPetsScreen> createState() => _MyPetsScreenState();
}

class _MyPetsScreenState extends State<MyPetsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> get petsCollection =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('pets');

  Future<void> _showPetForm({
    String? petId,
    Map<String, dynamic>? existingPet,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController =
        TextEditingController(text: existingPet?['name'] ?? '');
    final breedController =
        TextEditingController(text: existingPet?['breed'] ?? '');
    final ageController =
        TextEditingController(text: existingPet?['age']?.toString() ?? '');
    String species = existingPet?['species'] ?? 'Dog';
    String gender = existingPet?['gender'] ?? 'Not specified';

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: petCream,
            title: Text(
              petId == null ? 'Add your pet 🐾' : 'Edit pet details',
              style: const TextStyle(
                color: petInk,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Pet name *',
                        prefixIcon: Icon(Icons.pets_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter your pet’s name'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: species,
                      decoration: const InputDecoration(labelText: 'Species'),
                      items: ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other']
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => species = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: breedController,
                      decoration: const InputDecoration(
                        labelText: 'Breed (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age in years (optional)',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        final age = int.tryParse(value.trim());
                        if (age == null || age < 0 || age > 100) {
                          return 'Enter a valid age';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                     initialValue: gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: ['Not specified', 'Male', 'Female']
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => gender = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: petMuted),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: petPink,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final data = <String, dynamic>{
                    'name': nameController.text.trim(),
                    'species': species,
                    'breed': breedController.text.trim(),
                    'age': ageController.text.trim().isEmpty
                        ? null
                        : int.parse(ageController.text.trim()),
                    'gender': gender,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  try {
                    if (petId == null) {
                      data['createdAt'] = FieldValue.serverTimestamp();
                      await petsCollection.add(data);
                    } else {
                      await petsCollection.doc(petId).update(data);
                    }

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                            petId == null
                                ? '${nameController.text.trim()} added! 🐾'
                                : 'Pet details updated!',
                          ),
                        ),
                      );
                    }
                  } catch (error) {
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text('Could not save pet: $error')),
                      );
                    }
                  }
                },
                child: Text(petId == null ? 'Save pet' : 'Save changes'),
              ),
            ],
          ),
        ),
      );
    } finally {
      nameController.dispose();
      breedController.dispose();
      ageController.dispose();
    }
  }

  Future<void> _deletePet(String petId, String petName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: petCream,
        title: const Text('Delete pet profile?'),
        content: Text('Remove $petName from your pet profiles?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: petPink,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await petsCollection.doc(petId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$petName deleted.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete pet: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        backgroundColor: petCream,
        body: Center(child: Text('Please log in to view your pets.')),
      );
    }

    return Scaffold(
      backgroundColor: petCream,
      appBar: AppBar(
        backgroundColor: petCream,
        title: const Text(
          'My Pets 🐾',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: petPink,
        foregroundColor: Colors.white,
        onPressed: () => _showPetForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add pet'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: petsCollection.orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load pet profiles. Please check your connection '
                  'and Firestore security rules.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: petPink),
            );
          }

          final pets = snapshot.data?.docs ?? [];

          if (pets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🐶 🐱', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    const Text(
                      'No pets added yet!',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: petInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your furry friend’s details to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: petMuted),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: petPink,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showPetForm(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add your first pet'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Text(
                  'Your little family 💗',
                  style: TextStyle(fontSize: 16, color: petMuted),
                ),
              ),
              ...pets.map((petDocument) {
                final pet = petDocument.data();
                final name = pet['name'] as String? ?? 'My pet';
                final species = pet['species'] as String? ?? 'Other';
                final breed = pet['breed'] as String? ?? '';
                final age = pet['age'];
                final gender =
                    pet['gender'] as String? ?? 'Not specified';
                final emoji = species == 'Cat'
                    ? '🐱'
                    : species == 'Bird'
                        ? '🐦'
                        : species == 'Rabbit'
                            ? '🐰'
                            : species == 'Dog'
                                ? '🐶'
                                : '🐾';

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: petPalePink,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: petInk,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  species,
                                  if (breed.isNotEmpty) breed,
                                  if (age != null)
                                    '$age ${age == 1 ? 'year' : 'years'} old',
                                  if (gender != 'Not specified') gender,
                                ].join(' • '),
                                style: const TextStyle(
                                  color: petMuted,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showPetForm(
                                      petId: petDocument.id,
                                      existingPet: pet,
                                    ),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 17,
                                    ),
                                    label: const Text('Edit'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: petPink,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  TextButton.icon(
                                    onPressed: () => _deletePet(
                                      petDocument.id,
                                      name,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 17,
                                    ),
                                    label: const Text('Delete'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

