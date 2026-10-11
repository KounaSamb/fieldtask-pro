import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/sync_cubit.dart';

class NetworkBanner extends StatelessWidget {
  const NetworkBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncState>(
      builder: (context, state) {
        final online = state is SyncOnline || state is SyncCompleted;
        final syncing = state is SyncInProgress;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: online
                ? AppColors.success.withOpacity(0.12)
                : AppColors.danger.withOpacity(0.12),
            border: Border.all(
              color: online
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.danger.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: online ? AppColors.success : AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  syncing
                      ? 'Synchronisation en cours...'
                      : online
                          ? 'En ligne · Synchronisé'
                          : 'Hors ligne · Données locales',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: online
                        ? const Color(0xFF1F7A45)
                        : const Color(0xFFB02418),
                  ),
                ),
              ),
              Icon(
                syncing
                    ? Icons.sync
                    : online
                        ? Icons.cloud_done
                        : Icons.cloud_off,
                size: 16,
                color: online ? AppColors.success : AppColors.danger,
              ),
            ],
          ),
        );
      },
    );
  }
}
