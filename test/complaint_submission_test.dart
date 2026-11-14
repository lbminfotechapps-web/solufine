import 'package:solufine/features/marketing/complaint_form/domain/entity/season_list_entity.dart';
import 'package:solufine/features/marketing/complaint_form/domain/entity/crop_category.dart';
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
  final seasons = Completer<SeasonListEntity>();
  final crops = Completer<CropCategoryListEntity>();
  @override
  Future<SeasonListEntity> getSeaonList() => seasons.future;
  @override
  Future<CropCategoryListEntity> getCategoryList() => crops.future;
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
  test('season and crop requests load independently', () async {
    final repository = _Repository();
    final bloc = ComplaintBloc(
      complaintFormUsecase: ComplainFormUsecase(repository),
    );
    addTearDown(bloc.close);
    final seasonsLoading = bloc.stream.firstWhere(
      (s) => s.seasonStatus == ComplaintFormStatus.loading,
    );
    bloc.add(const GetSeasonListEvent());
    await seasonsLoading;
    final cropsLoading = bloc.stream.firstWhere(
      (s) => s.cropStatus == ComplaintFormStatus.loading,
    );
    bloc.add(const GetCropCategoryListEvent());
    await cropsLoading;
    final seasonsLoaded = bloc.stream.firstWhere(
      (s) => s.seasonStatus == ComplaintFormStatus.success,
    );
    repository.seasons.complete(
      const SeasonListEntity(
        status: true,
        message: '',
        result: [SeasonItemEntity(seasonId: '42', seasonName: 'API Season')],
      ),
    );
    await seasonsLoaded;
    expect(bloc.state.seasonListEntity!.result.single.seasonId, '42');
    expect(bloc.state.cropStatus, ComplaintFormStatus.loading);
    final cropsLoaded = bloc.stream.firstWhere(
      (s) => s.cropStatus == ComplaintFormStatus.success,
    );
    repository.crops.complete(
      const CropCategoryListEntity(status: true, message: '', result: []),
    );
    await cropsLoaded;
    expect(bloc.state.seasonStatus, ComplaintFormStatus.success);
  });

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
