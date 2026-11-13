import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ============================================================================
// 1. VERİ MODELLERİ (MODELS)
// ============================================================================

class MenuItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });
}

class Restaurant {
  final String id;
  final String name;
  final String category;
  final double rating;
  final String deliveryTime;
  final String currencySymbol;
  double commissionRate;
  final List<MenuItem> menu;

  Restaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.deliveryTime,
    required this.currencySymbol,
    this.commissionRate = 10.0,
    required this.menu,
  });
}

class CartItem {
  final MenuItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});
}

class OrderModel {
  final String id;
  final String restaurantName;
  final double totalAmount;
  final String currencySymbol;
  final String deliveryAddress;
  String status; // 'pending', 'preparing', 'on_the_way', 'delivered'
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.restaurantName,
    required this.totalAmount,
    required this.currencySymbol,
    required this.deliveryAddress,
    this.status = 'pending',
    required this.createdAt,
  });
}

class WalletTransaction {
  final String id;
  final String title;
  final double amount;
  final String type; // 'top_up' veya 'spend'
  final DateTime date;

  WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
  });
}

// ============================================================================
// 2. DURUM YÖNETİMİ (STATE MANAGEMENT / PROVIDERS)
// ============================================================================

class AppStateProvider with ChangeNotifier {
  // Örnek Restoran Verileri (Canlı güncellenebilir)
  final List<Restaurant> _restaurants = [
    Restaurant(
      id: 'r1',
      name: 'Global Burger Co.',
      category: 'Fast Food • Burgers',
      rating: 4.8,
      deliveryTime: '20-30 dk',
      currencySymbol: '\$',
      commissionRate: 12.0,
      menu: [
        MenuItem(id: 'm1', name: 'Double Truffle Burger', price: 14.50, imageUrl: '🍔'),
        MenuItem(id: 'm2', name: 'Crispy Parmesan Fries', price: 5.00, imageUrl: '🍟'),
      ],
    ),
    Restaurant(
      id: 'r2',
      name: 'Napoli Woodfire Pizza',
      category: 'Italian • Pizza',
      rating: 4.9,
      deliveryTime: '25-40 dk',
      currencySymbol: '\$',
      commissionRate: 10.0,
      menu: [
        MenuItem(id: 'm3', name: 'Margherita D.O.P', price: 16.00, imageUrl: '🍕'),
        MenuItem(id: 'm4', name: 'Tiramisu Classico', price: 7.50, imageUrl: '🍰'),
      ],
    ),
  ];

  // Sepet Verileri
  final Map<String, CartItem> _cartItems = {};
  String _currencySymbol = '\$';

