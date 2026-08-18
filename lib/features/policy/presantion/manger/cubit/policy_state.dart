part of 'policy_cubit.dart';

sealed class PolicyState extends Equatable {
  const PolicyState();

  @override
  List<Object?> get props => [];
}

final class PolicyInitial extends PolicyState {}

/// المحتوى معروض دائماً — انظر شرح [PolicyCubit] في غياب حالة خطأ.
final class PolicyLoaded extends PolicyState {
  final PolicyContent content;

  /// وصل من الخادم في هذه الجلسة. `false` يعني نسخة مخزَّنة أو مدمجة —
  /// صالحة للعرض، لكن قد يكون الأدمن حدّثها بعدها.
  final bool fresh;

  const PolicyLoaded({required this.content, required this.fresh});

  @override
  List<Object?> get props => [content, fresh];
}
