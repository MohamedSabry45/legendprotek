import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/sell_invoices_remote_datasource.dart';
import 'invoices_state.dart';

class InvoicesCubit extends Cubit<InvoicesState> {
  InvoicesCubit() : super(InvoicesInitial());

  static InvoicesCubit get(context) => BlocProvider.of<InvoicesCubit>(context);

  late final SellInvoicesRemoteDataSource _remote = SellInvoicesRemoteDataSource();

  Future<void> load({required int contactId}) async {
    emit(InvoicesLoading());
    try {
      final invoices = await _remote.getSellInvoices(contactId: contactId);
      if (isClosed) return;
      emit(InvoicesSuccess(invoices));
    } catch (e) {
      if (isClosed) return;
      emit(InvoicesError(e.toString()));
    }
  }
}
