class ApiConstants {
  // Current Laptop IP on Wi-Fi: 192.168.2.23
  // Change this to your current IP if you move to a new network
  static const String ipAddress = '192.168.2.23';
  static const String baseUrl = 'http://$ipAddress:3000/api';

  // Sub-routes
  static const String authSubRoute = '/api';
  static const String notificationsSubRoute = '$baseUrl/notifications';
  static const String productsSubRoute = '$baseUrl/products';
  static const String ordersSubRoute = '$baseUrl/orders';
  static const String reviewsSubRoute = '$baseUrl/reviews';
  static const String vouchersSubRoute = '$baseUrl/vouchers';
  static const String userSubRoute = '$baseUrl/user';
  static const String chatSubRoute = '$baseUrl/chat';
  static const String uploadSubRoute = '$baseUrl/upload';
}
