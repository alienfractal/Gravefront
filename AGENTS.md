# Working in Gravefront Arena

Read `docs/ARCHITECTURE.md` before adding units, levels, screens, animations, assets, or services. Use RobotFluttbag and CoolorBurn as structural references; follow the RTS ownership table and actual source when adapting their patterns.

Keep combat and campaign rules independent of Flutter/Flame rendering. Put new code beside the state and responsibility it serves. Asset decoding belongs in cache services; frame choice belongs in handlers; screen transitions belong in `CampaignFsm`. Use FlutterGen's `Assets` references for bundled asset paths and regenerate `lib/gen/assets.gen.dart` after adding assets. Optional horizontal sheet suffixes use `_WxH-frames` or `-WxH-frames`. Keep the 320 × 200 camera and 320 × 160 battlefield at the project's documented scale with nearest-neighbor sampling.

Update `docs/ARCHITECTURE.md` and `README.md` when ownership or user-visible behavior changes. Run formatting, analysis, tests, and a Windows build for code changes.
