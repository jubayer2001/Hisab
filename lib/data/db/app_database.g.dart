// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    iconKey,
    colorValue,
    sortOrder,
    isArchived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;

  /// [EntryType.expense] or [EntryType.income].
  final String type;
  final String iconKey;
  final int colorValue;
  final int sortOrder;

  /// Hidden from the pickers but kept so old entries still show their category.
  final bool isArchived;
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorValue,
    required this.sortOrder,
    required this.isArchived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['icon_key'] = Variable<String>(iconKey);
    map['color_value'] = Variable<int>(colorValue);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_archived'] = Variable<bool>(isArchived);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      iconKey: Value(iconKey),
      colorValue: Value(colorValue),
      sortOrder: Value(sortOrder),
      isArchived: Value(isArchived),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'iconKey': serializer.toJson<String>(iconKey),
      'colorValue': serializer.toJson<int>(colorValue),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isArchived': serializer.toJson<bool>(isArchived),
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? iconKey,
    int? colorValue,
    int? sortOrder,
    bool? isArchived,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    iconKey: iconKey ?? this.iconKey,
    colorValue: colorValue ?? this.colorValue,
    sortOrder: sortOrder ?? this.sortOrder,
    isArchived: isArchived ?? this.isArchived,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorValue: $colorValue, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, type, iconKey, colorValue, sortOrder, isArchived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.iconKey == this.iconKey &&
          other.colorValue == this.colorValue &&
          other.sortOrder == this.sortOrder &&
          other.isArchived == this.isArchived);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String> iconKey;
  final Value<int> colorValue;
  final Value<int> sortOrder;
  final Value<bool> isArchived;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String type,
    required String iconKey,
    required int colorValue,
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
  }) : name = Value(name),
       type = Value(type),
       iconKey = Value(iconKey),
       colorValue = Value(colorValue);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? iconKey,
    Expression<int>? colorValue,
    Expression<int>? sortOrder,
    Expression<bool>? isArchived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorValue != null) 'color_value': colorValue,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isArchived != null) 'is_archived': isArchived,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String>? iconKey,
    Value<int>? colorValue,
    Value<int>? sortOrder,
    Value<bool>? isArchived,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorValue: $colorValue, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }
}

