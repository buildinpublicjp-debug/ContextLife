# Project: ContextLife

> "Record everything. Explain nothing."

## 1. Philosophy

**"Your life is the context."**

- アプリは「記録インフラ」に徹する
- 知性（整形・要約・分析）はClaudeに任せる
- ローカルファースト、プライバシー最優先
- API代ゼロ（on-device処理）

## 2. Quick Reference

| Item | Value |
|------|-------|
| Platform | iOS 17+ |
| Language | Swift 6.0 |
| UI Framework | SwiftUI |
| Architecture | MVVM with @Observable |
| Data Persistence | SwiftData |
| Speech Recognition | WhisperKit (Core ML) |
| Audio Recording | AVAudioEngine |
| Location | Core Location (Significant-Change) |
| Monetization | RevenueCat |

## 3. Design Language

**"Terminal meets Zen."**

| Element | Value |
|---------|-------|
| Background | #0D1117 (almost black) |
| Primary | #00FF66 (terminal green) |
| Font | SF Mono |
| Style | Minimal, retro, quiet |
| Animation | Typewriter effect (sparingly) |

## 4. Project Structure

```
ContextLife/
├── Sources/
│   ├── App/
│   │   └── ContextLifeApp.swift
│   ├── Features/
│   │   ├── Timeline/
│   │   ├── History/
│   │   └── Settings/
│   └── Core/
│       ├── Models/
│       │   ├── DailyRecord.swift
│       │   ├── TranscriptionSegment.swift
│       │   └── LocationVisit.swift
│       ├── Services/
│       │   ├── AudioRecorder.swift
│       │   ├── WhisperTranscriber.swift
│       │   └── LocationTracker.swift
│       └── Extensions/
├── Tests/
│   ├── ModelTests/
│   └── ServiceTests/
└── Resources/
```

## 5. Data Models

### DailyRecord
- 日付ベースで1日分のデータを管理
- 複数のTranscriptionSegmentを保持
- 同じ日は同じDailyRecordに追加

### TranscriptionSegment
- 15分ごとの録音単位
- timestamp, duration, audioFilePath, transcription
- isProcessed, processingFailedフラグ

### LocationVisit
- 滞在地を記録
- arrival/departure時刻で期間管理
- TranscriptionSegmentとは時刻ベースで紐付け（リレーションなし）

## 6. Coding Standards

### DO
- Swift 6の厳密な並行処理を使用
- @Observable を使用
- 1ビュー200行以内
- Guard early, return early
- 意味のある変数名

### DO NOT
- @ObservableObject（古いAPI）
- 強制アンラップ（!）
- UIKitの混用（SwiftUIで実現可能な限り）
- 巨大なビュー
- Magic numbers

## 7. Testing Strategy (TDD)

### Test First
1. テストを書く（Red）
2. 最小限の実装（Green）
3. リファクタリング（Refactor）

### Test Categories
- **ModelTests**: データモデルの振る舞い
- **ServiceTests**: AudioRecorder, WhisperTranscriber等
- **IntegrationTests**: データフロー全体

## 8. Key Principles

| # | Principle | Meaning |
|---|-----------|----------|
| 1 | Less is more | 機能を足すより削る |
| 2 | Passive over active | ユーザーに操作させない |
| 3 | Data over decoration | 見た目より情報 |
| 4 | Local over cloud | プライバシーを守る |
| 5 | Record, don't interpret | 記録だけ、解釈はAIに |
| 6 | Boring is good | 存在を忘れるくらいが丁度いい |

## 9. Monetization

| Feature | Free | Pro ($4.99/mo) |
|---------|:----:|:--------------:|
| Recording | ✅ | ✅ |
| Location | ✅ | ✅ |
| Whisper Model | base | large-v3_turbo |
| History | 3 days | Unlimited |
| Export | ❌ | ✅ |
| Obsidian Sync | ❌ | ✅ |

## 10. Current Phase

**Phase 5-6: Data Persistence & History**

- [ ] DailyRecord model
- [ ] TranscriptionSegment model
- [ ] SwiftData configuration
- [ ] Auto-save on recording stop
- [ ] History view with real data

---

*Last updated: 2026-01-28*