import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/constants.dart';
import 'features/inventory/data/datasources/background_service.dart';
import 'features/inventory/data/inventory_repository_impl.dart';
import 'features/inventory/domain/repositories/inventory_repository.dart';
import 'features/inventory/presentation/inventory_bloc.dart';
import 'features/inventory/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Background Service
  await BackgroundService().initialize();

  runApp(const GuardianInventoryApp());
}

class GuardianInventoryApp extends StatelessWidget {
  const GuardianInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<InventoryRepository>(
      create: (context) => InventoryRepositoryImpl(),
      child: BlocProvider<InventoryBloc>(
        create: (context) =>
            InventoryBloc(repository: context.read<InventoryRepository>()),
        child: MaterialApp(
          title: Constants.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: const HomePage(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