class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPoishaMeta = const VerificationMeta(
    'amountPoisha',
  );
  @override
  late final GeneratedColumn<int> amountPoisha = GeneratedColumn<int>(
    'amount_poisha',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _recurringIdMeta = const VerificationMeta(
    'recurringId',
  );
  @override
  late final GeneratedColumn<int> recurringId = GeneratedColumn<int>(
    'recurring_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    amountPoisha,
    categoryId,
    paymentMethod,
    note,
    date,
    createdAt,
    recurringId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount_poisha')) {
      context.handle(
        _amountPoishaMeta,
        amountPoisha.isAcceptableOrUnknown(
          data['amount_poisha']!,
          _amountPoishaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPoishaMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('recurring_id')) {
      context.handle(
        _recurringIdMeta,
        recurringId.isAcceptableOrUnknown(
          data['recurring_id']!,
          _recurringIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amountPoisha: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_poisha'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      recurringId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurring_id'],
      ),
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }
}

class Entry extends DataClass implements Insertable<Entry> {
  final int id;
  final String type;

  /// Whole poisha (1 Taka = 100 poisha), never a floating point number.
  final int amountPoisha;
  final int categoryId;
  final String? paymentMethod;
  final String? note;

  /// "yyyy-MM-dd", see dates.dart.
  final String date;
  final DateTime createdAt;

  /// Schema version 3: the monthly income ([Recurrings.autoAdd]) that added this entry by
  /// itself, or null for anything the person typed in.
  final int? recurringId;
  const Entry({
    required this.id,
    required this.type,
    required this.amountPoisha,
    required this.categoryId,
    this.paymentMethod,
    this.note,
    required this.date,
    required this.createdAt,
    this.recurringId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['amount_poisha'] = Variable<int>(amountPoisha);
    map['category_id'] = Variable<int>(categoryId);
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['date'] = Variable<String>(date);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || recurringId != null) {
      map['recurring_id'] = Variable<int>(recurringId);
    }
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      type: Value(type),
      amountPoisha: Value(amountPoisha),
      categoryId: Value(categoryId),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      date: Value(date),
      createdAt: Value(createdAt),
      recurringId: recurringId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringId),
    );
  }

  factory Entry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      amountPoisha: serializer.fromJson<int>(json['amountPoisha']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      note: serializer.fromJson<String?>(json['note']),
      date: serializer.fromJson<String>(json['date']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      recurringId: serializer.fromJson<int?>(json['recurringId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'amountPoisha': serializer.toJson<int>(amountPoisha),
      'categoryId': serializer.toJson<int>(categoryId),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'note': serializer.toJson<String?>(note),
      'date': serializer.toJson<String>(date),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'recurringId': serializer.toJson<int?>(recurringId),
    };
  }

  Entry copyWith({
    int? id,
    String? type,
    int? amountPoisha,
    int? categoryId,
    Value<String?> paymentMethod = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? date,
    DateTime? createdAt,
    Value<int?> recurringId = const Value.absent(),
  }) => Entry(
    id: id ?? this.id,
    type: type ?? this.type,
    amountPoisha: amountPoisha ?? this.amountPoisha,
    categoryId: categoryId ?? this.categoryId,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    note: note.present ? note.value : this.note,
    date: date ?? this.date,
    createdAt: createdAt ?? this.createdAt,
    recurringId: recurringId.present ? recurringId.value : this.recurringId,
  );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amountPoisha: data.amountPoisha.present
          ? data.amountPoisha.value
          : this.amountPoisha,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      note: data.note.present ? data.note.value : this.note,
      date: data.date.present ? data.date.value : this.date,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      recurringId: data.recurringId.present
          ? data.recurringId.value
          : this.recurringId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amountPoisha: $amountPoisha, ')
          ..write('categoryId: $categoryId, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('recurringId: $recurringId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amountPoisha,
    categoryId,
    paymentMethod,
    note,
    date,
    createdAt,
    recurringId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == this.id &&
          other.type == this.type &&
          other.amountPoisha == this.amountPoisha &&
          other.categoryId == this.categoryId &&
          other.paymentMethod == this.paymentMethod &&
          other.note == this.note &&
          other.date == this.date &&
          other.createdAt == this.createdAt &&
          other.recurringId == this.recurringId);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<int> id;
  final Value<String> type;
  final Value<int> amountPoisha;
  final Value<int> categoryId;
  final Value<String?> paymentMethod;
  final Value<String?> note;
  final Value<String> date;
  final Value<DateTime> createdAt;
  final Value<int?> recurringId;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amountPoisha = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.note = const Value.absent(),
    this.date = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.recurringId = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required int amountPoisha,
    required int categoryId,
    this.paymentMethod = const Value.absent(),
    this.note = const Value.absent(),
    required String date,
    this.createdAt = const Value.absent(),
    this.recurringId = const Value.absent(),
  }) : type = Value(type),
       amountPoisha = Value(amountPoisha),
       categoryId = Value(categoryId),
       date = Value(date);
  static Insertable<Entry> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<int>? amountPoisha,
    Expression<int>? categoryId,
    Expression<String>? paymentMethod,
    Expression<String>? note,
    Expression<String>? date,
    Expression<DateTime>? createdAt,
    Expression<int>? recurringId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amountPoisha != null) 'amount_poisha': amountPoisha,
      if (categoryId != null) 'category_id': categoryId,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (note != null) 'note': note,
      if (date != null) 'date': date,
      if (createdAt != null) 'created_at': createdAt,
      if (recurringId != null) 'recurring_id': recurringId,
    });
  }

  EntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<int>? amountPoisha,
    Value<int>? categoryId,
    Value<String?>? paymentMethod,
    Value<String?>? note,
    Value<String>? date,
    Value<DateTime>? createdAt,
    Value<int?>? recurringId,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amountPoisha: amountPoisha ?? this.amountPoisha,
      categoryId: categoryId ?? this.categoryId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      recurringId: recurringId ?? this.recurringId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amountPoisha.present) {
      map['amount_poisha'] = Variable<int>(amountPoisha.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (recurringId.present) {
      map['recurring_id'] = Variable<int>(recurringId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amountPoisha: $amountPoisha, ')
          ..write('categoryId: $categoryId, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('recurringId: $recurringId')
          ..write(')'))
        .toString();
  }
}

class $DayStatusesTable extends DayStatuses
    with TableInfo<$DayStatusesTable, DayStatuse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayStatusesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noSpendMeta = const VerificationMeta(
    'noSpend',
  );
  @override
  late final GeneratedColumn<bool> noSpend = GeneratedColumn<bool>(
    'no_spend',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("no_spend" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [date, noSpend];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_statuses';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayStatuse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('no_spend')) {
      context.handle(
        _noSpendMeta,
        noSpend.isAcceptableOrUnknown(data['no_spend']!, _noSpendMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DayStatuse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayStatuse(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      noSpend: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}no_spend'],
      )!,
    );
  }

  @override
  $DayStatusesTable createAlias(String alias) {
    return $DayStatusesTable(attachedDatabase, alias);
  }
}

class DayStatuse extends DataClass implements Insertable<DayStatuse> {
  final String date;
  final bool noSpend;
  const DayStatuse({required this.date, required this.noSpend});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['no_spend'] = Variable<bool>(noSpend);
    return map;
  }

  DayStatusesCompanion toCompanion(bool nullToAbsent) {
    return DayStatusesCompanion(date: Value(date), noSpend: Value(noSpend));
  }

  factory DayStatuse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayStatuse(
      date: serializer.fromJson<String>(json['date']),
      noSpend: serializer.fromJson<bool>(json['noSpend']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'noSpend': serializer.toJson<bool>(noSpend),
    };
  }

  DayStatuse copyWith({String? date, bool? noSpend}) =>
      DayStatuse(date: date ?? this.date, noSpend: noSpend ?? this.noSpend);
  DayStatuse copyWithCompanion(DayStatusesCompanion data) {
    return DayStatuse(
      date: data.date.present ? data.date.value : this.date,
      noSpend: data.noSpend.present ? data.noSpend.value : this.noSpend,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayStatuse(')
          ..write('date: $date, ')
          ..write('noSpend: $noSpend')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, noSpend);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayStatuse &&
          other.date == this.date &&
          other.noSpend == this.noSpend);
}

class DayStatusesCompanion extends UpdateCompanion<DayStatuse> {
  final Value<String> date;
  final Value<bool> noSpend;
  final Value<int> rowid;
  const DayStatusesCompanion({
    this.date = const Value.absent(),
    this.noSpend = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayStatusesCompanion.insert({
    required String date,
    this.noSpend = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DayStatuse> custom({
    Expression<String>? date,
    Expression<bool>? noSpend,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (noSpend != null) 'no_spend': noSpend,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayStatusesCompanion copyWith({
    Value<String>? date,
    Value<bool>? noSpend,
    Value<int>? rowid,
  }) {
    return DayStatusesCompanion(
      date: date ?? this.date,
      noSpend: noSpend ?? this.noSpend,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (noSpend.present) {
      map['no_spend'] = Variable<bool>(noSpend.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayStatusesCompanion(')
          ..write('date: $date, ')
          ..write('noSpend: $noSpend, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _amountPoishaMeta = const VerificationMeta(
    'amountPoisha',
  );
  @override
  late final GeneratedColumn<int> amountPoisha = GeneratedColumn<int>(
    'amount_poisha',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, categoryId, amountPoisha];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Budget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('amount_poisha')) {
      context.handle(
        _amountPoishaMeta,
        amountPoisha.isAcceptableOrUnknown(
          data['amount_poisha']!,
          _amountPoishaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPoishaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      amountPoisha: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_poisha'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final int id;
  final int? categoryId;
  final int amountPoisha;
  const Budget({required this.id, this.categoryId, required this.amountPoisha});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['amount_poisha'] = Variable<int>(amountPoisha);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      amountPoisha: Value(amountPoisha),
    );
  }

  factory Budget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      amountPoisha: serializer.fromJson<int>(json['amountPoisha']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int?>(categoryId),
      'amountPoisha': serializer.toJson<int>(amountPoisha),
    };
  }

  Budget copyWith({
    int? id,
    Value<int?> categoryId = const Value.absent(),
    int? amountPoisha,
  }) => Budget(
    id: id ?? this.id,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    amountPoisha: amountPoisha ?? this.amountPoisha,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      amountPoisha: data.amountPoisha.present
          ? data.amountPoisha.value
          : this.amountPoisha,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountPoisha: $amountPoisha')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, categoryId, amountPoisha);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.amountPoisha == this.amountPoisha);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<int> id;
  final Value<int?> categoryId;
  final Value<int> amountPoisha;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amountPoisha = const Value.absent(),
  });
  BudgetsCompanion.insert({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    required int amountPoisha,
  }) : amountPoisha = Value(amountPoisha);
  static Insertable<Budget> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<int>? amountPoisha,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (amountPoisha != null) 'amount_poisha': amountPoisha,
    });
  }

  BudgetsCompanion copyWith({
    Value<int>? id,
    Value<int?>? categoryId,
    Value<int>? amountPoisha,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amountPoisha: amountPoisha ?? this.amountPoisha,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (amountPoisha.present) {
      map['amount_poisha'] = Variable<int>(amountPoisha.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountPoisha: $amountPoisha')
          ..write(')'))
        .toString();
  }
}

class $RecurringsTable extends Recurrings
    with TableInfo<$RecurringsTable, Recurring> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPoishaMeta = const VerificationMeta(
    'amountPoisha',
  );
  @override
  late final GeneratedColumn<int> amountPoisha = GeneratedColumn<int>(
    'amount_poisha',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _dayOfMonthMeta = const VerificationMeta(
    'dayOfMonth',
  );
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
    'day_of_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastHandledMonthMeta = const VerificationMeta(
    'lastHandledMonth',
  );
  @override
  late final GeneratedColumn<String> lastHandledMonth = GeneratedColumn<String>(
    'last_handled_month',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoAddMeta = const VerificationMeta(
    'autoAdd',
  );
  @override
  late final GeneratedColumn<bool> autoAdd = GeneratedColumn<bool>(
    'auto_add',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_add" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _startMonthMeta = const VerificationMeta(
    'startMonth',
  );
  @override
  late final GeneratedColumn<String> startMonth = GeneratedColumn<String>(
    'start_month',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    type,
    amountPoisha,
    categoryId,
    dayOfMonth,
    isActive,
    lastHandledMonth,
    autoAdd,
    startMonth,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurrings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Recurring> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount_poisha')) {
      context.handle(
        _amountPoishaMeta,
        amountPoisha.isAcceptableOrUnknown(
          data['amount_poisha']!,
          _amountPoishaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPoishaMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
        _dayOfMonthMeta,
        dayOfMonth.isAcceptableOrUnknown(
          data['day_of_month']!,
          _dayOfMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dayOfMonthMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('last_handled_month')) {
      context.handle(
        _lastHandledMonthMeta,
        lastHandledMonth.isAcceptableOrUnknown(
          data['last_handled_month']!,
          _lastHandledMonthMeta,
        ),
      );
    }
    if (data.containsKey('auto_add')) {
      context.handle(
        _autoAddMeta,
        autoAdd.isAcceptableOrUnknown(data['auto_add']!, _autoAddMeta),
      );
    }
    if (data.containsKey('start_month')) {
      context.handle(
        _startMonthMeta,
        startMonth.isAcceptableOrUnknown(data['start_month']!, _startMonthMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recurring map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recurring(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amountPoisha: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_poisha'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      dayOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_month'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      lastHandledMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_handled_month'],
      ),
      autoAdd: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_add'],
      )!,
      startMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_month'],
      ),
    );
  }

  @override
  $RecurringsTable createAlias(String alias) {
    return $RecurringsTable(attachedDatabase, alias);
  }
}

class Recurring extends DataClass implements Insertable<Recurring> {
  final int id;
  final String title;
  final String type;
  final int amountPoisha;
  final int categoryId;

  /// 1 to 31. In shorter months the last day of the month is used.
  final int dayOfMonth;
  final bool isActive;

  /// "yyyy-MM" of the month the user last confirmed or skipped this item.
  final String? lastHandledMonth;

  /// Schema version 3. Monthly income that records itself on its day, instead of waiting
  /// to be confirmed. Bills always keep asking first.
  final bool autoAdd;

  /// Schema version 3, "yyyy-MM": the first month an automatic item may be added for, so a
  /// new salary is never filled in backwards into months before it was set up.
  final String? startMonth;
  const Recurring({
    required this.id,
    required this.title,
    required this.type,
    required this.amountPoisha,
    required this.categoryId,
    required this.dayOfMonth,
    required this.isActive,
    this.lastHandledMonth,
    required this.autoAdd,
    this.startMonth,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    map['amount_poisha'] = Variable<int>(amountPoisha);
    map['category_id'] = Variable<int>(categoryId);
    map['day_of_month'] = Variable<int>(dayOfMonth);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || lastHandledMonth != null) {
      map['last_handled_month'] = Variable<String>(lastHandledMonth);
    }
    map['auto_add'] = Variable<bool>(autoAdd);
    if (!nullToAbsent || startMonth != null) {
      map['start_month'] = Variable<String>(startMonth);
    }
    return map;
  }

  RecurringsCompanion toCompanion(bool nullToAbsent) {
    return RecurringsCompanion(
      id: Value(id),
      title: Value(title),
      type: Value(type),
      amountPoisha: Value(amountPoisha),
      categoryId: Value(categoryId),
      dayOfMonth: Value(dayOfMonth),
      isActive: Value(isActive),
      lastHandledMonth: lastHandledMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(lastHandledMonth),
      autoAdd: Value(autoAdd),
      startMonth: startMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(startMonth),
    );
  }

  factory Recurring.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recurring(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      amountPoisha: serializer.fromJson<int>(json['amountPoisha']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      dayOfMonth: serializer.fromJson<int>(json['dayOfMonth']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      lastHandledMonth: serializer.fromJson<String?>(json['lastHandledMonth']),
      autoAdd: serializer.fromJson<bool>(json['autoAdd']),
      startMonth: serializer.fromJson<String?>(json['startMonth']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'amountPoisha': serializer.toJson<int>(amountPoisha),
      'categoryId': serializer.toJson<int>(categoryId),
      'dayOfMonth': serializer.toJson<int>(dayOfMonth),
      'isActive': serializer.toJson<bool>(isActive),
      'lastHandledMonth': serializer.toJson<String?>(lastHandledMonth),
      'autoAdd': serializer.toJson<bool>(autoAdd),
      'startMonth': serializer.toJson<String?>(startMonth),
    };
  }

  Recurring copyWith({
    int? id,
    String? title,
    String? type,
    int? amountPoisha,
    int? categoryId,
    int? dayOfMonth,
    bool? isActive,
    Value<String?> lastHandledMonth = const Value.absent(),
    bool? autoAdd,
    Value<String?> startMonth = const Value.absent(),
  }) => Recurring(
    id: id ?? this.id,
    title: title ?? this.title,
    type: type ?? this.type,
    amountPoisha: amountPoisha ?? this.amountPoisha,
    categoryId: categoryId ?? this.categoryId,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    isActive: isActive ?? this.isActive,
    lastHandledMonth: lastHandledMonth.present
        ? lastHandledMonth.value
        : this.lastHandledMonth,
    autoAdd: autoAdd ?? this.autoAdd,
    startMonth: startMonth.present ? startMonth.value : this.startMonth,
  );
  Recurring copyWithCompanion(RecurringsCompanion data) {
    return Recurring(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      amountPoisha: data.amountPoisha.present
          ? data.amountPoisha.value
          : this.amountPoisha,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      dayOfMonth: data.dayOfMonth.present
          ? data.dayOfMonth.value
          : this.dayOfMonth,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      lastHandledMonth: data.lastHandledMonth.present
          ? data.lastHandledMonth.value
          : this.lastHandledMonth,
      autoAdd: data.autoAdd.present ? data.autoAdd.value : this.autoAdd,
      startMonth: data.startMonth.present
          ? data.startMonth.value
          : this.startMonth,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recurring(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('amountPoisha: $amountPoisha, ')
          ..write('categoryId: $categoryId, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('isActive: $isActive, ')
          ..write('lastHandledMonth: $lastHandledMonth, ')
          ..write('autoAdd: $autoAdd, ')
          ..write('startMonth: $startMonth')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    type,
    amountPoisha,
    categoryId,
    dayOfMonth,
    isActive,
    lastHandledMonth,
    autoAdd,
    startMonth,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recurring &&
          other.id == this.id &&
          other.title == this.title &&
          other.type == this.type &&
          other.amountPoisha == this.amountPoisha &&
          other.categoryId == this.categoryId &&
          other.dayOfMonth == this.dayOfMonth &&
          other.isActive == this.isActive &&
          other.lastHandledMonth == this.lastHandledMonth &&
          other.autoAdd == this.autoAdd &&
          other.startMonth == this.startMonth);
}

class RecurringsCompanion extends UpdateCompanion<Recurring> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> type;
  final Value<int> amountPoisha;
  final Value<int> categoryId;
  final Value<int> dayOfMonth;
  final Value<bool> isActive;
  final Value<String?> lastHandledMonth;
  final Value<bool> autoAdd;
  final Value<String?> startMonth;
  const RecurringsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.amountPoisha = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.isActive = const Value.absent(),
    this.lastHandledMonth = const Value.absent(),
    this.autoAdd = const Value.absent(),
    this.startMonth = const Value.absent(),
  });
  RecurringsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String type,
    required int amountPoisha,
    required int categoryId,
    required int dayOfMonth,
    this.isActive = const Value.absent(),
    this.lastHandledMonth = const Value.absent(),
    this.autoAdd = const Value.absent(),
    this.startMonth = const Value.absent(),
  }) : title = Value(title),
       type = Value(type),
       amountPoisha = Value(amountPoisha),
       categoryId = Value(categoryId),
       dayOfMonth = Value(dayOfMonth);
  static Insertable<Recurring> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? type,
    Expression<int>? amountPoisha,
    Expression<int>? categoryId,
    Expression<int>? dayOfMonth,
    Expression<bool>? isActive,
    Expression<String>? lastHandledMonth,
    Expression<bool>? autoAdd,
    Expression<String>? startMonth,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (amountPoisha != null) 'amount_poisha': amountPoisha,
      if (categoryId != null) 'category_id': categoryId,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (isActive != null) 'is_active': isActive,
      if (lastHandledMonth != null) 'last_handled_month': lastHandledMonth,
      if (autoAdd != null) 'auto_add': autoAdd,
      if (startMonth != null) 'start_month': startMonth,
    });
  }

  RecurringsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? type,
    Value<int>? amountPoisha,
    Value<int>? categoryId,
    Value<int>? dayOfMonth,
    Value<bool>? isActive,
    Value<String?>? lastHandledMonth,
    Value<bool>? autoAdd,
    Value<String?>? startMonth,
  }) {
    return RecurringsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      amountPoisha: amountPoisha ?? this.amountPoisha,
      categoryId: categoryId ?? this.categoryId,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isActive: isActive ?? this.isActive,
      lastHandledMonth: lastHandledMonth ?? this.lastHandledMonth,
      autoAdd: autoAdd ?? this.autoAdd,
      startMonth: startMonth ?? this.startMonth,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amountPoisha.present) {
      map['amount_poisha'] = Variable<int>(amountPoisha.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (lastHandledMonth.present) {
      map['last_handled_month'] = Variable<String>(lastHandledMonth.value);
    }
    if (autoAdd.present) {
      map['auto_add'] = Variable<bool>(autoAdd.value);
    }
    if (startMonth.present) {
      map['start_month'] = Variable<String>(startMonth.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('amountPoisha: $amountPoisha, ')
          ..write('categoryId: $categoryId, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('isActive: $isActive, ')
          ..write('lastHandledMonth: $lastHandledMonth, ')
          ..write('autoAdd: $autoAdd, ')
          ..write('startMonth: $startMonth')
          ..write(')'))
        .toString();
  }
}

class $SavingsGoalsTable extends SavingsGoals
    with TableInfo<$SavingsGoalsTable, SavingsGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetPoishaMeta = const VerificationMeta(
    'targetPoisha',
  );
  @override
  late final GeneratedColumn<int> targetPoisha = GeneratedColumn<int>(
    'target_poisha',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<String> deadline = GeneratedColumn<String>(
    'deadline',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    targetPoisha,
    deadline,
    colorValue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsGoal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_poisha')) {
      context.handle(
        _targetPoishaMeta,
        targetPoisha.isAcceptableOrUnknown(
          data['target_poisha']!,
          _targetPoishaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetPoishaMeta);
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsGoal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      targetPoisha: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_poisha'],
      )!,
      deadline: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deadline'],
      ),
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
    );
  }

  @override
  $SavingsGoalsTable createAlias(String alias) {
    return $SavingsGoalsTable(attachedDatabase, alias);
  }
}

class SavingsGoal extends DataClass implements Insertable<SavingsGoal> {
  final int id;
  final String name;
  final int targetPoisha;

  /// "yyyy-MM-dd", optional.
  final String? deadline;
  final int colorValue;
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetPoisha,
    this.deadline,
    required this.colorValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['target_poisha'] = Variable<int>(targetPoisha);
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<String>(deadline);
    }
    map['color_value'] = Variable<int>(colorValue);
    return map;
  }

  SavingsGoalsCompanion toCompanion(bool nullToAbsent) {
    return SavingsGoalsCompanion(
      id: Value(id),
      name: Value(name),
      targetPoisha: Value(targetPoisha),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      colorValue: Value(colorValue),
    );
  }

  factory SavingsGoal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsGoal(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetPoisha: serializer.fromJson<int>(json['targetPoisha']),
      deadline: serializer.fromJson<String?>(json['deadline']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'targetPoisha': serializer.toJson<int>(targetPoisha),
      'deadline': serializer.toJson<String?>(deadline),
      'colorValue': serializer.toJson<int>(colorValue),
    };
  }

  SavingsGoal copyWith({
    int? id,
    String? name,
    int? targetPoisha,
    Value<String?> deadline = const Value.absent(),
    int? colorValue,
  }) => SavingsGoal(
    id: id ?? this.id,
    name: name ?? this.name,
    targetPoisha: targetPoisha ?? this.targetPoisha,
    deadline: deadline.present ? deadline.value : this.deadline,
    colorValue: colorValue ?? this.colorValue,
  );
  SavingsGoal copyWithCompanion(SavingsGoalsCompanion data) {
    return SavingsGoal(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetPoisha: data.targetPoisha.present
          ? data.targetPoisha.value
          : this.targetPoisha,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoal(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetPoisha: $targetPoisha, ')
          ..write('deadline: $deadline, ')
          ..write('colorValue: $colorValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, targetPoisha, deadline, colorValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsGoal &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetPoisha == this.targetPoisha &&
          other.deadline == this.deadline &&
          other.colorValue == this.colorValue);
}

class SavingsGoalsCompanion extends UpdateCompanion<SavingsGoal> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> targetPoisha;
  final Value<String?> deadline;
  final Value<int> colorValue;
  const SavingsGoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetPoisha = const Value.absent(),
    this.deadline = const Value.absent(),
    this.colorValue = const Value.absent(),
  });
  SavingsGoalsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int targetPoisha,
    this.deadline = const Value.absent(),
    required int colorValue,
  }) : name = Value(name),
       targetPoisha = Value(targetPoisha),
       colorValue = Value(colorValue);
  static Insertable<SavingsGoal> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? targetPoisha,
    Expression<String>? deadline,
    Expression<int>? colorValue,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetPoisha != null) 'target_poisha': targetPoisha,
      if (deadline != null) 'deadline': deadline,
      if (colorValue != null) 'color_value': colorValue,
    });
  }

  SavingsGoalsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? targetPoisha,
    Value<String?>? deadline,
    Value<int>? colorValue,
  }) {
    return SavingsGoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetPoisha: targetPoisha ?? this.targetPoisha,
      deadline: deadline ?? this.deadline,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetPoisha.present) {
      map['target_poisha'] = Variable<int>(targetPoisha.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<String>(deadline.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetPoisha: $targetPoisha, ')
          ..write('deadline: $deadline, ')
          ..write('colorValue: $colorValue')
          ..write(')'))
        .toString();
  }
}

