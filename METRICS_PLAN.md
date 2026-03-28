# Routka Metrics Plan

## Goal

Instrument Routka so product decisions can be made from measurable behavior across the full route lifecycle:

- app open and session start
- location permission and readiness
- recording start, progress, stop, and save
- measured run creation
- replay selection and completion
- import and export flows
- history and track detail consumption
- reliability, latency, and data quality

This plan aims to cover as much of the app as possible while keeping the schema stable, privacy-safe, and useful for dashboards.

## Principles

- Track outcomes, not just taps.
- Prefer derived metrics over raw event volume.
- Keep PII and raw coordinates out of analytics.
- Separate product analytics from diagnostics and crash logging.
- Every event should answer a product, UX, or reliability question.

## Common Event Fields

Attach these fields to most events where applicable:

- `session_id`: app session identifier
- `user_id`: anonymous stable analytics identifier
- `app_version`
- `build_number`
- `ios_version`
- `device_family`
- `screen`
- `source`: where the action started, for example `map_tab`, `tracks_tab`, `track_detail`
- `track_id`: internal identifier when the action is tied to a track
- `track_type`: `record`, `import`, `measurement`
- `replay_mode`: `classical`, `replay`
- `recording_policy_type`: `manual`, `reaching_speed`, `reaching_distance`
- `recording_policy_name`
- `has_replay_selected`
- `permission_state`

## Product Areas And Metrics

### 1. App Usage And Retention

Events:

- `app_opened`
- `app_became_active`
- `tab_selected`

Metrics:

- Daily active users: how many unique users open the app each day.
- Weekly active users: how many unique users remain active over time.
- DAU/WAU ratio: how habit-forming the product is.
- Sessions per user: how often people come back.
- Avg session length: whether users actually spend time recording or reviewing routes.
- Tab distribution: which primary surfaces matter most, `Map` vs `Tracks`.

### 2. Location Permission Funnel

Events:

- `location_permission_prompt_shown`
- `location_permission_requested`
- `location_permission_changed`
- `location_updates_started`
- `location_updates_failed`

Metrics:

- Prompt-to-grant conversion: how many users grant access after being asked.
- Grant rate by app stage: whether asking too early hurts conversion.
- Denial rate: how much the app is blocked by permissions.
- Time to first authorized state: friction in onboarding.
- Time to first location fix: readiness of the app after access is granted.

### 3. Recording Funnel

Events:

- `recording_start_tapped`
- `recording_started`
- `recording_point_appended`
- `recording_stop_tapped`
- `recording_stopped`
- `recording_saved`
- `recording_discarded`
- `recording_empty_rejected`

Metrics:

- Recording start rate: how often users begin a run after opening the map.
- Start-to-save conversion: whether sessions finish successfully.
- Empty recording rate: failed attempts due to no points or immediate stop.
- Avg recordings per active user: core product usage intensity.
- Recording duration distribution: what kinds of runs people record.
- Points per recording: tracking density and signal quality.
- Distance per recording: real product utility and use-case mix.

### 4. Auto-Stop And Measurement Usage

Events:

- `measurement_picker_opened`
- `recording_policy_selected`
- `measurement_progress_updated`
- `measurement_auto_stopped`
- `measured_track_saved`
- `measured_track_opened`

Metrics:

- Policy adoption rate: how often users choose measurement modes over manual.
- Policy mix: which presets matter, speed-based or distance-based.
- Auto-stop completion rate: whether policies successfully complete once started.
- Measured track save rate: how many completed attempts become saved comparisons.
- Repeat usage by policy: which measurement modes create habitual use.
- Median completion time by policy: how demanding each preset is.

### 5. Replay Usage

Events:

- `replay_track_selected`
- `replay_track_deselected`
- `replay_checkpoint_entered`
- `replay_auto_started`
- `replay_progress_updated`
- `replay_completed`
- `replay_recording_saved`
- `replay_completion_below_threshold`

Metrics:

- Replay attach rate: how often users pick an old track to compare against.
- Replay start rate after selection: whether the feature is understandable.
- Replay completion rate: whether users can finish guided replays.
- Completion threshold pass rate: how often replay runs qualify as valid.
- Time from selection to start: friction in the replay setup flow.
- Replay-derived save rate: practical value of the feature.

### 6. Import And Export Funnel

Events:

- `import_cta_tapped`
- `import_picker_presented`
- `import_started`
- `import_succeeded`
- `import_failed`
- `export_cta_tapped`
- `export_started`
- `export_succeeded`
- `export_failed`

Metrics:

- Import attempt rate: external route adoption.
- Import success rate: health of the file import path.
- Invalid file rate: quality of inbound files and UX mismatch.
- Export usage rate: how often users want data portability.
- Export success rate: reliability of sharing and backup workflows.
- Imported track re-open rate: whether imported content remains useful after ingest.

### 7. Tracks Tab Consumption

Events:

- `tracks_tab_opened`
- `tracks_hero_stat_tapped`
- `tracks_section_scrolled_to`
- `history_more_tapped`
- `measurements_more_tapped`
- `imports_more_tapped`
- `track_card_opened`
- `measured_track_card_opened`
- `empty_state_cta_tapped`

Metrics:

- Tracks tab open rate: interest in browsing past activity.
- Section engagement rate: which content types users actually inspect.
- Card open-through rate: whether the carousels produce detail views.
- Empty state CTA conversion: whether the tab successfully routes users back to action.
- History vs measurement vs import interest split: what stored content provides the most value.

### 8. Detail View Engagement

Events:

- `track_detail_opened`
- `track_detail_closed`
- `track_detail_export_tapped`
- `track_detail_replay_tapped`
- `track_deleted`

Metrics:

