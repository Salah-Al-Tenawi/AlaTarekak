part of 'search_cubit.dart';

sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

final class SearchInitial extends SearchState {}

final class SearchLoading extends SearchState {}

final class SearchSucces extends SearchState {
  final List<TripModel> trips;

  const SearchSucces({required this.trips});

  @override
  List<Object> get props => [trips];
}

final class SearchErorr extends SearchState {
  /// رسالة عربية جاهزة للعرض — لا نصّ الخادم.
  final String error;

  /// رُفض البحث لأن الراكب غير موثَّق: الشاشة تنقله إلى التوثيق بدل
  /// تركه أمام رسالة لا يعرف ما يفعل بعدها. كانت الشاشة تستنتج ذلك
  /// بمطابقة نصّ إنجليزي بيدها، وهو ما ألزمها بحمل الرسالة الخام.
  final bool needsVerification;

  const SearchErorr({required this.error, this.needsVerification = false});

  @override
  List<Object> get props => [error, needsVerification];
}

