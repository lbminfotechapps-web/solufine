
class BankModel {
  final String id;
  final String name;
  final String bankName;
  final String branch;
  final String accountNo;

  const BankModel({
    required this.id,
    required this.name,
    required this.bankName,
    required this.branch,
    required this.accountNo,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: json['fld_bank_id']?.toString() ?? '',
      name: json['fld_bank_name']?.toString() ?? '',
      bankName: json['bank_name']?.toString() ?? '',
      branch: json['fld_branch']?.toString() ?? '',
      accountNo: json['fld_acc_no']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fld_bank_id': id,
      'fld_bank_name': name,
      'bank_name': bankName,
      'fld_branch': branch,
      'fld_acc_no': accountNo,
    };
  }
}