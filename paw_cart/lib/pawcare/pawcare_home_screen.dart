import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pet_assessment_screen.dart';
import 'pet_chat_screen.dart';

const Color pawCarePink = Color(0xFFFF6F9F);
const Color pawCarePalePink = Color(0xFFFFE7EF);
const Color pawCareCream = Color(0xFFFFFAF7);
const Color pawCareInk = Color(0xFF382B32);
const Color pawCareMuted = Color(0xFF8E7D85);

class PawCareHomeScreen extends StatefulWidget {
  const PawCareHomeScreen({super.key});

  @override
  State<PawCareHomeScreen> createState() => _PawCareHomeScreenState();
}

class _PawCareHomeScreenState extends State<PawCareHomeScreen> {
  String? selectedPetId;
  Map<String, dynamic>? selectedPet;

  String _petEmoji(String species) {
    switch (species.toLowerCase()) {
      case 'dog': return '🐶';
      case 'cat': return '🐱';
      case 'bird': return '🐦';
      case 'rabbit': return '🐰';
      default: return '🐾';
    }
  }

  void _selectPet(String id, Map<String, dynamic> pet) {
    setState(() {
      selectedPetId = id;
      selectedPet = pet;
    });
  }

  void _openAssessment() {
    if (selectedPet == null) return;
    final species = (selectedPet!['species'] as String? ?? '').toLowerCase().trim();
    if (!['dog', 'cat', 'bird', 'rabbit'].contains(species)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PawCare assessments currently support dogs, cats, birds and rabbits.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PetAssessmentScreen(pet: Map<String, dynamic>.from(selectedPet!))),
    );
  }

  void _openChat() {
    if (selectedPet == null) return;
    final species = (selectedPet!['species'] as String? ?? '').toLowerCase().trim();
    if (!['dog', 'cat', 'bird', 'rabbit'].contains(species)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PawCare chat currently supports dogs, cats, birds and rabbits.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PetChatScreen(pet: Map<String, dynamic>.from(selectedPet!))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to use PawCare AI.')));
    }

    final petsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .orderBy('createdAt')
        .snapshots();

    return Scaffold(
      backgroundColor: pawCareCream,
      appBar: AppBar(
        backgroundColor: pawCareCream,
        title: const Text('PawCare AI 🐾',
            style: TextStyle(fontWeight: FontWeight.w900, color: pawCareInk)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: petsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load your pet profiles.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: pawCarePink));
          }

          final pets = snapshot.data?.docs ?? [];
          if (pets.isEmpty) return _buildEmptyPets();

          final selectedDocument = pets.where((pet) => pet.id == selectedPetId);
          if (selectedDocument.isNotEmpty) {
            selectedPet = selectedDocument.first.data();
          } else {
            selectedPetId = pets.first.id;
            selectedPet = pets.first.data();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 25),
              const Text('Choose your little companion',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: pawCareInk)),
              const SizedBox(height: 5),
              const Text('Select a pet to personalise your care experience.',
                  style: TextStyle(color: pawCareMuted, fontSize: 13)),
              const SizedBox(height: 15),
              ...pets.map((petDocument) {
                final pet = petDocument.data();
                final isSelected = selectedPetId == petDocument.id;
                final name = pet['name'] as String? ?? 'My pet';
                final species = pet['species'] as String? ?? 'Other';
                final breed = pet['breed'] as String? ?? '';
                return GestureDetector(
                  onTap: () => _selectPet(petDocument.id, pet),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? pawCarePink : const Color(0xFFF0E4E9),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58, height: 58, alignment: Alignment.center,
                          decoration: BoxDecoration(color: pawCarePalePink, borderRadius: BorderRadius.circular(17)),
                          child: Text(_petEmoji(species), style: const TextStyle(fontSize: 32)),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: pawCareInk)),
                              const SizedBox(height: 4),
                              Text([
                                species,
                                if (breed.isNotEmpty) breed,
                                if (pet['age'] != null) '${pet['age']} years old',
                              ].join(' • '), style: const TextStyle(color: pawCareMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                            color: isSelected ? pawCarePink : pawCareMuted),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 15),
              if (selectedPet != null) ...[
                Text('Care options for ${selectedPet!['name']}',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: pawCareInk)),
                const SizedBox(height: 13),
                _buildFeatureCard(
                  icon: Icons.assignment_outlined,
                  title: 'Pet Health Assessment',
                  description: 'Answer a few questions and receive a personalised care report.',
                  buttonLabel: 'Start assessment',
                  onTap: _openAssessment,
                ),
                const SizedBox(height: 13),
                _buildFeatureCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Ask PawCare AI',
                  description: 'Ask questions about nutrition, hygiene, exercise and everyday pet care.',
                  buttonLabel: 'Start chatting',
                  onTap: _openChat,
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: pawCarePalePink, borderRadius: BorderRadius.circular(18)),
                  child: const Text('Select a pet above to explore personalised care options. 💗',
                      style: TextStyle(color: pawCareInk, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 22),
              const Text(
                'PawCare AI provides general pet-care information and does not replace professional veterinary advice.',
                textAlign: TextAlign.center,
                style: TextStyle(color: pawCareMuted, fontSize: 11, height: 1.5),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFD8E5), Color(0xFFFFEEF3)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A little more love, a little better care 💗',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: pawCareInk)),
                SizedBox(height: 9),
                Text('Your AI-powered companion for everyday pet-care guidance.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: pawCareInk)),
              ],
            ),
          ),
          SizedBox(width: 10),
          Text('🐾', style: TextStyle(fontSize: 48)),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFF0E4E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(color: pawCarePalePink, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: pawCarePink, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: pawCareInk))),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(color: pawCareMuted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: pawCarePink, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPets() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐶 🐱', style: TextStyle(fontSize: 55)),
            const SizedBox(height: 16),
            const Text('No pets added yet!',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: pawCareInk)),
            const SizedBox(height: 8),
            const Text('Add a pet profile in My Pets before using PawCare AI.',
                textAlign: TextAlign.center, style: TextStyle(color: pawCareMuted, height: 1.5)),
            const SizedBox(height: 17),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: pawCarePink, foregroundColor: Colors.white),
              child: const Text('Back to PawCart'),
            ),
          ],
        ),
      ),
    );
  }
}
