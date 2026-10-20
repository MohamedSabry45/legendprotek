import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/config/style/app_spacing.dart';
import 'package:reservation_workshop/core/widgets/app_card.dart';
import 'package:reservation_workshop/core/widgets/login_required_view.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_state.dart';
import 'package:reservation_workshop/modules/invoices/presentation/cubits/invoices_cubit/invoices_cubit.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/modules/invoices/presentation/cubits/invoices_cubit/invoices_state.dart';
import 'package:reservation_workshop/modules/invoices/presentation/screens/invoice_details_args.dart';
import 'package:reservation_workshop/modules/invoices/presentation/widgets/invoice_card_widget.dart';

class InvoicesTabView extends StatelessWidget {
  const InvoicesTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InvoicesCubit>(
      create: (_) => InvoicesCubit(),
      child: const _InvoicesTabBody(),
    );
  }
}

class _InvoicesTabBody extends StatefulWidget {
  const _InvoicesTabBody();

  @override
  State<_InvoicesTabBody> createState() => _InvoicesTabBodyState();
}

class _InvoicesTabBodyState extends State<_InvoicesTabBody> {
  int? _lastLoadedContactId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final customerState = context.read<CustomerInfoCubit>().state;
    if (customerState is CustomerInfoSuccess) {
      final id = customerState.info.id;
      if (id > 0 && id != _lastLoadedContactId) {
        _lastLoadedContactId = id;
        context.read<InvoicesCubit>().load(contactId: id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerInfoCubit, CustomerInfoState>(
      builder: (context, customerState) {
        final contactId = customerState is CustomerInfoSuccess
            ? customerState.info.id
            : 0;

        if (contactId == 0) {
          return const LoginRequiredView();
        }

        if (customerState is CustomerInfoLoading || contactId == 0) {
          return const Center(child: CircularProgressIndicator());
        }

        return BlocBuilder<InvoicesCubit, InvoicesState>(
          builder: (context, state) {
            if (state is InvoicesLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is InvoicesError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Toasters.displayMessage(state.message),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: 180,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<InvoicesCubit>().load(
                            contactId: contactId,
                          );
                        },
                        child: Text('common.retry'.tr()),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is InvoicesSuccess) {
              if (state.invoices.isEmpty) {
                return AppCard(
                  backgroundColor: const Color(0xFF050505),
                  borderColor: const Color(0xFFD4AF37).withOpacity(0.25),
                  child: Text(
                    'invoices.empty'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () =>
                    context.read<InvoicesCubit>().load(contactId: contactId),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 100),
                  itemBuilder: (context, index) {
                    final invoice = state.invoices[index];
                    return InvoiceCardWidget(
                      invoice: invoice,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          RoutesName.invoiceDetailsScreen,
                          arguments: InvoiceDetailsArgs(invoice: invoice),
                        );
                      },
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemCount: state.invoices.length,
                ),
              );
            }

            return Center(
              child: Text(
                'tabs.invoice'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
