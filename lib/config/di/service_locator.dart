import 'package:app_events/data/datasources/firebase_other_datasource.dart';
import 'package:app_events/data/datasources/firebase_resource_datasource.dart';
import 'package:app_events/data/datasources/firebase_schedule_datasource.dart';
import 'package:app_events/data/datasources/firebase_user_datasource.dart';
import 'package:app_events/data/repositories/other_repository_impl.dart';
import 'package:app_events/data/repositories/resource_repository_impl.dart';
import 'package:app_events/data/repositories/schedule_repository_impl.dart';
import 'package:app_events/data/repositories/user_repository_impl.dart';
import 'package:app_events/domain/datasources/other_datasource.dart';
import 'package:app_events/domain/datasources/resource_datasource.dart';
import 'package:app_events/domain/datasources/schedule_datasource.dart';
import 'package:app_events/domain/datasources/user_datasource.dart';
import 'package:app_events/domain/repositories/other_repository.dart';
import 'package:app_events/domain/repositories/resource_repository.dart';
import 'package:app_events/domain/repositories/schedule_repository.dart';
import 'package:app_events/domain/repositories/user_repository.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);

  sl.registerLazySingleton<ScheduleDatasource>(
    () => FirebaseScheduleDatasource(sl()),
  );
  sl.registerLazySingleton<ResourceDatasource>(
    () => FirebaseResourceDatasource(sl()),
  );
  sl.registerLazySingleton<UserDatasource>(() => FirebaseUserDatasource(sl()));

  sl.registerLazySingleton<OtherDatasource>(
    () => FirebaseOtherDatasource(sl()),
  );

  sl.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ResourceRepository>(
    () => ResourceRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(sl()));
  sl.registerLazySingleton<OtherRepository>(() => OtherRepositoryImpl(sl()));

  sl.registerFactory(() => UserProvider(sl<UserRepository>()));
  sl.registerFactory(
    () => SignInSocialNetworkProvider(
      sl<GoogleSignIn>(),
      sl<FirebaseAuth>(),
      sl<UserProvider>(),
    ),
  );
}
