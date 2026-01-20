import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../domain/entities/inventory_item.dart';
import '../domain/repositories/inventory_repository.dart';

// Events
abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object> get props => [];
}

class LoadInventoryItems extends InventoryEvent {}

class UpdateInventoryItems extends InventoryEvent {
  final List<InventoryItem> items;

  const UpdateInventoryItems(this.items);

  @override
  List<Object> get props => [items];
}

class ToggleEssentialStatus extends InventoryEvent {
  final String itemId;

  const ToggleEssentialStatus(this.itemId);

  @override
  List<Object> get props => [itemId];
}

// States
abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<InventoryItem> items;

  const InventoryLoaded(this.items);

  @override
  List<Object> get props => [items];
}

class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository repository;
  StreamSubscription? _itemsSubscription;

  InventoryBloc({required this.repository}) : super(InventoryInitial()) {
    on<LoadInventoryItems>(_onLoadInventoryItems);
    on<UpdateInventoryItems>(_onUpdateInventoryItems);
    on<ToggleEssentialStatus>(_onToggleEssentialStatus);
  }

  void _onLoadInventoryItems(
    LoadInventoryItems event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      // Listen to the stream for real-time updates
      _itemsSubscription?.cancel();
      _itemsSubscription = repository.itemsStream.listen((items) {
        add(UpdateInventoryItems(items));
      });

      // Also get initial data
      final items = await repository.getWatchedItems();
      emit(InventoryLoaded(items));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  void _onUpdateInventoryItems(
    UpdateInventoryItems event,
    Emitter<InventoryState> emit,
  ) {
    emit(InventoryLoaded(event.items));
  }

  void _onToggleEssentialStatus(
    ToggleEssentialStatus event,
    Emitter<InventoryState> emit,
  ) {
    repository.toggleEssentialStatus(event.itemId);
  }

  @override
  Future<void> close() {
    _itemsSubscription?.cancel();
    return super.close();
  }
}
