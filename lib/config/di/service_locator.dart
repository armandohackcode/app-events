import 'package:app_events/data/datasources/firebase_auth_datasource.dart';
import 'package:app_events/data/datasources/firebase_event_datasource.dart';
import 'package:app_events/data/datasources/firebase_other_datasource.dart';
import 'package:app_events/data/datasources/firebase_resource_datasource.dart';
import 'package:app_events/data/datasources/firebase_schedule_datasource.dart';
import 'package:app_events/data/datasources/firebase_speed_run_datasource.dart';
import 'package:app_events/data/datasources/firebase_spin_datasource.dart';
import 'package:app_events/data/datasources/firebase_talk_interaction_datasource.dart';
import 'package:app_events/data/datasources/firebase_user_datasource.dart';
import 'package:app_events/data/repositories/auth_repository_impl.dart';
import 'package:app_events/data/repositories/event_repository_impl.dart';
import 'package:app_events/data/repositories/other_repository_impl.dart';
import 'package:app_events/data/repositories/resource_repository_impl.dart';
import 'package:app_events/data/repositories/schedule_repository_impl.dart';
import 'package:app_events/data/repositories/speed_run_repository_impl.dart';
import 'package:app_events/data/repositories/spin_repository_impl.dart';
import 'package:app_events/data/repositories/talk_interaction_repository_impl.dart';
import 'package:app_events/data/repositories/user_repository_impl.dart';
import 'package:app_events/domain/datasources/auth_datasource.dart';
import 'package:app_events/domain/datasources/event_datasource.dart';
import 'package:app_events/domain/datasources/other_datasource.dart';
import 'package:app_events/domain/datasources/resource_datasource.dart';
import 'package:app_events/domain/datasources/schedule_datasource.dart';
import 'package:app_events/domain/datasources/speed_run_datasource.dart';
import 'package:app_events/domain/datasources/spin_datasource.dart';
import 'package:app_events/domain/datasources/talk_interaction_datasource.dart';
import 'package:app_events/domain/datasources/user_datasource.dart';
import 'package:app_events/domain/repositories/auth_repository.dart';
import 'package:app_events/domain/repositories/event_repository.dart';
import 'package:app_events/domain/repositories/other_repository.dart';
import 'package:app_events/domain/repositories/resource_repository.dart';
import 'package:app_events/domain/repositories/schedule_repository.dart';
import 'package:app_events/domain/repositories/speed_run_repository.dart';
import 'package:app_events/domain/repositories/spin_repository.dart';
import 'package:app_events/domain/repositories/talk_interaction_repository.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/event_provider.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/live_activity_provider.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/ui/providers/speed_run_provider.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:app_events/ui/providers/talk_interaction_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<FirebaseFunctions>(
    () => FirebaseFunctions.instanceFor(region: 'us-central1'),
  );

  sl.registerLazySingleton<AuthDatasource>(
    () => FirebaseAuthDatasource(sl(), sl()),
  );
  sl.registerLazySingleton<EventDatasource>(
    () => FirebaseEventDatasource(sl(), sl()),
  );
  sl.registerLazySingleton<ScheduleDatasource>(
    () => FirebaseScheduleDatasource(sl(), sl()),
  );
  sl.registerLazySingleton<ResourceDatasource>(
    () => FirebaseResourceDatasource(sl()),
  );
  sl.registerLazySingleton<UserDatasource>(() => FirebaseUserDatasource(sl()));
  sl.registerLazySingleton<OtherDatasource>(
    () => FirebaseOtherDatasource(sl(), sl()),
  );
  sl.registerLazySingleton<SpeedRunDatasource>(
    () => FirebaseSpeedRunDatasource(sl(), sl()),
  );
  sl.registerLazySingleton<SpinDatasource>(
    () => FirebaseSpinDatasource(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<TalkInteractionDatasource>(
    () => FirebaseTalkInteractionDatasource(sl(), sl()),
  );

  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<EventRepository>(() => EventRepositoryImpl(sl()));
  sl.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ResourceRepository>(
    () => ResourceRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(sl()));
  sl.registerLazySingleton<OtherRepository>(() => OtherRepositoryImpl(sl()));
  sl.registerLazySingleton<SpeedRunRepository>(
    () => SpeedRunRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<SpinRepository>(() => SpinRepositoryImpl(sl()));
  sl.registerLazySingleton<TalkInteractionRepository>(
    () => TalkInteractionRepositoryImpl(sl()),
  );

  sl.registerFactory(() => EventProvider(sl<EventRepository>()));
  sl.registerFactory(
    () => LiveActivityProvider(sl<EventRepository>(), sl<ScheduleRepository>()),
  );
  sl.registerFactory(() => SpeedRunProvider(sl<SpeedRunRepository>()));
  sl.registerFactory(() => UserProvider(sl<UserRepository>()));
  sl.registerFactory(
    () => SignInSocialNetworkProvider(sl<AuthRepository>(), sl<UserProvider>()),
  );
  sl.registerFactory(() => GdgSpinProvider(sl<SpinRepository>()));
  sl.registerFactory(() => SpinAdminProvider(sl<SpinRepository>()));
  sl.registerFactory(
    () => TalkInteractionProvider(sl<TalkInteractionRepository>()),
  );
}
