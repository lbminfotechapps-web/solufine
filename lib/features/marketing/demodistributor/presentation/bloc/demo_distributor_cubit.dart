import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/demo_distributor_entry.dart';
import '../../domain/usecases/demo_distributor_usecases.dart';

class DemoDistributorState {
  final bool submitting;
  final String? success, error;
  const DemoDistributorState({
    this.submitting = false,
    this.success,
    this.error,
  });
}

class DemoDistributorCubit extends Cubit<DemoDistributorState> {
  final GetDemoDistributorOptions getOptions;
  final SubmitDemoDistributor submitEntry;
  DemoDistributorCubit(this.getOptions, this.submitEntry)
    : super(const DemoDistributorState());
  bool get canSubmit => submitEntry.available;
  Future<List<DemoOption>> options(
    DemoLookup kind, {
    required String userId,
    String parentId = '',
    String query = '',
    String subcategoryId = '',
  }) async {
    final rows = await getOptions(kind, userId: userId, parentId: parentId);
    return rows
        .where(
          (row) =>
              (kind != DemoLookup.variety || row.parentId == subcategoryId) &&
              row.name.toLowerCase().contains(query.trim().toLowerCase()),
        )
        .toList();
  }

  Future<void> submit(DemoDistributorEntry entry) async {
    if (state.submitting || state.success != null) return;
    emit(const DemoDistributorState(submitting: true));
    try {
      final message = await submitEntry(entry);
      if (!isClosed) emit(DemoDistributorState(success: message));
    } catch (error) {
      if (!isClosed) emit(DemoDistributorState(error: error.toString()));
    }
  }
}