class $GoalDepositsTable extends GoalDeposits
    with TableInfo<$GoalDepositsTable, GoalDeposit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalDepositsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<int> goalId = GeneratedColumn<int>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES savings_goals (id)',
    ),
  );
  static const VerificationMeta _amountPoishaMeta = const VerificationMeta(
    'amountPoisha',
  );
  @override
  late final GeneratedColumn<int> amountPoisha = GeneratedColumn<int>(
    'amount_poisha',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, goalId, amountPoisha, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_deposits';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalDeposit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('amount_poisha')) {
      context.handle(
        _amountPoishaMeta,
        amountPoisha.isAcceptableOrUnknown(
          data['amount_poisha']!,
          _amountPoishaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPoishaMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalDeposit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalDeposit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_id'],
      )!,
      amountPoisha: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_poisha'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $GoalDepositsTable createAlias(String alias) {
    return $GoalDepositsTable(attachedDatabase, alias);
  }
}

class GoalDeposit extends DataClass implements Insertable<GoalDeposit> {
  final int id;
  final int goalId;
  final int amountPoisha;
  final String date;
  const GoalDeposit({
    required this.id,
    required this.goalId,
    required this.amountPoisha,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['goal_id'] = Variable<int>(goalId);
    map['amount_poisha'] = Variable<int>(amountPoisha);
    map['date'] = Variable<String>(date);
    return map;
  }

  GoalDepositsCompanion toCompanion(bool nullToAbsent) {
    return GoalDepositsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      amountPoisha: Value(amountPoisha),
      date: Value(date),
    );
  }

