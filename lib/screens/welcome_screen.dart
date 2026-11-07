import 'package:flutter/material.dart';
import 'package:expense_tracker_app/core/l10n.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'main_navigation_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const blue = Color(0xFF087FFF);
  static const ink = Color(0xFF09123D);
  static const muted = Color(0xFF7885A3);

  void _continue(BuildContext context) {
    final signedIn =
        context.read<AuthProvider>().isAuthenticated;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => signedIn
            ? const MainNavigationScreen()
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signedIn =
        context.watch<AuthProvider>().isAuthenticated;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -170,
            left: -120,
            child: _bubble(330),
          ),
          Positioned(
            bottom: -220,
            right: -150,
            child: _bubble(400),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;

                final compact = h < 800;
                final veryCompact = h < 680;

                return Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 680,
                    ),
                    child: Padding(
                      padding:
                          EdgeInsets.fromLTRB(
                        24,
                        veryCompact ? 6 : 10,
                        24,
                        veryCompact ? 10 : 20,
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment:
                                Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  _continue(context),
                              style:
                                  TextButton.styleFrom(
                                backgroundColor:
                                    const Color(
                                  0xFFEAF4FF,
                                ),
                                foregroundColor:
                                    blue,
                                padding:
                                    EdgeInsets.symmetric(
                                  horizontal:
                                      veryCompact
                                          ? 16
                                          : 22,
                                  vertical:
                                      veryCompact
                                          ? 6
                                          : 9,
                                ),
                              ),
                              child:
                                  Text(context.tr('skip')),
                            ),
                          ),

                          SizedBox(
                            height:
                                veryCompact ? 0 : 4,
                          ),

                          Expanded(
                            flex: compact ? 4 : 5,
                            child: const Padding(
                              padding:
                                  EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child:
                                  _WelcomeArtwork(),
                            ),
                          ),

                          SizedBox(
                            height:
                                veryCompact ? 4 : 10,
                          ),

                          Text(
                            context.tr('welcome_to'),
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color: ink,
                              fontSize:
                                  veryCompact
                                      ? 24
                                      : compact
                                          ? 27
                                          : 31,
                              height: 1.1,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          Text(
                            'Expense Tracker',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color: blue,
                              fontSize:
                                  veryCompact
                                      ? 27
                                      : compact
                                          ? 30
                                          : 34,
                              height: 1.2,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          SizedBox(
                            height:
                                veryCompact ? 5 : 10,
                          ),

                          Text(
                            context.tr('welcome_subtitle'),
                            textAlign:
                                TextAlign.center,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: muted,
                              fontSize:
                                  veryCompact
                                      ? 12
                                      : 14,
                              height: 1.4,
                            ),
                          ),

                          SizedBox(
                            height:
                                veryCompact ? 8 : 16,
                          ),

                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _Feature(
                                  Icons
                                      .account_balance_wallet_outlined,
                                  context.tr('wallets'),
                                  context.tr('manage_accounts'),
                                  const Color(
                                    0xFF00BE8A,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _Feature(
                                  Icons
                                      .bar_chart_rounded,
                                  context.tr('expenses'),
                                  context.tr('track_spending'),
                                  blue,
                                ),
                              ),
                              Expanded(
                                child: _Feature(
                                  Icons
                                      .track_changes_rounded,
                                  context.tr('budgets'),
                                  context.tr('control_budget'),
                                  const Color(
                                    0xFFFF881E,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(
                            height:
                                veryCompact ? 8 : 16,
                          ),

                          SizedBox(
                            width: double.infinity,
                            height:
                                veryCompact ? 46 : 54,
                            child: FilledButton(
                              onPressed: () =>
                                  _continue(context),
                              style:
                                  FilledButton.styleFrom(
                                backgroundColor: blue,
                                foregroundColor:
                                    Colors.white,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    15,
                                  ),
                                ),
                              ),
                              child: Text(
                                signedIn
                                    ? context.tr('continue')
                                    : context.tr('login'),
                                style:
                                    const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          if (!signedIn) ...[
                            SizedBox(
                              height:
                                  veryCompact
                                      ? 7
                                      : 10,
                            ),
                            SizedBox(
                              width: double.infinity,
                              height:
                                  veryCompact
                                      ? 46
                                      : 54,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushReplacement(
                                    MaterialPageRoute<
                                        void>(
                                      builder: (_) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                                style:
                                    OutlinedButton
                                        .styleFrom(
                                  foregroundColor:
                                      blue,
                                  side:
                                      const BorderSide(
                                    color: blue,
                                  ),
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      15,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  context.tr('create_account'),
                                  style:
                                      const TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  Widget _bubble(double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE8F4FF),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(
    this.icon,
    this.title,
    this.description,
    this.color,
  );

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).height < 700;

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: compact ? 42 : 52,
            height: compact ? 42 : 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: compact ? 22 : 27,
            ),
          ),
          SizedBox(
            height: compact ? 5 : 8,
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WelcomeScreen.ink,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12 : 14,
            ),
          ),
          SizedBox(
            height: compact ? 2 : 4,
          ),
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: WelcomeScreen.muted,
              fontSize: compact ? 10 : 12,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeArtwork extends StatelessWidget {
  const _WelcomeArtwork();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 500,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 370,
                height: 265,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFE4F3FF),
                  borderRadius:
                      BorderRadius.circular(130),
                ),
              ),

              Positioned(
                bottom: 8,
                child: Container(
                  width: 340,
                  height: 32,
                  decoration:
                      const BoxDecoration(
                    color: Color(0xFFC9E6FF),
                    borderRadius:
                        BorderRadius.all(
                      Radius.elliptical(
                        170,
                        16,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 52,
                left: 165,
                child: Transform.rotate(
                  angle: -0.38,
                  child: Container(
                    width: 148,
                    height: 118,
                    decoration:
                        BoxDecoration(
                      gradient:
                          const LinearGradient(
                        colors: [
                          Color(
                            0xFF7BE89C,
                          ),
                          Color(
                            0xFF00B88E,
                          ),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(
                          0xFF98F5B7,
                        ),
                        width: 5,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        9,
                      ),
                    ),
                    child: const Icon(
                      Icons.attach_money_rounded,
                      color: Colors.white,
                      size: 70,
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 27,
                left: 126,
                child: Transform.rotate(
                  angle: -0.09,
                  child: Container(
                    width: 240,
                    height: 160,
                    decoration:
                        BoxDecoration(
                      gradient:
                          const LinearGradient(
                        begin:
                            Alignment.topLeft,
                        end: Alignment
                            .bottomRight,
                        colors: [
                          Color(
                            0xFF42AEFF,
                          ),
                          Color(
                            0xFF0054EA,
                          ),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        26,
                      ),
                      border: Border.all(
                        color: const Color(
                          0xFF278CFF,
                        ),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: WelcomeScreen
                              .blue
                              .withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 18,
                          offset:
                              const Offset(
                            0,
                            10,
                          ),
                        ),
                      ],
                    ),
                    child: Align(
                      alignment:
                          Alignment.centerRight,
                      child: Container(
                        width: 70,
                        height: 48,
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFF0875F4,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),
                        child:
                            const Icon(
                          Icons.circle,
                          color: Color(
                            0xFFFFC34F,
                          ),
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 12,
                left: 10,
                child: Transform.rotate(
                  angle: -0.13,
                  child: _card(
                    context.tr('income'),
                    '\$2,500',
                    const Color(
                      0xFF00BF8A,
                    ),
                    Icons.arrow_upward,
                  ),
                ),
              ),

              Positioned(
                top: 45,
                right: 6,
                child: Transform.rotate(
                  angle: 0.15,
                  child: _card(
                    context.tr('expense'),
                    '\$1,800',
                    const Color(
                      0xFFFF526F,
                    ),
                    Icons.arrow_downward,
                  ),
                ),
              ),

              Positioned(
                bottom: 10,
                right: 4,
                child: Transform.rotate(
                  angle: 0.14,
                  child: Container(
                    width: 148,
                    height: 85,
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Icon(
                          Icons.donut_small,
                          color: Color(
                            0xFFFFB847,
                          ),
                          size: 54,
                        ),
                        Icon(
                          Icons
                              .format_list_bulleted,
                          color: Color(
                            0xFF77B5FF,
                          ),
                          size: 36,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color:
                        WelcomeScreen.muted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Icon(
            Icons.bar_chart_rounded,
            color:
                color.withValues(alpha: 0.3),
            size: 34,
          ),
        ],
      ),
    );
  }
}