part of 'diplomatic_message_popup_overlay.dart';

class _DiplomaticMessageDialogResult {
  final DiplomaticMessageResponse? response;
  final bool minimize;

  const _DiplomaticMessageDialogResult._later()
    : response = null,
      minimize = true;

  const _DiplomaticMessageDialogResult._minimized()
    : response = null,
      minimize = true;

  const _DiplomaticMessageDialogResult.respond(this.response)
    : minimize = false;

  static const later = _DiplomaticMessageDialogResult._later();
  static const minimized = _DiplomaticMessageDialogResult._minimized();
}

class _DiplomaticProposalDialogResult {
  final bool? accepted;
  final bool minimize;

  const _DiplomaticProposalDialogResult._later()
    : accepted = null,
      minimize = true;

  const _DiplomaticProposalDialogResult._minimized()
    : accepted = null,
      minimize = true;

  const _DiplomaticProposalDialogResult.respond(this.accepted)
    : minimize = false;

  static const later = _DiplomaticProposalDialogResult._later();
  static const minimized = _DiplomaticProposalDialogResult._minimized();
}
