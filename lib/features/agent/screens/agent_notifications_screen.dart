import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../providers/agent_provider.dart';
import '../repository/agent_repository.dart';
import '../../../core/services/audio_service.dart';

class AgentNotificationsScreen extends StatefulWidget {
  const AgentNotificationsScreen({super.key});

  @override
  State<AgentNotificationsScreen> createState() =>
      _AgentNotificationsScreenState();
}

class _AgentNotificationsScreenState extends State<AgentNotificationsScreen> {
  final AgentRepository _agentRepository = AgentRepository();
  final AudioService _audioService = AudioService();
  
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isMarkingAll = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  String selectedFilter = "Tout";

  final List<String> filters = [
    "Tout",
    "Missions",
    "Paiements",
    "Boost",
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupConnectivityListener();
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
  
  /// Charge les notifications depuis l'API
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Implémenter getNotifications dans AgentRepository
      // final notifications = await _agentRepository.getNotifications();
      
      // Données de test pour le moment
      final notifications = [
        {
          'id': '1',
          'icon': Icons.work_outline,
          'title': 'Nouvelle mission disponible !',
          'subtitle': 'SBEE Akpakpa à 500m de vous',
          'time': 'Maintenant',
          'color': Colors.orange,
          'is_read': false,
          'type': 'mission',
        },
        {
          'id': '2',
          'icon': Icons.check_circle_outline,
          'title': 'Mission acceptée',
          'subtitle': 'Attente à la banque BOA',
          'time': 'Il y a 5 min',
          'color': Colors.green,
          'is_read': true,
          'type': 'mission',
        },
        {
          'id': '3',
          'icon': Icons.account_balance_wallet_outlined,
          'title': 'Paiement reçu',
          'subtitle': 'Vous avez gagné 2 400 FCFA',
          'time': 'Il y a 1h',
          'color': Colors.blue,
          'is_read': true,
          'type': 'payment',
        },
        {
          'id': '4',
          'icon': Icons.flash_on_outlined,
          'title': 'Boost activé',
          'subtitle': 'Votre boost est actif jusqu\'au 15/06/2024',
          'time': 'Il y a 2h',
          'color': Colors.purple,
          'is_read': false,
          'type': 'boost',
        },
      ];
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement notifications: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Configure l'écouteur de connectivité
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        // Retour de connexion, recharger les notifications
        _loadNotifications();
      }
    });
  }
  
  /// Marque une notification comme lue
  Future<void> _markAsRead(String notificationId) async {
    try {
      // TODO: Implémenter markNotificationAsRead dans AgentRepository
      // final success = await _agentRepository.markNotificationAsRead(notificationId);
      final success = true; // Simulation
      
      if (success) {
        setState(() {
          _notifications = _notifications.map((notif) {
            if (notif['id'] == notificationId) {
              return {...notif, 'is_read': true};
            }
            return notif;
          }).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur marquage lecture: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Supprime une notification
  Future<void> _deleteNotification(String notificationId) async {
    try {
      // TODO: Implémenter deleteNotification dans AgentRepository
      // final success = await _agentRepository.deleteNotification(notificationId);
      final success = true; // Simulation
      
      if (success) {
        setState(() {
          _notifications.removeWhere((notif) => notif['id'] == notificationId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur suppression: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Marque toutes les notifications comme lues
  Future<void> _markAllAsRead() async {
    setState(() {
      _isMarkingAll = true;
    });
    
    try {
      // TODO: Implémenter markAllNotificationsAsRead dans AgentRepository
      // final success = await _agentRepository.markAllNotificationsAsRead();
      final success = true; // Simulation
      
      if (success) {
        setState(() {
          _notifications = _notifications.map((notif) {
            return {...notif, 'is_read': true};
          }).toList();
          _isMarkingAll = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les notifications marquées comme lues'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isMarkingAll = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur marquage: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Filtre les notifications
  List<Map<String, dynamic>> get _filteredNotifications {
    if (selectedFilter == "Tout") return _notifications;
    
    return _notifications.where((notif) {
      final type = notif['type']?.toString().toLowerCase() ?? '';
      switch (selectedFilter) {
        case "Missions":
          return type.contains('mission') || type.contains('work');
        case "Paiements":
          return type.contains('paiement') || type.contains('payment') || type.contains('wallet');
        case "Boost":
          return type.contains('boost') || type.contains('flash');
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          // BOUTON TOUT MARQUER COMME LU
          if (_notifications.any((notif) => !(notif['is_read'] ?? true)))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: _isMarkingAll ? null : _markAllAsRead,
                  icon: _isMarkingAll
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.done_all, size: 18),
                  label: Text(
                    _isMarkingAll ? 'Marquage...' : 'Tout marquer comme lu',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD400),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = selectedFilter == filter;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFFFFD400) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFFD400)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.black : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // LISTE DES NOTIFICATIONS
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune notification',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vous n\'avez pas encore de notifications',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = _filteredNotifications[index];
                          final isRead = notification['is_read'] ?? true;
                          
                          return Dismissible(
                            key: Key(notification['id']?.toString() ?? index.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            onDismissed: (direction) {
                              _deleteNotification(notification['id']?.toString() ?? '');
                            },
                            child: GestureDetector(
                              onTap: () {
                                if (!isRead) {
                                  _markAsRead(notification['id']?.toString() ?? '');
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isRead ? Colors.white : const Color(0xFFFFF7CC),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Icône
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: (notification['color'] as Color?)?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        notification['icon'] as IconData? ?? Icons.notifications,
                                        color: notification['color'] as Color? ?? Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 16),
                                    
                                    // Contenu
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notification['title']?.toString() ?? '',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notification['subtitle']?.toString() ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Point rouge si non lu
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFD400),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    
                                    const SizedBox(width: 8),
                                    
                                    // Heure
                                    Text(
                                      notification['time']?.toString() ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
