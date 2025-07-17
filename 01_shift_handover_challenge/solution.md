# Solution.md – Shift Handover Challenge

## Summary


## What I fixed

### 1. I made models imutable


### 2. Implemented clean architecture

### 3. Seperated the widgets into modular layers

### 4. Error handling

### 5. Tests

### 6. Theme + UI

## Folder structure

```
lib/
├── core/
│   └── error/, theme/, utils/
├── features/
│   └── shift_handover/
│       ├── data/
│       ├── domain/
│       └── presentation/
```


## Feature status

* [x] Load shift report
* [x] Add notes
* [x] Submit report (with summary + end time)
* [x] Stored in memory
* [x] Bloc with error handling
* [x] Tests (unit + integration)
* [x] UI cleanup