  factory GoalDeposit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalDeposit(
      id: serializer.fromJson<int>(json['id']),
      goalId: serializer.fromJson<int>(json['goalId']),
      amountPoisha: serializer.fromJson<int>(json['amountPoisha']),
      date: serializer.fromJson<String>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'goalId': serializer.toJson<int>(goalId),
      'amountPoisha': serializer.toJson<int>(amountPoisha),
      'date': serializer.toJson<String>(date),
    };
  }

  GoalDeposit copyWith({
    int? id,
    int? goalId,
    int? amountPoisha,
    String? date,
  }) => GoalDeposit(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    amountPoisha: amountPoisha ?? this.amountPoisha,
    date: date ?? this.date,
  );
  GoalDeposit copyWithCompanion(GoalDepositsCompanion data) {
    return GoalDeposit(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      amountPoisha: data.amountPoisha.present
          ? data.amountPoisha.value
          : this.amountPoisha,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalDeposit(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('amountPoisha: $amountPoisha, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, goalId, amountPoisha, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalDeposit &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.amountPoisha == this.amountPoisha &&
          other.date == this.date);
}

class GoalDepositsCompanion extends UpdateCompanion<GoalDeposit> {
  final Value<int> id;
  final Value<int> goalId;
  final Value<int> amountPoisha;
  final Value<String> date;
  const GoalDepositsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.amountPoisha = const Value.absent(),
    this.date = const Value.absent(),
  });
  GoalDepositsCompanion.insert({
    this.id = const Value.absent(),
    required int goalId,
    required int amountPoisha,
    required String date,
  }) : goalId = Value(goalId),
       amountPoisha = Value(amountPoisha),
       date = Value(date);
  static Insertable<GoalDeposit> custom({
    Expression<int>? id,
    Expression<int>? goalId,
    Expression<int>? amountPoisha,
    Expression<String>? date,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (amountPoisha != null) 'amount_poisha': amountPoisha,
      if (date != null) 'date': date,
    });
  }

  GoalDepositsCompanion copyWith({
    Value<int>? id,
    Value<int>? goalId,
    Value<int>? amountPoisha,
    Value<String>? date,
  }) {
    return GoalDepositsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amountPoisha: amountPoisha ?? this.amountPoisha,
      date: date ?? this.date,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<int>(goalId.value);
    }
    if (amountPoisha.present) {
      map['amount_poisha'] = Variable<int>(amountPoisha.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalDepositsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('amountPoisha: $amountPoisha, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }
}

class $DharRecordsTable extends DharRecords
    with TableInfo<$DharRecordsTable, DharRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DharRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _personMeta = const VerificationMeta('person');
  @override
  late final GeneratedColumn<String> person = GeneratedColumn<String>(
    'person',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPoishaMeta = const VerificationMeta(
    'amountPoisha',
  );
  @override
  late final GeneratedColumn<int> amountPoisha = GeneratedColumn<int>(
    'amount_poisha',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _settledMeta = const VerificationMeta(
    'settled',
  );
  @override
  late final GeneratedColumn<bool> settled = GeneratedColumn<bool>(
    'settled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("settled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    person,
    direction,
    amountPoisha,
    date,
    dueDate,
    note,
    settled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dhar_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<DharRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person')) {
      context.handle(
        _personMeta,
        person.isAcceptableOrUnknown(data['person']!, _personMeta),
      );
    } else if (isInserting) {
      context.missing(_personMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('amount_poisha')) {
      context.handle(
        _amountPoishaMeta,
        amountPoisha.isAcceptableOrUnknown(
          data['amount_poisha']!,
          _amountPoishaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPoishaMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('settled')) {
      context.handle(
        _settledMeta,
        settled.isAcceptableOrUnknown(data['settled']!, _settledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DharRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DharRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      person: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      amountPoisha: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_poisha'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      settled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}settled'],
      )!,
    );
  }

  @override
  $DharRecordsTable createAlias(String alias) {
    return $DharRecordsTable(attachedDatabase, alias);
  }
}

class DharRecord extends DataClass implements Insertable<DharRecord> {
  final int id;
  final String person;
  final String direction;
  final int amountPoisha;
  final String date;
  final String? dueDate;
  final String? note;
  final bool settled;
  const DharRecord({
    required this.id,
    required this.person,
    required this.direction,
    required this.amountPoisha,
    required this.date,
    this.dueDate,
    this.note,
    required this.settled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person'] = Variable<String>(person);
    map['direction'] = Variable<String>(direction);
    map['amount_poisha'] = Variable<int>(amountPoisha);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['settled'] = Variable<bool>(settled);
    return map;
  }

  DharRecordsCompanion toCompanion(bool nullToAbsent) {
    return DharRecordsCompanion(
      id: Value(id),
      person: Value(person),
      direction: Value(direction),
      amountPoisha: Value(amountPoisha),
      date: Value(date),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      settled: Value(settled),
    );
  }

  factory DharRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DharRecord(
      id: serializer.fromJson<int>(json['id']),
      person: serializer.fromJson<String>(json['person']),
      direction: serializer.fromJson<String>(json['direction']),
      amountPoisha: serializer.fromJson<int>(json['amountPoisha']),
      date: serializer.fromJson<String>(json['date']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      note: serializer.fromJson<String?>(json['note']),
      settled: serializer.fromJson<bool>(json['settled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'person': serializer.toJson<String>(person),
      'direction': serializer.toJson<String>(direction),
      'amountPoisha': serializer.toJson<int>(amountPoisha),
      'date': serializer.toJson<String>(date),
      'dueDate': serializer.toJson<String?>(dueDate),
      'note': serializer.toJson<String?>(note),
      'settled': serializer.toJson<bool>(settled),
    };
  }

  DharRecord copyWith({
    int? id,
    String? person,
    String? direction,
    int? amountPoisha,
    String? date,
    Value<String?> dueDate = const Value.absent(),
    Value<String?> note = const Value.absent(),
    bool? settled,
  }) => DharRecord(
    id: id ?? this.id,
    person: person ?? this.person,
    direction: direction ?? this.direction,
    amountPoisha: amountPoisha ?? this.amountPoisha,
    date: date ?? this.date,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    note: note.present ? note.value : this.note,
    settled: settled ?? this.settled,
  );
  DharRecord copyWithCompanion(DharRecordsCompanion data) {
    return DharRecord(
      id: data.id.present ? data.id.value : this.id,
      person: data.person.present ? data.person.value : this.person,
      direction: data.direction.present ? data.direction.value : this.direction,
      amountPoisha: data.amountPoisha.present
          ? data.amountPoisha.value
          : this.amountPoisha,
      date: data.date.present ? data.date.value : this.date,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      note: data.note.present ? data.note.value : this.note,
      settled: data.settled.present ? data.settled.value : this.settled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DharRecord(')
          ..write('id: $id, ')
          ..write('person: $person, ')
          ..write('direction: $direction, ')
          ..write('amountPoisha: $amountPoisha, ')
          ..write('date: $date, ')
          ..write('dueDate: $dueDate, ')
          ..write('note: $note, ')
          ..write('settled: $settled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    person,
    direction,
    amountPoisha,
    date,
    dueDate,
    note,
    settled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DharRecord &&
          other.id == this.id &&
          other.person == this.person &&
          other.direction == this.direction &&
          other.amountPoisha == this.amountPoisha &&
          other.date == this.date &&
          other.dueDate == this.dueDate &&
          other.note == this.note &&
          other.settled == this.settled);
}

class DharRecordsCompanion extends UpdateCompanion<DharRecord> {
  final Value<int> id;
  final Value<String> person;
  final Value<String> direction;
  final Value<int> amountPoisha;
  final Value<String> date;
  final Value<String?> dueDate;
  final Value<String?> note;
  final Value<bool> settled;
  const DharRecordsCompanion({
    this.id = const Value.absent(),
    this.person = const Value.absent(),
    this.direction = const Value.absent(),
    this.amountPoisha = const Value.absent(),
    this.date = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.note = const Value.absent(),
    this.settled = const Value.absent(),
  });
  DharRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String person,
    required String direction,
    required int amountPoisha,
    required String date,
    this.dueDate = const Value.absent(),
    this.note = const Value.absent(),
    this.settled = const Value.absent(),
  }) : person = Value(person),
       direction = Value(direction),
       amountPoisha = Value(amountPoisha),
       date = Value(date);
  static Insertable<DharRecord> custom({
    Expression<int>? id,
    Expression<String>? person,
    Expression<String>? direction,
    Expression<int>? amountPoisha,
    Expression<String>? date,
    Expression<String>? dueDate,
    Expression<String>? note,
    Expression<bool>? settled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (person != null) 'person': person,
      if (direction != null) 'direction': direction,
      if (amountPoisha != null) 'amount_poisha': amountPoisha,
      if (date != null) 'date': date,
      if (dueDate != null) 'due_date': dueDate,
      if (note != null) 'note': note,
      if (settled != null) 'settled': settled,
    });
  }

  DharRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? person,
    Value<String>? direction,
    Value<int>? amountPoisha,
    Value<String>? date,
    Value<String?>? dueDate,
    Value<String?>? note,
    Value<bool>? settled,
  }) {
    return DharRecordsCompanion(
      id: id ?? this.id,
      person: person ?? this.person,
      direction: direction ?? this.direction,
      amountPoisha: amountPoisha ?? this.amountPoisha,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      settled: settled ?? this.settled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (person.present) {
      map['person'] = Variable<String>(person.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (amountPoisha.present) {
      map['amount_poisha'] = Variable<int>(amountPoisha.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (settled.present) {
      map['settled'] = Variable<bool>(settled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DharRecordsCompanion(')
          ..write('id: $id, ')
          ..write('person: $person, ')
          ..write('direction: $direction, ')
          ..write('amountPoisha: $amountPoisha, ')
          ..write('date: $date, ')
          ..write('dueDate: $dueDate, ')
          ..write('note: $note, ')
          ..write('settled: $settled')
          ..write(')'))
        .toString();
  }
}

class $DharPaymentsTable extends DharPayments
    with TableInfo<$DharPaymentsTable, DharPayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DharPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dharIdMeta = const VerificationMeta('dharId');
  @override
  late final GeneratedColumn<int> dharId = GeneratedColumn<int>(
    'dhar_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dhar_records (id)',
    ),
  );
  static const VerificationMeta _amountPoishaMeta = const VerificationMeta(
    'amountPoisha',
  );
  @override
  late final GeneratedColumn<int> amountPoisha = GeneratedColumn<int>(
    'amount_poisha',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, dharId, amountPoisha, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dhar_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<DharPayment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dhar_id')) {
      context.handle(
        _dharIdMeta,
        dharId.isAcceptableOrUnknown(data['dhar_id']!, _dharIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dharIdMeta);
    }
    if (data.containsKey('amount_poisha')) {
      context.handle(
        _amountPoishaMeta,
        amountPoisha.isAcceptableOrUnknown(
          data['amount_poisha']!,
          _amountPoishaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPoishaMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DharPayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DharPayment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dharId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dhar_id'],
      )!,
      amountPoisha: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_poisha'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $DharPaymentsTable createAlias(String alias) {
    return $DharPaymentsTable(attachedDatabase, alias);
  }
}

class DharPayment extends DataClass implements Insertable<DharPayment> {
  final int id;
  final int dharId;
  final int amountPoisha;
  final String date;
  const DharPayment({
    required this.id,
    required this.dharId,
    required this.amountPoisha,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dhar_id'] = Variable<int>(dharId);
    map['amount_poisha'] = Variable<int>(amountPoisha);
    map['date'] = Variable<String>(date);
    return map;
  }

  DharPaymentsCompanion toCompanion(bool nullToAbsent) {
    return DharPaymentsCompanion(
      id: Value(id),
      dharId: Value(dharId),
      amountPoisha: Value(amountPoisha),
      date: Value(date),
    );
  }

  factory DharPayment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DharPayment(
      id: serializer.fromJson<int>(json['id']),
      dharId: serializer.fromJson<int>(json['dharId']),
      amountPoisha: serializer.fromJson<int>(json['amountPoisha']),
      date: serializer.fromJson<String>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dharId': serializer.toJson<int>(dharId),
      'amountPoisha': serializer.toJson<int>(amountPoisha),
      'date': serializer.toJson<String>(date),
    };
  }

  DharPayment copyWith({
    int? id,
    int? dharId,
    int? amountPoisha,
    String? date,
  }) => DharPayment(
    id: id ?? this.id,
    dharId: dharId ?? this.dharId,
    amountPoisha: amountPoisha ?? this.amountPoisha,
    date: date ?? this.date,
  );
  DharPayment copyWithCompanion(DharPaymentsCompanion data) {
    return DharPayment(
      id: data.id.present ? data.id.value : this.id,
      dharId: data.dharId.present ? data.dharId.value : this.dharId,
      amountPoisha: data.amountPoisha.present
          ? data.amountPoisha.value
          : this.amountPoisha,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DharPayment(')
          ..write('id: $id, ')
          ..write('dharId: $dharId, ')
          ..write('amountPoisha: $amountPoisha, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dharId, amountPoisha, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DharPayment &&
          other.id == this.id &&
          other.dharId == this.dharId &&
          other.amountPoisha == this.amountPoisha &&
          other.date == this.date);
}

class DharPaymentsCompanion extends UpdateCompanion<DharPayment> {
  final Value<int> id;
  final Value<int> dharId;
  final Value<int> amountPoisha;
  final Value<String> date;
  const DharPaymentsCompanion({
    this.id = const Value.absent(),
    this.dharId = const Value.absent(),
    this.amountPoisha = const Value.absent(),
    this.date = const Value.absent(),
  });
  DharPaymentsCompanion.insert({
    this.id = const Value.absent(),
    required int dharId,
    required int amountPoisha,
    required String date,
  }) : dharId = Value(dharId),
       amountPoisha = Value(amountPoisha),
       date = Value(date);
  static Insertable<DharPayment> custom({
    Expression<int>? id,
    Expression<int>? dharId,
    Expression<int>? amountPoisha,
    Expression<String>? date,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dharId != null) 'dhar_id': dharId,
      if (amountPoisha != null) 'amount_poisha': amountPoisha,
      if (date != null) 'date': date,
    });
  }

  DharPaymentsCompanion copyWith({
    Value<int>? id,
    Value<int>? dharId,
    Value<int>? amountPoisha,
    Value<String>? date,
  }) {
    return DharPaymentsCompanion(
      id: id ?? this.id,
      dharId: dharId ?? this.dharId,
      amountPoisha: amountPoisha ?? this.amountPoisha,
      date: date ?? this.date,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dharId.present) {
      map['dhar_id'] = Variable<int>(dharId.value);
    }
    if (amountPoisha.present) {
      map['amount_poisha'] = Variable<int>(amountPoisha.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DharPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('dharId: $dharId, ')
          ..write('amountPoisha: $amountPoisha, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }
}

class $EraseSnapshotsTable extends EraseSnapshots
    with TableInfo<$EraseSnapshotsTable, EraseSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EraseSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'erase_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<EraseSnapshot> instance, {
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
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EraseSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EraseSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $EraseSnapshotsTable createAlias(String alias) {
    return $EraseSnapshotsTable(attachedDatabase, alias);
  }
}

class EraseSnapshot extends DataClass implements Insertable<EraseSnapshot> {
  final int id;
  final DateTime createdAt;

  /// The same JSON a backup file holds.
  final String payload;
  const EraseSnapshot({
    required this.id,
    required this.createdAt,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  EraseSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return EraseSnapshotsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      payload: Value(payload),
    );
  }

  factory EraseSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EraseSnapshot(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'payload': serializer.toJson<String>(payload),
    };
  }

  EraseSnapshot copyWith({int? id, DateTime? createdAt, String? payload}) =>
      EraseSnapshot(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        payload: payload ?? this.payload,
      );
  EraseSnapshot copyWithCompanion(EraseSnapshotsCompanion data) {
    return EraseSnapshot(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EraseSnapshot(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EraseSnapshot &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.payload == this.payload);
}

class EraseSnapshotsCompanion extends UpdateCompanion<EraseSnapshot> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  final Value<String> payload;
  const EraseSnapshotsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.payload = const Value.absent(),
  });
  EraseSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    required String payload,
  }) : payload = Value(payload);
  static Insertable<EraseSnapshot> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? payload,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (payload != null) 'payload': payload,
    });
  }

  EraseSnapshotsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? createdAt,
    Value<String>? payload,
  }) {
    return EraseSnapshotsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EraseSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $DayStatusesTable dayStatuses = $DayStatusesTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $RecurringsTable recurrings = $RecurringsTable(this);
  late final $SavingsGoalsTable savingsGoals = $SavingsGoalsTable(this);
  late final $GoalDepositsTable goalDeposits = $GoalDepositsTable(this);
  late final $DharRecordsTable dharRecords = $DharRecordsTable(this);
  late final $DharPaymentsTable dharPayments = $DharPaymentsTable(this);
  late final $EraseSnapshotsTable eraseSnapshots = $EraseSnapshotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    entries,
    dayStatuses,
    budgets,
    recurrings,
    savingsGoals,
    goalDeposits,
    dharRecords,
    dharPayments,
    eraseSnapshots,
  ];
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  required String type,
  required String iconKey,
  required int colorValue,
  Value<int> sortOrder,
  Value<bool> isArchived,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> type,
  Value<String> iconKey,
  Value<int> colorValue,
  Value<int> sortOrder,
  Value<bool> isArchived,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EntriesTable, List<Entry>> _entriesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.entries,
    aliasName: 'categories__id__entries__category_id',
  );

  $$EntriesTableProcessedTableManager get entriesRefs {
    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BudgetsTable, List<Budget>> _budgetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.budgets,
    aliasName: 'categories__id__budgets__category_id',
  );

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecurringsTable, List<Recurring>>
  _recurringsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recurrings,
    aliasName: 'categories__id__recurrings__category_id',
  );

  $$RecurringsTableProcessedTableManager get recurringsRefs {
    final manager = $$RecurringsTableTableManager(
      $_db,
      $_db.recurrings,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_recurringsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entriesRefs(
    Expression<bool> Function($$EntriesTableFilterComposer f) f,
  ) {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetsRefs(
    Expression<bool> Function($$BudgetsTableFilterComposer f) f,
  ) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recurringsRefs(
    Expression<bool> Function($$RecurringsTableFilterComposer f) f,
  ) {
    final $$RecurringsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurrings,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringsTableFilterComposer(
            $db: $db,
            $table: $db.recurrings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  Expression<T> entriesRefs<T extends Object>(
    Expression<T> Function($$EntriesTableAnnotationComposer a) f,
  ) {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(
    Expression<T> Function($$BudgetsTableAnnotationComposer a) f,
  ) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recurringsRefs<T extends Object>(
    Expression<T> Function($$RecurringsTableAnnotationComposer a) f,
  ) {
    final $$RecurringsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurrings,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringsTableAnnotationComposer(
            $db: $db,
            $table: $db.recurrings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({
            bool entriesRefs,
            bool budgetsRefs,
            bool recurringsRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                type: type,
                iconKey: iconKey,
                colorValue: colorValue,
                sortOrder: sortOrder,
                isArchived: isArchived,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String type,
                required String iconKey,
                required int colorValue,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                type: type,
                iconKey: iconKey,
                colorValue: colorValue,
                sortOrder: sortOrder,
                isArchived: isArchived,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, Category>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                entriesRefs = false,
                budgetsRefs = false,
                recurringsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (entriesRefs) db.entries,
                    if (budgetsRefs) db.budgets,
                    if (recurringsRefs) db.recurrings,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entriesRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Entry
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._entriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).entriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (budgetsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Budget
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._budgetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recurringsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Recurring
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._recurringsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).recurringsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
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

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({
        bool entriesRefs,
        bool budgetsRefs,
        bool recurringsRefs,
      })
    >;
typedef $$EntriesTableCreateCompanionBuilder = EntriesCompanion Function({
  Value<int> id,
  required String type,
  required int amountPoisha,
  required int categoryId,
  Value<String?> paymentMethod,
  Value<String?> note,
  required String date,
  Value<DateTime> createdAt,
  Value<int?> recurringId,
});
typedef $$EntriesTableUpdateCompanionBuilder = EntriesCompanion Function({
  Value<int> id,
  Value<String> type,
  Value<int> amountPoisha,
  Value<int> categoryId,
  Value<String?> paymentMethod,
  Value<String?> note,
  Value<String> date,
  Value<DateTime> createdAt,
  Value<int?> recurringId,
});

final class $$EntriesTableReferences
    extends BaseReferences<_$AppDatabase, $EntriesTable, Entry> {
  $$EntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('entries__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recurringId => $composableBuilder(
    column: $table.recurringId,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurringId => $composableBuilder(
    column: $table.recurringId,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get recurringId => $composableBuilder(
    column: $table.recurringId,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntriesTable,
          Entry,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (Entry, $$EntriesTableReferences),
          Entry,
          PrefetchHooks Function({bool categoryId})
        > {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amountPoisha = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> recurringId = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                type: type,
                amountPoisha: amountPoisha,
                categoryId: categoryId,
                paymentMethod: paymentMethod,
                note: note,
                date: date,
                createdAt: createdAt,
                recurringId: recurringId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required int amountPoisha,
                required int categoryId,
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String date,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> recurringId = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                type: type,
                amountPoisha: amountPoisha,
                categoryId: categoryId,
                paymentMethod: paymentMethod,
                note: note,
                date: date,
                createdAt: createdAt,
                recurringId: recurringId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntriesTable, Entry>(table),
                  $$EntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
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
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$EntriesTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$EntriesTableReferences
                            ._categoryIdTable(db)
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

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntriesTable,
      Entry,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (Entry, $$EntriesTableReferences),
      Entry,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$DayStatusesTableCreateCompanionBuilder =
    DayStatusesCompanion Function({
      required String date,
      Value<bool> noSpend,
      Value<int> rowid,
    });
typedef $$DayStatusesTableUpdateCompanionBuilder =
    DayStatusesCompanion Function({
      Value<String> date,
      Value<bool> noSpend,
      Value<int> rowid,
    });

class $$DayStatusesTableFilterComposer
    extends Composer<_$AppDatabase, $DayStatusesTable> {
  $$DayStatusesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get noSpend => $composableBuilder(
    column: $table.noSpend,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayStatusesTableOrderingComposer
    extends Composer<_$AppDatabase, $DayStatusesTable> {
  $$DayStatusesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get noSpend => $composableBuilder(
    column: $table.noSpend,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayStatusesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayStatusesTable> {
  $$DayStatusesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get noSpend =>
      $composableBuilder(column: $table.noSpend, builder: (column) => column);
}

class $$DayStatusesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayStatusesTable,
          DayStatuse,
          $$DayStatusesTableFilterComposer,
          $$DayStatusesTableOrderingComposer,
          $$DayStatusesTableAnnotationComposer,
          $$DayStatusesTableCreateCompanionBuilder,
          $$DayStatusesTableUpdateCompanionBuilder,
          (
            DayStatuse,
            BaseReferences<_$AppDatabase, $DayStatusesTable, DayStatuse>,
          ),
          DayStatuse,
          PrefetchHooks Function()
        > {
  $$DayStatusesTableTableManager(_$AppDatabase db, $DayStatusesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayStatusesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayStatusesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayStatusesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<bool> noSpend = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayStatusesCompanion(
                date: date,
                noSpend: noSpend,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                Value<bool> noSpend = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayStatusesCompanion.insert(
                date: date,
                noSpend: noSpend,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DayStatusesTable, DayStatuse>(table),
                  BaseReferences<_$AppDatabase, $DayStatusesTable, DayStatuse>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayStatusesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayStatusesTable,
      DayStatuse,
      $$DayStatusesTableFilterComposer,
      $$DayStatusesTableOrderingComposer,
      $$DayStatusesTableAnnotationComposer,
      $$DayStatusesTableCreateCompanionBuilder,
      $$DayStatusesTableUpdateCompanionBuilder,
      (
        DayStatuse,
        BaseReferences<_$AppDatabase, $DayStatusesTable, DayStatuse>,
      ),
      DayStatuse,
      PrefetchHooks Function()
    >;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  Value<int> id,
  Value<int?> categoryId,
  required int amountPoisha,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<int> id,
  Value<int?> categoryId,
  Value<int> amountPoisha,
});

final class $$BudgetsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetsTable, Budget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('budgets__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          Budget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (Budget, $$BudgetsTableReferences),
          Budget,
          PrefetchHooks Function({bool categoryId})
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int> amountPoisha = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                categoryId: categoryId,
                amountPoisha: amountPoisha,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                required int amountPoisha,
              }) => BudgetsCompanion.insert(
                id: id,
                categoryId: categoryId,
                amountPoisha: amountPoisha,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetsTable, Budget>(table),
                  $$BudgetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
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
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$BudgetsTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$BudgetsTableReferences
                            ._categoryIdTable(db)
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

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      Budget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (Budget, $$BudgetsTableReferences),
      Budget,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$RecurringsTableCreateCompanionBuilder = RecurringsCompanion Function({
  Value<int> id,
  required String title,
  required String type,
  required int amountPoisha,
  required int categoryId,
  required int dayOfMonth,
  Value<bool> isActive,
  Value<String?> lastHandledMonth,
  Value<bool> autoAdd,
  Value<String?> startMonth,
});
typedef $$RecurringsTableUpdateCompanionBuilder = RecurringsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> type,
  Value<int> amountPoisha,
  Value<int> categoryId,
  Value<int> dayOfMonth,
  Value<bool> isActive,
  Value<String?> lastHandledMonth,
  Value<bool> autoAdd,
  Value<String?> startMonth,
});

final class $$RecurringsTableReferences
    extends BaseReferences<_$AppDatabase, $RecurringsTable, Recurring> {
  $$RecurringsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('recurrings__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecurringsTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringsTable> {
  $$RecurringsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastHandledMonth => $composableBuilder(
    column: $table.lastHandledMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoAdd => $composableBuilder(
    column: $table.autoAdd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startMonth => $composableBuilder(
    column: $table.startMonth,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringsTable> {
  $$RecurringsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastHandledMonth => $composableBuilder(
    column: $table.lastHandledMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoAdd => $composableBuilder(
    column: $table.autoAdd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startMonth => $composableBuilder(
    column: $table.startMonth,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringsTable> {
  $$RecurringsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get lastHandledMonth => $composableBuilder(
    column: $table.lastHandledMonth,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoAdd =>
      $composableBuilder(column: $table.autoAdd, builder: (column) => column);

  GeneratedColumn<String> get startMonth => $composableBuilder(
    column: $table.startMonth,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringsTable,
          Recurring,
          $$RecurringsTableFilterComposer,
          $$RecurringsTableOrderingComposer,
          $$RecurringsTableAnnotationComposer,
          $$RecurringsTableCreateCompanionBuilder,
          $$RecurringsTableUpdateCompanionBuilder,
          (Recurring, $$RecurringsTableReferences),
          Recurring,
          PrefetchHooks Function({bool categoryId})
        > {
  $$RecurringsTableTableManager(_$AppDatabase db, $RecurringsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amountPoisha = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int> dayOfMonth = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> lastHandledMonth = const Value.absent(),
                Value<bool> autoAdd = const Value.absent(),
                Value<String?> startMonth = const Value.absent(),
              }) => RecurringsCompanion(
                id: id,
                title: title,
                type: type,
                amountPoisha: amountPoisha,
                categoryId: categoryId,
                dayOfMonth: dayOfMonth,
                isActive: isActive,
                lastHandledMonth: lastHandledMonth,
                autoAdd: autoAdd,
                startMonth: startMonth,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String type,
                required int amountPoisha,
                required int categoryId,
                required int dayOfMonth,
                Value<bool> isActive = const Value.absent(),
                Value<String?> lastHandledMonth = const Value.absent(),
                Value<bool> autoAdd = const Value.absent(),
                Value<String?> startMonth = const Value.absent(),
              }) => RecurringsCompanion.insert(
                id: id,
                title: title,
                type: type,
                amountPoisha: amountPoisha,
                categoryId: categoryId,
                dayOfMonth: dayOfMonth,
                isActive: isActive,
                lastHandledMonth: lastHandledMonth,
                autoAdd: autoAdd,
                startMonth: startMonth,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurringsTable, Recurring>(table),
                  $$RecurringsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
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
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$RecurringsTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$RecurringsTableReferences
                            ._categoryIdTable(db)
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

typedef $$RecurringsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringsTable,
      Recurring,
      $$RecurringsTableFilterComposer,
      $$RecurringsTableOrderingComposer,
      $$RecurringsTableAnnotationComposer,
      $$RecurringsTableCreateCompanionBuilder,
      $$RecurringsTableUpdateCompanionBuilder,
      (Recurring, $$RecurringsTableReferences),
      Recurring,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$SavingsGoalsTableCreateCompanionBuilder =
    SavingsGoalsCompanion Function({
      Value<int> id,
      required String name,
      required int targetPoisha,
      Value<String?> deadline,
      required int colorValue,
    });
typedef $$SavingsGoalsTableUpdateCompanionBuilder =
    SavingsGoalsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> targetPoisha,
      Value<String?> deadline,
      Value<int> colorValue,
    });

final class $$SavingsGoalsTableReferences
    extends BaseReferences<_$AppDatabase, $SavingsGoalsTable, SavingsGoal> {
  $$SavingsGoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GoalDepositsTable, List<GoalDeposit>>
  _goalDepositsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.goalDeposits,
    aliasName: 'savings_goals__id__goal_deposits__goal_id',
  );

  $$GoalDepositsTableProcessedTableManager get goalDepositsRefs {
    final manager = $$GoalDepositsTableTableManager(
      $_db,
      $_db.goalDeposits,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_goalDepositsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SavingsGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetPoisha => $composableBuilder(
    column: $table.targetPoisha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> goalDepositsRefs(
    Expression<bool> Function($$GoalDepositsTableFilterComposer f) f,
  ) {
    final $$GoalDepositsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goalDeposits,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalDepositsTableFilterComposer(
            $db: $db,
            $table: $db.goalDeposits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SavingsGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetPoisha => $composableBuilder(
    column: $table.targetPoisha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavingsGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get targetPoisha => $composableBuilder(
    column: $table.targetPoisha,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  Expression<T> goalDepositsRefs<T extends Object>(
    Expression<T> Function($$GoalDepositsTableAnnotationComposer a) f,
  ) {
    final $$GoalDepositsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goalDeposits,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalDepositsTableAnnotationComposer(
            $db: $db,
            $table: $db.goalDeposits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SavingsGoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavingsGoalsTable,
          SavingsGoal,
          $$SavingsGoalsTableFilterComposer,
          $$SavingsGoalsTableOrderingComposer,
          $$SavingsGoalsTableAnnotationComposer,
          $$SavingsGoalsTableCreateCompanionBuilder,
          $$SavingsGoalsTableUpdateCompanionBuilder,
          (SavingsGoal, $$SavingsGoalsTableReferences),
          SavingsGoal,
          PrefetchHooks Function({bool goalDepositsRefs})
        > {
  $$SavingsGoalsTableTableManager(_$AppDatabase db, $SavingsGoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> targetPoisha = const Value.absent(),
                Value<String?> deadline = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
              }) => SavingsGoalsCompanion(
                id: id,
                name: name,
                targetPoisha: targetPoisha,
                deadline: deadline,
                colorValue: colorValue,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int targetPoisha,
                Value<String?> deadline = const Value.absent(),
                required int colorValue,
              }) => SavingsGoalsCompanion.insert(
                id: id,
                name: name,
                targetPoisha: targetPoisha,
                deadline: deadline,
                colorValue: colorValue,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavingsGoalsTable, SavingsGoal>(table),
                  $$SavingsGoalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalDepositsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (goalDepositsRefs) db.goalDeposits],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (goalDepositsRefs)
                    await $_getPrefetchedData<
                      SavingsGoal,
                      $SavingsGoalsTable,
                      GoalDeposit
                    >(
                      currentTable: table,
                      referencedTable: $$SavingsGoalsTableReferences
                          ._goalDepositsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SavingsGoalsTableReferences(
                            db,
                            table,
                            p0,
                          ).goalDepositsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.goalId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SavingsGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavingsGoalsTable,
      SavingsGoal,
      $$SavingsGoalsTableFilterComposer,
      $$SavingsGoalsTableOrderingComposer,
      $$SavingsGoalsTableAnnotationComposer,
      $$SavingsGoalsTableCreateCompanionBuilder,
      $$SavingsGoalsTableUpdateCompanionBuilder,
      (SavingsGoal, $$SavingsGoalsTableReferences),
      SavingsGoal,
      PrefetchHooks Function({bool goalDepositsRefs})
    >;
typedef $$GoalDepositsTableCreateCompanionBuilder =
    GoalDepositsCompanion Function({
      Value<int> id,
      required int goalId,
      required int amountPoisha,
      required String date,
    });
typedef $$GoalDepositsTableUpdateCompanionBuilder =
    GoalDepositsCompanion Function({
      Value<int> id,
      Value<int> goalId,
      Value<int> amountPoisha,
      Value<String> date,
    });

final class $$GoalDepositsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalDepositsTable, GoalDeposit> {
  $$GoalDepositsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SavingsGoalsTable _goalIdTable(_$AppDatabase db) =>
      db.savingsGoals.createAlias('goal_deposits__goal_id__savings_goals__id');

  $$SavingsGoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<int>('goal_id')!;

    final manager = $$SavingsGoalsTableTableManager(
      $_db,
      $_db.savingsGoals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GoalDepositsTableFilterComposer
    extends Composer<_$AppDatabase, $GoalDepositsTable> {
  $$GoalDepositsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  $$SavingsGoalsTableFilterComposer get goalId {
    final $$SavingsGoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.savingsGoals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsGoalsTableFilterComposer(
            $db: $db,
            $table: $db.savingsGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalDepositsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalDepositsTable> {
  $$GoalDepositsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  $$SavingsGoalsTableOrderingComposer get goalId {
    final $$SavingsGoalsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.savingsGoals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsGoalsTableOrderingComposer(
            $db: $db,
            $table: $db.savingsGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalDepositsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalDepositsTable> {
  $$GoalDepositsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  $$SavingsGoalsTableAnnotationComposer get goalId {
    final $$SavingsGoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.savingsGoals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsGoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.savingsGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalDepositsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalDepositsTable,
          GoalDeposit,
          $$GoalDepositsTableFilterComposer,
          $$GoalDepositsTableOrderingComposer,
          $$GoalDepositsTableAnnotationComposer,
          $$GoalDepositsTableCreateCompanionBuilder,
          $$GoalDepositsTableUpdateCompanionBuilder,
          (GoalDeposit, $$GoalDepositsTableReferences),
          GoalDeposit,
          PrefetchHooks Function({bool goalId})
        > {
  $$GoalDepositsTableTableManager(_$AppDatabase db, $GoalDepositsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalDepositsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalDepositsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalDepositsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> goalId = const Value.absent(),
                Value<int> amountPoisha = const Value.absent(),
                Value<String> date = const Value.absent(),
              }) => GoalDepositsCompanion(
                id: id,
                goalId: goalId,
                amountPoisha: amountPoisha,
                date: date,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int goalId,
                required int amountPoisha,
                required String date,
              }) => GoalDepositsCompanion.insert(
                id: id,
                goalId: goalId,
                amountPoisha: amountPoisha,
                date: date,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalDepositsTable, GoalDeposit>(table),
                  $$GoalDepositsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
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
                    if (goalId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.goalId,
                        referencedTable: $$GoalDepositsTableReferences
                            ._goalIdTable(db),
                        referencedColumn: $$GoalDepositsTableReferences
                            ._goalIdTable(db)
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

typedef $$GoalDepositsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalDepositsTable,
      GoalDeposit,
      $$GoalDepositsTableFilterComposer,
      $$GoalDepositsTableOrderingComposer,
      $$GoalDepositsTableAnnotationComposer,
      $$GoalDepositsTableCreateCompanionBuilder,
      $$GoalDepositsTableUpdateCompanionBuilder,
      (GoalDeposit, $$GoalDepositsTableReferences),
      GoalDeposit,
      PrefetchHooks Function({bool goalId})
    >;
typedef $$DharRecordsTableCreateCompanionBuilder =
    DharRecordsCompanion Function({
      Value<int> id,
      required String person,
      required String direction,
      required int amountPoisha,
      required String date,
      Value<String?> dueDate,
      Value<String?> note,
      Value<bool> settled,
    });
typedef $$DharRecordsTableUpdateCompanionBuilder =
    DharRecordsCompanion Function({
      Value<int> id,
      Value<String> person,
      Value<String> direction,
      Value<int> amountPoisha,
      Value<String> date,
      Value<String?> dueDate,
      Value<String?> note,
      Value<bool> settled,
    });

final class $$DharRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $DharRecordsTable, DharRecord> {
  $$DharRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DharPaymentsTable, List<DharPayment>>
  _dharPaymentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dharPayments,
    aliasName: 'dhar_records__id__dhar_payments__dhar_id',
  );

  $$DharPaymentsTableProcessedTableManager get dharPaymentsRefs {
    final manager = $$DharPaymentsTableTableManager(
      $_db,
      $_db.dharPayments,
    ).filter((f) => f.dharId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_dharPaymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DharRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $DharRecordsTable> {
  $$DharRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get person => $composableBuilder(
    column: $table.person,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get settled => $composableBuilder(
    column: $table.settled,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> dharPaymentsRefs(
    Expression<bool> Function($$DharPaymentsTableFilterComposer f) f,
  ) {
    final $$DharPaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dharPayments,
      getReferencedColumn: (t) => t.dharId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DharPaymentsTableFilterComposer(
            $db: $db,
            $table: $db.dharPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DharRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $DharRecordsTable> {
  $$DharRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get person => $composableBuilder(
    column: $table.person,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get settled => $composableBuilder(
    column: $table.settled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DharRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DharRecordsTable> {
  $$DharRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get person =>
      $composableBuilder(column: $table.person, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get settled =>
      $composableBuilder(column: $table.settled, builder: (column) => column);

  Expression<T> dharPaymentsRefs<T extends Object>(
    Expression<T> Function($$DharPaymentsTableAnnotationComposer a) f,
  ) {
    final $$DharPaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dharPayments,
      getReferencedColumn: (t) => t.dharId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DharPaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.dharPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DharRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DharRecordsTable,
          DharRecord,
          $$DharRecordsTableFilterComposer,
          $$DharRecordsTableOrderingComposer,
          $$DharRecordsTableAnnotationComposer,
          $$DharRecordsTableCreateCompanionBuilder,
          $$DharRecordsTableUpdateCompanionBuilder,
          (DharRecord, $$DharRecordsTableReferences),
          DharRecord,
          PrefetchHooks Function({bool dharPaymentsRefs})
        > {
  $$DharRecordsTableTableManager(_$AppDatabase db, $DharRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DharRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DharRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DharRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> person = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<int> amountPoisha = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> settled = const Value.absent(),
              }) => DharRecordsCompanion(
                id: id,
                person: person,
                direction: direction,
                amountPoisha: amountPoisha,
                date: date,
                dueDate: dueDate,
                note: note,
                settled: settled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String person,
                required String direction,
                required int amountPoisha,
                required String date,
                Value<String?> dueDate = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> settled = const Value.absent(),
              }) => DharRecordsCompanion.insert(
                id: id,
                person: person,
                direction: direction,
                amountPoisha: amountPoisha,
                date: date,
                dueDate: dueDate,
                note: note,
                settled: settled,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DharRecordsTable, DharRecord>(table),
                  $$DharRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dharPaymentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (dharPaymentsRefs) db.dharPayments],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dharPaymentsRefs)
                    await $_getPrefetchedData<
                      DharRecord,
                      $DharRecordsTable,
                      DharPayment
                    >(
                      currentTable: table,
                      referencedTable: $$DharRecordsTableReferences
                          ._dharPaymentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DharRecordsTableReferences(
                            db,
                            table,
                            p0,
                          ).dharPaymentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.dharId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DharRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DharRecordsTable,
      DharRecord,
      $$DharRecordsTableFilterComposer,
      $$DharRecordsTableOrderingComposer,
      $$DharRecordsTableAnnotationComposer,
      $$DharRecordsTableCreateCompanionBuilder,
      $$DharRecordsTableUpdateCompanionBuilder,
      (DharRecord, $$DharRecordsTableReferences),
      DharRecord,
      PrefetchHooks Function({bool dharPaymentsRefs})
    >;
typedef $$DharPaymentsTableCreateCompanionBuilder =
    DharPaymentsCompanion Function({
      Value<int> id,
      required int dharId,
      required int amountPoisha,
      required String date,
    });
typedef $$DharPaymentsTableUpdateCompanionBuilder =
    DharPaymentsCompanion Function({
      Value<int> id,
      Value<int> dharId,
      Value<int> amountPoisha,
      Value<String> date,
    });

final class $$DharPaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $DharPaymentsTable, DharPayment> {
  $$DharPaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DharRecordsTable _dharIdTable(_$AppDatabase db) =>
      db.dharRecords.createAlias('dhar_payments__dhar_id__dhar_records__id');

  $$DharRecordsTableProcessedTableManager get dharId {
    final $_column = $_itemColumn<int>('dhar_id')!;

    final manager = $$DharRecordsTableTableManager(
      $_db,
      $_db.dharRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dharIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DharPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $DharPaymentsTable> {
  $$DharPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  $$DharRecordsTableFilterComposer get dharId {
    final $$DharRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dharId,
      referencedTable: $db.dharRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DharRecordsTableFilterComposer(
            $db: $db,
            $table: $db.dharRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DharPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DharPaymentsTable> {
  $$DharPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  $$DharRecordsTableOrderingComposer get dharId {
    final $$DharRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dharId,
      referencedTable: $db.dharRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DharRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.dharRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DharPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DharPaymentsTable> {
  $$DharPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountPoisha => $composableBuilder(
    column: $table.amountPoisha,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  $$DharRecordsTableAnnotationComposer get dharId {
    final $$DharRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dharId,
      referencedTable: $db.dharRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DharRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.dharRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DharPaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DharPaymentsTable,
          DharPayment,
          $$DharPaymentsTableFilterComposer,
          $$DharPaymentsTableOrderingComposer,
          $$DharPaymentsTableAnnotationComposer,
          $$DharPaymentsTableCreateCompanionBuilder,
          $$DharPaymentsTableUpdateCompanionBuilder,
          (DharPayment, $$DharPaymentsTableReferences),
          DharPayment,
          PrefetchHooks Function({bool dharId})
        > {
  $$DharPaymentsTableTableManager(_$AppDatabase db, $DharPaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DharPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DharPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DharPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dharId = const Value.absent(),
                Value<int> amountPoisha = const Value.absent(),
                Value<String> date = const Value.absent(),
              }) => DharPaymentsCompanion(
                id: id,
                dharId: dharId,
                amountPoisha: amountPoisha,
                date: date,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dharId,
                required int amountPoisha,
                required String date,
              }) => DharPaymentsCompanion.insert(
                id: id,
                dharId: dharId,
                amountPoisha: amountPoisha,
                date: date,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DharPaymentsTable, DharPayment>(table),
                  $$DharPaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dharId = false}) {
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
                    if (dharId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.dharId,
                        referencedTable: $$DharPaymentsTableReferences
                            ._dharIdTable(db),
                        referencedColumn: $$DharPaymentsTableReferences
                            ._dharIdTable(db)
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

typedef $$DharPaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DharPaymentsTable,
      DharPayment,
      $$DharPaymentsTableFilterComposer,
      $$DharPaymentsTableOrderingComposer,
      $$DharPaymentsTableAnnotationComposer,
      $$DharPaymentsTableCreateCompanionBuilder,
      $$DharPaymentsTableUpdateCompanionBuilder,
      (DharPayment, $$DharPaymentsTableReferences),
      DharPayment,
      PrefetchHooks Function({bool dharId})
    >;
typedef $$EraseSnapshotsTableCreateCompanionBuilder =
    EraseSnapshotsCompanion Function({
      Value<int> id,
      Value<DateTime> createdAt,
      required String payload,
    });
typedef $$EraseSnapshotsTableUpdateCompanionBuilder =
    EraseSnapshotsCompanion Function({
      Value<int> id,
      Value<DateTime> createdAt,
      Value<String> payload,
    });

class $$EraseSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $EraseSnapshotsTable> {
  $$EraseSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EraseSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $EraseSnapshotsTable> {
  $$EraseSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EraseSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EraseSnapshotsTable> {
  $$EraseSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$EraseSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EraseSnapshotsTable,
          EraseSnapshot,
          $$EraseSnapshotsTableFilterComposer,
          $$EraseSnapshotsTableOrderingComposer,
          $$EraseSnapshotsTableAnnotationComposer,
          $$EraseSnapshotsTableCreateCompanionBuilder,
          $$EraseSnapshotsTableUpdateCompanionBuilder,
          (
            EraseSnapshot,
            BaseReferences<_$AppDatabase, $EraseSnapshotsTable, EraseSnapshot>,
          ),
          EraseSnapshot,
          PrefetchHooks Function()
        > {
  $$EraseSnapshotsTableTableManager(
    _$AppDatabase db,
    $EraseSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EraseSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EraseSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EraseSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> payload = const Value.absent(),
              }) => EraseSnapshotsCompanion(
                id: id,
                createdAt: createdAt,
                payload: payload,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                required String payload,
              }) => EraseSnapshotsCompanion.insert(
                id: id,
                createdAt: createdAt,
                payload: payload,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EraseSnapshotsTable, EraseSnapshot>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $EraseSnapshotsTable,
                    EraseSnapshot
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EraseSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EraseSnapshotsTable,
      EraseSnapshot,
      $$EraseSnapshotsTableFilterComposer,
      $$EraseSnapshotsTableOrderingComposer,
      $$EraseSnapshotsTableAnnotationComposer,
      $$EraseSnapshotsTableCreateCompanionBuilder,
      $$EraseSnapshotsTableUpdateCompanionBuilder,
      (
        EraseSnapshot,
        BaseReferences<_$AppDatabase, $EraseSnapshotsTable, EraseSnapshot>,
      ),
      EraseSnapshot,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$DayStatusesTableTableManager get dayStatuses =>
      $$DayStatusesTableTableManager(_db, _db.dayStatuses);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$RecurringsTableTableManager get recurrings =>
      $$RecurringsTableTableManager(_db, _db.recurrings);
  $$SavingsGoalsTableTableManager get savingsGoals =>
      $$SavingsGoalsTableTableManager(_db, _db.savingsGoals);
  $$GoalDepositsTableTableManager get goalDeposits =>
      $$GoalDepositsTableTableManager(_db, _db.goalDeposits);
  $$DharRecordsTableTableManager get dharRecords =>
      $$DharRecordsTableTableManager(_db, _db.dharRecords);
  $$DharPaymentsTableTableManager get dharPayments =>
      $$DharPaymentsTableTableManager(_db, _db.dharPayments);
  $$EraseSnapshotsTableTableManager get eraseSnapshots =>
      $$EraseSnapshotsTableTableManager(_db, _db.eraseSnapshots);
}
