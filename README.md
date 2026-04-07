# Feature Documentation

## Structure

```structure
docs/
├── _common/                        ← Viết 1 lần cho cả project
│   ├── api-conventions.md          # Error codes, auth, pagination, timestamps
│   ├── test-strategy.md            # Test pyramid, environments, global DoD
│   └── architecture.md             # System diagram, layers, observability, deploy
│
└── features/
    ├── _template/                  ← Copy folder này khi bắt đầu feature mới
    │   ├── 01_PRD.md
    │   ├── 02_change-impact.md
    │   ├── 03_technical-design.md
    │   ├── 04_test-plan.md
    │   ├── 05_traceability-matrix.md
    │   └── 06_ADR-001_[title].md      # Thêm khi cần
    │
    ├── user-auth/                  ← Ví dụ feature đã có
    ├── product-catalog/
    └── checkout-flow/
```

## Bắt đầu feature mới

```bash
cp -r docs/features/_template docs/features/[feature-slug]
```

Rồi điền từng file. **Không copy nội dung từ `_common`** — chỉ link đến.

## Phân biệt common vs per-feature

| Nội dung | Common | Per-feature |
| - | - | - |
| Error codes & format | ✅ `api-conventions.md` | ❌ Không lặp lại |
| Auth scheme | ✅ `api-conventions.md` | ❌ Không lặp lại |
| Pagination format | ✅ `api-conventions.md` | ❌ Không lặp lại |
| Test pyramid & tooling | ✅ `test-strategy.md` | ❌ Không lặp lại |
| Test environments | ✅ `test-strategy.md` | ❌ Không lặp lại |
| Global DoD | ✅ `test-strategy.md` | ❌ Không lặp lại |
| System diagram | ✅ `architecture.md` | ❌ Không lặp lại |
| Layer responsibilities | ✅ `architecture.md` | ❌ Không lặp lại |
| **Feature requirements** | ❌ | ✅ `01_PRD.md` |
| **Data model của feature** | ❌ | ✅ `03_technical-design.md` |
| **Business logic đặc thù** | ❌ | ✅ `03_technical-design.md` |
| **API endpoints của feature** | ❌ | ✅ `openapi.yaml` |
| **Test cases cụ thể** | ❌ | ✅ `04_test-plan.md` |
| **Feature bị ảnh hưởng** | ❌ | ✅ `02_change-impact.md` |
| **FR → Test linkage** | ❌ | ✅ `05_traceability-matrix.md` |

## Workflow

Step 1: Dùng script Copy `_template` → `docs/features/[name]/` để tạo folder mới cho feature.

Step 2:`01_PRD.md`
   └─ Problem, requirements, acceptance criteria, success metrics

Step 3: `02_change-impact.md`
   └─ Greenfield? → "No impact", done
   └─ Có ảnh hưởng? → Map đầy đủ trước khi design

Step 4: `03_technical-design.md`
   └─ Chỉ viết phần đặc thù của feature
   └─ Link đến `_common` thay vì copy

Step 5: `04_test-plan.md`
   └─ Chỉ viết test cases, không lặp strategy

Step 6: `05_traceability-matrix.md`
   └─ Link FR → design section → test case IDs

Step 7: `06_ADR-xxx.md` (khi có quyết định kiến trúc đáng ghi)

Step 8: Implement & test
   └─ Cập nhật `05_traceability-matrix.md` khi tests pass

## Scope của mỗi file theo độ phức tạp

| File | CRUD đơn giản | Business phức tạp |
| - | - | - |
| `01_PRD.md` | ~20 dòng | ~50 dòng |
| `03_technical-design.md` | Data model + endpoints | + Business logic flows chi tiết |
| `02_change-impact.md` | "No impact" hoặc 1 bảng nhỏ | Phân tích đầy đủ |
| `04_test-plan.md` | ~10 test cases | ~30+ test cases |
| `05_traceability-matrix.md` | 4–5 dòng | 10–20 dòng |
| `06_ADR-xxx.md` | Thường không cần | 1–3 ADRs |
