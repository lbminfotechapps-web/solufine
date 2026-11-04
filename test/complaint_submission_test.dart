import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/features/marketing/complaint_form/domain/repository/complaint_form_repo.dart';
import 'package:solufine/features/marketing/complaint_form/domain/usecase/complain_form_usecase.dart';
import 'package:solufine/features/marketing/complaint_form/domain/entity/outlet_list_entity.dart';
import 'package:solufine/features/marketing/complaint_form/presentation/bloc/complaint_bloc.dart';
import 'package:solufine/features/marketing/complaint_form/presentation/bloc/complaint_event.dart';
import 'package:solufine/features/marketing/complaint_form/presentation/bloc/complaint_state.dart';

class _Repository implements ComplaintFormRepo {
  final completion = Completer<Map<String, dynamic>>();
  Map<String, dynamic>? payload;
  @override
  Future<Map<String, dynamic>> submitComplaintForm(Map<String, dynamic> data) {
    payload = data;
    return completion.future;
  }

  @override
  Future<OutletListEntity> getOutletList(
    String user,
    String type,
    String query,
  ) async => const OutletListEntity(status: true, message: '', result: []);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'search success cannot complete an ongoing submission; IDs pass through',
    () async {
      final repository = _Repository();
      final bloc = ComplaintBloc(
        complaintFormUsecase: ComplainFormUsecase(repository),
      );
      addTearDown(bloc.close);
      final loading = bloc.stream.firstWhere(
        (s) => s.submissionStatus == ComplaintFormStatus.loading,
      );
      bloc.add(
        const SubmitComplaintFormEvent(
          jsonData: {'complaintCrop': '17', 'productId': '21,22'},
        ),
      );
      await loading;
      final searched = bloc.stream.firstWhere(
        (s) => s.status == ComplaintFormStatus.success,
      );
      bloc.add(
        const GetOutletListEvent(
          userId: '1',
          dealerType: 'Dealer',
          dealerName: 'A',
        ),
      );
      await searched;
      expect(bloc.state.submissionStatus, ComplaintFormStatus.loading);
      expect(repository.payload, {'complaintCrop': '17', 'productId': '21,22'});
      final submitted = bloc.stream.firstWhere(
        (s) => s.submissionStatus == ComplaintFormStatus.success,
      );
      repository.completion.complete({'status': true});
      await submitted;
    },
  );

  test(
    'failed submission reports failure so the form can be retried',
    () async {
      final repository = _Repository();
      final bloc = ComplaintBloc(
        complaintFormUsecase: ComplainFormUsecase(repository),
      );
      addTearDown(bloc.close);
      final loading = bloc.stream.firstWhere(
        (s) => s.submissionStatus == ComplaintFormStatus.loading,
      );
      bloc.add(const SubmitComplaintFormEvent(jsonData: {}));
      await loading;
      final failed = bloc.stream.firstWhere(
        (s) => s.submissionStatus == ComplaintFormStatus.failure,
      );
      repository.completion.completeError(StateError('Upload failed'));
      final state = await failed;
      expect(state.errorMessage, contains('Upload failed'));
    },
  );
}
