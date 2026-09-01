import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lottie/lottie.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:open_core_hr/api/dio_api/exceptions/api_exceptions.dart';
import 'package:open_core_hr/screens/Permission/permissions_screen.dart';
import 'package:passkeys/exceptions.dart';

import '../../Utils/app_widgets.dart';
import '../../service/passkey_service.dart';
import '../../main.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_data_provider.dart';
import '../../utils/app_images.dart';
import '../../utils/design_system.dart';
import '../ForgotPassword/ForgotPassword.dart';
import '../org_choose_screen.dart';
import 'LoginStore.dart';

class LoginScreen extends StatefulWidget {
  final bool isDeviceVerified;
  static String tag = '/LoginScreen';

  const LoginScreen({super.key, this.isDeviceVerified = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final LoginStore _loginStore = LoginStore();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passkeyLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    init();
    _emailController.text = '';
    _passwordController.text = '';
    _loginStore.employeeId = _emailController.text;
    _loginStore.password = _passwordController.text;
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> init() async {
    await sharedHelper.refreshAppSettings();
    await moduleService.refreshModuleSettings();
    _loginStore.setupValidations();
  }

  /// Signs the user in with a passkey via the device biometric prompt
  /// (fingerprint / face), then persists the returned session like a normal
  /// login.
  Future<void> _signInWithPasskey() async {
    if (_passkeyLoading) return;
    HapticFeedback.mediumImpact();
    hideKeyboard(context);
    setState(() => _passkeyLoading = true);
    try {
      final user = await PasskeyService().login();
      if (!mounted) return;
      final status = await _loginStore.savePasskeyUser(user);
      if (!mounted) return;
      sharedHelper.routeBasedOnStatus(context, status);
    } catch (e) {
      if (!mounted) return;
      final message = switch (e) {
        PasskeyAuthCancelledException() => 'Passkey sign-in was cancelled.',
        NoCredentialsAvailableException() =>
          'No passkey found. Please sign in with email/password and set up biometric login.',
        DomainNotAssociatedException() =>
          'This app is not linked to the passkey domain yet.',
        _ => e is ApiException && e.message.trim().isNotEmpty
            ? e.message
            : 'Passkey sign-in failed. Please try again.',
      };
      toast(message);
    } finally {
      if (mounted) setState(() => _passkeyLoading = false);
    }
  }

  void _showLanguageSelector() {
    final languages = languageList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Observer(
        builder: (_) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: appStore.isDarkModeOn
                ? const Color(0xFF1F2937)
                : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF696CFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.language,
                        color: Color(0xFF696CFF),
                        size: 24,
                      ),
                    ),
                    16.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language.lblLanguage,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: appStore.isDarkModeOn
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                          ),
                          4.height,
                          Text(
                            language.lblSupportLanguage,
                            style: TextStyle(
                              fontSize: 13,
                              color: appStore.isDarkModeOn
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: appStore.isDarkModeOn
                    ? Colors.grey[700]
                    : const Color(0xFFE5E7EB),
              ),
              // Language list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    final isSelected =
                        appStore.selectedLanguageCode == lang.languageCode;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          await appStore.setLanguage(
                            lang.languageCode!,
                            context: context,
                          );
                          setState(() {});
                          if (mounted) {
                            Navigator.pop(context);
                            toast(language.lblLanguageChanged);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF696CFF).withOpacity(0.08)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              // Flag
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.asset(
                                  lang.flag.validate(),
                                  width: 28,
                                  height: 20,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 28,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.flag,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              16.width,
                              // Language name
                              Expanded(
                                child: Text(
                                  lang.name.validate(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF696CFF)
                                        : appStore.isDarkModeOn
                                            ? Colors.white
                                            : const Color(0xFF111827),
                                  ),
                                ),
                              ),
                              // Check mark for selected
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF696CFF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
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
              // Bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget demoModeWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB44F), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.science_outlined,
            color: Colors.white,
            size: 36,
          ),
          10.height,
          const Text(
            'App is in demo mode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          6.height,
          const Text(
            'You can login with demo employee id and password',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          16.height,
          Observer(
            builder: (_) => _loginStore.isDemoRegisterBtnLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          var result = await _loginStore.createDemoUser();
                          if (result.toLowerCase() == 'active') {
                            if (!mounted) return;
                            sharedHelper.refreshAppSettings();
                            PermissionScreen().launch(context, isNewTask: true);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: const Center(
                          child: Text(
                            'Register as a demo employee',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF97316),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: context.width(),
        height: context.height(),
        decoration: BoxDecoration(
          color: appStore.isDarkModeOn ? AppDesignSystem.neutral900 : AppDesignSystem.backgroundColor,
        ),
        child: Stack(
          children: [
            // Background Ornaments
            if (!appStore.isDarkModeOn) ...[
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppDesignSystem.primaryColor.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppDesignSystem.primaryColor.withOpacity(0.03),
                  ),
                ),
              ),
            ],

            SafeArea(
              child: Stack(
                children: [
              // Main content
              Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 400,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Login form content
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Observer(
                        builder: (_) => Column(
                          children: [
                            // App Logo with Glassmorphism
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: (appStore.isDarkModeOn ? AppDesignSystem.neutral800 : white).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: (appStore.isDarkModeOn ? white : AppDesignSystem.neutral200).withOpacity(0.1),
                                  width: 1.5,
                                ),
                                boxShadow: AppDesignSystem.shadowMedium,
                              ),
                              child: Image.asset(
                                appLogoImg,
                                height: 70,
                                width: 70,
                              ),
                            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                            24.height,

                            // Modern Login Card
                            Container(
                              decoration: BoxDecoration(
                                color: appStore.isDarkModeOn ? AppDesignSystem.neutral800 : white,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: AppDesignSystem.shadowLarge,
                                border: Border.all(
                                  color: (appStore.isDarkModeOn ? white : AppDesignSystem.neutral200).withOpacity(0.05),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // App Name & Welcom
                                    Text(
                                      mainAppName,
                                      style: boldTextStyle(
                                        size: 26,
                                        color: AppDesignSystem.primaryColor,
                                        letterSpacing: -0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    8.height,
                                    Text(
                                      language.lblPleaseLoginToContinue,
                                      style: secondaryTextStyle(
                                        size: 14,
                                        color: AppDesignSystem.neutral500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    32.height,

                                    // **Device Verified Case**
                                    widget.isDeviceVerified
                                        ? Column(
                                            children: [
                                              Lottie.asset(
                                                'assets/animations/screen_tap.json',
                                                height: 150,
                                                repeat: true,
                                              ),
                                              16.height,
                                              Text(
                                                language
                                                    .lblLooksLikeYouAlreadyRegisteredThisDeviceYouCanUseOneTapLogin,
                                                textAlign: TextAlign.center,
                                                style: secondaryTextStyle(size: 14),
                                              ),
                                              20.height,
                                              _loginStore.isLoginWithUidBtnLoading
                                                  ? loadingWidgetMaker()
                                                  : AppButton(
                                                      text: language.lblOneTapLogin,
                                                      color: appStore.appColorPrimary,
                                                      elevation: 4,
                                                      textColor: Colors.white,
                                                      shapeBorder: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      onTap: () async {
                                                        hideKeyboard(context);
                                                        var result =
                                                            await _loginStore.loginWithUid();
                                                        sharedHelper.routeBasedOnStatus(
                                                            context, result);
                                                      },
                                                    ),
                                              12.height,
                                              Text(
                                                language
                                                    .lblIfYouWantToLoginWithDifferentAccountPleaseContactAdministrator,
                                                textAlign: TextAlign.center,
                                                style: secondaryTextStyle(size: 12),
                                              ),
                                            ],
                                          )
                                        // **Regular Login Form**
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              // Email/Username Field
                                              Observer(
                                                builder: (_) => TextFormField(
                                                  controller: _emailController,
                                                  keyboardType: TextInputType.text,
                                                  autocorrect: false,
                                                  enableSuggestions: false,
                                                  autofillHints: const <String>[],
                                                  onChanged: (value) => _loginStore.employeeId = value,
                                                  decoration: AppDesignSystem.modernInputDecoration(
                                                    hintText: language.lblEmail,
                                                    prefixIcon: const Icon(Iconsax.sms, size: 20),
                                                  ).copyWith(
                                                    errorText: _loginStore.error.employeeId,
                                                  ),
                                                  cursorColor: AppDesignSystem.primaryColor,
                                                ),
                                              ),
                                              20.height,

                                              // Password Field
                                              Observer(
                                                builder: (_) => TextFormField(
                                                  controller: _passwordController,
                                                  obscureText: true,
                                                  autocorrect: false,
                                                  enableSuggestions: false,
                                                  autofillHints: const <String>[],
                                                  onChanged: (value) => _loginStore.password = value,
                                                  decoration: AppDesignSystem.modernInputDecoration(
                                                    hintText: language.lblPassword,
                                                    prefixIcon: const Icon(Iconsax.lock, size: 20),
                                                  ).copyWith(
                                                    errorText: _loginStore.error.password,
                                                  ),
                                                  cursorColor: AppDesignSystem.primaryColor,
                                                ),
                                              ),
                                              12.height,

                                              // Forgot Password
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    HapticFeedback.lightImpact();
                                                    const ForgotPassword().launch(context);
                                                  },
                                                    child: Text(
                                                      language.lblForgotPassword,
                                                      style: boldTextStyle(
                                                        size: 13,
                                                        color: AppDesignSystem.primaryColor,
                                                      ),
                                                    ),
                                                ),
                                              ),
                                              24.height,

                                              // Login Button
                                              _loginStore.isLoading ||
                                                      _loginStore.isDemoRegisterBtnLoading ||
                                                      _loginStore.isLoginWithUidBtnLoading
                                                  ? const Center(child: CircularProgressIndicator())
                                                  : AppButton(
                                                      width: double.infinity,
                                                      text: language.lblLogin,
                                                      textStyle: boldTextStyle(color: white),
                                                      color: AppDesignSystem.primaryColor,
                                                      shapeBorder: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      onTap: () async {
                                                        HapticFeedback.mediumImpact();
                                                        hideKeyboard(context);
                                                        _loginStore.validateAll();
                                                        if (_loginStore.canLogin) {
                                                          var result = await _loginStore.login();
                                                          if (mounted) sharedHelper.routeBasedOnStatus(context, result);
                                                        }
                                                      },
                                                    ).animate().fadeIn(delay: 400.ms),

                                              // Passkey / biometric sign-in
                                              if (_passkeyLoading)
                                                const Center(
                                                  child: SizedBox(
                                                    width: 26,
                                                    height: 26,
                                                    child: CircularProgressIndicator(strokeWidth: 2.5),
                                                  ),
                                                )
                                              else
                                                OutlinedButton.icon(
                                                  onPressed: _signInWithPasskey,
                                                  icon: const Icon(Icons.fingerprint, size: 20),
                                                  label: const Text('Sign in with passkey'),
                                                  style: OutlinedButton.styleFrom(
                                                    minimumSize: const Size.fromHeight(52),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    side: BorderSide(
                                                      color: AppDesignSystem.primaryColor.withOpacity(0.5),
                                                    ),
                                                    foregroundColor: AppDesignSystem.primaryColor,
                                                  ),
                                                ).animate().fadeIn(delay: 500.ms),
                                            ],
                                          ),
                                  ],
                                ),
                              ),
                            ),

                            // Demo Mode Widget
                            if (getIsDemoMode() && !widget.isDeviceVerified) ...[
                              16.height,
                              demoModeWidget(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Company Switcher (SaaS mode)
                  if (getIsSaaSMode())
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppDesignSystem.primaryColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.business_outlined,
                              color: AppDesignSystem.primaryColor,
                              size: 20,
                            ),
                            10.width,
                            Text(
                              appStore.centralDomainURL,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppDesignSystem.primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            10.width,
                            Icon(
                              Icons.refresh_rounded,
                              color: AppDesignSystem.primaryColor,
                              size: 20,
                            )
                          ],
                        ),
                      ).onTap(() {
                        HapticFeedback.lightImpact();
                        OrgChooseScreen().launch(context);
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
              // Language Switcher Button - Top Right
              Positioned(
                top: 8,
                right: 8,
                child: Observer(
                  builder: (_) {
                    final currentLang = languageList().firstWhere(
                      (l) => l.languageCode == appStore.selectedLanguageCode,
                      orElse: () => languageList().first,
                    );
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showLanguageSelector();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Image.asset(
                                  currentLang.flag.validate(),
                                  width: 20,
                                  height: 14,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.language,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                              8.width,
                              Text(
                                currentLang.name.validate(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              4.width,
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 18,
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
        ),
      ],
    ),
  ),
);
}
}
