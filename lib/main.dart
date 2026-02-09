import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/service_locator.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'package:sout_salah/core/utils/app_bloc_observer.dart';
import 'package:sout_salah/core/utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fsddnmdmfrrapbumggsg.supabase.co',
    anonKey: 'sb_publishable_JBJGtNO6N7B6jTbK0r-xUA_hdEEGXR4',
  );

  await di.init();

  Bloc.observer = AppBlocObserver(di.sl<AppLogger>());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()..add(CheckAuthStatus())),
      ],
      child: MaterialApp(
        title: 'Sout Salah',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6930)),
          useMaterial3: true,
        ),
        home: const LoginPage(),
      ),
    );
  }
}
