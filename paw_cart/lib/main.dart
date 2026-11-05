import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'checkout_screen.dart';
import 'order_state_machine.dart';
import 'order_model.dart';
import 'order_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'my_pets_screen.dart';
import 'pawcare/pawcare_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PawCartApp());
}

const Color pawPink = Color(0xFFFF6F9F);
const Color pawPalePink = Color(0xFFFFE7EF);
const Color pawCream = Color(0xFFFFFAF7);
const Color pawInk = Color(0xFF382B32);
const Color pawMuted = Color(0xFF8E7D85);

class PawCartApp extends StatelessWidget {
  const PawCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: pawPink,
      brightness: Brightness.light,
      surface: Colors.white,
    );

    return MaterialApp(
      title: 'PawCart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: pawCream,
        appBarTheme: const AppBarTheme(
          backgroundColor: pawCream,
          foregroundColor: pawInk,
          elevation: 0,
          centerTitle: false,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: pawInk,
          displayColor: pawInk,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      
home: StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = snapshot.data;

    if (user != null) {
      return const PawCartShell();
    }

    return const AuthScreen();
  },
),

    );
  }
}


class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.emoji,
    required this.description,
    required this.imageAsset,
    this.tag,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String emoji;
  final String description;
  final String imageAsset;
  final String? tag;
}


 
const List<Product> sampleProducts = [
  Product(
    id: 'p1',
    name: 'Cloud Nine Bed',
    category: 'Comfort',
    price: 899,
    emoji: '🛏️',
    imageAsset: 'assets/images/cloud_nine_bed.png',
    tag: 'Bestseller',
    description: 'A soft, cosy bed for long naps and sweet dreams.',
  ),
  Product(
    id: 'p2',
    name: 'Berry Rope Toy',
    category: 'Toys',
    price: 249,
    emoji: '🧸',
    imageAsset: 'assets/images/berry_rope_toy.png',
    tag: 'Playtime pick',
    description: 'A playful rope toy for supervised tug and fetch sessions.',
  ),
  Product(
    id: 'p3',
    name: 'Purrfect Bowl',
    category: 'Feeding',
    price: 399,
    emoji: '🥣',
    imageAsset: 'assets/images/purrfect_bowl.png',
    description: 'A cute everyday bowl for food or fresh water.',
  ),
  Product(
    id: 'p4',
    name: 'Paw Balm',
    category: 'Grooming',
    price: 299,
    emoji: '🧴',
    imageAsset: 'assets/images/paw_balm.png',
    description: 'A handy paw-care essential for your pet-care shelf.',
  ),
  Product(
    id: 'p5',
    name: 'Tiny Treat Jar',
    category: 'Treats',
    price: 349,
    emoji: '🍪',
    imageAsset: 'assets/images/tiny_treat_jar.png',
    tag: 'New',
    description: 'A reusable jar for keeping treats neat and easy to reach.',
  ),
  Product(
    id: 'p6',
    name: 'Meow Cushion',
    category: 'Comfort',
    price: 699,
    emoji: '🐱',
    imageAsset: 'assets/images/meow_cushion.png',
    description: 'A fluffy cushion for cats who take lounging seriously.',
  ),
  Product(
    id: 'p7',
    name: 'Walkies Set',
    category: 'Accessories',
    price: 599,
    emoji: '🦮',
    imageAsset: 'assets/images/walkies_set.png',
    description: 'A simple everyday walking set for your next adventure.',
  ),
  Product(
    id: 'p8',
    name: 'Happy Paws Kit',
    category: 'Grooming',
    price: 749,
    emoji: '🐾',
    imageAsset: 'assets/images/happy_paws_kit.png',
    tag: 'Pet parent fave',
    description: 'A starter kit for making grooming days feel less daunting.',
  ),
];


class PawCartShell extends StatefulWidget {
  const PawCartShell({super.key});

  @override
  State<PawCartShell> createState() => _PawCartShellState();
}

class _PawCartShellState extends State<PawCartShell> {
  int _selectedTab = 0;
  final Map<String, int> _cart = {};
  String _search = '';
  String _category = 'All';

  int get _cartCount => _cart.values.fold(0, (sum, quantity) => sum + quantity);

