part of 'hud_action_deck.dart';

class _SelectionDetailModalModel {
  final SelectionDetailViewModel detail;
  final bool peek;

  const _SelectionDetailModalModel({required this.detail, required this.peek});
}

extension _HudActionDeckDetailModal on _HudActionDeckState {
  void _syncDetailModal() {
    final detail = _activeDetail(AppLocalizations.of(context));
    _queueDetailNotifierUpdate(detail);
    if (detail == null) {
      _lastRequestedDetailKey = null;
      if (_detailModalOpen && _detailModalContext != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final modalContext = _detailModalContext;
          if (modalContext == null) return;
          unawaited(Navigator.of(modalContext).maybePop());
        });
      }
      return;
    }
    if (_detailModalOpen || _lastRequestedDetailKey == detail.contentKey) {
      return;
    }
    _lastRequestedDetailKey = detail.contentKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_showDetailModal(detail));
    });
  }

  void _queueDetailNotifierUpdate(SelectionDetailViewModel? detail) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _detailNotifier.value = detail == null
          ? null
          : _SelectionDetailModalModel(
              detail: detail,
              peek: widget.selectionDetailPeek,
            );
    });
  }

  Future<void> _showDetailModal(SelectionDetailViewModel detail) async {
    if (_detailModalOpen || !mounted) return;
    _detailModalOpen = true;
    _detailNotifier.value = _SelectionDetailModalModel(
      detail: detail,
      peek: widget.selectionDetailPeek,
    );

    await showGameBottomSheet<void>(
      context: context,
      builder: (modalContext) {
        _detailModalContext = modalContext;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            10,
            0,
            10,
            10 + MediaQuery.viewInsetsOf(modalContext).bottom,
          ),
          child: ValueListenableBuilder<_SelectionDetailModalModel?>(
            valueListenable: _detailNotifier,
            builder: (context, currentModal, _) {
              if (currentModal == null) return const SizedBox.shrink();
              return SelectionDetailSheet(
                model: currentModal.detail,
                compact: MediaQuery.sizeOf(modalContext).width < 380,
                fillWidth: true,
                bottomSheet: true,
                peek: currentModal.peek,
                cityRuleset: widget.cityRuleset,
                technologyRuleset: widget.technologyRuleset,
                onClose: () {
                  widget.onCloseSelectionDetail();
                  unawaited(Navigator.of(modalContext).maybePop());
                },
                onDetachTroop: _detachTroop,
                onSelectWorkerImprovement: _selectWorkerImprovement,
                onConfirmWorkerImprovement: _confirmWorkerImprovement,
                onCancelWorkerActionSelection: _cancelWorkerActionSelection,
              );
            },
          ),
        );
      },
    );

    if (!mounted) return;
    _detailModalOpen = false;
    _detailModalContext = null;
    _lastRequestedDetailKey = null;
    if (widget.openSelectionDetailChipId == detail.chipId) {
      widget.onCloseSelectionDetail();
    }
  }
}
