import 'package:customer_app/providers/active_trip.dart';
import 'package:customer_app/providers/location.dart';
import 'package:customer_app/servivces/auth_service.dart';
import 'package:customer_app/types/customer_info.dart';
import 'package:customer_app/types/trip.dart';
import 'package:customer_app/ui/active_trip.dart';
import 'package:customer_app/ui/new_trip.dart';
import 'package:customer_app/ui/select_location.dart';
import 'package:customer_app/ui/rating.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/global.dart';
import 'package:logger/logger.dart';

class LoginPage extends StatefulWidget {
  final AuthService authService;

  const LoginPage({Key? key, required this.authService}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  var logger = Logger();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vui lòng đăng nhập!'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                icon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                icon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () async {
                String username = _usernameController.text;
                String password = _passwordController.text;

                try {
                  final user =
                      await widget.authService.login(username, password);

                  // ignore: unnecessary_null_comparison
                  if (user != null) {
                    await widget.authService.saveToken(user['token']);
                    logger.i("user: ", user['token']);
                    CustomerInfo customer = CustomerInfo(
                      user['id'],
                      user['avatarUrl'],
                      user['name'],
                      user['phoneNumber'],
                      user['token'],
                    );

                    globalCustomer = customer;

                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          final locProvider = LocationProvider.of(context);

                          final currentTrip = TripProvider.of(context);

                          if (!locProvider.isDemoLocationFixed) {
                            return LocationScaffold();
                          }

                          if (currentTrip.isActive) {
                            return tripIsFinished(
                                    currentTrip.activeTrip!.status)
                                ? tripRating(context)
                                : const ActiveTrip();
                          }

                          return NewTrip(tripProvider: currentTrip); //
                        },
                      ),
                    );
                  } else {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đăng nhập thất bại. Vui lòng thử lại.'),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error during login: $e');
                  // Handle other errors
                }
              },
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
