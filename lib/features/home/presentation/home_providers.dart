import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../library/domain/vod_item.dart';
import '../data/home_repository.dart';
import '../domain/daily_verse.dart';
import '../domain/home_banner.dart';

final homeRepositoryProvider = Provider((ref) => HomeRepository(ref.watch(supabaseClientProvider)));

final homeBannersProvider =
    FutureProvider<List<HomeBanner>>((ref) => ref.watch(homeRepositoryProvider).banners());

final featuredVideosProvider =
    FutureProvider<List<VodItem>>((ref) => ref.watch(homeRepositoryProvider).featured());

final latestByCategoryProvider = FutureProvider.family<List<VodItem>, MediaCategory>(
  (ref, category) => ref.watch(homeRepositoryProvider).latest(category),
);

final verseOfTheDayProvider =
    FutureProvider<DailyVerse?>((ref) => ref.watch(homeRepositoryProvider).verseOfTheDay());

final donationUrlProvider =
    FutureProvider<String?>((ref) => ref.watch(homeRepositoryProvider).donationUrl());
