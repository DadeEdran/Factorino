// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, CustomerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV4,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: nowMillis,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: nowMillis,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SyncStatus>($CustomersTable.$convertersyncStatus);
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
    'mobile',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companyNameMeta = const VerificationMeta(
    'companyName',
  );
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
    'company_name',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 160),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nationalIdMeta = const VerificationMeta(
    'nationalId',
  );
  @override
  late final GeneratedColumn<String> nationalId = GeneratedColumn<String>(
    'national_id',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 10),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _economicIdMeta = const VerificationMeta(
    'economicId',
  );
  @override
  late final GeneratedColumn<String> economicId = GeneratedColumn<String>(
    'economic_id',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 2000),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _searchNameMeta = const VerificationMeta(
    'searchName',
  );
  @override
  late final GeneratedColumn<String> searchName = GeneratedColumn<String>(
    'search_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 300),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    lastSyncedAt,
    fullName,
    mobile,
    companyName,
    address,
    nationalId,
    economicId,
    notes,
    searchName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('mobile')) {
      context.handle(
        _mobileMeta,
        mobile.isAcceptableOrUnknown(data['mobile']!, _mobileMeta),
      );
    }
    if (data.containsKey('company_name')) {
      context.handle(
        _companyNameMeta,
        companyName.isAcceptableOrUnknown(
          data['company_name']!,
          _companyNameMeta,
        ),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('national_id')) {
      context.handle(
        _nationalIdMeta,
        nationalId.isAcceptableOrUnknown(data['national_id']!, _nationalIdMeta),
      );
    }
    if (data.containsKey('economic_id')) {
      context.handle(
        _economicIdMeta,
        economicId.isAcceptableOrUnknown(data['economic_id']!, _economicIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('search_name')) {
      context.handle(
        _searchNameMeta,
        searchName.isAcceptableOrUnknown(data['search_name']!, _searchNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: $CustomersTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      ),
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      mobile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mobile'],
      ),
      companyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_name'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      nationalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}national_id'],
      ),
      economicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}economic_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      searchName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_name'],
      )!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatus>(SyncStatus.values);
}

class CustomerRow extends DataClass implements Insertable<CustomerRow> {
  /// UUID v4, never `AUTOINCREMENT`: integer keys allocated independently on
  /// two devices collide the moment those devices sync (D-001).
  final String id;

  /// Epoch milliseconds, UTC (D-005). Never a localized date string.
  final int createdAt;

  /// Bumped on every write. Repositories own this; it is not automatic.
  final int updatedAt;

  /// Soft delete (D-003). A hard delete cannot be propagated to another
  /// device, which would resurrect the row on the next sync. Every read must
  /// filter this -- see `soft_delete.dart`, the single place that expresses it.
  final int? deletedAt;
  final SyncStatus syncStatus;
  final int? lastSyncedAt;

  /// Length limits are enforced at the schema boundary as well as in the UI,
  /// because the UI is not the only writer -- import (Phase 6) is another.
  ///
  /// **Every `max:` below must equal the matching constant in
  /// `data/models/field_limits.dart`, which is what the forms use.** They
  /// cannot reference it directly: `drift_dev` reads this argument with
  /// `readIntLiteral`, which returns `null` for anything but an integer
  /// literal, so a constant here would generate a column with *no* length
  /// constraint at all -- silently. `test/data/database/field_limits_test.dart`
  /// asks each generated column where it actually starts rejecting values and
  /// fails if the two disagree.
  final String fullName;

  /// Iranian mobile, normalized to `09xxxxxxxxx` before storage (§9). Stored
  /// as text: it is an identifier, not a quantity, and leading zeros matter.
  final String? mobile;
  final String? companyName;
  final String? address;

  /// کد ملی — optional, and checksum-validated at the boundary when present.
  final String? nationalId;

  /// کد اقتصادی
  final String? economicId;
  final String? notes;

  /// [fullName] and [companyName] run through the Persian text normalizer,
  /// so that a customer saved as "علي" is found by typing "علی" (§9).
  ///
  /// Denormalized deliberately: normalizing at query time would defeat the
  /// index and force a full scan. Written by the repository layer, which is
  /// the only writer, so it cannot drift out of sync with [fullName].
  final String searchName;
  const CustomerRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    required this.fullName,
    this.mobile,
    this.companyName,
    this.address,
    this.nationalId,
    this.economicId,
    this.notes,
    required this.searchName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    {
      map['sync_status'] = Variable<int>(
        $CustomersTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    map['full_name'] = Variable<String>(fullName);
    if (!nullToAbsent || mobile != null) {
      map['mobile'] = Variable<String>(mobile);
    }
    if (!nullToAbsent || companyName != null) {
      map['company_name'] = Variable<String>(companyName);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || nationalId != null) {
      map['national_id'] = Variable<String>(nationalId);
    }
    if (!nullToAbsent || economicId != null) {
      map['economic_id'] = Variable<String>(economicId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['search_name'] = Variable<String>(searchName);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
: Value(deletedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
: Value(lastSyncedAt),
      fullName: Value(fullName),
      mobile: mobile == null && nullToAbsent
          ? const Value.absent()
: Value(mobile),
      companyName: companyName == null && nullToAbsent
          ? const Value.absent()
: Value(companyName),
      address: address == null && nullToAbsent
          ? const Value.absent()
: Value(address),
      nationalId: nationalId == null && nullToAbsent
          ? const Value.absent()
: Value(nationalId),
      economicId: economicId == null && nullToAbsent
          ? const Value.absent()
: Value(economicId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
: Value(notes),
      searchName: Value(searchName),
    );
  }

  factory CustomerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      syncStatus: $CustomersTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
      fullName: serializer.fromJson<String>(json['fullName']),
      mobile: serializer.fromJson<String?>(json['mobile']),
      companyName: serializer.fromJson<String?>(json['companyName']),
      address: serializer.fromJson<String?>(json['address']),
      nationalId: serializer.fromJson<String?>(json['nationalId']),
      economicId: serializer.fromJson<String?>(json['economicId']),
      notes: serializer.fromJson<String?>(json['notes']),
      searchName: serializer.fromJson<String>(json['searchName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'syncStatus': serializer.toJson<int>(
        $CustomersTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'fullName': serializer.toJson<String>(fullName),
      'mobile': serializer.toJson<String?>(mobile),
      'companyName': serializer.toJson<String?>(companyName),
      'address': serializer.toJson<String?>(address),
      'nationalId': serializer.toJson<String?>(nationalId),
      'economicId': serializer.toJson<String?>(economicId),
      'notes': serializer.toJson<String?>(notes),
      'searchName': serializer.toJson<String>(searchName),
    };
  }

  CustomerRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    SyncStatus? syncStatus,
    Value<int?> lastSyncedAt = const Value.absent(),
    String? fullName,
    Value<String?> mobile = const Value.absent(),
    Value<String?> companyName = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<String?> nationalId = const Value.absent(),
    Value<String?> economicId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? searchName,
  }) => CustomerRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    fullName: fullName ?? this.fullName,
    mobile: mobile.present ? mobile.value : this.mobile,
    companyName: companyName.present ? companyName.value : this.companyName,
    address: address.present ? address.value : this.address,
    nationalId: nationalId.present ? nationalId.value : this.nationalId,
    economicId: economicId.present ? economicId.value : this.economicId,
    notes: notes.present ? notes.value : this.notes,
    searchName: searchName ?? this.searchName,
  );
  CustomerRow copyWithCompanion(CustomersCompanion data) {
    return CustomerRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
: this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
: this.lastSyncedAt,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      mobile: data.mobile.present ? data.mobile.value : this.mobile,
      companyName: data.companyName.present
          ? data.companyName.value
: this.companyName,
      address: data.address.present ? data.address.value : this.address,
      nationalId: data.nationalId.present
          ? data.nationalId.value
: this.nationalId,
      economicId: data.economicId.present
          ? data.economicId.value
: this.economicId,
      notes: data.notes.present ? data.notes.value : this.notes,
      searchName: data.searchName.present
          ? data.searchName.value
: this.searchName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerRow(')
..write('id: $id, ')
..write('createdAt: $createdAt, ')
..write('updatedAt: $updatedAt, ')
..write('deletedAt: $deletedAt, ')
..write('syncStatus: $syncStatus, ')
..write('lastSyncedAt: $lastSyncedAt, ')
..write('fullName: $fullName, ')
..write('mobile: $mobile, ')
..write('companyName: $companyName, ')
..write('address: $address, ')
..write('nationalId: $nationalId, ')
..write('economicId: $economicId, ')
..write('notes: $notes, ')
..write('searchName: $searchName')
..write(')'))
.toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    lastSyncedAt,
    fullName,
    mobile,
    companyName,
    address,
    nationalId,
    economicId,
    notes,
    searchName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.fullName == this.fullName &&
          other.mobile == this.mobile &&
          other.companyName == this.companyName &&
          other.address == this.address &&
          other.nationalId == this.nationalId &&
          other.economicId == this.economicId &&
          other.notes == this.notes &&
          other.searchName == this.searchName);
}

class CustomersCompanion extends UpdateCompanion<CustomerRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int?> lastSyncedAt;
  final Value<String> fullName;
  final Value<String?> mobile;
  final Value<String?> companyName;
  final Value<String?> address;
  final Value<String?> nationalId;
  final Value<String?> economicId;
  final Value<String?> notes;
  final Value<String> searchName;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.fullName = const Value.absent(),
    this.mobile = const Value.absent(),
    this.companyName = const Value.absent(),
    this.address = const Value.absent(),
    this.nationalId = const Value.absent(),
    this.economicId = const Value.absent(),
    this.notes = const Value.absent(),
    this.searchName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    required String fullName,
    this.mobile = const Value.absent(),
    this.companyName = const Value.absent(),
    this.address = const Value.absent(),
    this.nationalId = const Value.absent(),
    this.economicId = const Value.absent(),
    this.notes = const Value.absent(),
    this.searchName = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : fullName = Value(fullName);
  static Insertable<CustomerRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? lastSyncedAt,
    Expression<String>? fullName,
    Expression<String>? mobile,
    Expression<String>? companyName,
    Expression<String>? address,
    Expression<String>? nationalId,
    Expression<String>? economicId,
    Expression<String>? notes,
    Expression<String>? searchName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (fullName != null) 'full_name': fullName,
      if (mobile != null) 'mobile': mobile,
      if (companyName != null) 'company_name': companyName,
      if (address != null) 'address': address,
      if (nationalId != null) 'national_id': nationalId,
      if (economicId != null) 'economic_id': economicId,
      if (notes != null) 'notes': notes,
      if (searchName != null) 'search_name': searchName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<SyncStatus>? syncStatus,
    Value<int?>? lastSyncedAt,
    Value<String>? fullName,
    Value<String?>? mobile,
    Value<String?>? companyName,
    Value<String?>? address,
    Value<String?>? nationalId,
    Value<String?>? economicId,
    Value<String?>? notes,
    Value<String>? searchName,
    Value<int>? rowid,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      fullName: fullName ?? this.fullName,
      mobile: mobile ?? this.mobile,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      nationalId: nationalId ?? this.nationalId,
      economicId: economicId ?? this.economicId,
      notes: notes ?? this.notes,
      searchName: searchName ?? this.searchName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $CustomersTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (mobile.present) {
      map['mobile'] = Variable<String>(mobile.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (nationalId.present) {
      map['national_id'] = Variable<String>(nationalId.value);
    }
    if (economicId.present) {
      map['economic_id'] = Variable<String>(economicId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (searchName.present) {
      map['search_name'] = Variable<String>(searchName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
..write('id: $id, ')
..write('createdAt: $createdAt, ')
..write('updatedAt: $updatedAt, ')
..write('deletedAt: $deletedAt, ')
..write('syncStatus: $syncStatus, ')
..write('lastSyncedAt: $lastSyncedAt, ')
..write('fullName: $fullName, ')
..write('mobile: $mobile, ')
..write('companyName: $companyName, ')
..write('address: $address, ')
..write('nationalId: $nationalId, ')
..write('economicId: $economicId, ')
..write('notes: $notes, ')
..write('searchName: $searchName, ')
..write('rowid: $rowid')
..write(')'))
.toString();
  }
}

class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV4,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: nowMillis,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: nowMillis,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SyncStatus>($ProductsTable.$convertersyncStatus);
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 160,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ProductType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ProductType>($ProductsTable.$convertertype);
  static const VerificationMeta _priceRialMeta = const VerificationMeta(
    'priceRial',
  );
  @override
  late final GeneratedColumn<int> priceRial = GeneratedColumn<int>(
    'price_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 30,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 2000),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _searchNameMeta = const VerificationMeta(
    'searchName',
  );
  @override
  late final GeneratedColumn<String> searchName = GeneratedColumn<String>(
    'search_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    lastSyncedAt,
    name,
    type,
    priceRial,
    unit,
    description,
    searchName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price_rial')) {
      context.handle(
        _priceRialMeta,
        priceRial.isAcceptableOrUnknown(data['price_rial']!, _priceRialMeta),
      );
    } else if (isInserting) {
      context.missing(_priceRialMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('search_name')) {
      context.handle(
        _searchNameMeta,
        searchName.isAcceptableOrUnknown(data['search_name']!, _searchNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: $ProductsTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $ProductsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      priceRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_rial'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      searchName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_name'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatus>(SyncStatus.values);
  static JsonTypeConverter2<ProductType, int, int> $convertertype =
      const EnumIndexConverter<ProductType>(ProductType.values);
}

class ProductRow extends DataClass implements Insertable<ProductRow> {
  /// UUID v4, never `AUTOINCREMENT`: integer keys allocated independently on
  /// two devices collide the moment those devices sync (D-001).
  final String id;

  /// Epoch milliseconds, UTC (D-005). Never a localized date string.
  final int createdAt;

  /// Bumped on every write. Repositories own this; it is not automatic.
  final int updatedAt;

  /// Soft delete (D-003). A hard delete cannot be propagated to another
  /// device, which would resurrect the row on the next sync. Every read must
  /// filter this -- see `soft_delete.dart`, the single place that expresses it.
  final int? deletedAt;
  final SyncStatus syncStatus;
  final int? lastSyncedAt;

  /// Every `max:` below must equal the matching constant in
  /// `data/models/field_limits.dart` -- see the note on `Customers.fullName`
  /// for why the constant cannot be referenced here and what enforces the
  /// agreement instead.
  final String name;
  final ProductType type;

  /// Integer **Rial**, never a double (D-002). Toman is a display unit only.
  final int priceRial;

  /// Unit of measure: عدد, کیلوگرم, ساعت, متر ... Free text, because the set of
  /// units a workshop uses is not something this app should presume to fix.
  final String unit;
  final String? description;

  /// Normalized [name] for accent- and ZWNJ-insensitive search (§9).
  /// See the note on `Customers.searchName`.
  final String searchName;
  const ProductRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    required this.name,
    required this.type,
    required this.priceRial,
    required this.unit,
    this.description,
    required this.searchName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    {
      map['sync_status'] = Variable<int>(
        $ProductsTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<int>($ProductsTable.$convertertype.toSql(type));
    }
    map['price_rial'] = Variable<int>(priceRial);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['search_name'] = Variable<String>(searchName);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
: Value(deletedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
: Value(lastSyncedAt),
      name: Value(name),
      type: Value(type),
      priceRial: Value(priceRial),
      unit: Value(unit),
      description: description == null && nullToAbsent
          ? const Value.absent()
: Value(description),
      searchName: Value(searchName),
    );
  }

  factory ProductRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      syncStatus: $ProductsTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
      name: serializer.fromJson<String>(json['name']),
      type: $ProductsTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      priceRial: serializer.fromJson<int>(json['priceRial']),
      unit: serializer.fromJson<String>(json['unit']),
      description: serializer.fromJson<String?>(json['description']),
      searchName: serializer.fromJson<String>(json['searchName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'syncStatus': serializer.toJson<int>(
        $ProductsTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<int>(
        $ProductsTable.$convertertype.toJson(type),
      ),
      'priceRial': serializer.toJson<int>(priceRial),
      'unit': serializer.toJson<String>(unit),
      'description': serializer.toJson<String?>(description),
      'searchName': serializer.toJson<String>(searchName),
    };
  }

  ProductRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    SyncStatus? syncStatus,
    Value<int?> lastSyncedAt = const Value.absent(),
    String? name,
    ProductType? type,
    int? priceRial,
    String? unit,
    Value<String?> description = const Value.absent(),
    String? searchName,
  }) => ProductRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    name: name ?? this.name,
    type: type ?? this.type,
    priceRial: priceRial ?? this.priceRial,
    unit: unit ?? this.unit,
    description: description.present ? description.value : this.description,
    searchName: searchName ?? this.searchName,
  );
  ProductRow copyWithCompanion(ProductsCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
: this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
: this.lastSyncedAt,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      priceRial: data.priceRial.present ? data.priceRial.value : this.priceRial,
      unit: data.unit.present ? data.unit.value : this.unit,
      description: data.description.present
          ? data.description.value
: this.description,
      searchName: data.searchName.present
          ? data.searchName.value
: this.searchName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRow(')
..write('id: $id, ')
..write('createdAt: $createdAt, ')
..write('updatedAt: $updatedAt, ')
..write('deletedAt: $deletedAt, ')
..write('syncStatus: $syncStatus, ')
..write('lastSyncedAt: $lastSyncedAt, ')
..write('name: $name, ')
..write('type: $type, ')
..write('priceRial: $priceRial, ')
..write('unit: $unit, ')
..write('description: $description, ')
..write('searchName: $searchName')
..write(')'))
.toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    lastSyncedAt,
    name,
    type,
    priceRial,
    unit,
    description,
    searchName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.name == this.name &&
          other.type == this.type &&
          other.priceRial == this.priceRial &&
          other.unit == this.unit &&
          other.description == this.description &&
          other.searchName == this.searchName);
}

class ProductsCompanion extends UpdateCompanion<ProductRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int?> lastSyncedAt;
  final Value<String> name;
  final Value<ProductType> type;
  final Value<int> priceRial;
  final Value<String> unit;
  final Value<String?> description;
  final Value<String> searchName;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.priceRial = const Value.absent(),
    this.unit = const Value.absent(),
    this.description = const Value.absent(),
    this.searchName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    required String name,
    required ProductType type,
    required int priceRial,
    required String unit,
    this.description = const Value.absent(),
    this.searchName = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       type = Value(type),
       priceRial = Value(priceRial),
       unit = Value(unit);
  static Insertable<ProductRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? lastSyncedAt,
    Expression<String>? name,
    Expression<int>? type,
    Expression<int>? priceRial,
    Expression<String>? unit,
    Expression<String>? description,
    Expression<String>? searchName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (priceRial != null) 'price_rial': priceRial,
      if (unit != null) 'unit': unit,
      if (description != null) 'description': description,
      if (searchName != null) 'search_name': searchName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<SyncStatus>? syncStatus,
    Value<int?>? lastSyncedAt,
    Value<String>? name,
    Value<ProductType>? type,
    Value<int>? priceRial,
    Value<String>? unit,
    Value<String?>? description,
    Value<String>? searchName,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      name: name ?? this.name,
      type: type ?? this.type,
      priceRial: priceRial ?? this.priceRial,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      searchName: searchName ?? this.searchName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $ProductsTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $ProductsTable.$convertertype.toSql(type.value),
      );
    }
    if (priceRial.present) {
      map['price_rial'] = Variable<int>(priceRial.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (searchName.present) {
      map['search_name'] = Variable<String>(searchName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
..write('id: $id, ')
..write('createdAt: $createdAt, ')
..write('updatedAt: $updatedAt, ')
..write('deletedAt: $deletedAt, ')
..write('syncStatus: $syncStatus, ')
..write('lastSyncedAt: $lastSyncedAt, ')
..write('name: $name, ')
..write('type: $type, ')
..write('priceRial: $priceRial, ')
..write('unit: $unit, ')
..write('description: $description, ')
..write('searchName: $searchName, ')
..write('rowid: $rowid')
..write(')'))
.toString();
  }
}

class $InvoicesTable extends Invoices
    with TableInfo<$InvoicesTable, InvoiceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV4,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: nowMillis,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: nowMillis,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SyncStatus>($InvoicesTable.$convertersyncStatus);
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberYearMeta = const VerificationMeta(
    'numberYear',
  );
  @override
  late final GeneratedColumn<int> numberYear = GeneratedColumn<int>(
    'number_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberSequenceMeta = const VerificationMeta(
    'numberSequence',
  );
  @override
  late final GeneratedColumn<int> numberSequence = GeneratedColumn<int>(
    'number_sequence',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (id)',
    ),
  );
  static const VerificationMeta _issueDateMeta = const VerificationMeta(
    'issueDate',
  );
  @override
  late final GeneratedColumn<int> issueDate = GeneratedColumn<int>(
    'issue_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<int> dueDate = GeneratedColumn<int>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discountRialMeta = const VerificationMeta(
    'discountRial',
  );
  @override
  late final GeneratedColumn<int> discountRial = GeneratedColumn<int>(
    'discount_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discountPercentBpMeta = const VerificationMeta(
    'discountPercentBp',
  );
  @override
  late final GeneratedColumn<int> discountPercentBp = GeneratedColumn<int>(
    'discount_percent_bp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taxRateBpMeta = const VerificationMeta(
    'taxRateBp',
  );
  @override
  late final GeneratedColumn<int> taxRateBp = GeneratedColumn<int>(
    'tax_rate_bp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 2000),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerNameSnapshotMeta =
      const VerificationMeta('customerNameSnapshot');
  @override
  late final GeneratedColumn<String> customerNameSnapshot =
      GeneratedColumn<String>(
        'customer_name_snapshot',
        aliasedName,
        true,
        additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 120),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _customerCompanySnapshotMeta =
      const VerificationMeta('customerCompanySnapshot');
  @override
  late final GeneratedColumn<String> customerCompanySnapshot =
      GeneratedColumn<String>(
        'customer_company_snapshot',
        aliasedName,
        true,
        additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 160),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _customerNationalIdSnapshotMeta =
      const VerificationMeta('customerNationalIdSnapshot');
  @override
  late final GeneratedColumn<String> customerNationalIdSnapshot =
      GeneratedColumn<String>(
        'customer_national_id_snapshot',
        aliasedName,
        true,
        additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 10),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _customerEconomicIdSnapshotMeta =
      const VerificationMeta('customerEconomicIdSnapshot');
  @override
  late final GeneratedColumn<String> customerEconomicIdSnapshot =
      GeneratedColumn<String>(
        'customer_economic_id_snapshot',
        aliasedName,
        true,
        additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _customerAddressSnapshotMeta =
      const VerificationMeta('customerAddressSnapshot');
  @override
  late final GeneratedColumn<String> customerAddressSnapshot =
      GeneratedColumn<String>(
        'customer_address_snapshot',
        aliasedName,
        true,
        additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<InvoiceStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<InvoiceStatus>($InvoicesTable.$converterstatus);
  static const VerificationMeta _grossTotalRialMeta = const VerificationMeta(
    'grossTotalRial',
  );
  @override
  late final GeneratedColumn<int> grossTotalRial = GeneratedColumn<int>(
    'gross_total_rial',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtotalRialMeta = const VerificationMeta(
    'subtotalRial',
  );
  @override
  late final GeneratedColumn<int> subtotalRial = GeneratedColumn<int>(
    'subtotal_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalDiscountRialMeta = const VerificationMeta(
    'totalDiscountRial',
  );
  @override
  late final GeneratedColumn<int> totalDiscountRial = GeneratedColumn<int>(
    'total_discount_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalTaxRialMeta = const VerificationMeta(
    'totalTaxRial',
  );
  @override
  late final GeneratedColumn<int> totalTaxRial = GeneratedColumn<int>(
    'total_tax_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _roundingAdjustmentRialMeta =
      const VerificationMeta('roundingAdjustmentRial');
  @override
  late final GeneratedColumn<int> roundingAdjustmentRial = GeneratedColumn<int>(
    'rounding_adjustment_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _grandTotalRialMeta = const VerificationMeta(
    'grandTotalRial',
  );
  @override
  late final GeneratedColumn<int> grandTotalRial = GeneratedColumn<int>(
    'grand_total_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    lastSyncedAt,
    number,
    numberYear,
    numberSequence,
    customerId,
    issueDate,
    dueDate,
    discountRial,
    discountPercentBp,
    taxRateBp,
    notes,
    customerNameSnapshot,
    customerCompanySnapshot,
    customerNationalIdSnapshot,
    customerEconomicIdSnapshot,
    customerAddressSnapshot,
    status,
    grossTotalRial,
    subtotalRial,
    totalDiscountRial,
    totalTaxRial,
    roundingAdjustmentRial,
    grandTotalRial,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoices';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvoiceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('number_year')) {
      context.handle(
        _numberYearMeta,
        numberYear.isAcceptableOrUnknown(data['number_year']!, _numberYearMeta),
      );
    }
    if (data.containsKey('number_sequence')) {
      context.handle(
        _numberSequenceMeta,
        numberSequence.isAcceptableOrUnknown(
          data['number_sequence']!,
          _numberSequenceMeta,
        ),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('issue_date')) {
      context.handle(
        _issueDateMeta,
        issueDate.isAcceptableOrUnknown(data['issue_date']!, _issueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_issueDateMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('discount_rial')) {
      context.handle(
        _discountRialMeta,
        discountRial.isAcceptableOrUnknown(
          data['discount_rial']!,
          _discountRialMeta,
        ),
      );
    }
    if (data.containsKey('discount_percent_bp')) {
      context.handle(
        _discountPercentBpMeta,
        discountPercentBp.isAcceptableOrUnknown(
          data['discount_percent_bp']!,
          _discountPercentBpMeta,
        ),
      );
    }
    if (data.containsKey('tax_rate_bp')) {
      context.handle(
        _taxRateBpMeta,
        taxRateBp.isAcceptableOrUnknown(data['tax_rate_bp']!, _taxRateBpMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('customer_name_snapshot')) {
      context.handle(
        _customerNameSnapshotMeta,
        customerNameSnapshot.isAcceptableOrUnknown(
          data['customer_name_snapshot']!,
          _customerNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('customer_company_snapshot')) {
      context.handle(
        _customerCompanySnapshotMeta,
        customerCompanySnapshot.isAcceptableOrUnknown(
          data['customer_company_snapshot']!,
          _customerCompanySnapshotMeta,
        ),
      );
    }
    if (data.containsKey('customer_national_id_snapshot')) {
      context.handle(
        _customerNationalIdSnapshotMeta,
        customerNationalIdSnapshot.isAcceptableOrUnknown(
          data['customer_national_id_snapshot']!,
          _customerNationalIdSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('customer_economic_id_snapshot')) {
      context.handle(
        _customerEconomicIdSnapshotMeta,
        customerEconomicIdSnapshot.isAcceptableOrUnknown(
          data['customer_economic_id_snapshot']!,
          _customerEconomicIdSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('customer_address_snapshot')) {
      context.handle(
        _customerAddressSnapshotMeta,
        customerAddressSnapshot.isAcceptableOrUnknown(
          data['customer_address_snapshot']!,
          _customerAddressSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('gross_total_rial')) {
      context.handle(
        _grossTotalRialMeta,
        grossTotalRial.isAcceptableOrUnknown(
          data['gross_total_rial']!,
          _grossTotalRialMeta,
        ),
      );
    }
    if (data.containsKey('subtotal_rial')) {
      context.handle(
        _subtotalRialMeta,
        subtotalRial.isAcceptableOrUnknown(
          data['subtotal_rial']!,
          _subtotalRialMeta,
        ),
      );
    }
    if (data.containsKey('total_discount_rial')) {
      context.handle(
        _totalDiscountRialMeta,
        totalDiscountRial.isAcceptableOrUnknown(
          data['total_discount_rial']!,
          _totalDiscountRialMeta,
        ),
      );
    }
    if (data.containsKey('total_tax_rial')) {
      context.handle(
        _totalTaxRialMeta,
        totalTaxRial.isAcceptableOrUnknown(
          data['total_tax_rial']!,
          _totalTaxRialMeta,
        ),
      );
    }
    if (data.containsKey('rounding_adjustment_rial')) {
      context.handle(
        _roundingAdjustmentRialMeta,
        roundingAdjustmentRial.isAcceptableOrUnknown(
          data['rounding_adjustment_rial']!,
          _roundingAdjustmentRialMeta,
        ),
      );
    }
    if (data.containsKey('grand_total_rial')) {
      context.handle(
        _grandTotalRialMeta,
        grandTotalRial.isAcceptableOrUnknown(
          data['grand_total_rial']!,
          _grandTotalRialMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: $InvoicesTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      ),
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      ),
      numberYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number_year'],
      ),
      numberSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number_sequence'],
      ),
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      issueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}issue_date'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_date'],
      ),
      discountRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_rial'],
      )!,
      discountPercentBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_percent_bp'],
      ),
      taxRateBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_rate_bp'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      customerNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name_snapshot'],
      ),
      customerCompanySnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_company_snapshot'],
      ),
      customerNationalIdSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_national_id_snapshot'],
      ),
      customerEconomicIdSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_economic_id_snapshot'],
      ),
      customerAddressSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_address_snapshot'],
      ),
      status: $InvoicesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      grossTotalRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gross_total_rial'],
      ),
      subtotalRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal_rial'],
      )!,
      totalDiscountRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_discount_rial'],
      )!,
      totalTaxRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_tax_rial'],
      )!,
      roundingAdjustmentRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rounding_adjustment_rial'],
      )!,
      grandTotalRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grand_total_rial'],
      )!,
    );
  }

  @override
  $InvoicesTable createAlias(String alias) {
    return $InvoicesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatus>(SyncStatus.values);
  static JsonTypeConverter2<InvoiceStatus, int, int> $converterstatus =
      const EnumIndexConverter<InvoiceStatus>(InvoiceStatus.values);
}

