import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

part 'src/state.dart';
part 'src/components.dart';
part 'src/core_screens.dart';
part 'src/booking.dart';
part 'src/account_screens.dart';
part 'src/services_screens.dart';

void main() => runApp(DigitalLabApp());

class DigitalLabApp extends StatefulWidget {
  DigitalLabApp({super.key, AppStore? store}) : store = store ?? AppStore();
  final AppStore store;
  @override
  State<DigitalLabApp> createState() => _DigitalLabAppState();
}
class _DigitalLabAppState extends State<DigitalLabApp> {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) => AppScope(
      store: widget.store,
      child: MaterialApp(
        title: 'Digital Lab',
        debugShowCheckedModeBanner: false,
        locale: Locale(widget.store.arabic ? 'ar' : 'en'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: widget.store.themeMode,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: TextScaler.linear(
              media.textScaler.scale(1) * widget.store.textScale)),
            child: child!,
          );
        },
        home: const AppShell(),
      ),
    ),
  );
}
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}
class _AppShellState extends State<AppShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final labels = [s.t('الرئيسية','Home'),s.t('نتائجي','Results'),
      s.t('اكتشف','Explore'),s.t('حجوزاتي','Bookings'),s.t('حسابي','Account')];
    const icons = [Icons.space_dashboard_outlined, Icons.description_outlined,
      Icons.explore_outlined, Icons.calendar_month_outlined, Icons.person_outline];
    final pages = <Widget>[
      HomeScreen(onTab: (i) => setState(() => tab = i)),
      const ResultsScreen(), const ExploreScreen(),
      const BookingsScreen(), const AccountScreen(),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 960;
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const BrandMark(size: 34), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Digital Lab', style: TextStyle(fontSize: 18,fontWeight: FontWeight.w800)),
            Text(s.t('المختبر الرقمي','YOUR HEALTH, CONNECTED'),
              style: TextStyle(fontSize: 10,letterSpacing: s.arabic ? 0 : 1.5,color: muted(context))),
          ]),
        ]),
        actions: [
          IconButton(tooltip: s.t('تغيير اللغة','Change language'),
            onPressed: s.toggleLanguage, icon: const Icon(Icons.translate)),
          IconButton(tooltip: s.t('الإشعارات','Notifications'),
            onPressed: () => go(context, const NotificationsScreen()),
            icon: Badge(isLabelVisible: s.unreadCount > 0,
              label: Text('${s.unreadCount}'),child: const Icon(Icons.notifications_none))),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(children: [
        if (wide) NavigationRail(
          selectedIndex: tab, labelType: NavigationRailLabelType.all,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: List.generate(labels.length, (i) => NavigationRailDestination(
            icon: Icon(icons[i]),label: Text(labels[i]))),
        ),
        Expanded(child: Column(children: [
          Container(width: double.infinity, color: accent.withAlpha(14),
            padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 7),
            child: Text(s.t('نسخة تفاعلية تجريبية • بيانات وهمية، تُصفّر عند إعادة التشغيل',
              'Interactive demo • Fictional data, reset on restart'),
              textAlign: TextAlign.center,style: const TextStyle(fontSize: 11))),
          Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 180),
            child: KeyedSubtree(key: ValueKey(tab),child: pages[tab]))),
        ])),
      ]),
      bottomNavigationBar: wide ? null : NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: List.generate(labels.length, (i) => NavigationDestination(
          icon: Icon(icons[i]), label: labels[i])),
      ),
    );
  }
}
