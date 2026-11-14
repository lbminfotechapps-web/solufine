import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/features/marketing/dsi/data/models/dsi_model.dart';

void main() {
  test('maps the DSI list API fields and preserves formatted savings', () {
    final record = DsiRecordModel.fromJson({
      'fld_dsi_id': '1',
      'fld_created_date': '31-10-2026',
      'fld_emp_id': '4',
      'fld_effectiveness': 'Money',
      'fld_description': 'test',
      'fld_adm_name': 'LBM Prasanna Medhe',
      'fld_image': 'DSI_1793423382470.jpg',
      'fld_save_money': '60.00 ₹',
      'fld_save_time': '80 min',
    });
    expect(record.id, '1');
    expect(record.date, '31-10-2026');
    expect(record.effectiveness, 'Money');
    expect(record.description, 'test');
    expect(record.employeeName, 'LBM Prasanna Medhe');
    expect(record.imageUrl, 'DSI_1793423382470.jpg');
    expect(record.saveMoney, '60.00 ₹');
    expect(record.saveTime, '80 min');
  });
}