class InvoiceRow extends DataClass implements Insertable<InvoiceRow> {
  /// UUID v4, never `AUTOINCREMENT`: integer keys allocated independently on
  /// two devices collide the moment those devices sync (D-001).
  final String id;

  /// Epoch milliseconds, UTC (D-005). Never a localized date string.
  final int createdAt;

  /// Bumped on every write. Repositories own this; it is not automatic.
  final int updatedAt;

  /// Soft delete (D-003). A hard delete cannot be propagated to another
  /// device, which would resurrect the row on the next sync. Every read must
  /// filter this -- see `soft_delete.dart`, the single place that expresses it.
  final int? deletedAt;
  final SyncStatus syncStatus;
  final int? lastSyncedAt;

  /// The full human-facing number, e.g. `INV-1405-0001` (D-013).
  ///
  /// Uniquely indexed **including soft-deleted rows**: a number that has been
  /// issued is spent, and reusing it would produce two different documents
  /// with one identity.
  ///
  /// **Null until the invoice is issued** (D-048). A draft carries no number,
  /// because allocating one at creation meant an abandoned draft consumed a
  /// number permanently — the unique index above covers soft-deleted rows, so
  /// the gap it left could never be reclaimed, and a business whose numbering
  /// has holes has a conversation to have with an auditor.
  ///
  /// Nullable rather than an empty-string sentinel, and that is the whole
  /// mechanism: SQLite treats `''` as equal to `''` in a unique index, so a
  /// second numberless draft would collide, while **NULLs are distinct** in
  /// one. `issue()` is what fills these three columns in.
  final String? number;

  /// The Jalali year and sequence the number was allocated from, stored
  /// separately so allocation is `MAX(number_sequence) WHERE number_year = ?`
  /// inside a transaction, rather than parsing formatted strings.
  ///
  /// Null exactly when [number] is. `MAX` ignores nulls, so an unissued draft
  /// takes no part in allocation without the query having to exclude it.
  final int? numberYear;
  final int? numberSequence;

  /// No cascade: a customer referenced by an invoice is soft-deleted only,
  /// never hard-deleted (D-003), and SQLite's default `NO ACTION` is what
  /// makes an attempted hard delete fail loudly instead of orphaning rows.
  final String customerId;

  /// Epoch milliseconds, UTC. Displayed as Jalali; reporting periods are
  /// Jalali month boundaries converted to instants (D-005, D-006).
  final int issueDate;
  final int? dueDate;

  /// Invoice-level discount as an absolute Rial amount, allocated across items
  /// proportionally by line net with largest-remainder rounding (§4 step 4).
  final int discountRial;

  /// If the user entered the discount as a percentage, the entered percentage
  /// in basis points is kept alongside the resolved amount (§4 step 2), so the
  /// document can show what was actually typed.
  final int? discountPercentBp;

  /// Invoice-level tax rate in basis points. Null means "fall through to the
  /// default in settings" (§4 step 6).
  final int? taxRateBp;
  final String? notes;
  final String? customerNameSnapshot;
  final String? customerCompanySnapshot;

  /// کد ملی and کد اقتصادی as they stood at issue. These are the fields with
  /// legal weight on an Iranian invoice and the ones a correction changes, so
  /// a snapshot that omitted them would protect the least consequential field
  /// (D-052).
  final String? customerNationalIdSnapshot;
  final String? customerEconomicIdSnapshot;
  final String? customerAddressSnapshot;
  final InvoiceStatus status;

  /// `Σ lineGross` -- the **first term of the printed summary** (D-055).
  ///
  /// Stored rather than recomputed, for the reason every other figure here is:
  /// step 1 of §4 carries a rounding rule, so a gross re-derived on read is
  /// today's rule applied to yesterday's document. That is D-004's failure
  /// applied to arithmetic instead of to price, and the PDF layer is the one
  /// place it would be both invisible and permanent (§12).
  ///
  /// **Nullable, and `NOT NULL DEFAULT 0` was refused.** Invoices written
  /// before schema v4 are backfilled where their stored figures reconcile
  /// exactly, and left **null** where they do not -- zero is a number a
  /// document prints, and a gross of zero beside a grand total of 21,230,000
  /// is worse than an admission that the figure is unknown. Everything
  /// rendering it says so in Persian; `invoiceGrossLabel` is the one place the
  /// wording lives, on `invoiceNumberLabel`'s precedent.
  final int? grossTotalRial;
  final int subtotalRial;
  final int totalDiscountRial;
  final int totalTaxRial;

  /// The delta applied by optional whole-invoice rounding, kept so the invoice
  /// still reconciles exactly (§4 "Rounding").
  final int roundingAdjustmentRial;
  final int grandTotalRial;
  const InvoiceRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    this.number,
    this.numberYear,
    this.numberSequence,
    required this.customerId,
    required this.issueDate,
    this.dueDate,
    required this.discountRial,
    this.discountPercentBp,
    this.taxRateBp,
    this.notes,
    this.customerNameSnapshot,
    this.customerCompanySnapshot,
    this.customerNationalIdSnapshot,
    this.customerEconomicIdSnapshot,
    this.customerAddressSnapshot,
    required this.status,
    this.grossTotalRial,
    required this.subtotalRial,
    required this.totalDiscountRial,
    required this.totalTaxRial,
    required this.roundingAdjustmentRial,
    required this.grandTotalRial,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    {
      map['sync_status'] = Variable<int>(
        $InvoicesTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<String>(number);
    }
    if (!nullToAbsent || numberYear != null) {
      map['number_year'] = Variable<int>(numberYear);
    }
    if (!nullToAbsent || numberSequence != null) {
      map['number_sequence'] = Variable<int>(numberSequence);
    }
    map['customer_id'] = Variable<String>(customerId);
    map['issue_date'] = Variable<int>(issueDate);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<int>(dueDate);
    }
    map['discount_rial'] = Variable<int>(discountRial);
    if (!nullToAbsent || discountPercentBp != null) {
      map['discount_percent_bp'] = Variable<int>(discountPercentBp);
    }
    if (!nullToAbsent || taxRateBp != null) {
      map['tax_rate_bp'] = Variable<int>(taxRateBp);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || customerNameSnapshot != null) {
      map['customer_name_snapshot'] = Variable<String>(customerNameSnapshot);
    }
    if (!nullToAbsent || customerCompanySnapshot != null) {
      map['customer_company_snapshot'] = Variable<String>(
        customerCompanySnapshot,
      );
    }
    if (!nullToAbsent || customerNationalIdSnapshot != null) {
      map['customer_national_id_snapshot'] = Variable<String>(
        customerNationalIdSnapshot,
      );
    }
    if (!nullToAbsent || customerEconomicIdSnapshot != null) {
      map['customer_economic_id_snapshot'] = Variable<String>(
        customerEconomicIdSnapshot,
      );
    }
    if (!nullToAbsent || customerAddressSnapshot != null) {
      map['customer_address_snapshot'] = Variable<String>(
        customerAddressSnapshot,
      );
    }
    {
      map['status'] = Variable<int>(
        $InvoicesTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || grossTotalRial != null) {
      map['gross_total_rial'] = Variable<int>(grossTotalRial);
    }
    map['subtotal_rial'] = Variable<int>(subtotalRial);
    map['total_discount_rial'] = Variable<int>(totalDiscountRial);
    map['total_tax_rial'] = Variable<int>(totalTaxRial);
    map['rounding_adjustment_rial'] = Variable<int>(roundingAdjustmentRial);
    map['grand_total_rial'] = Variable<int>(grandTotalRial);
    return map;
  }

  InvoicesCompanion toCompanion(bool nullToAbsent) {
    return InvoicesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
: Value(deletedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
: Value(lastSyncedAt),
      number: number == null && nullToAbsent
          ? const Value.absent()
: Value(number),
      numberYear: numberYear == null && nullToAbsent
          ? const Value.absent()
: Value(numberYear),
      numberSequence: numberSequence == null && nullToAbsent
          ? const Value.absent()
: Value(numberSequence),
      customerId: Value(customerId),
      issueDate: Value(issueDate),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
: Value(dueDate),
      discountRial: Value(discountRial),
      discountPercentBp: discountPercentBp == null && nullToAbsent
          ? const Value.absent()
: Value(discountPercentBp),
      taxRateBp: taxRateBp == null && nullToAbsent
          ? const Value.absent()
: Value(taxRateBp),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
: Value(notes),
      customerNameSnapshot: customerNameSnapshot == null && nullToAbsent
          ? const Value.absent()
: Value(customerNameSnapshot),
      customerCompanySnapshot: customerCompanySnapshot == null && nullToAbsent
          ? const Value.absent()
: Value(customerCompanySnapshot),
      customerNationalIdSnapshot:
          customerNationalIdSnapshot == null && nullToAbsent
          ? const Value.absent()
: Value(customerNationalIdSnapshot),
      customerEconomicIdSnapshot:
          customerEconomicIdSnapshot == null && nullToAbsent
          ? const Value.absent()
: Value(customerEconomicIdSnapshot),
      customerAddressSnapshot: customerAddressSnapshot == null && nullToAbsent
          ? const Value.absent()
: Value(customerAddressSnapshot),
      status: Value(status),
      grossTotalRial: grossTotalRial == null && nullToAbsent
          ? const Value.absent()
: Value(grossTotalRial),
      subtotalRial: Value(subtotalRial),
      totalDiscountRial: Value(totalDiscountRial),
      totalTaxRial: Value(totalTaxRial),
      roundingAdjustmentRial: Value(roundingAdjustmentRial),
      grandTotalRial: Value(grandTotalRial),
    );
  }

  factory InvoiceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      syncStatus: $InvoicesTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
      number: serializer.fromJson<String?>(json['number']),
      numberYear: serializer.fromJson<int?>(json['numberYear']),
      numberSequence: serializer.fromJson<int?>(json['numberSequence']),
      customerId: serializer.fromJson<String>(json['customerId']),
      issueDate: serializer.fromJson<int>(json['issueDate']),
      dueDate: serializer.fromJson<int?>(json['dueDate']),
      discountRial: serializer.fromJson<int>(json['discountRial']),
      discountPercentBp: serializer.fromJson<int?>(json['discountPercentBp']),
      taxRateBp: serializer.fromJson<int?>(json['taxRateBp']),
      notes: serializer.fromJson<String?>(json['notes']),
      customerNameSnapshot: serializer.fromJson<String?>(
        json['customerNameSnapshot'],
      ),
      customerCompanySnapshot: serializer.fromJson<String?>(
        json['customerCompanySnapshot'],
      ),
      customerNationalIdSnapshot: serializer.fromJson<String?>(
        json['customerNationalIdSnapshot'],
      ),
      customerEconomicIdSnapshot: serializer.fromJson<String?>(
        json['customerEconomicIdSnapshot'],
      ),
      customerAddressSnapshot: serializer.fromJson<String?>(
        json['customerAddressSnapshot'],
      ),
      status: $InvoicesTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      grossTotalRial: serializer.fromJson<int?>(json['grossTotalRial']),
      subtotalRial: serializer.fromJson<int>(json['subtotalRial']),
      totalDiscountRial: serializer.fromJson<int>(json['totalDiscountRial']),
      totalTaxRial: serializer.fromJson<int>(json['totalTaxRial']),
      roundingAdjustmentRial: serializer.fromJson<int>(
        json['roundingAdjustmentRial'],
      ),
      grandTotalRial: serializer.fromJson<int>(json['grandTotalRial']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'syncStatus': serializer.toJson<int>(
        $InvoicesTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'number': serializer.toJson<String?>(number),
      'numberYear': serializer.toJson<int?>(numberYear),
      'numberSequence': serializer.toJson<int?>(numberSequence),
      'customerId': serializer.toJson<String>(customerId),
      'issueDate': serializer.toJson<int>(issueDate),
      'dueDate': serializer.toJson<int?>(dueDate),
      'discountRial': serializer.toJson<int>(discountRial),
      'discountPercentBp': serializer.toJson<int?>(discountPercentBp),
      'taxRateBp': serializer.toJson<int?>(taxRateBp),
      'notes': serializer.toJson<String?>(notes),
      'customerNameSnapshot': serializer.toJson<String?>(customerNameSnapshot),
      'customerCompanySnapshot': serializer.toJson<String?>(
        customerCompanySnapshot,
      ),
      'customerNationalIdSnapshot': serializer.toJson<String?>(
        customerNationalIdSnapshot,
      ),
      'customerEconomicIdSnapshot': serializer.toJson<String?>(
        customerEconomicIdSnapshot,
      ),
      'customerAddressSnapshot': serializer.toJson<String?>(
        customerAddressSnapshot,
      ),
      'status': serializer.toJson<int>(
        $InvoicesTable.$converterstatus.toJson(status),
      ),
      'grossTotalRial': serializer.toJson<int?>(grossTotalRial),
      'subtotalRial': serializer.toJson<int>(subtotalRial),
      'totalDiscountRial': serializer.toJson<int>(totalDiscountRial),
      'totalTaxRial': serializer.toJson<int>(totalTaxRial),
      'roundingAdjustmentRial': serializer.toJson<int>(roundingAdjustmentRial),
      'grandTotalRial': serializer.toJson<int>(grandTotalRial),
    };
  }

  InvoiceRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    SyncStatus? syncStatus,
    Value<int?> lastSyncedAt = const Value.absent(),
    Value<String?> number = const Value.absent(),
    Value<int?> numberYear = const Value.absent(),
    Value<int?> numberSequence = const Value.absent(),
    String? customerId,
    int? issueDate,
    Value<int?> dueDate = const Value.absent(),
    int? discountRial,
    Value<int?> discountPercentBp = const Value.absent(),
    Value<int?> taxRateBp = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> customerNameSnapshot = const Value.absent(),
    Value<String?> customerCompanySnapshot = const Value.absent(),
    Value<String?> customerNationalIdSnapshot = const Value.absent(),
    Value<String?> customerEconomicIdSnapshot = const Value.absent(),
    Value<String?> customerAddressSnapshot = const Value.absent(),
    InvoiceStatus? status,
    Value<int?> grossTotalRial = const Value.absent(),
    int? subtotalRial,
    int? totalDiscountRial,
    int? totalTaxRial,
    int? roundingAdjustmentRial,
    int? grandTotalRial,
  }) => InvoiceRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    number: number.present ? number.value : this.number,
    numberYear: numberYear.present ? numberYear.value : this.numberYear,
    numberSequence: numberSequence.present
        ? numberSequence.value
: this.numberSequence,
    customerId: customerId ?? this.customerId,
    issueDate: issueDate ?? this.issueDate,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    discountRial: discountRial ?? this.discountRial,
    discountPercentBp: discountPercentBp.present
        ? discountPercentBp.value
: this.discountPercentBp,
    taxRateBp: taxRateBp.present ? taxRateBp.value : this.taxRateBp,
    notes: notes.present ? notes.value : this.notes,
    customerNameSnapshot: customerNameSnapshot.present
        ? customerNameSnapshot.value
: this.customerNameSnapshot,
    customerCompanySnapshot: customerCompanySnapshot.present
        ? customerCompanySnapshot.value
: this.customerCompanySnapshot,
    customerNationalIdSnapshot: customerNationalIdSnapshot.present
        ? customerNationalIdSnapshot.value
: this.customerNationalIdSnapshot,
    customerEconomicIdSnapshot: customerEconomicIdSnapshot.present
        ? customerEconomicIdSnapshot.value
: this.customerEconomicIdSnapshot,
    customerAddressSnapshot: customerAddressSnapshot.present
        ? customerAddressSnapshot.value
: this.customerAddressSnapshot,
    status: status ?? this.status,
    grossTotalRial: grossTotalRial.present
        ? grossTotalRial.value
: this.grossTotalRial,
    subtotalRial: subtotalRial ?? this.subtotalRial,
    totalDiscountRial: totalDiscountRial ?? this.totalDiscountRial,
    totalTaxRial: totalTaxRial ?? this.totalTaxRial,
    roundingAdjustmentRial:
        roundingAdjustmentRial ?? this.roundingAdjustmentRial,
    grandTotalRial: grandTotalRial ?? this.grandTotalRial,
  );
  InvoiceRow copyWithCompanion(InvoicesCompanion data) {
    return InvoiceRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
: this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
: this.lastSyncedAt,
      number: data.number.present ? data.number.value : this.number,
      numberYear: data.numberYear.present
          ? data.numberYear.value
: this.numberYear,
      numberSequence: data.numberSequence.present
          ? data.numberSequence.value
: this.numberSequence,
      customerId: data.customerId.present
          ? data.customerId.value
: this.customerId,
      issueDate: data.issueDate.present ? data.issueDate.value : this.issueDate,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      discountRial: data.discountRial.present
          ? data.discountRial.value
: this.discountRial,
      discountPercentBp: data.discountPercentBp.present
          ? data.discountPercentBp.value
: this.discountPercentBp,
      taxRateBp: data.taxRateBp.present ? data.taxRateBp.value : this.taxRateBp,
      notes: data.notes.present ? data.notes.value : this.notes,
      customerNameSnapshot: data.customerNameSnapshot.present
          ? data.customerNameSnapshot.value
: this.customerNameSnapshot,
      customerCompanySnapshot: data.customerCompanySnapshot.present
          ? data.customerCompanySnapshot.value
: this.customerCompanySnapshot,
      customerNationalIdSnapshot: data.customerNationalIdSnapshot.present
          ? data.customerNationalIdSnapshot.value
: this.customerNationalIdSnapshot,
      customerEconomicIdSnapshot: data.customerEconomicIdSnapshot.present
          ? data.customerEconomicIdSnapshot.value
: this.customerEconomicIdSnapshot,
      customerAddressSnapshot: data.customerAddressSnapshot.present
          ? data.customerAddressSnapshot.value
: this.customerAddressSnapshot,
      status: data.status.present ? data.status.value : this.status,
      grossTotalRial: data.grossTotalRial.present
          ? data.grossTotalRial.value
: this.grossTotalRial,
      subtotalRial: data.subtotalRial.present
          ? data.subtotalRial.value
: this.subtotalRial,
      totalDiscountRial: data.totalDiscountRial.present
          ? data.totalDiscountRial.value
: this.totalDiscountRial,
      totalTaxRial: data.totalTaxRial.present
          ? data.totalTaxRial.value
: this.totalTaxRial,
      roundingAdjustmentRial: data.roundingAdjustmentRial.present
          ? data.roundingAdjustmentRial.value
: this.roundingAdjustmentRial,
      grandTotalRial: data.grandTotalRial.present
          ? data.grandTotalRial.value
: this.grandTotalRial,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceRow(')
..write('id: $id, ')
..write('createdAt: $createdAt, ')
..write('updatedAt: $updatedAt, ')
..write('deletedAt: $deletedAt, ')
..write('syncStatus: $syncStatus, ')
..write('lastSyncedAt: $lastSyncedAt, ')
..write('number: $number, ')
..write('numberYear: $numberYear, ')
..write('numberSequence: $numberSequence, ')
..write('customerId: $customerId, ')
..write('issueDate: $issueDate, ')
..write('dueDate: $dueDate, ')
..write('discountRial: $discountRial, ')
..write('discountPercentBp: $discountPercentBp, ')
..write('taxRateBp: $taxRateBp, ')
..write('notes: $notes, ')
..write('customerNameSnapshot: $customerNameSnapshot, ')
..write('customerCompanySnapshot: $customerCompanySnapshot, ')
..write('customerNationalIdSnapshot: $customerNationalIdSnapshot, ')
..write('customerEconomicIdSnapshot: $customerEconomicIdSnapshot, ')
..write('customerAddressSnapshot: $customerAddressSnapshot, ')
..write('status: $status, ')
..write('grossTotalRial: $grossTotalRial, ')
..write('subtotalRial: $subtotalRial, ')
..write('totalDiscountRial: $totalDiscountRial, ')
..write('totalTaxRial: $totalTaxRial, ')
..write('roundingAdjustmentRial: $roundingAdjustmentRial, ')
..write('grandTotalRial: $grandTotalRial')
..write(')'))
.toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    lastSyncedAt,
    number,
    numberYear,
    numberSequence,
    customerId,
    issueDate,
    dueDate,
    discountRial,
    discountPercentBp,
    taxRateBp,
    notes,
    customerNameSnapshot,
    customerCompanySnapshot,
    customerNationalIdSnapshot,
    customerEconomicIdSnapshot,
    customerAddressSnapshot,
    status,
    grossTotalRial,
    subtotalRial,
    totalDiscountRial,
    totalTaxRial,
    roundingAdjustmentRial,
    grandTotalRial,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.number == this.number &&
          other.numberYear == this.numberYear &&
          other.numberSequence == this.numberSequence &&
          other.customerId == this.customerId &&
          other.issueDate == this.issueDate &&
          other.dueDate == this.dueDate &&
          other.discountRial == this.discountRial &&
          other.discountPercentBp == this.discountPercentBp &&
          other.taxRateBp == this.taxRateBp &&
          other.notes == this.notes &&
          other.customerNameSnapshot == this.customerNameSnapshot &&
          other.customerCompanySnapshot == this.customerCompanySnapshot &&
          other.customerNationalIdSnapshot == this.customerNationalIdSnapshot &&
          other.customerEconomicIdSnapshot == this.customerEconomicIdSnapshot &&
          other.customerAddressSnapshot == this.customerAddressSnapshot &&
          other.status == this.status &&
          other.grossTotalRial == this.grossTotalRial &&
          other.subtotalRial == this.subtotalRial &&
          other.totalDiscountRial == this.totalDiscountRial &&
          other.totalTaxRial == this.totalTaxRial &&
          other.roundingAdjustmentRial == this.roundingAdjustmentRial &&
          other.grandTotalRial == this.grandTotalRial);
}

