import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'firebase_service.dart';
import 'providers/directions_service.dart';

class DeliveryScreen extends StatefulWidget {
  final String orderId;
  final double customerLat;
  final double customerLng;
  final VoidCallback? onBackPressed;

  const DeliveryScreen({
    super.key,
    required this.orderId,
    this.customerLat = 17.3850,
    this.customerLng = 78.4867,
    this.onBackPressed,
  });

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> with TickerProviderStateMixin {
  MapplsMapController? _mapController;

  LatLng? _partnerLocation;
  StreamSubscription<Map<String, double>?>? _locationSub;
  StreamSubscription<Map<String, dynamic>?>? _orderSub;
  final FirebaseService _firebaseService = FirebaseService();

  double? _distanceMetres;
  String _etaText = 'Calculating...';
  String _statusText = 'Order Placed';
  String _orderStatus = 'Placed';
  String _deliveryAddress = 'Your Location';
  
  List<LatLng> _routePoints = [];
  Timer? _routeTimer;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  LatLng get _customerLatLng => LatLng(widget.customerLat, widget.customerLng);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(_pulseController);

    _subscribeToOrderDetails();
    _subscribeToPartnerLocation();
  }

  void _subscribeToOrderDetails() {
    _orderSub = _firebaseService.streamOrder(widget.orderId).listen((order) {
      if (!mounted || order == null) return;
      setState(() {
        _orderStatus = order['status'] ?? 'Placed';
        if (order['address'] != null && order['address'].toString().isNotEmpty) {
          _deliveryAddress = order['address'];
        }
        _updateStatusTexts();
      });
    }, onError: (e) => debugPrint('Order stream error: $e'));
  }

  void _subscribeToPartnerLocation() {
    _locationSub = _firebaseService
        .streamDeliveryPartnerLocation(widget.orderId)
        .listen((coords) {
      if (!mounted || coords == null) return;
      final lat = coords['lat']!;
      final lng = coords['lng']!;
      final newPos = LatLng(lat, lng);
      
      setState(() {
        _partnerLocation = newPos;
      });
      
      _fetchRoute();
      _animateCamera();
      _updateMapDrawings();
    }, onError: (e) => debugPrint('Location stream error: $e'));
  }

  void _fetchRoute() async {
    if (_partnerLocation == null) return;
    
    // Throttle route fetching to avoid hitting API limits
    if (_routeTimer?.isActive ?? false) return;
    
    _routeTimer = Timer(const Duration(seconds: 15), () {});
    
    final routeData = await DirectionsService.getRoute(
      _partnerLocation!.latitude, _partnerLocation!.longitude,
      _customerLatLng.latitude, _customerLatLng.longitude
    );
    
    if (mounted && routeData != null) {
      setState(() {
        _routePoints = routeData['points'];
        _distanceMetres = (routeData['distance'] as num).toDouble();
        
        final durationSeconds = (routeData['duration'] as num).toDouble();
        _etaText = _calcEta(durationSeconds, _distanceMetres!);
        
        _updateStatusTexts();
      });
    }
  }

  void _updateStatusTexts() {
    if (_orderStatus == 'Delivered') {
      _etaText = 'Delivered!';
      _statusText = 'Order delivered successfully 🎉';
      return;
    }

    if (_orderStatus == 'Picked Up') {
      _statusText = 'Picked Up - Partner is heading to your address';
      if (_partnerLocation == null) _etaText = 'Picked Up';
      return;
    }

    if (_orderStatus == 'On the Way') {
      if (_distanceMetres != null) {
        _statusText = _distanceMetres! < 200 ? 'Almost there!' : 'On the way to deliver';
      } else {
        _statusText = 'Out for delivery';
        _etaText = 'On the way';
      }
      return;
    }

    if (_orderStatus == 'Processing') {
      _statusText = 'Preparing fresh milk at Jaanu\'s Farm...';
      _etaText = 'Processing';
      return;
    }

    // Default: Placed
    _statusText = 'Order received by Jaanu\'s Farm';
    if (_orderStatus != 'Processing') {
        _etaText = 'Order Placed';
    }
  }

  String _calcEta(double durationSeconds, double distanceMetres) {
    if (distanceMetres < 100) return 'Arrived!';
    final minutes = (durationSeconds / 60).ceil();
    return '$minutes min away';
  }