  // Sipariş Havuzu (Müşteri, Restoran, Kurye senkronize görür)
  final List<OrderModel> _orders = [
    OrderModel(
      id: 'ORD-1001',
      restaurantName: 'Global Burger Co.',
      totalAmount: 19.50,
      currencySymbol: '\$',
      deliveryAddress: 'Levent Mah. No: 12, İstanbul',
      status: 'preparing',
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];

  // Cüzdan Verileri
  double _walletBalance = 150.00;
  final List<WalletTransaction> _transactions = [
    WalletTransaction(
      id: 'tx1',
      title: 'Hoş Geldin Bonusu',
      amount: 150.00,
      type: 'top_up',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // Getters
  List<Restaurant> get restaurants => _restaurants;
  Map<String, CartItem> get cartItems => {..._cartItems};
  String get currencySymbol => _currencySymbol;
  List<OrderModel> get orders => _orders;
  double get walletBalance => _walletBalance;
  List<WalletTransaction> get transactions => _transactions;

  int get cartItemCount => _cartItems.values.fold(0, (sum, item) => sum + item.quantity);

  double get cartTotalAmount {
    double total = 0.0;
    _cartItems.forEach((key, cartItem) {
      total += cartItem.item.price * cartItem.quantity;
    });
    return total;
  }

  // Sepet İşlemleri
  void addToCart(MenuItem menuItem, String currency) {
    _currencySymbol = currency;
    if (_cartItems.containsKey(menuItem.id)) {
      _cartItems[menuItem.id]!.quantity += 1;
    } else {
      _cartItems[menuItem.id] = CartItem(item: menuItem);
    }
    notifyListeners();
  }

  void removeSingleFromCart(String itemId) {
    if (!_cartItems.containsKey(itemId)) return;
    if (_cartItems[itemId]!.quantity > 1) {
      _cartItems[itemId]!.quantity -= 1;
    } else {
      _cartItems.remove(itemId);
    }
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // Kupon Hesaplama
  double calculateDiscount(String code, double total) {
    if (code.trim().toUpperCase() == 'GLOBAL20') {
      return total * 0.20;
    } else if (code.trim().toUpperCase() == 'WELCOME10') {
      return total >= 10 ? 10.0 : 0.0;
    }
    return 0.0;
  }

  // Cüzdan İşlemleri
  void topUpWallet(double amount) {
    _walletBalance += amount;
    _transactions.insert(
      0,
      WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Cüzdan Bakiye Yükleme',
        amount: amount,
        type: 'top_up',
        date: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  // Sipariş Oluşturma (Ödeme Onayı Sonrası)
  OrderModel placeOrder({required double finalAmount, required bool payWithWallet, required String address}) {
    if (payWithWallet && _walletBalance >= finalAmount) {
      _walletBalance -= finalAmount;
      _transactions.insert(
        0,
        WalletTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Sipariş Ödemesi',
          amount: finalAmount,
          type: 'spend',
          date: DateTime.now(),
        ),
      );
    }

    final newOrder = OrderModel(
      id: 'ORD-${1000 + _orders.length + 1}',
      restaurantName: 'Global Food Partner',
      totalAmount: finalAmount,
      currencySymbol: _currencySymbol,
      deliveryAddress: address,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    _orders.insert(0, newOrder);
    clearCart();
    notifyListeners();
    return newOrder;
  }

  // Sipariş Durumu Güncelleme (Restoran & Kurye)
  void updateOrderStatus(String orderId, String newStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].status = newStatus;
      notifyListeners();
    }
  }

  // Restoran Menü Yönetimi
  void addMenuItem(String restaurantId, String name, double price, String icon) {
    final restIndex = _restaurants.indexWhere((r) => r.id == restaurantId);
    if (restIndex != -1) {
      _restaurants[restIndex].menu.add(
        MenuItem(
          id: 'm_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          price: price,
          imageUrl: icon,
        ),
      );
      notifyListeners();
    }
  }

  void updateMenuItemPrice(String restaurantId, String itemId, double newPrice) {
    final restIndex = _restaurants.indexWhere((r) => r.id == restaurantId);
    if (restIndex != -1) {
      final itemIndex = _restaurants[restIndex].menu.indexWhere((m) => m.id == itemId);
      if (itemIndex != -1) {
        final oldItem = _restaurants[restIndex].menu[itemIndex];
        _restaurants[restIndex].menu[itemIndex] = MenuItem(
          id: oldItem.id,
          name: oldItem.name,
          price: newPrice,
          imageUrl: oldItem.imageUrl,
        );
        notifyListeners();
      }
    }
  }

  // Admin Komisyon Güncelleme
  void updateCommissionRate(String restaurantId, double newRate) {
    final restIndex = _restaurants.indexWhere((r) => r.id == restaurantId);
    if (restIndex != -1) {
      _restaurants[restIndex].commissionRate = newRate;
      notifyListeners();
    }
  }
}

// ============================================================================
// 3. ANA UYGULAMA BAŞLANGICI (MAIN ENTRY POINT)
// ============================================================================

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: const GlobalFoodApp(),
    ),
  );
}

class GlobalFoodApp extends StatelessWidget {
  const GlobalFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Global Food Delivery',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MainNavigationHub(),
    );
  }
}

// ============================================================================
// 4. ROL TABANLI ANA GEZİNTİ MERKEZİ (MÜŞTERİ / RESTORAN / KURYE / ADMIN)
// ============================================================================

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    CustomerHomeScreen(),
    WalletScreen(),
    RestaurantPanelScreen(),
    CourierPanelScreen(),
    AdminPanelScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Sipariş'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Cüzdan'),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Restoran'),
          NavigationDestination(icon: Icon(Icons.delivery_dining), label: 'Kurye'),
          NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. MÜŞTERİ ANA EKRANI, SEPET, ÖDEME VE CANLI TAKİP