class InvoicesCompanion extends UpdateCompanion<InvoiceRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int?> lastSyncedAt;
  final Value<String?> number;
  final Value<int?> numberYear;
  final Value<int?> numberSequence;
  final Value<String> customerId;
  final Value<int> issueDate;
  final Value<int?> dueDate;
  final Value<int> discountRial;
  final Value<int?> discountPercentBp;
  final Value<int?> taxRateBp;
  final Value<String?> notes;
  final Value<String?> customerNameSnapshot;
  final Value<String?> customerCompanySnapshot;
  final Value<String?> customerNationalIdSnapshot;
  final Value<String?> customerEconomicIdSnapshot;
  final Value<String?> customerAddressSnapshot;
  final Value<InvoiceStatus> status;
  final Value<int?> grossTotalRial;
  final Value<int> subtotalRial;
  final Value<int> totalDiscountRial;
  final Value<int> totalTaxRial;
  final Value<int> roundingAdjustmentRial;
  final Value<int> grandTotalRial;
  final Value<int> rowid;
  const InvoicesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.number = const Value.absent(),
    this.numberYear = const Value.absent(),
    this.numberSequence = const Value.absent(),
    this.customerId = const Value.absent(),
    this.issueDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.discountRial = const Value.absent(),
    this.discountPercentBp = const Value.absent(),
    this.taxRateBp = const Value.absent(),
    this.notes = const Value.absent(),
    this.customerNameSnapshot = const Value.absent(),
    this.customerCompanySnapshot = const Value.absent(),
    this.customerNationalIdSnapshot = const Value.absent(),
    this.customerEconomicIdSnapshot = const Value.absent(),
    this.customerAddressSnapshot = const Value.absent(),
    this.status = const Value.absent(),
    this.grossTotalRial = const Value.absent(),
    this.subtotalRial = const Value.absent(),
    this.totalDiscountRial = const Value.absent(),
    this.totalTaxRial = const Value.absent(),
    this.roundingAdjustmentRial = const Value.absent(),
    this.grandTotalRial = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoicesCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.number = const Value.absent(),
    this.numberYear = const Value.absent(),
    this.numberSequence = const Value.absent(),
    required String customerId,
    required int issueDate,
    this.dueDate = const Value.absent(),
    this.discountRial = const Value.absent(),
    this.discountPercentBp = const Value.absent(),
    this.taxRateBp = const Value.absent(),
    this.notes = const Value.absent(),
    this.customerNameSnapshot = const Value.absent(),
    this.customerCompanySnapshot = const Value.absent(),
    this.customerNationalIdSnapshot = const Value.absent(),
    this.customerEconomicIdSnapshot = const Value.absent(),
    this.customerAddressSnapshot = const Value.absent(),
    required InvoiceStatus status,
    this.grossTotalRial = const Value.absent(),
    this.subtotalRial = const Value.absent(),
    this.totalDiscountRial = const Value.absent(),
    this.totalTaxRial = const Value.absent(),
    this.roundingAdjustmentRial = const Value.absent(),
    this.grandTotalRial = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : customerId = Value(customerId),
       issueDate = Value(issueDate),
       status = Value(status);
  static Insertable<InvoiceRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? lastSyncedAt,
    Expression<String>? number,
    Expression<int>? numberYear,
    Expression<int>? numberSequence,
    Expression<String>? customerId,
    Expression<int>? issueDate,
    Expression<int>? dueDate,
    Expression<int>? discountRial,
    Expression<int>? discountPercentBp,
    Expression<int>? taxRateBp,
    Expression<String>? notes,
    Expression<String>? customerNameSnapshot,
    Expression<String>? customerCompanySnapshot,
    Expression<String>? customerNationalIdSnapshot,
    Expression<String>? customerEconomicIdSnapshot,
    Expression<String>? customerAddressSnapshot,
    Expression<int>? status,
    Expression<int>? grossTotalRial,
    Expression<int>? subtotalRial,
    Expression<int>? totalDiscountRial,
    Expression<int>? totalTaxRial,
    Expression<int>? roundingAdjustmentRial,
    Expression<int>? grandTotalRial,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (number != null) 'number': number,
      if (numberYear != null) 'number_year': numberYear,
      if (numberSequence != null) 'number_sequence': numberSequence,
      if (customerId != null) 'customer_id': customerId,
      if (issueDate != null) 'issue_date': issueDate,
      if (dueDate != null) 'due_date': dueDate,
      if (discountRial != null) 'discount_rial': discountRial,
      if (discountPercentBp != null) 'discount_percent_bp': discountPercentBp,
      if (taxRateBp != null) 'tax_rate_bp': taxRateBp,
      if (notes != null) 'notes': notes,
      if (customerNameSnapshot != null)
        'customer_name_snapshot': customerNameSnapshot,
      if (customerCompanySnapshot != null)
        'customer_company_snapshot': customerCompanySnapshot,
      if (customerNationalIdSnapshot != null)
        'customer_national_id_snapshot': customerNationalIdSnapshot,
      if (customerEconomicIdSnapshot != null)
        'customer_economic_id_snapshot': customerEconomicIdSnapshot,
      if (customerAddressSnapshot != null)
        'customer_address_snapshot': customerAddressSnapshot,
      if (status != null) 'status': status,
      if (grossTotalRial != null) 'gross_total_rial': grossTotalRial,
      if (subtotalRial != null) 'subtotal_rial': subtotalRial,
      if (totalDiscountRial != null) 'total_discount_rial': totalDiscountRial,
      if (totalTaxRial != null) 'total_tax_rial': totalTaxRial,
      if (roundingAdjustmentRial != null)
        'rounding_adjustment_rial': roundingAdjustmentRial,
      if (grandTotalRial != null) 'grand_total_rial': grandTotalRial,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoicesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<SyncStatus>? syncStatus,
    Value<int?>? lastSyncedAt,
    Value<String?>? number,
    Value<int?>? numberYear,
    Value<int?>? numberSequence,
    Value<String>? customerId,
    Value<int>? issueDate,
    Value<int?>? dueDate,
    Value<int>? discountRial,
    Value<int?>? discountPercentBp,
    Value<int?>? taxRateBp,
    Value<String?>? notes,
    Value<String?>? customerNameSnapshot,
    Value<String?>? customerCompanySnapshot,
    Value<String?>? customerNationalIdSnapshot,
    Value<String?>? customerEconomicIdSnapshot,
    Value<String?>? customerAddressSnapshot,
    Value<InvoiceStatus>? status,
    Value<int?>? grossTotalRial,
    Value<int>? subtotalRial,
    Value<int>? totalDiscountRial,
    Value<int>? totalTaxRial,
    Value<int>? roundingAdjustmentRial,
    Value<int>? grandTotalRial,
    Value<int>? rowid,
  }) {
    return InvoicesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      number: number ?? this.number,
      numberYear: numberYear ?? this.numberYear,
      numberSequence: numberSequence ?? this.numberSequence,
      customerId: customerId ?? this.customerId,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      discountRial: discountRial ?? this.discountRial,
      discountPercentBp: discountPercentBp ?? this.discountPercentBp,
      taxRateBp: taxRateBp ?? this.taxRateBp,
      notes: notes ?? this.notes,
      customerNameSnapshot: customerNameSnapshot ?? this.customerNameSnapshot,
      customerCompanySnapshot:
          customerCompanySnapshot ?? this.customerCompanySnapshot,
      customerNationalIdSnapshot:
          customerNationalIdSnapshot ?? this.customerNationalIdSnapshot,
      customerEconomicIdSnapshot:
          customerEconomicIdSnapshot ?? this.customerEconomicIdSnapshot,
      customerAddressSnapshot:
          customerAddressSnapshot ?? this.customerAddressSnapshot,
      status: status ?? this.status,
      grossTotalRial: grossTotalRial ?? this.grossTotalRial,
      subtotalRial: subtotalRial ?? this.subtotalRial,
      totalDiscountRial: totalDiscountRial ?? this.totalDiscountRial,
      totalTaxRial: totalTaxRial ?? this.totalTaxRial,
      roundingAdjustmentRial:
          roundingAdjustmentRial ?? this.roundingAdjustmentRial,
      grandTotalRial: grandTotalRial ?? this.grandTotalRial,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $InvoicesTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (numberYear.present) {
      map['number_year'] = Variable<int>(numberYear.value);
    }
    if (numberSequence.present) {
      map['number_sequence'] = Variable<int>(numberSequence.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (issueDate.present) {
      map['issue_date'] = Variable<int>(issueDate.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<int>(dueDate.value);
    }
    if (discountRial.present) {
      map['discount_rial'] = Variable<int>(discountRial.value);
    }
    if (discountPercentBp.present) {
      map['discount_percent_bp'] = Variable<int>(discountPercentBp.value);
    }
    if (taxRateBp.present) {
      map['tax_rate_bp'] = Variable<int>(taxRateBp.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (customerNameSnapshot.present) {
      map['customer_name_snapshot'] = Variable<String>(
        customerNameSnapshot.value,
      );
    }
    if (customerCompanySnapshot.present) {
      map['customer_company_snapshot'] = Variable<String>(
        customerCompanySnapshot.value,
      );
    }
    if (customerNationalIdSnapshot.present) {
      map['customer_national_id_snapshot'] = Variable<String>(
        customerNationalIdSnapshot.value,
      );
    }
    if (customerEconomicIdSnapshot.present) {
      map['customer_economic_id_snapshot'] = Variable<String>(
        customerEconomicIdSnapshot.value,
      );
    }
    if (customerAddressSnapshot.present) {
      map['customer_address_snapshot'] = Variable<String>(
        customerAddressSnapshot.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $InvoicesTable.$converterstatus.toSql(status.value),
      );
    }
    if (grossTotalRial.present) {
      map['gross_total_rial'] = Variable<int>(grossTotalRial.value);
    }
    if (subtotalRial.present) {
      map['subtotal_rial'] = Variable<int>(subtotalRial.value);
    }
    if (totalDiscountRial.present) {
      map['total_discount_rial'] = Variable<int>(totalDiscountRial.value);
    }
    if (totalTaxRial.present) {
      map['total_tax_rial'] = Variable<int>(totalTaxRial.value);
    }
    if (roundingAdjustmentRial.present) {
      map['rounding_adjustment_rial'] = Variable<int>(
        roundingAdjustmentRial.value,
      );
    }
    if (grandTotalRial.present) {
      map['grand_total_rial'] = Variable<int>(grandTotalRial.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoicesCompanion(')
..write('id: $id, ')
..write('createdAt: $createdAt, ')
..write('updatedAt: $updatedAt, ')
..write('deletedAt: $deletedAt, ')
..write('syncStatus: $syncStatus, ')
..write('lastSyncedAt: $lastSyncedAt, ')
..write('number: $number, ')
..write('numberYear: $numberYear, ')
..write('numberSequence: $numberSequence, ')
..write('customerId: $customerId, ')
..write('issueDate: $issueDate, ')
..write('dueDate: $dueDate, ')
..write('discountRial: $discountRial, ')
..write('discountPercentBp: $discountPercentBp, ')
..write('taxRateBp: $taxRateBp, ')
..write('notes: $notes, ')
..write('customerNameSnapshot: $customerNameSnapshot, ')
..write('customerCompanySnapshot: $customerCompanySnapshot, ')
..write('customerNationalIdSnapshot: $customerNationalIdSnapshot, ')
..write('customerEconomicIdSnapshot: $customerEconomicIdSnapshot, ')
..write('customerAddressSnapshot: $customerAddressSnapshot, ')
..write('status: $status, ')
..write('grossTotalRial: $grossTotalRial, ')
..write('subtotalRial: $subtotalRial, ')
..write('totalDiscountRial: $totalDiscountRial, ')
..write('totalTaxRial: $totalTaxRial, ')
..write('roundingAdjustmentRial: $roundingAdjustmentRial, ')
..write('grandTotalRial: $grandTotalRial, ')
..write('rowid: $rowid')
..write(')'))
.toString();
  }
}

class $InvoiceItemsTable extends InvoiceItems
    with TableInfo<$InvoiceItemsTable, InvoiceItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoiceItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV4,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: nowMillis,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: nowMillis,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SyncStatus>($InvoiceItemsTable.$convertersyncStatus);
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES invoices (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _titleSnapshotMeta = const VerificationMeta(
    'titleSnapshot',
  );
  @override
  late final GeneratedColumn<String> titleSnapshot = GeneratedColumn<String>(
    'title_snapshot',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitSnapshotMeta = const VerificationMeta(
    'unitSnapshot',
  );
  @override
  late final GeneratedColumn<String> unitSnapshot = GeneratedColumn<String>(
    'unit_snapshot',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 30,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceRialMeta = const VerificationMeta(
    'unitPriceRial',
  );
  @override
  late final GeneratedColumn<int> unitPriceRial = GeneratedColumn<int>(
    'unit_price_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMilliMeta = const VerificationMeta(
    'quantityMilli',
  );
  @override
  late final GeneratedColumn<int> quantityMilli = GeneratedColumn<int>(
    'quantity_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountRialMeta = const VerificationMeta(
    'discountRial',
  );
  @override
  late final GeneratedColumn<int> discountRial = GeneratedColumn<int>(
    'discount_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discountPercentBpMeta = const VerificationMeta(
    'discountPercentBp',
  );
  @override
  late final GeneratedColumn<int> discountPercentBp = GeneratedColumn<int>(
    'discount_percent_bp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedTaxRateBpMeta = const VerificationMeta(
    'resolvedTaxRateBp',
  );
  @override
  late final GeneratedColumn<int> resolvedTaxRateBp = GeneratedColumn<int>(
    'resolved_tax_rate_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineGrossRialMeta = const VerificationMeta(
    'lineGrossRial',
  );
  @override
  late final GeneratedColumn<int> lineGrossRial = GeneratedColumn<int>(
    'line_gross_rial',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allocatedInvoiceDiscountRialMeta =
      const VerificationMeta('allocatedInvoiceDiscountRial');
  @override
  late final GeneratedColumn<int> allocatedInvoiceDiscountRial =
      GeneratedColumn<int>(
        'allocated_invoice_discount_rial',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lineNetRialMeta = const VerificationMeta(
    'lineNetRial',
  );
  @override
  late final GeneratedColumn<int> lineNetRial = GeneratedColumn<int>(
    'line_net_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lineTaxRialMeta = const VerificationMeta(
    'lineTaxRial',
  );
  @override
  late final GeneratedColumn<int> lineTaxRial = GeneratedColumn<int>(
    'line_tax_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lineTotalRialMeta = const VerificationMeta(
    'lineTotalRial',
  );
  @override
  late final GeneratedColumn<int> lineTotalRial = GeneratedColumn<int>(
    'line_total_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    lastSyncedAt,
    invoiceId,
    productId,
    position,
    titleSnapshot,
    unitSnapshot,
    unitPriceRial,
    quantityMilli,
    discountRial,
    discountPercentBp,
    resolvedTaxRateBp,
    lineGrossRial,
    allocatedInvoiceDiscountRial,
    lineNetRial,
    lineTaxRial,
    lineTotalRial,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoice_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvoiceItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('title_snapshot')) {
      context.handle(
        _titleSnapshotMeta,
        titleSnapshot.isAcceptableOrUnknown(
          data['title_snapshot']!,
          _titleSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_titleSnapshotMeta);
    }
    if (data.containsKey('unit_snapshot')) {
      context.handle(
        _unitSnapshotMeta,
        unitSnapshot.isAcceptableOrUnknown(
          data['unit_snapshot']!,
          _unitSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitSnapshotMeta);
    }
    if (data.containsKey('unit_price_rial')) {
      context.handle(
        _unitPriceRialMeta,
        unitPriceRial.isAcceptableOrUnknown(
          data['unit_price_rial']!,
          _unitPriceRialMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitPriceRialMeta);
    }
    if (data.containsKey('quantity_milli')) {
      context.handle(
        _quantityMilliMeta,
        quantityMilli.isAcceptableOrUnknown(
          data['quantity_milli']!,
          _quantityMilliMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityMilliMeta);
    }
    if (data.containsKey('discount_rial')) {
      context.handle(
        _discountRialMeta,
        discountRial.isAcceptableOrUnknown(
          data['discount_rial']!,
          _discountRialMeta,
        ),
      );
    }
    if (data.containsKey('discount_percent_bp')) {
      context.handle(
        _discountPercentBpMeta,
        discountPercentBp.isAcceptableOrUnknown(
          data['discount_percent_bp']!,
          _discountPercentBpMeta,
        ),
      );
    }
    if (data.containsKey('resolved_tax_rate_bp')) {
      context.handle(
        _resolvedTaxRateBpMeta,
        resolvedTaxRateBp.isAcceptableOrUnknown(
          data['resolved_tax_rate_bp']!,
          _resolvedTaxRateBpMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resolvedTaxRateBpMeta);
    }
    if (data.containsKey('line_gross_rial')) {
      context.handle(
        _lineGrossRialMeta,
        lineGrossRial.isAcceptableOrUnknown(
          data['line_gross_rial']!,
          _lineGrossRialMeta,
        ),
      );
    }
    if (data.containsKey('allocated_invoice_discount_rial')) {
      context.handle(
        _allocatedInvoiceDiscountRialMeta,
        allocatedInvoiceDiscountRial.isAcceptableOrUnknown(
          data['allocated_invoice_discount_rial']!,
          _allocatedInvoiceDiscountRialMeta,
        ),
      );
    }
    if (data.containsKey('line_net_rial')) {
      context.handle(
        _lineNetRialMeta,
        lineNetRial.isAcceptableOrUnknown(
          data['line_net_rial']!,
          _lineNetRialMeta,
        ),
      );
    }
    if (data.containsKey('line_tax_rial')) {
      context.handle(
        _lineTaxRialMeta,
        lineTaxRial.isAcceptableOrUnknown(
          data['line_tax_rial']!,
          _lineTaxRialMeta,
        ),
      );
    }
    if (data.containsKey('line_total_rial')) {
      context.handle(
        _lineTotalRialMeta,
        lineTotalRial.isAcceptableOrUnknown(
          data['line_total_rial']!,
          _lineTotalRialMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: $InvoiceItemsTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      ),
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      titleSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_snapshot'],
      )!,
      unitSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_snapshot'],
      )!,
      unitPriceRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_rial'],
      )!,
      quantityMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_milli'],
      )!,
      discountRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_rial'],
      )!,
      discountPercentBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_percent_bp'],
      ),
      resolvedTaxRateBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resolved_tax_rate_bp'],
      )!,
      lineGrossRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_gross_rial'],
      ),
      allocatedInvoiceDiscountRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}allocated_invoice_discount_rial'],
      ),
      lineNetRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_net_rial'],
      )!,
      lineTaxRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_tax_rial'],
      )!,
      lineTotalRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_total_rial'],
      )!,
    );
  }

  @override
  $InvoiceItemsTable createAlias(String alias) {
    return $InvoiceItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatus>(SyncStatus.values);
}

class InvoiceItemRow extends DataClass implements Insertable<InvoiceItemRow> {
  /// UUID v4, never `AUTOINCREMENT`: integer keys allocated independently on
  /// two devices collide the moment those devices sync (D-001).
  final String id;

  /// Epoch milliseconds, UTC (D-005). Never a localized date string.
  final int createdAt;

  /// Bumped on every write. Repositories own this; it is not automatic.
  final int updatedAt;

  /// Soft delete (D-003). A hard delete cannot be propagated to another
  /// device, which would resurrect the row on the next sync. Every read must
  /// filter this -- see `soft_delete.dart`, the single place that expresses it.
  final int? deletedAt;
  final SyncStatus syncStatus;
  final int? lastSyncedAt;

  /// Cascades: an invoice item must never outlive its invoice. Invoice
  /// deletion itself is a soft delete; the cascade covers hard cleanup only
  ///.
  final String invoiceId;

  /// Nullable: a line may be typed freehand without a catalogue entry. Kept
  /// only for traceability -- it is never used to resolve price or title.
  final String? productId;

  /// Ordering within the invoice, so lines render as the user arranged them.
  final int position;
  final String titleSnapshot;
  final String unitSnapshot;
  final int unitPriceRial;

  /// Quantity scaled by 1000 (§4): `1.5` is stored as `1500`. Integer, so a
  /// fractional kilogram or hour never introduces floating point into the
  /// money path.
  final int quantityMilli;

  /// Absolute Rial. A percentage entered by the user is resolved to an amount
  /// at entry time and **both** are stored (§4 step 2).
  final int discountRial;
  final int? discountPercentBp;

  /// The tax rate that actually applied, resolved at creation time in the
  /// order item -> invoice -> settings default, and snapshotted here so a
  /// later settings change cannot alter an issued invoice (§4 step 6).
  final int resolvedTaxRateBp;

  /// `unitPrice x quantityMilli / 1000`, half-up -- **مبلغ کل** on the printed
  /// line, and the term every other figure on the row is measured from
  /// (D-055).
  ///
  /// Stored for the same reason [unitPriceRial] is a snapshot: §4 step 1
  /// carries a rounding rule, so a gross re-derived at render time is today's
  /// rule applied to a document issued under whatever rule was in force then.
  final int? lineGrossRial;

  /// This line's share of the invoice-level discount, allocated by largest
  /// remainder (§4 step 4).
  ///
  /// **Without it [lineNetRial] is unexplainable.** That column holds
  /// `netAfterInvoiceDiscount` -- the net after a deduction the header prints
  /// again -- so a document laying the two out beside each other reconciles
  /// nowhere unless the line says how much of the header's discount landed on
  /// it (D-055).
  final int? allocatedInvoiceDiscountRial;
  final int lineNetRial;
  final int lineTaxRial;
  final int lineTotalRial;
  const InvoiceItemRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    required this.invoiceId,
    this.productId,
    required this.position,
    required this.titleSnapshot,
    required this.unitSnapshot,
    required this.unitPriceRial,
    required this.quantityMilli,
    required this.discountRial,
    this.discountPercentBp,
    required this.resolvedTaxRateBp,
    this.lineGrossRial,
    this.allocatedInvoiceDiscountRial,
    required this.lineNetRial,
    required this.lineTaxRial,
    required this.lineTotalRial,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    {
      map['sync_status'] = Variable<int>(
        $InvoiceItemsTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    map['invoice_id'] = Variable<String>(invoiceId);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['position'] = Variable<int>(position);
    map['title_snapshot'] = Variable<String>(titleSnapshot);
    map['unit_snapshot'] = Variable<String>(unitSnapshot);
    map['unit_price_rial'] = Variable<int>(unitPriceRial);
    map['quantity_milli'] = Variable<int>(quantityMilli);
    map['discount_rial'] = Variable<int>(discountRial);
    if (!nullToAbsent || discountPercentBp != null) {
      map['discount_percent_bp'] = Variable<int>(discountPercentBp);
    }
    map['resolved_tax_rate_bp'] = Variable<int>(resolvedTaxRateBp);
    if (!nullToAbsent || lineGrossRial != null) {
      map['line_gross_rial'] = Variable<int>(lineGrossRial);
    }
    if (!nullToAbsent || allocatedInvoiceDiscountRial != null) {
      map['allocated_invoice_discount_rial'] = Variable<int>(
        allocatedInvoiceDiscountRial,
      );
    }
    map['line_net_rial'] = Variable<int>(lineNetRial);
    map['line_tax_rial'] = Variable<int>(lineTaxRial);
    map['line_total_rial'] = Variable<int>(lineTotalRial);
    return map;
  }

  InvoiceItemsCompanion toCompanion(bool nullToAbsent) {
    return InvoiceItemsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
: Value(deletedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
: Value(lastSyncedAt),
      invoiceId: Value(invoiceId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
: Value(productId),
      position: Value(position),
      titleSnapshot: Value(titleSnapshot),
      unitSnapshot: Value(unitSnapshot),
      unitPriceRial: Value(unitPriceRial),
      quantityMilli: Value(quantityMilli),
      discountRial: Value(discountRial),
      discountPercentBp: discountPercentBp == null && nullToAbsent
          ? const Value.absent()
: Value(discountPercentBp),
      resolvedTaxRateBp: Value(resolvedTaxRateBp),
      lineGrossRial: lineGrossRial == null && nullToAbsent
          ? const Value.absent()
: Value(lineGrossRial),
      allocatedInvoiceDiscountRial:
          allocatedInvoiceDiscountRial == null && nullToAbsent
          ? const Value.absent()
: Value(allocatedInvoiceDiscountRial),
      lineNetRial: Value(lineNetRial),
      lineTaxRial: Value(lineTaxRial),
      lineTotalRial: Value(lineTotalRial),
    );
  }

  factory InvoiceItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceItemRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      syncStatus: $InvoiceItemsTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      productId: serializer.fromJson<String?>(json['productId']),
      position: serializer.fromJson<int>(json['position']),
      titleSnapshot: serializer.fromJson<String>(json['titleSnapshot']),
      unitSnapshot: serializer.fromJson<String>(json['unitSnapshot']),
      unitPriceRial: serializer.fromJson<int>(json['unitPriceRial']),
      quantityMilli: serializer.fromJson<int>(json['quantityMilli']),
      discountRial: serializer.fromJson<int>(json['discountRial']),
      discountPercentBp: serializer.fromJson<int?>(json['discountPercentBp']),
      resolvedTaxRateBp: serializer.fromJson<int>(json['resolvedTaxRateBp']),
      lineGrossRial: serializer.fromJson<int?>(json['lineGrossRial']),
      allocatedInvoiceDiscountRial: serializer.fromJson<int?>(
        json['allocatedInvoiceDiscountRial'],
      ),
      lineNetRial: serializer.fromJson<int>(json['lineNetRial']),
      lineTaxRial: serializer.fromJson<int>(json['lineTaxRial']),
      lineTotalRial: serializer.fromJson<int>(json['lineTotalRial']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'syncStatus': serializer.toJson<int>(
        $InvoiceItemsTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'productId': serializer.toJson<String?>(productId),
      'position': serializer.toJson<int>(position),
      'titleSnapshot': serializer.toJson<String>(titleSnapshot),
      'unitSnapshot': serializer.toJson<String>(unitSnapshot),
      'unitPriceRial': serializer.toJson<int>(unitPriceRial),
      'quantityMilli': serializer.toJson<int>(quantityMilli),
      'discountRial': serializer.toJson<int>(discountRial),
      'discountPercentBp': serializer.toJson<int?>(discountPercentBp),
      'resolvedTaxRateBp': serializer.toJson<int>(resolvedTaxRateBp),
      'lineGrossRial': serializer.toJson<int?>(lineGrossRial),
      'allocatedInvoiceDiscountRial': serializer.toJson<int?>(
        allocatedInvoiceDiscountRial,
      ),
      'lineNetRial': serializer.toJson<int>(lineNetRial),
      'lineTaxRial': serializer.toJson<int>(lineTaxRial),
      'lineTotalRial': serializer.toJson<int>(lineTotalRial),
    };
  }

  InvoiceItemRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    SyncStatus? syncStatus,
    Value<int?> lastSyncedAt = const Value.absent(),
    String? invoiceId,
    Value<String?> productId = const Value.absent(),
    int? position,
    String? titleSnapshot,
    String? unitSnapshot,
    int? unitPriceRial,
    int? quantityMilli,
    int? discountRial,
    Value<int?> discountPercentBp = const Value.absent(),
    int? resolvedTaxRateBp,
    Value<int?> lineGrossRial = const Value.absent(),
    Value<int?> allocatedInvoiceDiscountRial = const Value.absent(),
    int? lineNetRial,
    int? lineTaxRial,
    int? lineTotalRial,
  }) => InvoiceItemRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    invoiceId: invoiceId ?? this.invoiceId,
    productId: productId.present ? productId.value : this.productId,
    position: position ?? this.position,
    titleSnapshot: titleSnapshot ?? this.titleSnapshot,
    unitSnapshot: unitSnapshot ?? this.unitSnapshot,
    unitPriceRial: unitPriceRial ?? this.unitPriceRial,
    quantityMilli: quantityMilli ?? this.quantityMilli,
    discountRial: discountRial ?? this.discountRial,
    discountPercentBp: discountPercentBp.present
        ? discountPercentBp.value
: this.discountPercentBp,
    resolvedTaxRateBp: resolvedTaxRateBp ?? this.resolvedTaxRateBp,
    lineGrossRial: lineGrossRial.present
        ? lineGrossRial.value
: this.lineGrossRial,
    allocatedInvoiceDiscountRial: allocatedInvoiceDiscountRial.present
        ? allocatedInvoiceDiscountRial.value
: this.allocatedInvoiceDiscountRial,
    lineNetRial: lineNetRial ?? this.lineNetRial,
    lineTaxRial: lineTaxRial ?? this.lineTaxRial,
    lineTotalRial: lineTotalRial ?? this.lineTotalRial,
  );
  InvoiceItemRow copyWithCompanion(InvoiceItemsCompanion data) {
    return InvoiceItemRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
: this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
: this.lastSyncedAt,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      productId: data.productId.present ? data.productId.value : this.productId,
      position: data.position.present ? data.position.value : this.position,
      titleSnapshot: data.titleSnapshot.present
          ? data.titleSnapshot.value
: this.titleSnapshot,
      unitSnapshot: data.unitSnapshot.present
          ? data.unitSnapshot.value
: this.unitSnapshot,
      unitPriceRial: data.unitPriceRial.present
          ? data.unitPriceRial.value
: this.unitPriceRial,
      quantityMilli: data.quantityMilli.present
          ? data.quantityMilli.value
: this.quantityMilli,
      discountRial: data.discountRial.present
          ? data.discountRial.value
: this.discountRial,
      discountPercentBp: data.discountPercentBp.present
          ? data.discountPercentBp.value
: this.discountPercentBp,
      resolvedTaxRateBp: data.resolvedTaxRateBp.present
          ? data.resolvedTaxRateBp.value
: this.resolvedTaxRateBp,
      lineGrossRial: data.lineGrossRial.present
          ? data.lineGrossRial.value
: this.lineGrossRial,
      allocatedInvoiceDiscountRial: data.allocatedInvoiceDiscountRial.present
          ? data.allocatedInvoiceDiscountRial.value
: this.allocatedInvoiceDiscountRial,
      lineNetRial: data.lineNetRial.present
          ? data.lineNetRial.value
: this.lineNetRial,
      lineTaxRial: data.lineTaxRial.present
          ? data.lineTaxRial.value
: this.lineTaxRial,
      lineTotalRial: data.lineTotalRial.present
          ? data.lineTotalRial.value
: this.lineTotalRial,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItemRow(')
..write('id: $id, ')
..write('createdAt: $createdAt, ')
..write('updatedAt: $updatedAt, ')
..write('deletedAt: $deletedAt, ')
..write('syncStatus: $syncStatus, ')
..write('lastSyncedAt: $lastSyncedAt, ')
..write('invoiceId: $invoiceId, ')
..write('productId: $productId, ')
..write('position: $position, ')
..write('titleSnapshot: $titleSnapshot, ')
..write('unitSnapshot: $unitSnapshot, ')
..write('unitPriceRial: $unitPriceRial, ')
..write('quantityMilli: $quantityMilli, ')
..write('discountRial: $discountRial, ')
..write('discountPercentBp: $discountPercentBp, ')
..write('resolvedTaxRateBp: $resolvedTaxRateBp, ')
..write('lineGrossRial: $lineGrossRial, ')
..write(
            'allocatedInvoiceDiscountRial: $allocatedInvoiceDiscountRial, ',
          )
..write('lineNetRial: $lineNetRial, ')
..write('lineTaxRial: $lineTaxRial, ')
..write('lineTotalRial: $lineTotalRial')
..write(')'))
.toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    lastSyncedAt,
    invoiceId,
    productId,
    position,
    titleSnapshot,
    unitSnapshot,
    unitPriceRial,
    quantityMilli,
    discountRial,
    discountPercentBp,
    resolvedTaxRateBp,
    lineGrossRial,
    allocatedInvoiceDiscountRial,
    lineNetRial,
    lineTaxRial,
    lineTotalRial,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceItemRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.invoiceId == this.invoiceId &&
          other.productId == this.productId &&
          other.position == this.position &&
          other.titleSnapshot == this.titleSnapshot &&
          other.unitSnapshot == this.unitSnapshot &&
          other.unitPriceRial == this.unitPriceRial &&
          other.quantityMilli == this.quantityMilli &&
          other.discountRial == this.discountRial &&
          other.discountPercentBp == this.discountPercentBp &&
          other.resolvedTaxRateBp == this.resolvedTaxRateBp &&
          other.lineGrossRial == this.lineGrossRial &&
          other.allocatedInvoiceDiscountRial ==
              this.allocatedInvoiceDiscountRial &&
          other.lineNetRial == this.lineNetRial &&
          other.lineTaxRial == this.lineTaxRial &&
          other.lineTotalRial == this.lineTotalRial);
}

class InvoiceItemsCompanion extends UpdateCompanion<InvoiceItemRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int?> lastSyncedAt;
  final Value<String> invoiceId;
  final Value<String?> productId;
  final Value<int> position;
  final Value<String> titleSnapshot;
  final Value<String> unitSnapshot;
  final Value<int> unitPriceRial;
  final Value<int> quantityMilli;
  final Value<int> discountRial;
  final Value<int?> discountPercentBp;
  final Value<int> resolvedTaxRateBp;
  final Value<int?> lineGrossRial;
  final Value<int?> allocatedInvoiceDiscountRial;
  final Value<int> lineNetRial;
  final Value<int> lineTaxRial;
  final Value<int> lineTotalRial;
  final Value<int> rowid;
  const InvoiceItemsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.productId = const Value.absent(),
    this.position = const Value.absent(),
    this.titleSnapshot = const Value.absent(),
    this.unitSnapshot = const Value.absent(),
    this.unitPriceRial = const Value.absent(),
    this.quantityMilli = const Value.absent(),
    this.discountRial = const Value.absent(),
    this.discountPercentBp = const Value.absent(),
    this.resolvedTaxRateBp = const Value.absent(),
    this.lineGrossRial = const Value.absent(),
    this.allocatedInvoiceDiscountRial = const Value.absent(),
    this.lineNetRial = const Value.absent(),
    this.lineTaxRial = const Value.absent(),
    this.lineTotalRial = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoiceItemsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    required String invoiceId,
    this.productId = const Value.absent(),
    this.position = const Value.absent(),
    required String titleSnapshot,
    required String unitSnapshot,
    required int unitPriceRial,
    required int quantityMilli,
    this.discountRial = const Value.absent(),
    this.discountPercentBp = const Value.absent(),
    required int resolvedTaxRateBp,
    this.lineGrossRial = const Value.absent(),
    this.allocatedInvoiceDiscountRial = const Value.absent(),
    this.lineNetRial = const Value.absent(),
    this.lineTaxRial = const Value.absent(),
    this.lineTotalRial = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : invoiceId = Value(invoiceId),
       titleSnapshot = Value(titleSnapshot),
       unitSnapshot = Value(unitSnapshot),
       unitPriceRial = Value(unitPriceRial),
       quantityMilli = Value(quantityMilli),
       resolvedTaxRateBp = Value(resolvedTaxRateBp);
  static Insertable<InvoiceItemRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? lastSyncedAt,
    Expression<String>? invoiceId,
    Expression<String>? productId,
    Expression<int>? position,
    Expression<String>? titleSnapshot,
    Expression<String>? unitSnapshot,
    Expression<int>? unitPriceRial,
    Expression<int>? quantityMilli,
    Expression<int>? discountRial,
    Expression<int>? discountPercentBp,
    Expression<int>? resolvedTaxRateBp,
    Expression<int>? lineGrossRial,
    Expression<int>? allocatedInvoiceDiscountRial,
    Expression<int>? lineNetRial,
    Expression<int>? lineTaxRial,
    Expression<int>? lineTotalRial,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (productId != null) 'product_id': productId,
      if (position != null) 'position': position,
      if (titleSnapshot != null) 'title_snapshot': titleSnapshot,
      if (unitSnapshot != null) 'unit_snapshot': unitSnapshot,
      if (unitPriceRial != null) 'unit_price_rial': unitPriceRial,
      if (quantityMilli != null) 'quantity_milli': quantityMilli,
      if (discountRial != null) 'discount_rial': discountRial,
      if (discountPercentBp != null) 'discount_percent_bp': discountPercentBp,
      if (resolvedTaxRateBp != null) 'resolved_tax_rate_bp': resolvedTaxRateBp,
      if (lineGrossRial != null) 'line_gross_rial': lineGrossRial,
      if (allocatedInvoiceDiscountRial != null)
        'allocated_invoice_discount_rial': allocatedInvoiceDiscountRial,
      if (lineNetRial != null) 'line_net_rial': lineNetRial,
      if (lineTaxRial != null) 'line_tax_rial': lineTaxRial,
      if (lineTotalRial != null) 'line_total_rial': lineTotalRial,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoiceItemsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<SyncStatus>? syncStatus,
    Value<int?>? lastSyncedAt,
    Value<String>? invoiceId,
    Value<String?>? productId,
    Value<int>? position,
    Value<String>? titleSnapshot,
    Value<String>? unitSnapshot,
    Value<int>? unitPriceRial,
    Value<int>? quantityMilli,
    Value<int>? discountRial,
    Value<int?>? discountPercentBp,
    Value<int>? resolvedTaxRateBp,
    Value<int?>? lineGrossRial,
    Value<int?>? allocatedInvoiceDiscountRial,
    Value<int>? lineNetRial,
    Value<int>? lineTaxRial,
    Value<int>? lineTotalRial,
    Value<int>? rowid,
  }) {
    return InvoiceItemsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      position: position ?? this.position,
      titleSnapshot: titleSnapshot ?? this.titleSnapshot,
      unitSnapshot: unitSnapshot ?? this.unitSnapshot,
      unitPriceRial: unitPriceRial ?? this.unitPriceRial,
      quantityMilli: quantityMilli ?? this.quantityMilli,
      discountRial: discountRial ?? this.discountRial,
      discountPercentBp: discountPercentBp ?? this.discountPercentBp,
      resolvedTaxRateBp: resolvedTaxRateBp ?? this.resolvedTaxRateBp,
      lineGrossRial: lineGrossRial ?? this.lineGrossRial,
      allocatedInvoiceDiscountRial:
          allocatedInvoiceDiscountRial ?? this.allocatedInvoiceDiscountRial,
      lineNetRial: lineNetRial ?? this.lineNetRial,
      lineTaxRial: lineTaxRial ?? this.lineTaxRial,
      lineTotalRial: lineTotalRial ?? this.lineTotalRial,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $InvoiceItemsTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (titleSnapshot.present) {
      map['title_snapshot'] = Variable<String>(titleSnapshot.value);
    }
    if (unitSnapshot.present) {
      map['unit_snapshot'] = Variable<String>(unitSnapshot.value);
    }
    if (unitPriceRial.present) {
      map['unit_price_rial'] = Variable<int>(unitPriceRial.value);
    }
    if (quantityMilli.present) {
      map['quantity_milli'] = Variable<int>(quantityMilli.value);
    }
    if (discountRial.present) {
      map['discount_rial'] = Variable<int>(discountRial.value);
    }
    if (discountPercentBp.present) {
      map['discount_percent_bp'] = Variable<int>(discountPercentBp.value);
    }
    if (resolvedTaxRateBp.present) {
      map['resolved_tax_rate_bp'] = Variable<int>(resolvedTaxRateBp.value);
    }
    if (lineGrossRial.present) {
      map['line_gross_rial'] = Variable<int>(lineGrossRial.value);
    }
    if (allocatedInvoiceDiscountRial.present) {
      map['allocated_invoice_discount_rial'] = Variable<int>(
        allocatedInvoiceDiscountRial.value,
      );
    }
    if (lineNetRial.present) {
      map['line_net_rial'] = Variable<int>(lineNetRial.value);
    }
    if (lineTaxRial.present) {
      map['line_tax_rial'] = Variable<int>(lineTaxRial.value);
    }
    if (lineTotalRial.present) {
      map['line_total_rial'] = Variable<int>(lineTotalRial.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItemsCompanion(')
..write('id: $id, ')
..write('createdAt: $createdAt, ')
..write('updatedAt: $updatedAt, ')
..write('deletedAt: $deletedAt, ')
..write('syncStatus: $syncStatus, ')
..write('lastSyncedAt: $lastSyncedAt, ')
..write('invoiceId: $invoiceId, ')
..write('productId: $productId, ')
..write('position: $position, ')
..write('titleSnapshot: $titleSnapshot, ')
..write('unitSnapshot: $unitSnapshot, ')
..write('unitPriceRial: $unitPriceRial, ')
..write('quantityMilli: $quantityMilli, ')
..write('discountRial: $discountRial, ')
..write('discountPercentBp: $discountPercentBp, ')
..write('resolvedTaxRateBp: $resolvedTaxRateBp, ')
..write('lineGrossRial: $lineGrossRial, ')
..write(
            'allocatedInvoiceDiscountRial: $allocatedInvoiceDiscountRial, ',
          )
..write('lineNetRial: $lineNetRial, ')
..write('lineTaxRial: $lineTaxRial, ')
..write('lineTotalRial: $lineTotalRial, ')
..write('rowid: $rowid')
..write(')'))
.toString();
  }
}

class $PaymentsTable extends Payments
    with TableInfo<$PaymentsTable, PaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV4,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: nowMillis,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: nowMillis,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SyncStatus>($PaymentsTable.$convertersyncStatus);
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES invoices (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _amountRialMeta = const VerificationMeta(
    'amountRial',
  );
  @override
  late final GeneratedColumn<int> amountRial = GeneratedColumn<int>(
    'amount_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<int> paidAt = GeneratedColumn<int>(
    'paid_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PaymentMethod, int> method =
      GeneratedColumn<int>(
        'method',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<PaymentMethod>($PaymentsTable.$convertermethod);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    lastSyncedAt,
    invoiceId,
    amountRial,
    paidAt,
    method,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('amount_rial')) {
      context.handle(
        _amountRialMeta,
        amountRial.isAcceptableOrUnknown(data['amount_rial']!, _amountRialMeta),
      );
    } else if (isInserting) {
      context.missing(_amountRialMeta);
    }
    if (data.containsKey('paid_at')) {
      context.handle(
        _paidAtMeta,
        paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta),
      );
    } else if (isInserting) {
      context.missing(_paidAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: $PaymentsTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      ),
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_id'],
      )!,
      amountRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_rial'],
      )!,
      paidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_at'],
      )!,
      method: $PaymentsTable.$convertermethod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}method'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatus>(SyncStatus.values);
  static JsonTypeConverter2<PaymentMethod, int, int> $convertermethod =
      const EnumIndexConverter<PaymentMethod>(PaymentMethod.values);
}