  double get _cartTotal {
    double total = 0;
    for (final entry in _cart.entries) {
      final product = sampleProducts.firstWhere((p) => p.id == entry.key);
      total += product.price * entry.value;
    }
    return total;
  }

  void _addToCart(Product product) {
    setState(() => _cart.update(product.id, (qty) => qty + 1, ifAbsent: () => 1));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${product.name} added to your cart 🐾'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _changeQuantity(Product product, int change) {
    setState(() {
      final next = (_cart[product.id] ?? 0) + change;
      if (next <= 0) {
        _cart.remove(product.id);
      } else {
        _cart[product.id] = next;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHome(),
      _buildShop(),
      _buildCart(),
      _buildOrders(),
      _buildProfile(),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _selectedTab, children: pages)),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _selectedTab,
        backgroundColor: Colors.white,
        indicatorColor: pawPalePink,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: pawPink),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: pawPink),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: _CartNavIcon(count: _cartCount),
            selectedIcon: _CartNavIcon(count: _cartCount, selected: true),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping, color: pawPink),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: pawPink),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    final featured = sampleProducts.take(4).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Row(
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: const BoxDecoration(
                    color: pawPalePink,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🐾', style: TextStyle(fontSize: 25)),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PawCart',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Little joys for your bestie',
                        style: TextStyle(color: pawMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Open cart',
                  onPressed: () => setState(() => _selectedTab = 2),
                  icon: Badge(
                    isLabelVisible: _cartCount > 0,
                    label: Text('$_cartCount'),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 27,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD8E5), Color(0xFFFFEEF3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'For the love\nof paws 💗',
                          style: TextStyle(
                            fontSize: 27,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Cute finds for your favourite little floof.',
                          style: TextStyle(fontSize: 13, color: pawInk),
                        ),
                        const SizedBox(height: 15),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: pawPink,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => setState(() => _selectedTab = 1),
                          child: const Text('Shop goodies'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('🐶', style: TextStyle(fontSize: 76)),
                ],
              ),
            ),
          ),
        ),

        // PawCare AI entry card.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PawCareHomeScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: const Color(0xFFFFD5E3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 58,
                        width: 58,
                        decoration: BoxDecoration(
                          color: pawPalePink,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Center(
                          child: Text(
                            '🐾',
                            style: TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meet PawCare AI 💗',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: pawInk,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Personalised pet-care guidance, assessments and AI chat.',
                              style: TextStyle(
                                fontSize: 11,
                                color: pawMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: pawPink,
                        size: 17,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _sectionHeading(
              'Shop by category',
              'Find their favourites',
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 105,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              scrollDirection: Axis.horizontal,
              children: const [
                _CategoryChip(label: 'Toys', emoji: '🧸'),
                _CategoryChip(label: 'Comfort', emoji: '🛏️'),
                _CategoryChip(label: 'Feeding', emoji: '🥣'),
                _CategoryChip(label: 'Grooming', emoji: '🫧'),
                _CategoryChip(label: 'Treats', emoji: '🍪'),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: _sectionHeading(
              'Little bestsellers',
              'Picked with love',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ProductCard(
                product: featured[index],
                onAdd: () => _addToCart(featured[index]),
                onTap: () => _showProductDetails(featured[index]),
              ),
              childCount: featured.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 13,
              mainAxisSpacing: 13,
              childAspectRatio: 0.73,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShop() {
    final categories = ['All', 'Toys', 'Comfort', 'Feeding', 'Grooming', 'Treats', 'Accessories'];
    final filtered = sampleProducts.where((product) {
      final matchesCategory = _category == 'All' || product.category == _category;
      final query = _search.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('The pet shop 🐾', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                const Text('Tiny treats, big tail wags.', style: TextStyle(color: pawMuted)),
                const SizedBox(height: 18),
                TextField(
                  onChanged: (value) => setState(() => _search = value),
                  decoration: const InputDecoration(
                    hintText: 'Search toys, beds, treats...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: categories.map((category) {
                      final selected = category == _category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (_) => setState(() => _category = category),
                          selectedColor: pawPalePink,
                          side: BorderSide(color: selected ? pawPink : const Color(0xFFF0E4E9)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (filtered.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No goodies found. Try another search 💗')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ProductCard(
                  product: filtered[index],
                  onAdd: () => _addToCart(filtered[index]),
                  onTap: () => _showProductDetails(filtered[index]),
                ),
                childCount: filtered.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 13,
                mainAxisSpacing: 13,
                childAspectRatio: 0.73,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCart() {
    final items = _cart.entries.toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const Text('Your little cart 🛍️', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('All their soon-to-be favourites.', style: TextStyle(color: pawMuted)),
        const SizedBox(height: 20),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: const Column(
              children: [
                Text('🛒', style: TextStyle(fontSize: 54)),
                SizedBox(height: 12),
                Text('Your cart is taking a nap', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                SizedBox(height: 5),
                Text('Add a few goodies for your bestie.', textAlign: TextAlign.center, style: TextStyle(color: pawMuted)),
              ],
            ),
          )
        else ...[
          ...items.map((entry) {
            final product = sampleProducts.firstWhere((p) => p.id == entry.key);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Container(
                    height: 68,
                    width: 68,
                    decoration: BoxDecoration(color: pawPalePink, borderRadius: BorderRadius.circular(16)),
                    child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      product.imageAsset,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: pawPink,
                          ),
                        );
                      },
                    ),
                  ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text('₹${product.price.toStringAsFixed(0)}', style: const TextStyle(color: pawPink, fontWeight: FontWeight.w800)),
                        Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _changeQuantity(product, -1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _changeQuantity(product, 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
            child: Column(
              children: [
                _priceRow('Subtotal', '₹${_cartTotal.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _priceRow('Delivery', _cartTotal >= 999 ? 'FREE' : '₹49'),
                const Divider(height: 22),
                _priceRow('Total', '₹${(_cartTotal + (_cartTotal >= 999 ? 0 : 49)).toStringAsFixed(0)}', bold: true),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: pawPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(15),
                    ),
                    onPressed: _showCheckoutInfo,
                    child: const Text('Continue to checkout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  
  
Widget _buildOrders() {
  return StreamBuilder<List<PawCartOrder>>(
    stream: OrderStore.instance.watchOrders(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('My orders 📦', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 18),
            _InfoPanel(
              emoji: '⚠️',
              title: 'Could not load orders',
              message: 'Check your internet connection and Firestore security rules. ${snapshot.error}',
            ),
          ],
        );
      }

      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
        return const Center(child: CircularProgressIndicator(color: pawPink));
      }

      final orders = snapshot.data ?? [];
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('My orders 📦', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Your pet goodies, all in one place.', style: TextStyle(color: pawMuted)),
          const SizedBox(height: 22),
          if (orders.isEmpty)
            const _InfoPanel(
              emoji: '💌',
              title: 'No orders yet!',
              message: 'Complete checkout and your order will appear here.',
            )
          else
            ...orders.map((order) {
              OrderEvent? nextEvent;
              String? actionLabel;

              switch (order.status) {
                case OrderStatus.placed:
                  break;
                case OrderStatus.paymentFailed:
                  nextEvent = OrderEvent.retryPayment;
                  actionLabel = 'Retry order';
                  break;
                case OrderStatus.paymentVerified:
                  nextEvent = OrderEvent.startPacking;
                  actionLabel = 'Start packing';
                  break;
                case OrderStatus.packing:
                  nextEvent = OrderEvent.ship;
                  actionLabel = 'Mark as shipped';
                  break;
                case OrderStatus.shipped:
                  nextEvent = OrderEvent.deliver;
                  actionLabel = 'Mark as delivered';
                  break;
                case OrderStatus.delivered:
                case OrderStatus.cancelled:
                  break;
              }

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: pawPalePink,
                            child: Icon(Icons.shopping_bag_outlined, color: pawPink),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('PawCart Order', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                Text(order.id, style: const TextStyle(color: pawMuted, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(color: pawPink, fontWeight: FontWeight.w900, fontSize: 17)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: pawPalePink, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined, color: pawPink),
                            const SizedBox(width: 10),
                            Expanded(child: Text(OrderStateMachine.label(order.status), style: const TextStyle(fontWeight: FontWeight.w800, color: pawInk))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('Customer: ${order.customerName}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text('${order.address}, ${order.city} - ${order.pinCode}', style: const TextStyle(color: pawMuted, height: 1.4)),
                      if (nextEvent != null && actionLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: pawPink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                              onPressed: () async {
                                final event = nextEvent;
                                if (event == null) return;
                                final previousStatus = order.status;
                                if (!order.machine.apply(event)) return;
                                try {
                                  await OrderStore.instance.updateStatus(order);
                                } catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Could not save order status: $error')),
                                  );
                                  // Restore the prior state if the cloud update failed.
                                  order.machine = OrderStateMachine(initialStatus: previousStatus);
                                }
                              },
                              child: Text(actionLabel),
                            ),
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
  );
}


  

Widget _buildProfile() {
  final user = FirebaseAuth.instance.currentUser;

  return ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Your profile 💗',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 18),
      const CircleAvatar(
        radius: 42,
        backgroundColor: pawPalePink,
        child: Text('🐱', style: TextStyle(fontSize: 42)),
      ),
      const SizedBox(height: 12),
      const Center(
        child: Text(
          'Hello, pet parent!',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(height: 5),
      Center(
        child: Text(
          user?.email ?? 'Your little corner of PawCart.',
          style: const TextStyle(color: pawMuted),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 22),
      _ProfileTile(
        icon: Icons.pets_outlined,
        title: 'My pets',
        subtitle: 'Add and manage your pet profiles',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MyPetsScreen(),
            ),
          );
        },
      ),
      const _ProfileTile(
        icon: Icons.favorite_border,
        title: 'Wishlist',
        subtitle: 'Save their future favourites',
      ),
      const _ProfileTile(
        icon: Icons.location_on_outlined,
        title: 'Delivery addresses',
        subtitle: 'Manage your saved addresses',
      ),
      const _ProfileTile(
        icon: Icons.help_outline,
        title: 'Help & support',
        subtitle: 'We are here to help',
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          
onPressed: () async {
  debugPrint('LOGOUT BUTTON TAPPED');

  try {
    await FirebaseAuth.instance.signOut();

    debugPrint('FIREBASE SIGN OUT SUCCESSFUL');
  } catch (e) {
    debugPrint('LOGOUT ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logout failed: $e'),
      ),
    );
  }
},

          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: pawPink,
            side: const BorderSide(color: pawPink),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Center(
        child: Text(
          'Thank you for being part of PawCart 🐾',
          style: TextStyle(color: pawMuted, fontSize: 12),
        ),
      ),
    ],
  );
}


  Widget _sectionHeading(String title, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              Text(subtitle, style: const TextStyle(color: pawMuted, fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_rounded, color: pawPink),
      ],
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w500))),
        Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600, fontSize: bold ? 17 : 14)),
      ],
    );
  }

  void _showProductDetails(Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: pawCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 130,
                width: 130,
                decoration: BoxDecoration(color: pawPalePink, borderRadius: BorderRadius.circular(28)),
                child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  product.imageAsset,
                  width: 130,
                  height: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.image_not_supported_outlined,
                      color: pawPink,
                      size: 40,
                    );
                  },
                ),
              ),
              ),
            ),
            const SizedBox(height: 20),
            Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(product.category, style: const TextStyle(color: pawMuted)),
            const SizedBox(height: 12),
            Text(product.description),
            const SizedBox(height: 14),
            Text('₹${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: pawPink)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: pawPink, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                onPressed: () {
                  Navigator.pop(context);
                  _addToCart(product);
                },
                child: const Text('Add to cart 🛍️'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
void _showCheckoutInfo() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CheckoutScreen(
        subtotal: _cartTotal,
        deliveryFee: _cartTotal >= 999 ? 0 : 49,
      ),
    ),
  );
}
}


class _CartNavIcon extends StatelessWidget {
  const _CartNavIcon({required this.count, this.selected = false});
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: Icon(selected ? Icons.shopping_bag : Icons.shopping_bag_outlined,
          color: selected ? pawPink : null),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.emoji});
  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      margin: const EdgeInsets.only(right: 9),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}


class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onAdd,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Image.asset(
                          product.imageAsset,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: pawPalePink,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: pawPink,
                                size: 36,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (product.tag != null)
                      Positioned(
                        top: 7,
                        left: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.tag!,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: pawPink,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: pawPink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.emoji, required this.title, required this.message});
  final String emoji;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: pawMuted, height: 1.45)),
        ],
      ),
    );
  }
}


class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: pawPalePink,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: pawPink),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: pawMuted,
              fontSize: 12,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