- Detail views per stored track: depth of engagement with recorded content.
- Replay-from-detail rate: how often details lead into comparison behavior.
- Export-from-detail rate: value of archived tracks.
- Delete rate: whether users perceive low quality or clutter in saved tracks.

### 9. Storage And Library Health

Events:

- `track_saved_to_storage`
- `track_updated_in_storage`
- `track_deleted_from_storage`
- `measured_track_saved_to_storage`
- `storage_operation_failed`

Metrics:

- Save failure rate: persistence reliability.
- Save latency: how long it takes from stop to durable storage.
- Track library growth per user: whether the app is building long-term value.
- Measurement library growth: stickiness of benchmarking behavior.
- Deletion-to-save ratio: health of saved content quality.

### 10. Map And Runtime Performance

Events:

- `map_view_opened`
- `map_ready`
- `map_snapshot_requested`
- `map_snapshot_succeeded`
- `map_snapshot_failed`
- `screen_render_slow`

Metrics:

- Time to map ready: startup experience on the core screen.
- Snapshot generation latency: performance of track previews.
- Snapshot failure rate: reliability of visual route previews.
- Slow screen render count: UI performance regressions over time.

### 11. Location Data Quality

Events:

- `location_fix_received`
- `location_fix_ignored`
- `location_accuracy_low`
- `speed_value_clamped`
- `distance_filter_effective`

Metrics:

- Avg time between fixes during active recording: sensor continuity.
- Low accuracy rate: whether poor GPS quality is affecting route trustworthiness.
- Negative speed clamp rate: how noisy source speed data is.
- Recording with sparse points rate: likely bad route fidelity.
- Outlier distance jump rate: possible GPS spikes or processing bugs.

### 12. Reliability And Error Monitoring

Events:

- `error_shown_to_user`
- `recording_save_failed`
- `import_decode_failed`
- `export_file_write_failed`
- `location_service_error`
- `unexpected_state_detected`

Metrics:

- Error rate per session: overall product stability.
- Error rate per funnel stage: where users get blocked.
- User-visible alert rate: how noisy the app feels.
- Top error classes by frequency: engineering prioritization input.

## Recommended Derived Business KPIs

These should sit on the main dashboard:

- `activation_rate`: users who grant location and start at least one recording within their first 3 sessions.
- `first_recording_success_rate`: first-time users who save a non-empty track.
- `weekly_recording_retention`: users who save at least one track in consecutive weeks.
- `measurement_adoption_rate`: active recorders who use an auto-stop policy.
- `replay_adoption_rate`: active library users who try replay.
- `library_value_rate`: users with at least 3 saved tracks who still return weekly.
- `imported_content_retention_rate`: users who import and later reopen imported tracks.

## Dashboard Views

### Executive Dashboard

- DAU, WAU, retention
- activation rate
- recordings started, saved, discarded
- import success rate
- replay adoption rate
- top reliability issues

### Growth And Funnel Dashboard

- permission funnel
- map open to recording start funnel
- recording start to save funnel
- tracks tab to detail view funnel
- import funnel

### Feature Dashboard

- manual vs measured recording split
- policy usage by preset name
- replay selection, start, completion
- export usage

### Quality Dashboard

- save latency
- map readiness latency
- snapshot success and failure
- sparse track rate
- low accuracy rate
- top errors

## Privacy And Data Boundaries

Do not send:

- raw GPS coordinates
- full route geometry
- precise addresses
- file names from imported documents
- user-entered names if they can reveal identity

Safe derived values:

- point count
- total distance bucket
- duration bucket
- speed bucket
- boolean flags
- anonymized track identifiers
- coarse country or locale if needed

## Event Naming Rules

- Use past-tense for completed events: `recording_started`, `import_succeeded`.
- Use explicit failure events instead of generic `error`.
- Keep parameters normalized and enumerable where possible.
- Do not overload one event with unrelated meanings.

## Suggested Implementation Layers

### 1. Analytics Service

Create a dedicated service, for example `AnalyticsServiceProtocol`, injected through `DependencyManager`.

Responsibilities:

- receive structured analytics events
- enrich with common context
- forward to provider SDKs
- allow debug logging in development

### 2. Product Event Model

Use a typed event enum or event structs instead of stringly-typed calls spread across views.

Responsibilities:

- define event names centrally
- define allowed parameter keys
- reduce schema drift

### 3. Performance And Diagnostics Layer

Keep performance timers and operational failures separate from product events, even if sent to the same backend.

### 4. Screen Tracking

Track meaningful screen exposures:

- map
- tracks tab
- track history
- measured track list
- imported track list
- track detail

Only emit once per appearance, not on every redraw.

## Recommended Instrumentation Order

### Phase 1: Core Funnel

- app open
- permission events
- recording start, stop, save, empty rejection
- tracks tab open
- track detail open
- import success and failure

This phase measures whether the core product works.

### Phase 2: Feature Depth

- measurement mode selection and completion
- replay selection and completion
- export events
- section-level tracks tab engagement

This phase measures what advanced features create real value.

### Phase 3: Performance And Quality

- map readiness timers
- storage latency
- snapshot latency
- GPS quality signals
- structured error taxonomy

This phase measures trust, quality, and engineering health.

## Success Criteria

The analytics rollout is successful when the team can answer these questions confidently:

- How many users get from first open to first saved track?
- Where do users fail in the permission and recording funnel?
- Do measurement presets create repeat usage?
- Does replay meaningfully increase return behavior?
- Are imported tracks used after import or ignored?
- Is poor GPS quality or app reliability reducing saved-track success?

## Minimum Viable Schema Checklist

- every key screen has a screen event
- every main funnel has start, success, and failure events
- every saved artifact has a creation event
- every user-visible error has a categorized diagnostic event
- every latency-sensitive operation has a timer
- no event sends raw route coordinates