class PaymentRow extends DataClass implements Insertable<PaymentRow> {
  /// UUID v4, never `AUTOINCREMENT`: integer keys allocated independently on
  /// two devices collide the moment those devices sync (D-001).
  final String id;

  /// Epoch milliseconds, UTC (D-005). Never a localized date string.
  final int createdAt;

  /// Bumped on every write. Repositories own this; it is not automatic.
  final int updatedAt;

  /// Soft delete (D-003). A hard delete cannot be propagated to another
  /// device, which would resurrect the row on the next sync. Every read must
  /// filter this -- see `soft_delete.dart`, the single place that expresses it.
  final int? deletedAt;
  final SyncStatus syncStatus;
  final int? lastSyncedAt;
  final String invoiceId;

  /// Integer Rial (D-002).
  final int amountRial;

  /// Epoch milliseconds, UTC (D-005).
  final int paidAt;
  final PaymentMethod method;
  final String? note;
  const PaymentRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    required this.invoiceId,
    required this.amountRial,
    required this.paidAt,
    required this.method,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    {
      map['sync_status'] = Variable<int>(
        $PaymentsTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    map['invoice_id'] = Variable<String>(invoiceId);
    map['amount_rial'] = Variable<int>(amountRial);
    map['paid_at'] = Variable<int>(paidAt);
    {
      map['method'] = Variable<int>(
        $PaymentsTable.$convertermethod.toSql(method),
      );
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
: Value(deletedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
: Value(lastSyncedAt),
      invoiceId: Value(invoiceId),
      amountRial: Value(amountRial),
      paidAt: Value(paidAt),
      method: Value(method),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory PaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      syncStatus: $PaymentsTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      amountRial: serializer.fromJson<int>(json['amountRial']),
      paidAt: serializer.fromJson<int>(json['paidAt']),
      method: $PaymentsTable.$convertermethod.fromJson(
        serializer.fromJson<int>(json['method']),
      ),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'syncStatus': serializer.toJson<int>(
        $PaymentsTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'amountRial': serializer.toJson<int>(amountRial),
      'paidAt': serializer.toJson<int>(paidAt),
      'method': serializer.toJson<int>(
        $PaymentsTable.$convertermethod.toJson(method),
      ),
      'note': serializer.toJson<String?>(note),
    };
  }

  PaymentRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    SyncStatus? syncStatus,
    Value<int?> lastSyncedAt = const Value.absent(),
    String? invoiceId,
    int? amountRial,
    int? paidAt,
    PaymentMethod? method,
    Value<String?> note = const Value.absent(),
  }) => PaymentRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    invoiceId: invoiceId ?? this.invoiceId,
    amountRial: amountRial ?? this.amountRial,
    paidAt: paidAt ?? this.paidAt,
    method: method ?? this.method,
    note: note.present ? note.value : this.note,
  );
  PaymentRow copyWithCompanion(PaymentsCompanion data) {
    return PaymentRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
: this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
: this.lastSyncedAt,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      amountRial: data.amountRial.present
          ? data.amountRial.value
: this.amountRial,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      method: data.method.present ? data.method.value : this.method,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentRow(')
..write('id: $id, ')
..write('createdAt: $createdAt, ')
..write('updatedAt: $updatedAt, ')
..write('deletedAt: $deletedAt, ')
..write('syncStatus: $syncStatus, ')
..write('lastSyncedAt: $lastSyncedAt, ')
..write('invoiceId: $invoiceId, ')
..write('amountRial: $amountRial, ')
..write('paidAt: $paidAt, ')
..write('method: $method, ')
..write('note: $note')
..write(')'))
.toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    lastSyncedAt,
    invoiceId,
    amountRial,
    paidAt,
    method,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.invoiceId == this.invoiceId &&
          other.amountRial == this.amountRial &&
          other.paidAt == this.paidAt &&
          other.method == this.method &&
          other.note == this.note);
}

