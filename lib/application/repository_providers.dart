import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tracelet/data/api/tracelet_api_client.dart';

import 'package:tracelet/data/gateways/aws_bottle_ocean_gateway.dart';

import 'package:tracelet/data/local/local_app_store.dart';

import 'package:tracelet/data/repositories/aws_message_repository.dart';

import 'package:tracelet/data/repositories/aws_settings_repository.dart';

import 'package:tracelet/data/repositories/aws_user_repository.dart';

import 'package:tracelet/application/auth_providers.dart';

import 'package:tracelet/domain/repositories/message_repository.dart';

import 'package:tracelet/domain/repositories/settings_repository.dart';

import 'package:tracelet/domain/repositories/user_repository.dart';



class BackendServices {

  const BackendServices({

    required this.api,

    required this.settings,

    required this.messages,

    required this.users,

  });



  final TraceletApiClient api;

  final SettingsRepository settings;

  final MessageRepository messages;

  final UserRepository users;

}



final backendServicesProvider = FutureProvider<BackendServices>((ref) async {

  final auth = await ref.watch(authNotifierProvider.future);

  if (!auth.isReady || auth.userId == null) {

    throw StateError('Auth not ready');

  }



  final prefs = await ref.watch(sharedPreferencesProvider.future);

  final authContext = ref.watch(apiAuthContextProvider);

  final api = TraceletApiClient(auth: authContext);

  final local = LocalAppStore(prefs);



  return BackendServices(

    api: api,

    settings: AwsSettingsRepository(api, local),

    messages: AwsMessageRepository(

      userId: auth.userId!,

      inbox: local,

      ocean: AwsBottleOceanGateway(api),

    ),

    users: AwsUserRepository(api),

  );

});



final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {

  return ref.watch(backendServicesProvider).requireValue.settings;

});



final messageRepositoryProvider = Provider<MessageRepository>((ref) {

  return ref.watch(backendServicesProvider).requireValue.messages;

});



final userRepositoryProvider = Provider<UserRepository>((ref) {

  return ref.watch(backendServicesProvider).requireValue.users;

});


