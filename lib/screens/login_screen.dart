import 'package:flutter/material.dart';

import '../models/login_request.dart';
import '../models/user_session.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'admin_dashboard_screen.dart';
import 'customer_main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final AuthService _authService = AuthService();

  bool _hidePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final bool isValid =
        _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final LoginRequest request = LoginRequest(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final UserSession user =
      await _authService.login(request);

      if (!mounted) {
        return;
      }

      final Widget destination;

      if (user.isAdmin) {
        destination = const AdminDashboardScreen();
      } else if (user.isCustomer) {
        destination = const CustomerMainScreen();
      } else {
        throw const AuthException(
          'Your account does not have a valid role.',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome ${user.fullName}'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => destination,
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'An unexpected error occurred.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openRegisterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const RegisterScreen();
        },
      ),
    );
  }

  void _showForgotPasswordMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Forgot password will be added later.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _LoginGridPainter(),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (
                  BuildContext context,
                  BoxConstraints constraints,
                  ) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    30,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 480,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const _BrandHeader(),

                              const SizedBox(height: 24),

                              const _CarCover(),

                              const SizedBox(height: 20),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  25,
                                  22,
                                  22,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardColor,
                                  border: Border.all(
                                    color: AppTheme.borderColor,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.largeRadius,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x14171717),
                                      offset: Offset(6, 6),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const _LoginHeading(),

                                    const SizedBox(height: 28),

                                    _FieldLabel(
                                      text: 'EMAIL ADDRESS',
                                    ),

                                    const SizedBox(height: 8),

                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType:
                                      TextInputType.emailAddress,
                                      textInputAction:
                                      TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.email,
                                        AutofillHints.username,
                                      ],
                                      decoration:
                                      const InputDecoration(
                                        hintText:
                                        'example@email.com',
                                        prefixIcon: Icon(
                                          Icons.mail_outline_rounded,
                                        ),
                                      ),
                                      validator: (String? value) {
                                        final String email =
                                            value?.trim() ?? '';

                                        if (email.isEmpty) {
                                          return 'Email is required';
                                        }

                                        if (!email.contains('@') ||
                                            !email.contains('.')) {
                                          return 'Enter a valid email';
                                        }

                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 20),

                                    _FieldLabel(
                                      text: 'PASSWORD',
                                    ),

                                    const SizedBox(height: 8),

                                    TextFormField(
                                      controller:
                                      _passwordController,
                                      obscureText: _hidePassword,
                                      textInputAction:
                                      TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onFieldSubmitted:
                                          (String value) {
                                        if (!_isLoading) {
                                          _login();
                                        }
                                      },
                                      decoration: InputDecoration(
                                        hintText:
                                        'Enter your password',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                        ),
                                        suffixIcon: IconButton(
                                          tooltip: _hidePassword
                                              ? 'Show password'
                                              : 'Hide password',
                                          onPressed: () {
                                            setState(() {
                                              _hidePassword =
                                              !_hidePassword;
                                            });
                                          },
                                          icon: Icon(
                                            _hidePassword
                                                ? Icons
                                                .visibility_outlined
                                                : Icons
                                                .visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                      validator: (String? value) {
                                        if (value == null ||
                                            value.isEmpty) {
                                          return 'Password is required';
                                        }

                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }

                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 12),

                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            activeColor:
                                            AppTheme.primaryBlue,
                                            side: const BorderSide(
                                              color:
                                              AppTheme.borderColor,
                                            ),
                                            shape:
                                            RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                4,
                                              ),
                                            ),
                                            onChanged:
                                                (bool? value) {
                                              setState(() {
                                                _rememberMe =
                                                    value ?? false;
                                              });
                                            },
                                          ),
                                        ),

                                        const SizedBox(width: 9),

                                        const Expanded(
                                          child: Text(
                                            'Remember me',
                                            style: TextStyle(
                                              color:
                                              AppTheme.textColor,
                                              fontSize: 12,
                                              fontWeight:
                                              FontWeight.w500,
                                            ),
                                          ),
                                        ),

                                        TextButton(
                                          onPressed:
                                          _showForgotPasswordMessage,
                                          child: const Text(
                                            'Forgot password?',
                                            style: TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 18),

                                    PrimaryButton(
                                      text: 'SIGN IN  →',
                                      isLoading: _isLoading,
                                      onPressed: _login,
                                    ),

                                    const SizedBox(height: 20),

                                    const Row(
                                      children: [
                                        Expanded(
                                          child: Divider(),
                                        ),
                                        Padding(
                                          padding:
                                          EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            'NEW MEMBER',
                                            style: TextStyle(
                                              color:
                                              AppTheme.mutedColor,
                                              fontSize: 10,
                                              fontWeight:
                                              FontWeight.w700,
                                              letterSpacing: 1.3,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed:
                                        _openRegisterScreen,
                                        icon: const Icon(
                                          Icons.person_add_alt_1_rounded,
                                          size: 19,
                                        ),
                                        label: const Text(
                                          'CREATE ACCOUNT',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              const _SecurityMessage(),
                            ],
                          ),
                        ),
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow,
            border: Border.all(
              color: AppTheme.primaryYellowStrong,
            ),
            borderRadius: BorderRadius.circular(
              AppTheme.defaultRadius,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12171717),
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            color: AppTheme.primaryBlue,
            size: 29,
          ),
        ),

        const SizedBox(width: 13),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Car Rental',
                style: TextStyle(
                  color: AppTheme.darkColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'PREMIUM MOBILITY',
                style: TextStyle(
                  color: AppTheme.primaryBlueDark,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: AppTheme.successSoft,
            borderRadius: BorderRadius.circular(
              AppTheme.smallRadius,
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: AppTheme.successColor,
                size: 15,
              ),
              SizedBox(width: 5),
              Text(
                'SECURE',
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CarCover extends StatelessWidget {
  const _CarCover();

  static const String _imageUrl =
      'https://images.unsplash.com/photo-1525198748134-37e71b522e9c'
      '?auto=format&fit=crop&w=1400&q=85';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlueSoft,
        border: Border.all(
          color: AppTheme.borderColor,
        ),
        borderRadius: BorderRadius.circular(
          AppTheme.largeRadius,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
                ) {
              return const ColoredBox(
                color: AppTheme.primaryBlueSoft,
                child: Center(
                  child: Icon(
                    Icons.directions_car_filled_rounded,
                    color: AppTheme.primaryBlue,
                    size: 72,
                  ),
                ),
              );
            },
          ),

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  Color(0xD9171717),
                  Color(0x33171717),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const Positioned(
            left: 18,
            right: 18,
            bottom: 17,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LUXURY IN EVERY JOURNEY',
                  style: TextStyle(
                    color: AppTheme.primaryYellow,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Your next drive.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginHeading extends StatelessWidget {
  const _LoginHeading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SECURE MEMBER ACCESS',
          style: TextStyle(
            color: AppTheme.primaryBlueDark,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
        SizedBox(height: 11),
        Text(
          'Welcome back',
          style: TextStyle(
            color: AppTheme.darkColor,
            fontSize: 31,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.3,
          ),
        ),
        SizedBox(height: 9),
        Text(
          'Enter your account details to manage your rentals and continue your journey.',
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.darkSoft,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }
}

class _SecurityMessage extends StatelessWidget {
  const _SecurityMessage();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          color: AppTheme.successColor,
          size: 15,
        ),
        SizedBox(width: 7),
        Flexible(
          child: Text(
            'YOUR CONNECTION IS SECURE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.mutedColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginGridPainter extends CustomPainter {
  const _LoginGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppTheme.borderSoft.withValues(alpha: 0.55)
      ..strokeWidth = 0.7;

    const double gridSize = 44;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant _LoginGridPainter oldDelegate,
      ) {
    return false;
  }
}