class PaymentsCompanion extends UpdateCompanion<PaymentRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int?> lastSyncedAt;
  final Value<String> invoiceId;
  final Value<int> amountRial;
  final Value<int> paidAt;
  final Value<PaymentMethod> method;
  final Value<String?> note;
  final Value<int> rowid;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.amountRial = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.method = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    required String invoiceId,
    required int amountRial,
    required int paidAt,
    required PaymentMethod method,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : invoiceId = Value(invoiceId),
       amountRial = Value(amountRial),
       paidAt = Value(paidAt),
       method = Value(method);
  static Insertable<PaymentRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? lastSyncedAt,
    Expression<String>? invoiceId,
    Expression<int>? amountRial,
    Expression<int>? paidAt,
    Expression<int>? method,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (amountRial != null) 'amount_rial': amountRial,
      if (paidAt != null) 'paid_at': paidAt,
      if (method != null) 'method': method,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<SyncStatus>? syncStatus,
    Value<int?>? lastSyncedAt,
    Value<String>? invoiceId,
    Value<int>? amountRial,
    Value<int>? paidAt,
    Value<PaymentMethod>? method,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return PaymentsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      invoiceId: invoiceId ?? this.invoiceId,
      amountRial: amountRial ?? this.amountRial,
      paidAt: paidAt ?? this.paidAt,
      method: method ?? this.method,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $PaymentsTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (amountRial.present) {
      map['amount_rial'] = Variable<int>(amountRial.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<int>(paidAt.value);
    }
    if (method.present) {
      map['method'] = Variable<int>(
        $PaymentsTable.$convertermethod.toSql(method.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
..write('id: $id, ')
..write('createdAt: $createdAt, ')
..write('updatedAt: $updatedAt, ')
..write('deletedAt: $deletedAt, ')
..write('syncStatus: $syncStatus, ')
..write('lastSyncedAt: $lastSyncedAt, ')
..write('invoiceId: $invoiceId, ')
..write('amountRial: $amountRial, ')
..write('paidAt: $paidAt, ')
..write('method: $method, ')
..write('note: $note, ')
..write('rowid: $rowid')
..write(')'))
.toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV4,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: nowMillis,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: nowMillis,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<SyncStatus>($SettingsTable.$convertersyncStatus);
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _singletonMeta = const VerificationMeta(
    'singleton',
  );
  @override
  late final GeneratedColumn<int> singleton = GeneratedColumn<int>(
    'singleton',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _defaultTaxRateBpMeta = const VerificationMeta(
    'defaultTaxRateBp',
  );
  @override
  late final GeneratedColumn<int> defaultTaxRateBp = GeneratedColumn<int>(
    'default_tax_rate_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1000),
  );
  static const VerificationMeta _roundingUnitRialMeta = const VerificationMeta(
    'roundingUnitRial',
  );
  @override
  late final GeneratedColumn<int> roundingUnitRial = GeneratedColumn<int>(
    'rounding_unit_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paymentTermDaysMeta = const VerificationMeta(
    'paymentTermDays',
  );
  @override
  late final GeneratedColumn<int> paymentTermDays = GeneratedColumn<int>(
    'payment_term_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _invoiceNumberPrefixMeta =
      const VerificationMeta('invoiceNumberPrefix');
  @override
  late final GeneratedColumn<String> invoiceNumberPrefix =
      GeneratedColumn<String>(
        'invoice_number_prefix',
        aliasedName,
        false,
        additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 1,
          maxTextLength: 12,
        ),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('INV'),
      );
  static const VerificationMeta _devicePrefixMeta = const VerificationMeta(
    'devicePrefix',
  );
  @override
  late final GeneratedColumn<String> devicePrefix = GeneratedColumn<String>(
    'device_prefix',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 8),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastBackupAtMeta = const VerificationMeta(
    'lastBackupAt',
  );
  @override
  late final GeneratedColumn<int> lastBackupAt = GeneratedColumn<int>(
    'last_backup_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sellerNameMeta = const VerificationMeta(
    'sellerName',
  );
  @override
  late final GeneratedColumn<String> sellerName = GeneratedColumn<String>(
    'seller_name',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 160),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sellerEconomicIdMeta = const VerificationMeta(
    'sellerEconomicId',
  );
  @override
  late final GeneratedColumn<String> sellerEconomicId = GeneratedColumn<String>(
    'seller_economic_id',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sellerAddressMeta = const VerificationMeta(
    'sellerAddress',
  );
  @override
  late final GeneratedColumn<String> sellerAddress = GeneratedColumn<String>(
    'seller_address',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sellerPhoneMeta = const VerificationMeta(
    'sellerPhone',
  );
  @override
  late final GeneratedColumn<String> sellerPhone = GeneratedColumn<String>(
    'seller_phone',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    lastSyncedAt,
    singleton,
    defaultTaxRateBp,
    roundingUnitRial,
    paymentTermDays,
    invoiceNumberPrefix,
    devicePrefix,
    lastBackupAt,
    sellerName,
    sellerEconomicId,
    sellerAddress,
    sellerPhone,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('singleton')) {
      context.handle(
        _singletonMeta,
        singleton.isAcceptableOrUnknown(data['singleton']!, _singletonMeta),
      );
    }
    if (data.containsKey('default_tax_rate_bp')) {
      context.handle(
        _defaultTaxRateBpMeta,
        defaultTaxRateBp.isAcceptableOrUnknown(
          data['default_tax_rate_bp']!,
          _defaultTaxRateBpMeta,
        ),
      );
    }
    if (data.containsKey('rounding_unit_rial')) {
      context.handle(
        _roundingUnitRialMeta,
        roundingUnitRial.isAcceptableOrUnknown(
          data['rounding_unit_rial']!,
          _roundingUnitRialMeta,
        ),
      );
    }
    if (data.containsKey('payment_term_days')) {
      context.handle(
        _paymentTermDaysMeta,
        paymentTermDays.isAcceptableOrUnknown(
          data['payment_term_days']!,
          _paymentTermDaysMeta,
        ),
      );
    }
    if (data.containsKey('invoice_number_prefix')) {
      context.handle(
        _invoiceNumberPrefixMeta,
        invoiceNumberPrefix.isAcceptableOrUnknown(
          data['invoice_number_prefix']!,
          _invoiceNumberPrefixMeta,
        ),
      );
    }
    if (data.containsKey('device_prefix')) {
      context.handle(
        _devicePrefixMeta,
        devicePrefix.isAcceptableOrUnknown(
          data['device_prefix']!,
          _devicePrefixMeta,
        ),
      );
    }
    if (data.containsKey('last_backup_at')) {
      context.handle(
        _lastBackupAtMeta,
        lastBackupAt.isAcceptableOrUnknown(
          data['last_backup_at']!,
          _lastBackupAtMeta,
        ),
      );
    }
    if (data.containsKey('seller_name')) {
      context.handle(
        _sellerNameMeta,
        sellerName.isAcceptableOrUnknown(data['seller_name']!, _sellerNameMeta),
      );
    }
    if (data.containsKey('seller_economic_id')) {
      context.handle(
        _sellerEconomicIdMeta,
        sellerEconomicId.isAcceptableOrUnknown(
          data['seller_economic_id']!,
          _sellerEconomicIdMeta,
        ),
      );
    }
    if (data.containsKey('seller_address')) {
      context.handle(
        _sellerAddressMeta,
        sellerAddress.isAcceptableOrUnknown(
          data['seller_address']!,
          _sellerAddressMeta,
        ),
      );
    }
    if (data.containsKey('seller_phone')) {
      context.handle(
        _sellerPhoneMeta,
        sellerPhone.isAcceptableOrUnknown(
          data['seller_phone']!,
          _sellerPhoneMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: $SettingsTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      ),
      singleton: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton'],
      )!,
      defaultTaxRateBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_tax_rate_bp'],
      )!,
      roundingUnitRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rounding_unit_rial'],
      )!,
      paymentTermDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_term_days'],
      )!,
      invoiceNumberPrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_number_prefix'],
      )!,
      devicePrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_prefix'],
      ),
      lastBackupAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_backup_at'],
      ),
      sellerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seller_name'],
      ),
      sellerEconomicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seller_economic_id'],
      ),
      sellerAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seller_address'],
      ),
      sellerPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seller_phone'],
      ),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatus>(SyncStatus.values);
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  /// UUID v4, never `AUTOINCREMENT`: integer keys allocated independently on
  /// two devices collide the moment those devices sync (D-001).
  final String id;

  /// Epoch milliseconds, UTC (D-005). Never a localized date string.
  final int createdAt;

  /// Bumped on every write. Repositories own this; it is not automatic.
  final int updatedAt;

  /// Soft delete (D-003). A hard delete cannot be propagated to another
  /// device, which would resurrect the row on the next sync. Every read must
  /// filter this -- see `soft_delete.dart`, the single place that expresses it.
  final int? deletedAt;
  final SyncStatus syncStatus;
  final int? lastSyncedAt;
  final int singleton;

  /// Default VAT rate in basis points, e.g. 10% = 1000. Configurable, never
  /// hardcoded, and changing it must not alter existing invoices -- which is
  /// why the resolved rate is snapshotted onto each item (§4).
  final int defaultTaxRateBp;

  /// Round the grand total to the nearest N Rial. `0` disables it (§4).
  final int roundingUnitRial;

  /// How many days after issue an invoice is due, by default (D-052).
  ///
  /// A payment term is a property of the business, not of the application. It
  /// was a 30-day constant in `features/invoices/domain/` until v3, which is
  /// correct for most Iranian businesses and wrong for every one that bills on
  /// 45 or 60 days -- and wrong invisibly, because a due date thirty days out
  /// looks deliberate.
  ///
  /// The literal `30` here rather than `kDefaultPaymentTermDays`, for the
  /// reason `withLength(max:)` cannot take a constant either: `drift_dev` reads
  /// this argument from the source expression, and what it does with a named
  /// constant is not something to find out from a shipped default.
  /// `field_limits_test.dart` asserts the generated default equals the
  /// constant, which is the same trade the length limits make.
  final int paymentTermDays;

  /// The `{prefix}` in `{prefix}-{jalaliYear}-{sequence:0000}` (D-013).
  final String invoiceNumberPrefix;

  /// Reserved for the multi-device numbering collision that cloud sync will
  /// introduce (D-013). Unused in Phase 1 and deliberately present: once two
  /// devices allocate numbers independently, the prefix is what keeps them
  /// apart, and adding the column then would mean migrating live data.
  final String? devicePrefix;

  /// Epoch milliseconds of the last successful export. Drives the backup
  /// reminder -- an offline-only financial app whose user has
  /// never made a backup is one lost phone away from losing the business.
  final int? lastBackupAt;

  /// The business name, as it appears on the document. The identifying field:
  /// the form requires it as soon as any other seller field is filled, and the
  /// document prints no block without it (D-077).
  final String? sellerName;

  /// کد اقتصادی of the issuing business. Optional -- plenty of the businesses
  /// this application is for do not have one.
  final String? sellerEconomicId;
  final String? sellerAddress;

  /// Kept as typed, deliberately not normalized to the `09xxxxxxxxx` mobile
  /// shape §9 defines for a customer: a seller's published number is as often
  /// a landline with an area code, and rewriting it would be the application
  /// overruling the user about their own letterhead.
  final String? sellerPhone;
  const SettingsRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    required this.singleton,
    required this.defaultTaxRateBp,
    required this.roundingUnitRial,
    required this.paymentTermDays,
    required this.invoiceNumberPrefix,
    this.devicePrefix,
    this.lastBackupAt,
    this.sellerName,
    this.sellerEconomicId,
    this.sellerAddress,
    this.sellerPhone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    {
      map['sync_status'] = Variable<int>(
        $SettingsTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    map['singleton'] = Variable<int>(singleton);
    map['default_tax_rate_bp'] = Variable<int>(defaultTaxRateBp);
    map['rounding_unit_rial'] = Variable<int>(roundingUnitRial);
    map['payment_term_days'] = Variable<int>(paymentTermDays);
    map['invoice_number_prefix'] = Variable<String>(invoiceNumberPrefix);
    if (!nullToAbsent || devicePrefix != null) {
      map['device_prefix'] = Variable<String>(devicePrefix);
    }
    if (!nullToAbsent || lastBackupAt != null) {
      map['last_backup_at'] = Variable<int>(lastBackupAt);
    }
    if (!nullToAbsent || sellerName != null) {
      map['seller_name'] = Variable<String>(sellerName);
    }
    if (!nullToAbsent || sellerEconomicId != null) {
      map['seller_economic_id'] = Variable<String>(sellerEconomicId);
    }
    if (!nullToAbsent || sellerAddress != null) {
      map['seller_address'] = Variable<String>(sellerAddress);
    }
    if (!nullToAbsent || sellerPhone != null) {
      map['seller_phone'] = Variable<String>(sellerPhone);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
: Value(deletedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
: Value(lastSyncedAt),
      singleton: Value(singleton),
      defaultTaxRateBp: Value(defaultTaxRateBp),
      roundingUnitRial: Value(roundingUnitRial),
      paymentTermDays: Value(paymentTermDays),
      invoiceNumberPrefix: Value(invoiceNumberPrefix),
      devicePrefix: devicePrefix == null && nullToAbsent
          ? const Value.absent()
: Value(devicePrefix),
      lastBackupAt: lastBackupAt == null && nullToAbsent
          ? const Value.absent()
: Value(lastBackupAt),
      sellerName: sellerName == null && nullToAbsent
          ? const Value.absent()
: Value(sellerName),
      sellerEconomicId: sellerEconomicId == null && nullToAbsent
          ? const Value.absent()
: Value(sellerEconomicId),
      sellerAddress: sellerAddress == null && nullToAbsent
          ? const Value.absent()
: Value(sellerAddress),
      sellerPhone: sellerPhone == null && nullToAbsent
          ? const Value.absent()
: Value(sellerPhone),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      syncStatus: $SettingsTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
      singleton: serializer.fromJson<int>(json['singleton']),
      defaultTaxRateBp: serializer.fromJson<int>(json['defaultTaxRateBp']),
      roundingUnitRial: serializer.fromJson<int>(json['roundingUnitRial']),
      paymentTermDays: serializer.fromJson<int>(json['paymentTermDays']),
      invoiceNumberPrefix: serializer.fromJson<String>(
        json['invoiceNumberPrefix'],
      ),
      devicePrefix: serializer.fromJson<String?>(json['devicePrefix']),
      lastBackupAt: serializer.fromJson<int?>(json['lastBackupAt']),
      sellerName: serializer.fromJson<String?>(json['sellerName']),
      sellerEconomicId: serializer.fromJson<String?>(json['sellerEconomicId']),
      sellerAddress: serializer.fromJson<String?>(json['sellerAddress']),
      sellerPhone: serializer.fromJson<String?>(json['sellerPhone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'syncStatus': serializer.toJson<int>(
        $SettingsTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'singleton': serializer.toJson<int>(singleton),
      'defaultTaxRateBp': serializer.toJson<int>(defaultTaxRateBp),
      'roundingUnitRial': serializer.toJson<int>(roundingUnitRial),
      'paymentTermDays': serializer.toJson<int>(paymentTermDays),
      'invoiceNumberPrefix': serializer.toJson<String>(invoiceNumberPrefix),
      'devicePrefix': serializer.toJson<String?>(devicePrefix),
      'lastBackupAt': serializer.toJson<int?>(lastBackupAt),
      'sellerName': serializer.toJson<String?>(sellerName),
      'sellerEconomicId': serializer.toJson<String?>(sellerEconomicId),
      'sellerAddress': serializer.toJson<String?>(sellerAddress),
      'sellerPhone': serializer.toJson<String?>(sellerPhone),
    };
  }

  SettingsRow copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    SyncStatus? syncStatus,
    Value<int?> lastSyncedAt = const Value.absent(),
    int? singleton,
    int? defaultTaxRateBp,
    int? roundingUnitRial,
    int? paymentTermDays,
    String? invoiceNumberPrefix,
    Value<String?> devicePrefix = const Value.absent(),
    Value<int?> lastBackupAt = const Value.absent(),
    Value<String?> sellerName = const Value.absent(),
    Value<String?> sellerEconomicId = const Value.absent(),
    Value<String?> sellerAddress = const Value.absent(),
    Value<String?> sellerPhone = const Value.absent(),
  }) => SettingsRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    singleton: singleton ?? this.singleton,
    defaultTaxRateBp: defaultTaxRateBp ?? this.defaultTaxRateBp,
    roundingUnitRial: roundingUnitRial ?? this.roundingUnitRial,
    paymentTermDays: paymentTermDays ?? this.paymentTermDays,
    invoiceNumberPrefix: invoiceNumberPrefix ?? this.invoiceNumberPrefix,
    devicePrefix: devicePrefix.present ? devicePrefix.value : this.devicePrefix,
    lastBackupAt: lastBackupAt.present ? lastBackupAt.value : this.lastBackupAt,
    sellerName: sellerName.present ? sellerName.value : this.sellerName,
    sellerEconomicId: sellerEconomicId.present
        ? sellerEconomicId.value
: this.sellerEconomicId,
    sellerAddress: sellerAddress.present
        ? sellerAddress.value
: this.sellerAddress,
    sellerPhone: sellerPhone.present ? sellerPhone.value : this.sellerPhone,
  );
  SettingsRow copyWithCompanion(SettingsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
: this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
: this.lastSyncedAt,
      singleton: data.singleton.present ? data.singleton.value : this.singleton,
      defaultTaxRateBp: data.defaultTaxRateBp.present
          ? data.defaultTaxRateBp.value
: this.defaultTaxRateBp,
      roundingUnitRial: data.roundingUnitRial.present
          ? data.roundingUnitRial.value
: this.roundingUnitRial,
      paymentTermDays: data.paymentTermDays.present
          ? data.paymentTermDays.value
: this.paymentTermDays,
      invoiceNumberPrefix: data.invoiceNumberPrefix.present
          ? data.invoiceNumberPrefix.value
: this.invoiceNumberPrefix,
      devicePrefix: data.devicePrefix.present
          ? data.devicePrefix.value
: this.devicePrefix,
      lastBackupAt: data.lastBackupAt.present
          ? data.lastBackupAt.value
: this.lastBackupAt,
      sellerName: data.sellerName.present
          ? data.sellerName.value
: this.sellerName,
      sellerEconomicId: data.sellerEconomicId.present
          ? data.sellerEconomicId.value
: this.sellerEconomicId,
      sellerAddress: data.sellerAddress.present
          ? data.sellerAddress.value
: this.sellerAddress,
      sellerPhone: data.sellerPhone.present
          ? data.sellerPhone.value
: this.sellerPhone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
..write('id: $id, ')
..write('createdAt: $createdAt, ')
..write('updatedAt: $updatedAt, ')
..write('deletedAt: $deletedAt, ')
..write('syncStatus: $syncStatus, ')
..write('lastSyncedAt: $lastSyncedAt, ')
..write('singleton: $singleton, ')
..write('defaultTaxRateBp: $defaultTaxRateBp, ')
..write('roundingUnitRial: $roundingUnitRial, ')
..write('paymentTermDays: $paymentTermDays, ')
..write('invoiceNumberPrefix: $invoiceNumberPrefix, ')
..write('devicePrefix: $devicePrefix, ')
..write('lastBackupAt: $lastBackupAt, ')
..write('sellerName: $sellerName, ')
..write('sellerEconomicId: $sellerEconomicId, ')
..write('sellerAddress: $sellerAddress, ')
..write('sellerPhone: $sellerPhone')
..write(')'))
.toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    lastSyncedAt,
    singleton,
    defaultTaxRateBp,
    roundingUnitRial,
    paymentTermDays,
    invoiceNumberPrefix,
    devicePrefix,
    lastBackupAt,
    sellerName,
    sellerEconomicId,
    sellerAddress,
    sellerPhone,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.singleton == this.singleton &&
          other.defaultTaxRateBp == this.defaultTaxRateBp &&
          other.roundingUnitRial == this.roundingUnitRial &&
          other.paymentTermDays == this.paymentTermDays &&
          other.invoiceNumberPrefix == this.invoiceNumberPrefix &&
          other.devicePrefix == this.devicePrefix &&
          other.lastBackupAt == this.lastBackupAt &&
          other.sellerName == this.sellerName &&
          other.sellerEconomicId == this.sellerEconomicId &&
          other.sellerAddress == this.sellerAddress &&
          other.sellerPhone == this.sellerPhone);
}

class SettingsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int?> lastSyncedAt;
  final Value<int> singleton;
  final Value<int> defaultTaxRateBp;
  final Value<int> roundingUnitRial;
  final Value<int> paymentTermDays;
  final Value<String> invoiceNumberPrefix;
  final Value<String?> devicePrefix;
  final Value<int?> lastBackupAt;
  final Value<String?> sellerName;
  final Value<String?> sellerEconomicId;
  final Value<String?> sellerAddress;
  final Value<String?> sellerPhone;
  final Value<int> rowid;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.singleton = const Value.absent(),
    this.defaultTaxRateBp = const Value.absent(),
    this.roundingUnitRial = const Value.absent(),
    this.paymentTermDays = const Value.absent(),
    this.invoiceNumberPrefix = const Value.absent(),
    this.devicePrefix = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
    this.sellerName = const Value.absent(),
    this.sellerEconomicId = const Value.absent(),
    this.sellerAddress = const Value.absent(),
    this.sellerPhone = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.singleton = const Value.absent(),
    this.defaultTaxRateBp = const Value.absent(),
    this.roundingUnitRial = const Value.absent(),
    this.paymentTermDays = const Value.absent(),
    this.invoiceNumberPrefix = const Value.absent(),
    this.devicePrefix = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
    this.sellerName = const Value.absent(),
    this.sellerEconomicId = const Value.absent(),
    this.sellerAddress = const Value.absent(),
    this.sellerPhone = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<SettingsRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? syncStatus,
    Expression<int>? lastSyncedAt,
    Expression<int>? singleton,
    Expression<int>? defaultTaxRateBp,
    Expression<int>? roundingUnitRial,
    Expression<int>? paymentTermDays,
    Expression<String>? invoiceNumberPrefix,
    Expression<String>? devicePrefix,
    Expression<int>? lastBackupAt,
    Expression<String>? sellerName,
    Expression<String>? sellerEconomicId,
    Expression<String>? sellerAddress,
    Expression<String>? sellerPhone,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (singleton != null) 'singleton': singleton,
      if (defaultTaxRateBp != null) 'default_tax_rate_bp': defaultTaxRateBp,
      if (roundingUnitRial != null) 'rounding_unit_rial': roundingUnitRial,
      if (paymentTermDays != null) 'payment_term_days': paymentTermDays,
      if (invoiceNumberPrefix != null)
        'invoice_number_prefix': invoiceNumberPrefix,
      if (devicePrefix != null) 'device_prefix': devicePrefix,
      if (lastBackupAt != null) 'last_backup_at': lastBackupAt,
      if (sellerName != null) 'seller_name': sellerName,
      if (sellerEconomicId != null) 'seller_economic_id': sellerEconomicId,
      if (sellerAddress != null) 'seller_address': sellerAddress,
      if (sellerPhone != null) 'seller_phone': sellerPhone,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<SyncStatus>? syncStatus,
    Value<int?>? lastSyncedAt,
    Value<int>? singleton,
    Value<int>? defaultTaxRateBp,
    Value<int>? roundingUnitRial,
    Value<int>? paymentTermDays,
    Value<String>? invoiceNumberPrefix,
    Value<String?>? devicePrefix,
    Value<int?>? lastBackupAt,
    Value<String?>? sellerName,
    Value<String?>? sellerEconomicId,
    Value<String?>? sellerAddress,
    Value<String?>? sellerPhone,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      singleton: singleton ?? this.singleton,
      defaultTaxRateBp: defaultTaxRateBp ?? this.defaultTaxRateBp,
      roundingUnitRial: roundingUnitRial ?? this.roundingUnitRial,
      paymentTermDays: paymentTermDays ?? this.paymentTermDays,
      invoiceNumberPrefix: invoiceNumberPrefix ?? this.invoiceNumberPrefix,
      devicePrefix: devicePrefix ?? this.devicePrefix,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      sellerName: sellerName ?? this.sellerName,
      sellerEconomicId: sellerEconomicId ?? this.sellerEconomicId,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $SettingsTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (singleton.present) {
      map['singleton'] = Variable<int>(singleton.value);
    }
    if (defaultTaxRateBp.present) {
      map['default_tax_rate_bp'] = Variable<int>(defaultTaxRateBp.value);
    }
    if (roundingUnitRial.present) {
      map['rounding_unit_rial'] = Variable<int>(roundingUnitRial.value);
    }
    if (paymentTermDays.present) {
      map['payment_term_days'] = Variable<int>(paymentTermDays.value);
    }
    if (invoiceNumberPrefix.present) {
      map['invoice_number_prefix'] = Variable<String>(
        invoiceNumberPrefix.value,
      );
    }
    if (devicePrefix.present) {
      map['device_prefix'] = Variable<String>(devicePrefix.value);
    }
    if (lastBackupAt.present) {
      map['last_backup_at'] = Variable<int>(lastBackupAt.value);
    }
    if (sellerName.present) {
      map['seller_name'] = Variable<String>(sellerName.value);
    }
    if (sellerEconomicId.present) {
      map['seller_economic_id'] = Variable<String>(sellerEconomicId.value);
    }
    if (sellerAddress.present) {
      map['seller_address'] = Variable<String>(sellerAddress.value);
    }
    if (sellerPhone.present) {
      map['seller_phone'] = Variable<String>(sellerPhone.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
..write('id: $id, ')
..write('createdAt: $createdAt, ')
..write('updatedAt: $updatedAt, ')
..write('deletedAt: $deletedAt, ')
..write('syncStatus: $syncStatus, ')
..write('lastSyncedAt: $lastSyncedAt, ')
..write('singleton: $singleton, ')
..write('defaultTaxRateBp: $defaultTaxRateBp, ')
..write('roundingUnitRial: $roundingUnitRial, ')
..write('paymentTermDays: $paymentTermDays, ')
..write('invoiceNumberPrefix: $invoiceNumberPrefix, ')
..write('devicePrefix: $devicePrefix, ')
..write('lastBackupAt: $lastBackupAt, ')
..write('sellerName: $sellerName, ')
..write('sellerEconomicId: $sellerEconomicId, ')
..write('sellerAddress: $sellerAddress, ')
..write('sellerPhone: $sellerPhone, ')
..write('rowid: $rowid')
..write(')'))
.toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $InvoicesTable invoices = $InvoicesTable(this);
  late final $InvoiceItemsTable invoiceItems = $InvoiceItemsTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index idxCustomersDeletedAt = Index(
    'idx_customers_deleted_at',
    'CREATE INDEX idx_customers_deleted_at ON customers (deleted_at)',
  );
  late final Index idxCustomersSearchName = Index(
    'idx_customers_search_name',
    'CREATE INDEX idx_customers_search_name ON customers (search_name)',
  );
  late final Index idxProductsDeletedAt = Index(
    'idx_products_deleted_at',
    'CREATE INDEX idx_products_deleted_at ON products (deleted_at)',
  );
  late final Index idxProductsSearchName = Index(
    'idx_products_search_name',
    'CREATE INDEX idx_products_search_name ON products (search_name)',
  );
  late final Index idxInvoicesDeletedAt = Index(
    'idx_invoices_deleted_at',
    'CREATE INDEX idx_invoices_deleted_at ON invoices (deleted_at)',
  );
  late final Index idxInvoicesIssueDate = Index(
    'idx_invoices_issue_date',
    'CREATE INDEX idx_invoices_issue_date ON invoices (issue_date)',
  );
  late final Index idxInvoicesCustomer = Index(
    'idx_invoices_customer',
    'CREATE INDEX idx_invoices_customer ON invoices (customer_id)',
  );
  late final Index idxInvoicesStatus = Index(
    'idx_invoices_status',
    'CREATE INDEX idx_invoices_status ON invoices (status)',
  );
  late final Index idxInvoicesNumberYear = Index(
    'idx_invoices_number_year',
    'CREATE INDEX idx_invoices_number_year ON invoices (number_year)',
  );
  late final Index idxInvoicesNumber = Index(
    'idx_invoices_number',
    'CREATE UNIQUE INDEX idx_invoices_number ON invoices (number)',
  );
  late final Index idxInvoiceItemsDeletedAt = Index(
    'idx_invoice_items_deleted_at',
    'CREATE INDEX idx_invoice_items_deleted_at ON invoice_items (deleted_at)',
  );
  late final Index idxInvoiceItemsInvoice = Index(
    'idx_invoice_items_invoice',
    'CREATE INDEX idx_invoice_items_invoice ON invoice_items (invoice_id)',
  );
  late final Index idxPaymentsDeletedAt = Index(
    'idx_payments_deleted_at',
    'CREATE INDEX idx_payments_deleted_at ON payments (deleted_at)',
  );
  late final Index idxPaymentsInvoice = Index(
    'idx_payments_invoice',
    'CREATE INDEX idx_payments_invoice ON payments (invoice_id)',
  );
  late final Index idxPaymentsPaidAt = Index(
    'idx_payments_paid_at',
    'CREATE INDEX idx_payments_paid_at ON payments (paid_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    customers,
    products,
    invoices,
    invoiceItems,
    payments,
    settings,
    idxCustomersDeletedAt,
    idxCustomersSearchName,
    idxProductsDeletedAt,
    idxProductsSearchName,
    idxInvoicesDeletedAt,
    idxInvoicesIssueDate,
    idxInvoicesCustomer,
    idxInvoicesStatus,
    idxInvoicesNumberYear,
    idxInvoicesNumber,
    idxInvoiceItemsDeletedAt,
    idxInvoiceItemsInvoice,
    idxPaymentsDeletedAt,
    idxPaymentsInvoice,
    idxPaymentsPaidAt,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'invoices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('invoice_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'invoices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('payments', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<SyncStatus> syncStatus,
  Value<int?> lastSyncedAt,
  required String fullName,
  Value<String?> mobile,
  Value<String?> companyName,
  Value<String?> address,
  Value<String?> nationalId,
  Value<String?> economicId,
  Value<String?> notes,
  Value<String> searchName,
  Value<int> rowid,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<SyncStatus> syncStatus,
  Value<int?> lastSyncedAt,
  Value<String> fullName,
  Value<String?> mobile,
  Value<String?> companyName,
  Value<String?> address,
  Value<String?> nationalId,
  Value<String?> economicId,
  Value<String?> notes,
  Value<String> searchName,
  Value<int> rowid,
});

