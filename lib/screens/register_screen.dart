import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() {
    return _RegisterScreenState();
  }
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final TextEditingController _fullNameController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  final TextEditingController _birthDateController =
  TextEditingController();

  final TextEditingController _licenseController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _licenseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime today = DateTime.now();

    final DateTime latestAllowedDate = DateTime(
      today.year - 18,
      today.month,
      today.day,
    );

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: latestAllowedDate,
      firstDate: DateTime(1900),
      lastDate: latestAllowedDate,
      helpText: 'SELECT DATE OF BIRTH',
      cancelText: 'CANCEL',
      confirmText: 'SELECT',
    );

    if (selectedDate == null) {
      return;
    }

    final String month =
    selectedDate.month.toString().padLeft(2, '0');

    final String day =
    selectedDate.day.toString().padLeft(2, '0');

    setState(() {
      _birthDateController.text =
      '${selectedDate.year}-$month-$day';
    });
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    final bool isValid =
        _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the terms and conditions.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Registration API connection will be added later.
    await Future<void>.delayed(
      const Duration(seconds: 1),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Account created successfully.',
        ),
        backgroundColor: AppTheme.successColor,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(
            left: 14,
            top: 10,
            bottom: 10,
          ),
          child: IconButton(
            tooltip: 'Back',
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
          ),
        ),
        title: const Text('Create Account'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _RegisterGridPainter(),
            ),
          ),
          SafeArea(
            top: false,
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  22,
                  20,
                  36,
                ),
                children: [
                  const _RegisterHeader(),

                  const SizedBox(height: 22),

                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      22,
                      20,
                      24,
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
                        const _SectionTitle(
                          number: '01',
                          title: 'PERSONAL INFORMATION',
                        ),

                        const SizedBox(height: 20),

                        const _FieldLabel(
                          text: 'FULL NAME',
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _fullNameController,
                          textCapitalization:
                          TextCapitalization.words,
                          textInputAction:
                          TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                            ),
                          ),
                          validator: (String? value) {
                            final String name =
                                value?.trim() ?? '';

                            if (name.length < 2 ||
                                name.length > 100) {
                              return 'Name must be between 2 and 100 characters';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        const _FieldLabel(
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
                          ],
                          decoration: const InputDecoration(
                            hintText: 'example@email.com',
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                            ),
                          ),
                          validator: (String? value) {
                            final String email =
                                value?.trim() ?? '';

                            final RegExp emailPattern =
                            RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            );

                            if (!emailPattern
                                .hasMatch(email)) {
                              return 'Enter a valid email address';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        const _FieldLabel(
                          text: 'PHONE NUMBER',
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType:
                          TextInputType.phone,
                          textInputAction:
                          TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.telephoneNumber,
                          ],
                          decoration: const InputDecoration(
                            hintText: '+970 59 000 0000',
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                            ),
                          ),
                          validator: (String? value) {
                            final String phone =
                                value?.trim() ?? '';

                            final RegExp phonePattern =
                            RegExp(
                              r'^\+?[0-9][0-9\s-]{6,19}$',
                            );

                            if (!phonePattern
                                .hasMatch(phone)) {
                              return 'Enter a valid phone number';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        const _FieldLabel(
                          text: 'DATE OF BIRTH',
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller:
                          _birthDateController,
                          readOnly: true,
                          onTap: _selectBirthDate,
                          decoration: const InputDecoration(
                            hintText: 'YYYY-MM-DD',
                            prefixIcon: Icon(
                              Icons
                                  .calendar_today_outlined,
                            ),
                            suffixIcon: Icon(
                              Icons
                                  .keyboard_arrow_down_rounded,
                            ),
                          ),
                          validator: (String? value) {
                            if (value == null ||
                                value.isEmpty) {
                              return 'Date of birth is required';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      22,
                      20,
                      24,
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
                        const _SectionTitle(
                          number: '02',
                          title: 'DRIVER DETAILS',
                        ),

                        const SizedBox(height: 20),

                        const _FieldLabel(
                          text: 'DRIVING LICENSE NUMBER',
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _licenseController,
                          textCapitalization:
                          TextCapitalization.characters,
                          textInputAction:
                          TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText:
                            'Enter your license number',
                            prefixIcon: Icon(
                              Icons.badge_outlined,
                            ),
                          ),
                          validator: (String? value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Driving license is required';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      22,
                      20,
                      24,
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
                        const _SectionTitle(
                          number: '03',
                          title: 'ACCOUNT SECURITY',
                        ),

                        const SizedBox(height: 20),

                        const _FieldLabel(
                          text: 'PASSWORD',
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _hidePassword,
                          textInputAction:
                          TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.newPassword,
                          ],
                          decoration: InputDecoration(
                            hintText:
                            'At least 8 characters',
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
                                value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        const _FieldLabel(
                          text: 'CONFIRM PASSWORD',
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller:
                          _confirmPasswordController,
                          obscureText:
                          _hideConfirmPassword,
                          textInputAction:
                          TextInputAction.done,
                          onFieldSubmitted:
                              (String value) {
                            if (!_isLoading) {
                              _register();
                            }
                          },
                          decoration: InputDecoration(
                            hintText:
                            'Enter your password again',
                            prefixIcon: const Icon(
                              Icons.lock_reset_outlined,
                            ),
                            suffixIcon: IconButton(
                              tooltip: _hideConfirmPassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () {
                                setState(() {
                                  _hideConfirmPassword =
                                  !_hideConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _hideConfirmPassword
                                    ? Icons
                                    .visibility_outlined
                                    : Icons
                                    .visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (String? value) {
                            if (value !=
                                _passwordController.text) {
                              return 'Passwords do not match';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

                        InkWell(
                          borderRadius:
                          BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              _acceptedTerms =
                              !_acceptedTerms;
                            });
                          },
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(
                              vertical: 5,
                            ),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _acceptedTerms,
                                    activeColor:
                                    AppTheme.primaryBlue,
                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                        4,
                                      ),
                                    ),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _acceptedTerms =
                                            value ?? false;
                                      });
                                    },
                                  ),
                                ),

                                const SizedBox(width: 10),

                                const Expanded(
                                  child: Text(
                                    'I confirm that my information is correct and accept the terms and conditions.',
                                    style: TextStyle(
                                      color:
                                      AppTheme.textColor,
                                      fontSize: 11,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  PrimaryButton(
                    text: 'CREATE ACCOUNT  →',
                    isLoading: _isLoading,
                    onPressed: _register,
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.login_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'ALREADY A MEMBER? SIGN IN',
                      ),
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

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(
          AppTheme.largeRadius,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x243178C6),
            offset: Offset(6, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow,
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    AppTheme.defaultRadius,
                  ),
                ),
              ),
              child: Icon(
                Icons.person_add_alt_1_rounded,
                color: AppTheme.darkColor,
                size: 30,
              ),
            ),
          ),

          SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'JOIN THE JOURNEY',
                  style: TextStyle(
                    color: AppTheme.primaryYellow,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Create your account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.7,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Reserve and manage vehicles easily.',
                  style: TextStyle(
                    color: Color(0xFFDCEBFA),
                    fontSize: 11,
                    height: 1.4,
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

class _SectionTitle extends StatelessWidget {
  final String number;
  final String title;

  const _SectionTitle({
    required this.number,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 33,
          height: 33,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow,
            border: Border.all(
              color: AppTheme.primaryYellowStrong,
            ),
            borderRadius: BorderRadius.circular(
              AppTheme.smallRadius,
            ),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppTheme.darkColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.primaryBlueDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
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
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }
}

class _RegisterGridPainter extends CustomPainter {
  const _RegisterGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppTheme.borderSoft.withValues(
        alpha: 0.50,
      )
      ..strokeWidth = 0.7;

    const double gridSize = 44;

    for (
    double x = 0;
    x <= size.width;
    x += gridSize
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (
    double y = 0;
    y <= size.height;
    y += gridSize
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant _RegisterGridPainter oldDelegate,
      ) {
    return false;
  }
}