// ============================================================================

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Teslimat Adresi', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('Levent, İstanbul 📍', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // Canlı Sipariş Takip Butonu
          if (appState.orders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map_outlined, color: Colors.deepOrange),
              tooltip: 'Aktif Siparişi Takip Et',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: appState.orders.first)),
                );
              },
            ),
          // Sepet İkonu
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, size: 28),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartAndCheckoutScreen()),
                ),
              ),
              if (appState.cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${appState.cartItemCount}',
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appState.restaurants.length,
        itemBuilder: (ctx, index) {
          final restaurant = appState.restaurants[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(restaurant.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Chip(
                        label: Text('⭐ ${restaurant.rating} • ${restaurant.deliveryTime}'),
                        backgroundColor: Colors.orange.shade50,
                      ),
                    ],
                  ),
                  Text(restaurant.category, style: TextStyle(color: Colors.grey.shade600)),
                  const Divider(height: 24),
                  ...restaurant.menu.map((menuItem) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Text(menuItem.imageUrl, style: const TextStyle(fontSize: 32)),
                        title: Text(menuItem.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${restaurant.currencySymbol}${menuItem.price.toStringAsFixed(2)}'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            appState.addToCart(menuItem, restaurant.currencySymbol);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${menuItem.name} sepete eklendi!'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Text('+ Ekle'),
                        ),
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CartAndCheckoutScreen extends StatefulWidget {
  const CartAndCheckoutScreen({super.key});

  @override
  State<CartAndCheckoutScreen> createState() => _CartAndCheckoutScreenState();
}

class _CartAndCheckoutScreenState extends State<CartAndCheckoutScreen> {
  final TextEditingController _couponController = TextEditingController();
  double _discount = 0.0;
  bool _useWallet = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final cartItems = appState.cartItems.values.toList();
    final subTotal = appState.cartTotalAmount;
    final finalTotal = (subTotal - _discount) < 0 ? 0.0 : (subTotal - _discount);

    return Scaffold(
      appBar: AppBar(title: const Text('Sepet ve Ödeme')),
      body: cartItems.isEmpty
          ? const Center(child: Text('Sepetiniz şu an boş 🛒', style: TextStyle(fontSize: 18)))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...cartItems.map((cartItem) => ListTile(
                            leading: Text(cartItem.item.imageUrl, style: const TextStyle(fontSize: 28)),
                            title: Text(cartItem.item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '${appState.currencySymbol}${(cartItem.item.price * cartItem.quantity).toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () => appState.removeSingleFromCart(cartItem.item.id),
                                ),
                                Text('${cartItem.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                  onPressed: () => appState.addToCart(cartItem.item, appState.currencySymbol),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 32),
                      // Kupon Alanı
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              decoration: const InputDecoration(
                                labelText: 'Kupon Kodu (Örn: GLOBAL20)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _discount = appState.calculateDiscount(_couponController.text, subTotal);
                              });
                            },
                            child: const Text('Uygula'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Cüzdan Seçeneği
                      SwitchListTile(
                        title: Text('Cüzdan Bakiyesi Kullan (\$${appState.walletBalance.toStringAsFixed(2)})'),
                        value: _useWallet,
                        onChanged: (val) => setState(() => _useWallet = val),
                      ),
                    ],
                  ),
                ),
                // Alt Ödeme Özeti
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ödenecek Tutar:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              '${appState.currencySymbol}${finalTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              if (_useWallet && appState.walletBalance < finalTotal) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cüzdan bakiyeniz yetersiz!')),
                                );
                                return;
                              }
                              final order = appState.placeOrder(
                                finalAmount: finalTotal,
                                payWithWallet: _useWallet,
                                address: 'Levent Mah. No: 12, İstanbul',
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
                              );
                            },
                            child: const Text('Siparişi Onayla ve Öde', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class OrderTrackingScreen extends StatelessWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final currentOrder = appState.orders.firstWhere((o) => o.id == order.id, orElse: () => order);

    return Scaffold(
      appBar: AppBar(title: Text('Sipariş Takibi #${currentOrder.id}')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepOrange.shade200),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delivery_dining, size: 64, color: Colors.deepOrange),
                  SizedBox(height: 12),
                  Text('Canlı GPS Harita Simülasyonu', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Kurye konumu anlık güncelleniyor...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.deepOrange),
              title: const Text('Sipariş Durumu'),
              subtitle: Text(
                currentOrder.status.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.deepOrange),
              title: const Text('Teslimat Adresi'),
              subtitle: Text(currentOrder.deliveryAddress),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 6. CÜZDAN EKRANI (WALLET)
// ============================================================================

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Global Cüzdanım 💳')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.deepOrange, Colors.orangeAccent]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mevcut Bakiye', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                    '\$${appState.walletBalance.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepOrange),
                    onPressed: () => appState.topUpWallet(50.0),
                    child: const Text('+ \$50.00 Bakiye Yükle'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Son İşlemler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: appState.transactions.length,
                itemBuilder: (ctx, i) {
                  final tx = appState.transactions[i];
                  final isTopUp = tx.type == 'top_up';
                  return ListTile(
                    leading: Icon(isTopUp ? Icons.add_circle : Icons.remove_circle, color: isTopUp ? Colors.green : Colors.red),
                    title: Text(tx.title),
                    trailing: Text(
                      '${isTopUp ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isTopUp ? Colors.green : Colors.red),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 7. RESTORAN YÖNETİM PANELİ (SİPARİŞ & MENÜ)
// ============================================================================

class RestaurantPanelScreen extends StatelessWidget {
  const RestaurantPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final restaurant = appState.restaurants.first;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Restoran Paneli 👨‍🍳'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Gelen Siparişler'),
              Tab(text: 'Menü Yönetimi'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Siparişler
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appState.orders.length,
              itemBuilder: (ctx, i) {
                final order = appState.orders[i];
                return Card(
                  child: ListTile(
                    title: Text('Sipariş #${order.id} - \$${order.totalAmount.toStringAsFixed(2)}'),
                    subtitle: Text('Durum: ${order.status}'),
                    trailing: order.status == 'pending'
                        ? ElevatedButton(
                            onPressed: () => appState.updateOrderStatus(order.id, 'preparing'),
                            child: const Text('Hazırla'),
                          )
                        : null,
                  ),
                );
              },
            ),
            // Tab 2: Menü Yönetimi
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: restaurant.menu.length + 1,
              itemBuilder: (ctx, i) {
                if (i == restaurant.menu.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        appState.addMenuItem(restaurant.id, 'Yeni Özel Menü', 18.00, '🍱');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Örnek Yeni Yemek Ekle'),
                    ),
                  );
                }
                final item = restaurant.menu[i];
                return ListTile(
                  leading: Text(item.imageUrl, style: const TextStyle(fontSize: 28)),
                  title: Text(item.name),
                  subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.price_change),
                    onPressed: () => appState.updateMenuItemPrice(restaurant.id, item.id, item.price + 1.0),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 8. KURYE TESLİMAT PANELİ
// ============================================================================

class CourierPanelScreen extends StatelessWidget {
  const CourierPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final activeOrders = appState.orders.where((o) => o.status == 'preparing' || o.status == 'on_the_way').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Kurye Teslimat Paneli 🛵')),
      body: activeOrders.isEmpty
          ? const Center(child: Text('Şu an aktif teslimat görevi yok.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeOrders.length,
              itemBuilder: (ctx, i) {
                final order = activeOrders[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Teslimat #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Adres: ${order.deliveryAddress}'),
                        const SizedBox(height: 12),
                        if (order.status == 'preparing')
                          ElevatedButton(
                            onPressed: () => appState.updateOrderStatus(order.id, 'on_the_way'),
                            child: const Text('Siparişi Teslim Al ve Yola Çık'),
                          )
                        else if (order.status == 'on_the_way')
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () => appState.updateOrderStatus(order.id, 'delivered'),
                            child: const Text('Müşteriye Teslim Edildi ✅'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// 9. ADMIN YÖNETİM PANELİ
// ============================================================================

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Yönetici (Admin) Paneli 🛡️')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Restoran Komisyon Yönetimi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: appState.restaurants.length,
                itemBuilder: (ctx, i) {
                  final rest = appState.restaurants[i];
                  return Card(
                    child: ListTile(
                      title: Text(rest.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Mevcut Komisyon Oranı: %${rest.commissionRate.toStringAsFixed(1)}'),
                      trailing: ElevatedButton(
                        onPressed: () => appState.updateCommissionRate(rest.id, rest.commissionRate + 1.0),
                        child: const Text('+%1 Artır'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