final class $$CustomersTableReferences
    extends BaseReferences<_$AppDatabase, $CustomersTable, CustomerRow> {
  $$CustomersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$InvoicesTable, List<InvoiceRow>>
  _invoicesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.invoices,
    aliasName: 'customers__id__invoices__customer_id',
  );

  $$InvoicesTableProcessedTableManager get invoicesRefs {
    final manager = $$InvoicesTableTableManager(
      $_db,
      $_db.invoices,
    ).filter((f) => f.customerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nationalId => $composableBuilder(
    column: $table.nationalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get economicId => $composableBuilder(
    column: $table.economicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchName => $composableBuilder(
    column: $table.searchName,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> invoicesRefs(
    Expression<bool> Function($$InvoicesTableFilterComposer f) f,
  ) {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableFilterComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nationalId => $composableBuilder(
    column: $table.nationalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get economicId => $composableBuilder(
    column: $table.economicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchName => $composableBuilder(
    column: $table.searchName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get mobile =>
      $composableBuilder(column: $table.mobile, builder: (column) => column);

  GeneratedColumn<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get nationalId => $composableBuilder(
    column: $table.nationalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get economicId => $composableBuilder(
    column: $table.economicId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get searchName => $composableBuilder(
    column: $table.searchName,
    builder: (column) => column,
  );

  Expression<T> invoicesRefs<T extends Object>(
    Expression<T> Function($$InvoicesTableAnnotationComposer a) f,
  ) {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTable,
          CustomerRow,
          $$CustomersTableFilterComposer,
          $$CustomersTableOrderingComposer,
          $$CustomersTableAnnotationComposer,
          $$CustomersTableCreateCompanionBuilder,
          $$CustomersTableUpdateCompanionBuilder,
          (CustomerRow, $$CustomersTableReferences),
          CustomerRow,
          PrefetchHooks Function({bool invoicesRefs})
        > {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
: super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String?> mobile = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> nationalId = const Value.absent(),
                Value<String?> economicId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> searchName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                fullName: fullName,
                mobile: mobile,
                companyName: companyName,
                address: address,
                nationalId: nationalId,
                economicId: economicId,
                notes: notes,
                searchName: searchName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                required String fullName,
                Value<String?> mobile = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> nationalId = const Value.absent(),
                Value<String?> economicId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> searchName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                fullName: fullName,
                mobile: mobile,
                companyName: companyName,
                address: address,
                nationalId: nationalId,
                economicId: economicId,
                notes: notes,
                searchName: searchName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
.map(
                (e) => (
                  e.readTable(table),
                  $$CustomersTableReferences(db, table, e),
                ),
              )
.toList(),
          prefetchHooksCallback: ({invoicesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (invoicesRefs) db.invoices],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (invoicesRefs)
                    await $_getPrefetchedData<
                      CustomerRow,
                      $CustomersTable,
                      InvoiceRow
                    >(
                      currentTable: table,
                      referencedTable: $$CustomersTableReferences
._invoicesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CustomersTableReferences(
                            db,
                            table,
                            p0,
                          ).invoicesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.customerId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTable,
      CustomerRow,
      $$CustomersTableFilterComposer,
      $$CustomersTableOrderingComposer,
      $$CustomersTableAnnotationComposer,
      $$CustomersTableCreateCompanionBuilder,
      $$CustomersTableUpdateCompanionBuilder,
      (CustomerRow, $$CustomersTableReferences),
      CustomerRow,
      PrefetchHooks Function({bool invoicesRefs})
    >;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<SyncStatus> syncStatus,
  Value<int?> lastSyncedAt,
  required String name,
  required ProductType type,
  required int priceRial,
  required String unit,
  Value<String?> description,
  Value<String> searchName,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<SyncStatus> syncStatus,
  Value<int?> lastSyncedAt,
  Value<String> name,
  Value<ProductType> type,
  Value<int> priceRial,
  Value<String> unit,
  Value<String?> description,
  Value<String> searchName,
  Value<int> rowid,
});

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, ProductRow> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$InvoiceItemsTable, List<InvoiceItemRow>>
  _invoiceItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.invoiceItems,
    aliasName: 'products__id__invoice_items__product_id',
  );

  $$InvoiceItemsTableProcessedTableManager get invoiceItemsRefs {
    final manager = $$InvoiceItemsTableTableManager(
      $_db,
      $_db.invoiceItems,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoiceItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ProductType, ProductType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get priceRial => $composableBuilder(
    column: $table.priceRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchName => $composableBuilder(
    column: $table.searchName,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> invoiceItemsRefs(
    Expression<bool> Function($$InvoiceItemsTableFilterComposer f) f,
  ) {
    final $$InvoiceItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceItemsTableFilterComposer(
            $db: $db,
            $table: $db.invoiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceRial => $composableBuilder(
    column: $table.priceRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchName => $composableBuilder(
    column: $table.searchName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ProductType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get priceRial =>
      $composableBuilder(column: $table.priceRial, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get searchName => $composableBuilder(
    column: $table.searchName,
    builder: (column) => column,
  );

  Expression<T> invoiceItemsRefs<T extends Object>(
    Expression<T> Function($$InvoiceItemsTableAnnotationComposer a) f,
  ) {
    final $$InvoiceItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.invoiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          ProductRow,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (ProductRow, $$ProductsTableReferences),
          ProductRow,
          PrefetchHooks Function({bool invoiceItemsRefs})
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
: super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<ProductType> type = const Value.absent(),
                Value<int> priceRial = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> searchName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                name: name,
                type: type,
                priceRial: priceRial,
                unit: unit,
                description: description,
                searchName: searchName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                required String name,
                required ProductType type,
                required int priceRial,
                required String unit,
                Value<String?> description = const Value.absent(),
                Value<String> searchName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                name: name,
                type: type,
                priceRial: priceRial,
                unit: unit,
                description: description,
                searchName: searchName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
.map(
                (e) => (
                  e.readTable(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
.toList(),
          prefetchHooksCallback: ({invoiceItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (invoiceItemsRefs) db.invoiceItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (invoiceItemsRefs)
                    await $_getPrefetchedData<
                      ProductRow,
                      $ProductsTable,
                      InvoiceItemRow
                    >(
                      currentTable: table,
                      referencedTable: $$ProductsTableReferences
._invoiceItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProductsTableReferences(
                        db,
                        table,
                        p0,
                      ).invoiceItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.productId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      ProductRow,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (ProductRow, $$ProductsTableReferences),
      ProductRow,
      PrefetchHooks Function({bool invoiceItemsRefs})
    >;
typedef $$InvoicesTableCreateCompanionBuilder = InvoicesCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<SyncStatus> syncStatus,
  Value<int?> lastSyncedAt,
  Value<String?> number,
  Value<int?> numberYear,
  Value<int?> numberSequence,
  required String customerId,
  required int issueDate,
  Value<int?> dueDate,
  Value<int> discountRial,
  Value<int?> discountPercentBp,
  Value<int?> taxRateBp,
  Value<String?> notes,
  Value<String?> customerNameSnapshot,
  Value<String?> customerCompanySnapshot,
  Value<String?> customerNationalIdSnapshot,
  Value<String?> customerEconomicIdSnapshot,
  Value<String?> customerAddressSnapshot,
  required InvoiceStatus status,
  Value<int?> grossTotalRial,
  Value<int> subtotalRial,
  Value<int> totalDiscountRial,
  Value<int> totalTaxRial,
  Value<int> roundingAdjustmentRial,
  Value<int> grandTotalRial,
  Value<int> rowid,
});
typedef $$InvoicesTableUpdateCompanionBuilder = InvoicesCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<SyncStatus> syncStatus,
  Value<int?> lastSyncedAt,
  Value<String?> number,
  Value<int?> numberYear,
  Value<int?> numberSequence,
  Value<String> customerId,
  Value<int> issueDate,
  Value<int?> dueDate,
  Value<int> discountRial,
  Value<int?> discountPercentBp,
  Value<int?> taxRateBp,
  Value<String?> notes,
  Value<String?> customerNameSnapshot,
  Value<String?> customerCompanySnapshot,
  Value<String?> customerNationalIdSnapshot,
  Value<String?> customerEconomicIdSnapshot,
  Value<String?> customerAddressSnapshot,
  Value<InvoiceStatus> status,
  Value<int?> grossTotalRial,
  Value<int> subtotalRial,
  Value<int> totalDiscountRial,
  Value<int> totalTaxRial,
  Value<int> roundingAdjustmentRial,
  Value<int> grandTotalRial,
  Value<int> rowid,
});

final class $$InvoicesTableReferences
    extends BaseReferences<_$AppDatabase, $InvoicesTable, InvoiceRow> {
  $$InvoicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CustomersTable _customerIdTable(_$AppDatabase db) =>
      db.customers.createAlias('invoices__customer_id__customers__id');

  $$CustomersTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<String>('customer_id')!;

    final manager = $$CustomersTableTableManager(
      $_db,
      $_db.customers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$InvoiceItemsTable, List<InvoiceItemRow>>
  _invoiceItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.invoiceItems,
    aliasName: 'invoices__id__invoice_items__invoice_id',
  );

  $$InvoiceItemsTableProcessedTableManager get invoiceItemsRefs {
    final manager = $$InvoiceItemsTableTableManager(
      $_db,
      $_db.invoiceItems,
    ).filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoiceItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PaymentsTable, List<PaymentRow>>
  _paymentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.payments,
    aliasName: 'invoices__id__payments__invoice_id',
  );

  $$PaymentsTableProcessedTableManager get paymentsRefs {
    final manager = $$PaymentsTableTableManager(
      $_db,
      $_db.payments,
    ).filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InvoicesTableFilterComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numberYear => $composableBuilder(
    column: $table.numberYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numberSequence => $composableBuilder(
    column: $table.numberSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get issueDate => $composableBuilder(
    column: $table.issueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountRial => $composableBuilder(
    column: $table.discountRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountPercentBp => $composableBuilder(
    column: $table.discountPercentBp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxRateBp => $composableBuilder(
    column: $table.taxRateBp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerNameSnapshot => $composableBuilder(
    column: $table.customerNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerCompanySnapshot => $composableBuilder(
    column: $table.customerCompanySnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerNationalIdSnapshot => $composableBuilder(
    column: $table.customerNationalIdSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerEconomicIdSnapshot => $composableBuilder(
    column: $table.customerEconomicIdSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerAddressSnapshot => $composableBuilder(
    column: $table.customerAddressSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<InvoiceStatus, InvoiceStatus, int>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get grossTotalRial => $composableBuilder(
    column: $table.grossTotalRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotalRial => $composableBuilder(
    column: $table.subtotalRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDiscountRial => $composableBuilder(
    column: $table.totalDiscountRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTaxRial => $composableBuilder(
    column: $table.totalTaxRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundingAdjustmentRial => $composableBuilder(
    column: $table.roundingAdjustmentRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grandTotalRial => $composableBuilder(
    column: $table.grandTotalRial,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomersTableFilterComposer get customerId {
    final $$CustomersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableFilterComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> invoiceItemsRefs(
    Expression<bool> Function($$InvoiceItemsTableFilterComposer f) f,
  ) {
    final $$InvoiceItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceItems,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceItemsTableFilterComposer(
            $db: $db,
            $table: $db.invoiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> paymentsRefs(
    Expression<bool> Function($$PaymentsTableFilterComposer f) f,
  ) {
    final $$PaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableFilterComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InvoicesTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numberYear => $composableBuilder(
    column: $table.numberYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numberSequence => $composableBuilder(
    column: $table.numberSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get issueDate => $composableBuilder(
    column: $table.issueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountRial => $composableBuilder(
    column: $table.discountRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountPercentBp => $composableBuilder(
    column: $table.discountPercentBp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxRateBp => $composableBuilder(
    column: $table.taxRateBp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerNameSnapshot => $composableBuilder(
    column: $table.customerNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerCompanySnapshot => $composableBuilder(
    column: $table.customerCompanySnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerNationalIdSnapshot => $composableBuilder(
    column: $table.customerNationalIdSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerEconomicIdSnapshot => $composableBuilder(
    column: $table.customerEconomicIdSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerAddressSnapshot => $composableBuilder(
    column: $table.customerAddressSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grossTotalRial => $composableBuilder(
    column: $table.grossTotalRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotalRial => $composableBuilder(
    column: $table.subtotalRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDiscountRial => $composableBuilder(
    column: $table.totalDiscountRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTaxRial => $composableBuilder(
    column: $table.totalTaxRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundingAdjustmentRial => $composableBuilder(
    column: $table.roundingAdjustmentRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grandTotalRial => $composableBuilder(
    column: $table.grandTotalRial,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomersTableOrderingComposer get customerId {
    final $$CustomersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableOrderingComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<int> get numberYear => $composableBuilder(
    column: $table.numberYear,
    builder: (column) => column,
  );

  GeneratedColumn<int> get numberSequence => $composableBuilder(
    column: $table.numberSequence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get issueDate =>
      $composableBuilder(column: $table.issueDate, builder: (column) => column);

  GeneratedColumn<int> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get discountRial => $composableBuilder(
    column: $table.discountRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountPercentBp => $composableBuilder(
    column: $table.discountPercentBp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxRateBp =>
      $composableBuilder(column: $table.taxRateBp, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get customerNameSnapshot => $composableBuilder(
    column: $table.customerNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerCompanySnapshot => $composableBuilder(
    column: $table.customerCompanySnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerNationalIdSnapshot => $composableBuilder(
    column: $table.customerNationalIdSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerEconomicIdSnapshot => $composableBuilder(
    column: $table.customerEconomicIdSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerAddressSnapshot => $composableBuilder(
    column: $table.customerAddressSnapshot,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<InvoiceStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get grossTotalRial => $composableBuilder(
    column: $table.grossTotalRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subtotalRial => $composableBuilder(
    column: $table.subtotalRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalDiscountRial => $composableBuilder(
    column: $table.totalDiscountRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalTaxRial => $composableBuilder(
    column: $table.totalTaxRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get roundingAdjustmentRial => $composableBuilder(
    column: $table.roundingAdjustmentRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grandTotalRial => $composableBuilder(
    column: $table.grandTotalRial,
    builder: (column) => column,
  );

  $$CustomersTableAnnotationComposer get customerId {
    final $$CustomersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableAnnotationComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> invoiceItemsRefs<T extends Object>(
    Expression<T> Function($$InvoiceItemsTableAnnotationComposer a) f,
  ) {
    final $$InvoiceItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceItems,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.invoiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> paymentsRefs<T extends Object>(
    Expression<T> Function($$PaymentsTableAnnotationComposer a) f,
  ) {
    final $$PaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InvoicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvoicesTable,
          InvoiceRow,
          $$InvoicesTableFilterComposer,
          $$InvoicesTableOrderingComposer,
          $$InvoicesTableAnnotationComposer,
          $$InvoicesTableCreateCompanionBuilder,
          $$InvoicesTableUpdateCompanionBuilder,
          (InvoiceRow, $$InvoicesTableReferences),
          InvoiceRow,
          PrefetchHooks Function({
            bool customerId,
            bool invoiceItemsRefs,
            bool paymentsRefs,
          })
        > {
  $$InvoicesTableTableManager(_$AppDatabase db, $InvoicesTable table)
: super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<String?> number = const Value.absent(),
                Value<int?> numberYear = const Value.absent(),
                Value<int?> numberSequence = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<int> issueDate = const Value.absent(),
                Value<int?> dueDate = const Value.absent(),
                Value<int> discountRial = const Value.absent(),
                Value<int?> discountPercentBp = const Value.absent(),
                Value<int?> taxRateBp = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> customerNameSnapshot = const Value.absent(),
                Value<String?> customerCompanySnapshot = const Value.absent(),
                Value<String?> customerNationalIdSnapshot =
                    const Value.absent(),
                Value<String?> customerEconomicIdSnapshot =
                    const Value.absent(),
                Value<String?> customerAddressSnapshot = const Value.absent(),
                Value<InvoiceStatus> status = const Value.absent(),
                Value<int?> grossTotalRial = const Value.absent(),
                Value<int> subtotalRial = const Value.absent(),
                Value<int> totalDiscountRial = const Value.absent(),
                Value<int> totalTaxRial = const Value.absent(),
                Value<int> roundingAdjustmentRial = const Value.absent(),
                Value<int> grandTotalRial = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoicesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                number: number,
                numberYear: numberYear,
                numberSequence: numberSequence,
                customerId: customerId,
                issueDate: issueDate,
                dueDate: dueDate,
                discountRial: discountRial,
                discountPercentBp: discountPercentBp,
                taxRateBp: taxRateBp,
                notes: notes,
                customerNameSnapshot: customerNameSnapshot,
                customerCompanySnapshot: customerCompanySnapshot,
                customerNationalIdSnapshot: customerNationalIdSnapshot,
                customerEconomicIdSnapshot: customerEconomicIdSnapshot,
                customerAddressSnapshot: customerAddressSnapshot,
                status: status,
                grossTotalRial: grossTotalRial,
                subtotalRial: subtotalRial,
                totalDiscountRial: totalDiscountRial,
                totalTaxRial: totalTaxRial,
                roundingAdjustmentRial: roundingAdjustmentRial,
                grandTotalRial: grandTotalRial,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<String?> number = const Value.absent(),
                Value<int?> numberYear = const Value.absent(),
                Value<int?> numberSequence = const Value.absent(),
                required String customerId,
                required int issueDate,
                Value<int?> dueDate = const Value.absent(),
                Value<int> discountRial = const Value.absent(),
                Value<int?> discountPercentBp = const Value.absent(),
                Value<int?> taxRateBp = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> customerNameSnapshot = const Value.absent(),
                Value<String?> customerCompanySnapshot = const Value.absent(),
                Value<String?> customerNationalIdSnapshot =
                    const Value.absent(),
                Value<String?> customerEconomicIdSnapshot =
                    const Value.absent(),
                Value<String?> customerAddressSnapshot = const Value.absent(),
                required InvoiceStatus status,
                Value<int?> grossTotalRial = const Value.absent(),
                Value<int> subtotalRial = const Value.absent(),
                Value<int> totalDiscountRial = const Value.absent(),
                Value<int> totalTaxRial = const Value.absent(),
                Value<int> roundingAdjustmentRial = const Value.absent(),
                Value<int> grandTotalRial = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoicesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                number: number,
                numberYear: numberYear,
                numberSequence: numberSequence,
                customerId: customerId,
                issueDate: issueDate,
                dueDate: dueDate,
                discountRial: discountRial,
                discountPercentBp: discountPercentBp,
                taxRateBp: taxRateBp,
                notes: notes,
                customerNameSnapshot: customerNameSnapshot,
                customerCompanySnapshot: customerCompanySnapshot,
                customerNationalIdSnapshot: customerNationalIdSnapshot,
                customerEconomicIdSnapshot: customerEconomicIdSnapshot,
                customerAddressSnapshot: customerAddressSnapshot,
                status: status,
                grossTotalRial: grossTotalRial,
                subtotalRial: subtotalRial,
                totalDiscountRial: totalDiscountRial,
                totalTaxRial: totalTaxRial,
                roundingAdjustmentRial: roundingAdjustmentRial,
                grandTotalRial: grandTotalRial,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
.map(
                (e) => (
                  e.readTable(table),
                  $$InvoicesTableReferences(db, table, e),
                ),
              )
.toList(),
          prefetchHooksCallback:
              ({
                customerId = false,
                invoiceItemsRefs = false,
                paymentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (invoiceItemsRefs) db.invoiceItems,
                    if (paymentsRefs) db.payments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (customerId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.customerId,
                            referencedTable: $$InvoicesTableReferences
._customerIdTable(db),
                            referencedColumn: $$InvoicesTableReferences
._customerIdTable(db)
.id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (invoiceItemsRefs)
                        await $_getPrefetchedData<
                          InvoiceRow,
                          $InvoicesTable,
                          InvoiceItemRow
                        >(
                          currentTable: table,
                          referencedTable: $$InvoicesTableReferences
._invoiceItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InvoicesTableReferences(
                                db,
                                table,
                                p0,
                              ).invoiceItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.invoiceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (paymentsRefs)
                        await $_getPrefetchedData<
                          InvoiceRow,
                          $InvoicesTable,
                          PaymentRow
                        >(
                          currentTable: table,
                          referencedTable: $$InvoicesTableReferences
._paymentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InvoicesTableReferences(
                                db,
                                table,
                                p0,
                              ).paymentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.invoiceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$InvoicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvoicesTable,
      InvoiceRow,
      $$InvoicesTableFilterComposer,
      $$InvoicesTableOrderingComposer,
      $$InvoicesTableAnnotationComposer,
      $$InvoicesTableCreateCompanionBuilder,
      $$InvoicesTableUpdateCompanionBuilder,
      (InvoiceRow, $$InvoicesTableReferences),
      InvoiceRow,
      PrefetchHooks Function({
        bool customerId,
        bool invoiceItemsRefs,
        bool paymentsRefs,
      })
    >;
typedef $$InvoiceItemsTableCreateCompanionBuilder =
    InvoiceItemsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<SyncStatus> syncStatus,
      Value<int?> lastSyncedAt,
      required String invoiceId,
      Value<String?> productId,
      Value<int> position,
      required String titleSnapshot,
      required String unitSnapshot,
      required int unitPriceRial,
      required int quantityMilli,
      Value<int> discountRial,
      Value<int?> discountPercentBp,
      required int resolvedTaxRateBp,
      Value<int?> lineGrossRial,
      Value<int?> allocatedInvoiceDiscountRial,
      Value<int> lineNetRial,
      Value<int> lineTaxRial,
      Value<int> lineTotalRial,
      Value<int> rowid,
    });
typedef $$InvoiceItemsTableUpdateCompanionBuilder =
    InvoiceItemsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<SyncStatus> syncStatus,
      Value<int?> lastSyncedAt,
      Value<String> invoiceId,
      Value<String?> productId,
      Value<int> position,
      Value<String> titleSnapshot,
      Value<String> unitSnapshot,
      Value<int> unitPriceRial,
      Value<int> quantityMilli,
      Value<int> discountRial,
      Value<int?> discountPercentBp,
      Value<int> resolvedTaxRateBp,
      Value<int?> lineGrossRial,
      Value<int?> allocatedInvoiceDiscountRial,
      Value<int> lineNetRial,
      Value<int> lineTaxRial,
      Value<int> lineTotalRial,
      Value<int> rowid,
    });

final class $$InvoiceItemsTableReferences
    extends BaseReferences<_$AppDatabase, $InvoiceItemsTable, InvoiceItemRow> {
  $$InvoiceItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InvoicesTable _invoiceIdTable(_$AppDatabase db) =>
      db.invoices.createAlias('invoice_items__invoice_id__invoices__id');

  $$InvoicesTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<String>('invoice_id')!;

    final manager = $$InvoicesTableTableManager(
      $_db,
      $_db.invoices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('invoice_items__product_id__products__id');

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<String>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InvoiceItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleSnapshot => $composableBuilder(
    column: $table.titleSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitSnapshot => $composableBuilder(
    column: $table.unitSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPriceRial => $composableBuilder(
    column: $table.unitPriceRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountRial => $composableBuilder(
    column: $table.discountRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountPercentBp => $composableBuilder(
    column: $table.discountPercentBp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resolvedTaxRateBp => $composableBuilder(
    column: $table.resolvedTaxRateBp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineGrossRial => $composableBuilder(
    column: $table.lineGrossRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get allocatedInvoiceDiscountRial => $composableBuilder(
    column: $table.allocatedInvoiceDiscountRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineNetRial => $composableBuilder(
    column: $table.lineNetRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineTaxRial => $composableBuilder(
    column: $table.lineTaxRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineTotalRial => $composableBuilder(
    column: $table.lineTotalRial,
    builder: (column) => ColumnFilters(column),
  );

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableFilterComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleSnapshot => $composableBuilder(
    column: $table.titleSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitSnapshot => $composableBuilder(
    column: $table.unitSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPriceRial => $composableBuilder(
    column: $table.unitPriceRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountRial => $composableBuilder(
    column: $table.discountRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountPercentBp => $composableBuilder(
    column: $table.discountPercentBp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resolvedTaxRateBp => $composableBuilder(
    column: $table.resolvedTaxRateBp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineGrossRial => $composableBuilder(
    column: $table.lineGrossRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get allocatedInvoiceDiscountRial => $composableBuilder(
    column: $table.allocatedInvoiceDiscountRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineNetRial => $composableBuilder(
    column: $table.lineNetRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineTaxRial => $composableBuilder(
    column: $table.lineTaxRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineTotalRial => $composableBuilder(
    column: $table.lineTotalRial,
    builder: (column) => ColumnOrderings(column),
  );

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableOrderingComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get titleSnapshot => $composableBuilder(
    column: $table.titleSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitSnapshot => $composableBuilder(
    column: $table.unitSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unitPriceRial => $composableBuilder(
    column: $table.unitPriceRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountRial => $composableBuilder(
    column: $table.discountRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountPercentBp => $composableBuilder(
    column: $table.discountPercentBp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resolvedTaxRateBp => $composableBuilder(
    column: $table.resolvedTaxRateBp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lineGrossRial => $composableBuilder(
    column: $table.lineGrossRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get allocatedInvoiceDiscountRial => $composableBuilder(
    column: $table.allocatedInvoiceDiscountRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lineNetRial => $composableBuilder(
    column: $table.lineNetRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lineTaxRial => $composableBuilder(
    column: $table.lineTaxRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lineTotalRial => $composableBuilder(
    column: $table.lineTotalRial,
    builder: (column) => column,
  );

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvoiceItemsTable,
          InvoiceItemRow,
          $$InvoiceItemsTableFilterComposer,
          $$InvoiceItemsTableOrderingComposer,
          $$InvoiceItemsTableAnnotationComposer,
          $$InvoiceItemsTableCreateCompanionBuilder,
          $$InvoiceItemsTableUpdateCompanionBuilder,
          (InvoiceItemRow, $$InvoiceItemsTableReferences),
          InvoiceItemRow,
          PrefetchHooks Function({bool invoiceId, bool productId})
        > {
  $$InvoiceItemsTableTableManager(_$AppDatabase db, $InvoiceItemsTable table)
: super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoiceItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoiceItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoiceItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<String> invoiceId = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> titleSnapshot = const Value.absent(),
                Value<String> unitSnapshot = const Value.absent(),
                Value<int> unitPriceRial = const Value.absent(),
                Value<int> quantityMilli = const Value.absent(),
                Value<int> discountRial = const Value.absent(),
                Value<int?> discountPercentBp = const Value.absent(),
                Value<int> resolvedTaxRateBp = const Value.absent(),
                Value<int?> lineGrossRial = const Value.absent(),
                Value<int?> allocatedInvoiceDiscountRial = const Value.absent(),
                Value<int> lineNetRial = const Value.absent(),
                Value<int> lineTaxRial = const Value.absent(),
                Value<int> lineTotalRial = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoiceItemsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                invoiceId: invoiceId,
                productId: productId,
                position: position,
                titleSnapshot: titleSnapshot,
                unitSnapshot: unitSnapshot,
                unitPriceRial: unitPriceRial,
                quantityMilli: quantityMilli,
                discountRial: discountRial,
                discountPercentBp: discountPercentBp,
                resolvedTaxRateBp: resolvedTaxRateBp,
                lineGrossRial: lineGrossRial,
                allocatedInvoiceDiscountRial: allocatedInvoiceDiscountRial,
                lineNetRial: lineNetRial,
                lineTaxRial: lineTaxRial,
                lineTotalRial: lineTotalRial,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                required String invoiceId,
                Value<String?> productId = const Value.absent(),
                Value<int> position = const Value.absent(),
                required String titleSnapshot,
                required String unitSnapshot,
                required int unitPriceRial,
                required int quantityMilli,
                Value<int> discountRial = const Value.absent(),
                Value<int?> discountPercentBp = const Value.absent(),
                required int resolvedTaxRateBp,
                Value<int?> lineGrossRial = const Value.absent(),
                Value<int?> allocatedInvoiceDiscountRial = const Value.absent(),
                Value<int> lineNetRial = const Value.absent(),
                Value<int> lineTaxRial = const Value.absent(),
                Value<int> lineTotalRial = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoiceItemsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                invoiceId: invoiceId,
                productId: productId,
                position: position,
                titleSnapshot: titleSnapshot,
                unitSnapshot: unitSnapshot,
                unitPriceRial: unitPriceRial,
                quantityMilli: quantityMilli,
                discountRial: discountRial,
                discountPercentBp: discountPercentBp,
                resolvedTaxRateBp: resolvedTaxRateBp,
                lineGrossRial: lineGrossRial,
                allocatedInvoiceDiscountRial: allocatedInvoiceDiscountRial,
                lineNetRial: lineNetRial,
                lineTaxRial: lineTaxRial,
                lineTotalRial: lineTotalRial,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
.map(
                (e) => (
                  e.readTable(table),
                  $$InvoiceItemsTableReferences(db, table, e),
                ),
              )
.toList(),
          prefetchHooksCallback: ({invoiceId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (invoiceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.invoiceId,
                        referencedTable: $$InvoiceItemsTableReferences
._invoiceIdTable(db),
                        referencedColumn: $$InvoiceItemsTableReferences
._invoiceIdTable(db)
.id,
                      ) as T;
                    }
                    if (productId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productId,
                        referencedTable: $$InvoiceItemsTableReferences
._productIdTable(db),
                        referencedColumn: $$InvoiceItemsTableReferences
._productIdTable(db)
.id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InvoiceItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvoiceItemsTable,
      InvoiceItemRow,
      $$InvoiceItemsTableFilterComposer,
      $$InvoiceItemsTableOrderingComposer,
      $$InvoiceItemsTableAnnotationComposer,
      $$InvoiceItemsTableCreateCompanionBuilder,
      $$InvoiceItemsTableUpdateCompanionBuilder,
      (InvoiceItemRow, $$InvoiceItemsTableReferences),
      InvoiceItemRow,
      PrefetchHooks Function({bool invoiceId, bool productId})
    >;
typedef $$PaymentsTableCreateCompanionBuilder = PaymentsCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<SyncStatus> syncStatus,
  Value<int?> lastSyncedAt,
  required String invoiceId,
  required int amountRial,
  required int paidAt,
  required PaymentMethod method,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$PaymentsTableUpdateCompanionBuilder = PaymentsCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<SyncStatus> syncStatus,
  Value<int?> lastSyncedAt,
  Value<String> invoiceId,
  Value<int> amountRial,
  Value<int> paidAt,
  Value<PaymentMethod> method,
  Value<String?> note,
  Value<int> rowid,
});

final class $$PaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $PaymentsTable, PaymentRow> {
  $$PaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InvoicesTable _invoiceIdTable(_$AppDatabase db) =>
      db.invoices.createAlias('payments__invoice_id__invoices__id');

  $$InvoicesTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<String>('invoice_id')!;

    final manager = $$InvoicesTableTableManager(
      $_db,
      $_db.invoices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PaymentMethod, PaymentMethod, int>
  get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableFilterComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableOrderingComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PaymentMethod, int> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTable,
          PaymentRow,
          $$PaymentsTableFilterComposer,
          $$PaymentsTableOrderingComposer,
          $$PaymentsTableAnnotationComposer,
          $$PaymentsTableCreateCompanionBuilder,
          $$PaymentsTableUpdateCompanionBuilder,
          (PaymentRow, $$PaymentsTableReferences),
          PaymentRow,
          PrefetchHooks Function({bool invoiceId})
        > {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
: super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<String> invoiceId = const Value.absent(),
                Value<int> amountRial = const Value.absent(),
                Value<int> paidAt = const Value.absent(),
                Value<PaymentMethod> method = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                invoiceId: invoiceId,
                amountRial: amountRial,
                paidAt: paidAt,
                method: method,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                required String invoiceId,
                required int amountRial,
                required int paidAt,
                required PaymentMethod method,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                invoiceId: invoiceId,
                amountRial: amountRial,
                paidAt: paidAt,
                method: method,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
.map(
                (e) => (
                  e.readTable(table),
                  $$PaymentsTableReferences(db, table, e),
                ),
              )
.toList(),
          prefetchHooksCallback: ({invoiceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (invoiceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.invoiceId,
                        referencedTable: $$PaymentsTableReferences
._invoiceIdTable(db),
                        referencedColumn: $$PaymentsTableReferences
._invoiceIdTable(db)
.id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTable,
      PaymentRow,
      $$PaymentsTableFilterComposer,
      $$PaymentsTableOrderingComposer,
      $$PaymentsTableAnnotationComposer,
      $$PaymentsTableCreateCompanionBuilder,
      $$PaymentsTableUpdateCompanionBuilder,
      (PaymentRow, $$PaymentsTableReferences),
      PaymentRow,
      PrefetchHooks Function({bool invoiceId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<SyncStatus> syncStatus,
  Value<int?> lastSyncedAt,
  Value<int> singleton,
  Value<int> defaultTaxRateBp,
  Value<int> roundingUnitRial,
  Value<int> paymentTermDays,
  Value<String> invoiceNumberPrefix,
  Value<String?> devicePrefix,
  Value<int?> lastBackupAt,
  Value<String?> sellerName,
  Value<String?> sellerEconomicId,
  Value<String?> sellerAddress,
  Value<String?> sellerPhone,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<SyncStatus> syncStatus,
  Value<int?> lastSyncedAt,
  Value<int> singleton,
  Value<int> defaultTaxRateBp,
  Value<int> roundingUnitRial,
  Value<int> paymentTermDays,
  Value<String> invoiceNumberPrefix,
  Value<String?> devicePrefix,
  Value<int?> lastBackupAt,
  Value<String?> sellerName,
  Value<String?> sellerEconomicId,
  Value<String?> sellerAddress,
  Value<String?> sellerPhone,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get singleton => $composableBuilder(
    column: $table.singleton,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultTaxRateBp => $composableBuilder(
    column: $table.defaultTaxRateBp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundingUnitRial => $composableBuilder(
    column: $table.roundingUnitRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentTermDays => $composableBuilder(
    column: $table.paymentTermDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceNumberPrefix => $composableBuilder(
    column: $table.invoiceNumberPrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devicePrefix => $composableBuilder(
    column: $table.devicePrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellerName => $composableBuilder(
    column: $table.sellerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellerEconomicId => $composableBuilder(
    column: $table.sellerEconomicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellerAddress => $composableBuilder(
    column: $table.sellerAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellerPhone => $composableBuilder(
    column: $table.sellerPhone,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get singleton => $composableBuilder(
    column: $table.singleton,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultTaxRateBp => $composableBuilder(
    column: $table.defaultTaxRateBp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundingUnitRial => $composableBuilder(
    column: $table.roundingUnitRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentTermDays => $composableBuilder(
    column: $table.paymentTermDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceNumberPrefix => $composableBuilder(
    column: $table.invoiceNumberPrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devicePrefix => $composableBuilder(
    column: $table.devicePrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellerName => $composableBuilder(
    column: $table.sellerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellerEconomicId => $composableBuilder(
    column: $table.sellerEconomicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellerAddress => $composableBuilder(
    column: $table.sellerAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellerPhone => $composableBuilder(
    column: $table.sellerPhone,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get singleton =>
      $composableBuilder(column: $table.singleton, builder: (column) => column);

  GeneratedColumn<int> get defaultTaxRateBp => $composableBuilder(
    column: $table.defaultTaxRateBp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get roundingUnitRial => $composableBuilder(
    column: $table.roundingUnitRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentTermDays => $composableBuilder(
    column: $table.paymentTermDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invoiceNumberPrefix => $composableBuilder(
    column: $table.invoiceNumberPrefix,
    builder: (column) => column,
  );

  GeneratedColumn<String> get devicePrefix => $composableBuilder(
    column: $table.devicePrefix,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sellerName => $composableBuilder(
    column: $table.sellerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sellerEconomicId => $composableBuilder(
    column: $table.sellerEconomicId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sellerAddress => $composableBuilder(
    column: $table.sellerAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sellerPhone => $composableBuilder(
    column: $table.sellerPhone,
    builder: (column) => column,
  );
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingsRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
: super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> singleton = const Value.absent(),
                Value<int> defaultTaxRateBp = const Value.absent(),
                Value<int> roundingUnitRial = const Value.absent(),
                Value<int> paymentTermDays = const Value.absent(),
                Value<String> invoiceNumberPrefix = const Value.absent(),
                Value<String?> devicePrefix = const Value.absent(),
                Value<int?> lastBackupAt = const Value.absent(),
                Value<String?> sellerName = const Value.absent(),
                Value<String?> sellerEconomicId = const Value.absent(),
                Value<String?> sellerAddress = const Value.absent(),
                Value<String?> sellerPhone = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                singleton: singleton,
                defaultTaxRateBp: defaultTaxRateBp,
                roundingUnitRial: roundingUnitRial,
                paymentTermDays: paymentTermDays,
                invoiceNumberPrefix: invoiceNumberPrefix,
                devicePrefix: devicePrefix,
                lastBackupAt: lastBackupAt,
                sellerName: sellerName,
                sellerEconomicId: sellerEconomicId,
                sellerAddress: sellerAddress,
                sellerPhone: sellerPhone,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> singleton = const Value.absent(),
                Value<int> defaultTaxRateBp = const Value.absent(),
                Value<int> roundingUnitRial = const Value.absent(),
                Value<int> paymentTermDays = const Value.absent(),
                Value<String> invoiceNumberPrefix = const Value.absent(),
                Value<String?> devicePrefix = const Value.absent(),
                Value<int?> lastBackupAt = const Value.absent(),
                Value<String?> sellerName = const Value.absent(),
                Value<String?> sellerEconomicId = const Value.absent(),
                Value<String?> sellerAddress = const Value.absent(),
                Value<String?> sellerPhone = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                singleton: singleton,
                defaultTaxRateBp: defaultTaxRateBp,
                roundingUnitRial: roundingUnitRial,
                paymentTermDays: paymentTermDays,
                invoiceNumberPrefix: invoiceNumberPrefix,
                devicePrefix: devicePrefix,
                lastBackupAt: lastBackupAt,
                sellerName: sellerName,
                sellerEconomicId: sellerEconomicId,
                sellerAddress: sellerAddress,
                sellerPhone: sellerPhone,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
.map((e) => (e.readTable(table), BaseReferences(db, table, e)))
.toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingsRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingsRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingsRow>),
      SettingsRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$InvoicesTableTableManager get invoices =>
      $$InvoicesTableTableManager(_db, _db.invoices);
  $$InvoiceItemsTableTableManager get invoiceItems =>
      $$InvoiceItemsTableTableManager(_db, _db.invoiceItems);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
