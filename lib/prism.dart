/// **Prism** — a unified Flutter component library.
///
/// Adaptive, Material-style widgets that feel native on phone, desktop and web.
/// Part of the Prism package family, consolidated into a single package.
library;

export 'src/adaptive_scaffold/adaptive_scaffold.dart';
export 'src/adaptive_dialog/adaptive_dialog.dart';
export 'src/ai/ai.dart';
export 'src/banner/banner.dart';
export 'src/changelog/changelog.dart';
export 'src/code_view/code_view.dart';
export 'src/form/form.dart';
export 'src/image/image.dart';
export 'src/markdown/markdown.dart';
export 'src/master_detail/master_detail.dart';
export 'src/pagination/pagination.dart';
export 'src/palette/palette.dart';
export 'src/search/search.dart';
export 'src/settings/settings.dart';
export 'src/state_views/state_views.dart';
export 'src/toast/toast.dart';
export 'src/updater/updater.dart';
export 'src/adaptive_scaffold/breakpoint.dart';
export 'src/ai/ai_chat_view.dart';
export 'src/ai/ai_client.dart';
export 'src/ai/ai_events.dart';
export 'src/ai/ai_tool.dart';
export 'src/ai/ai_agent.dart';
export 'src/ai/anthropic_stream_client.dart';
export 'src/ai/chat_message.dart';
export 'src/ai/embeddings.dart';
export 'src/ai/gemini_stream_client.dart';
export 'src/ai/openai_stream_client.dart';
export 'src/ai/sse_parser.dart';
export 'src/banner/announcement.dart';
export 'src/changelog/entry.dart';
export 'src/code_view/style.dart';
export 'src/image/fetch_failure.dart';
export 'src/image/fetch_strategy.dart';
export 'src/image/network_image_with_retry.dart';
export 'src/markdown/markdown_widget.dart';
export 'src/pagination/paginated_list.dart';
export 'src/pagination/scroll_trigger.dart';
export 'src/palette/color_palette.dart';
export 'src/palette/palette_extractor.dart';
export 'src/palette/palette_target.dart';
export 'src/search/highlight.dart';
export 'src/settings/controller.dart';
export 'src/settings/settings_page.dart';
export 'src/settings/tiles.dart';
export 'src/state_views/state_view.dart';
export 'src/state_views/style.dart';
export 'src/updater/version.dart';
export 'src/updater/update_gate.dart';
export 'src/updater/update_platform.dart';
export 'src/updater/store_flow.dart';
export 'src/updater/skip_store.dart';
export 'src/banner/store.dart';
export 'src/changelog/changelog_view.dart';
export 'src/changelog/store.dart';
export 'src/form/validation.dart';
export 'src/updater/update_policy.dart';
export 'src/updater/update_source.dart';
export 'src/code_view/tokenizer.dart';
export 'src/form/controller.dart';
export 'src/form/fields.dart';
export 'src/state_views/state.dart';
export 'src/updater/update_controller.dart';
export 'src/updater/update_screens.dart';
export 'src/updater/download_manager.dart';

// ── Design system ──────────────────────────────────────────────────────────
export 'src/theme/theme.dart';

// ── Added in 1.1.0 ─────────────────────────────────────────────────────────
export 'src/adaptive_sheet/adaptive_sheet.dart';
export 'src/avatar/avatar.dart';
export 'src/chip_input/chip_input.dart';
export 'src/command_palette/command_palette.dart';
export 'src/connection_banner/connection_banner.dart';
export 'src/data_table/data_table.dart';
export 'src/otp_field/otp_field.dart';
export 'src/skeleton/skeleton.dart';
export 'src/stepper/stepper.dart';
export 'src/timeline/timeline.dart';

// ── Added in 1.3.0 ─────────────────────────────────────────────────────────
export 'src/sync_status/sync_status.dart'
    show PrismSyncPhase, PrismSyncSnapshot, PrismSyncStatus;
export 'src/accordion/accordion.dart'
    show PrismAccordion, PrismAccordionSection;
export 'src/badge/badge.dart' show PrismBadge;
export 'src/calendar/calendar.dart' show PrismCalendar, PrismDateSelection;
export 'src/rating/rating.dart' show PrismRating;
export 'src/segmented_control/segmented_control.dart'
    show PrismSegment, PrismSegmentedControl;
export 'src/tabs/tabs.dart' show PrismTab, PrismTabs;
export 'src/debug/debug_overlay.dart' show PrismDebugOverlay;

// ── Added in 1.5.0 ─────────────────────────────────────────────────────────
export 'src/refresh/refresh.dart'
    show PrismFabAction, PrismFabMenu, PrismRefreshIndicator;
export 'src/controls/controls.dart'
    show
        PrismCheckbox,
        PrismDropdown,
        PrismDropdownItem,
        PrismSlider,
        PrismSwitch;
export 'src/states/states.dart' show PrismEmptyState, PrismLoadingOverlay;
export 'src/lottie/lottie.dart' show PrismLottie, PrismLottieCache;
export 'src/cards/cards.dart' show PrismCard, PrismDivider, PrismTile;
export 'src/progress/progress.dart'
    show PrismCircularProgress, PrismLinearProgress;
export 'src/media/media.dart'
    show PrismCarousel, PrismDividerWithLabel, PrismZoomableImage;
export 'src/ai/thinking_indicator.dart' show PrismAiThinkingIndicator;
export 'src/ai/ai_message_bubble.dart' show PrismAiMessageBubble;
export 'src/ai/prompt_composer.dart' show PrismPromptComposer;
export 'src/color_picker/color_picker.dart' show PrismColorPicker, HSV;
export 'src/overlay_stack/overlay_stack.dart'
    show PrismOverlayStack, PrismOverlayStep;
export 'src/sparkline/sparkline.dart' show PrismSparkline;