  void _animateCamera() {
    if (_partnerLocation == null || _mapController == null) return;

    final lats = [_customerLatLng.latitude, _partnerLocation!.latitude];
    final lngs = [_customerLatLng.longitude, _partnerLocation!.longitude];

    final bounds = LatLngBounds(
      southwest: LatLng(lats.reduce((a, b) => a < b ? a : b), lngs.reduce((a, b) => a < b ? a : b)),
      northeast: LatLng(lats.reduce((a, b) => a > b ? a : b), lngs.reduce((a, b) => a > b ? a : b)),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, left: 60, top: 100, right: 60, bottom: 320),
    );
  }

  void _updateMapDrawings() async {
    if (_mapController == null) return;
    
    await _mapController!.clearCircles();
    await _mapController!.clearLines();

    await _mapController!.addCircle(CircleOptions(
      geometry: _customerLatLng,
      circleRadius: 8.0,
      circleColor: '#FF0000',
    ));

    if (_partnerLocation != null) {
      await _mapController!.addCircle(CircleOptions(
        geometry: _partnerLocation!,
        circleRadius: 10.0,
        circleColor: '#0000FF',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2.0,
      ));
    }

    if (_routePoints.isNotEmpty) {
      await _mapController!.addLine(LineOptions(
        geometry: _routePoints,
        lineColor: '#0000FF',
        lineWidth: 4.0,
      ));
    } else if (_partnerLocation != null) {
      await _mapController!.addLine(LineOptions(
        geometry: [_customerLatLng, _partnerLocation!],
        lineColor: '#0000FF',
        lineWidth: 4.0,
      ));
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _orderSub?.cancel();
    _routeTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  int _getStepIndex() {
    switch (_orderStatus) {
      case 'Picked Up':
        return 1;
      case 'On the Way':
        return 2;
      case 'Delivered':
        return 3;
      case 'Placed':
      case 'Processing':
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortOrderId = widget.orderId.length > 8
        ? widget.orderId.substring(0, 8).toUpperCase()
        : widget.orderId.toUpperCase();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            if (widget.onBackPressed != null) {
              widget.onBackPressed!();
            } else {
              Navigator.pop(context);
            }
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Opacity(
                  opacity: _pulseAnim.value,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('Live Tracking • ORD-$shortOrderId',
                  style: const TextStyle(color: Colors.black87,
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MapplsMap(
            initialCameraPosition: CameraPosition(
              target: _customerLatLng,
              zoom: 15.0,
            ),
            onMapCreated: (MapplsMapController controller) {
              _mapController = controller;
              _updateMapDrawings();
            },
          ),

          if (_partnerLocation == null && _orderStatus != 'Delivered')
            Positioned(
              top: kToolbarHeight + 60, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.orange.withValues(alpha: 0.15), blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _orderStatus == 'Picked Up' || _orderStatus == 'On the Way'
                            ? 'Partner is active. Syncing live GPS coordinates...'
                            : 'Waiting for pickup & GPS tracking launch...',
                        style: TextStyle(color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.15,
            maxChildSize: 0.6,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20, offset: const Offset(0, -4)),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2)),
                      ),

                      // Order Pickup & Delivery Stepper Tracker
                      _buildStatusStepper(_getStepIndex()),

                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.electric_bike, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_etaText,
                                    style: TextStyle(fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary)),
                                const SizedBox(height: 2),
                                Text(_statusText,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          if (_distanceMetres != null) _DistancePill(metres: _distanceMetres!),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Partner Info & Quick Call
                      Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: Icon(Icons.delivery_dining,
                                    color: theme.colorScheme.primary, size: 22),
                              ),
                              if (_partnerLocation != null)
                                Positioned(
                                  bottom: 0, right: 0,
                                  child: Container(
                                    width: 12, height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Delivery Partner',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text("Jaanu's Farm Express",
                                    style: TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                          _ActionButton(
                            icon: Icons.phone, color: Colors.green,
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Calling delivery partner...'),
                                  behavior: SnackBarBehavior.floating),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(icon: Icons.chat_bubble_outline,
                              color: Colors.blue, onTap: () {}),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Delivery Address card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_deliveryAddress,
                                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper(int activeStep) {
    final steps = [
      {'title': 'Placed', 'icon': Icons.receipt_long},
      {'title': 'Picked Up', 'icon': Icons.inventory_2_outlined},
      {'title': 'On the Way', 'icon': Icons.electric_moped},
      {'title': 'Delivered', 'icon': Icons.check_circle_outline},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final isDone = index <= activeStep;
        final isCurrent = index == activeStep;

        Color circleColor = Colors.grey.shade300;
        Color iconColor = Colors.grey.shade600;

        if (isDone) {
          circleColor = isCurrent ? Colors.green : Colors.green.shade700;
          iconColor = Colors.white;
        }

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: circleColor,
                        shape: BoxShape.circle,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        steps[index]['icon'] as IconData,
                        color: iconColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index]['title'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                        color: isDone ? Colors.black87 : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: index < activeStep ? Colors.green : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _DistancePill extends StatelessWidget {
  final double metres;
  const _DistancePill({required this.metres});

  @override
  Widget build(BuildContext context) {
    final label = metres >= 1000
        ? '${(metres / 1000).toStringAsFixed(1)} km'
        : '${metres.toStringAsFixed(0)} m';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Text(label,
          style: TextStyle(color: Colors.green.shade700,
              fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
