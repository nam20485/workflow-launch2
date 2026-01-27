# Model Acquisition Guide - Summary

## Required Models

You need two ONNX models:

1. **Face Detection Model** - RetinaFace or SCRFD (640x640 input)
2. **Face Recognition Model** - ArcFace (112x112 input, 512-dim output)

## Quick Start - Download Pre-trained Models

### Option 1: InsightFace (Recommended)

```bash
pip install insightface onnxruntime
```

```python
import insightface
from insightface.app import FaceAnalysis

app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'])
app.prepare(ctx_id=0, det_size=(640, 640))

# Models auto-download to: ~/.insightface/models/buffalo_l/
# Copy:
# - det_10g.onnx (detection)
# - w600k_r50.onnx (recognition)
```

### Option 2: ONNX Model Zoo

- Download from: https://github.com/onnx/models
- Look for RetinaFace, UltraFace models

## Testing Your Models

```python
import onnxruntime as ort

session = ort.InferenceSession("detection.onnx")
print("Input shape:", session.get_inputs()[0].shape)
print("Output shape:", session.get_outputs()[0].shape)
```

## Model Placement

Place models in your project:
```
PerformerIdentifier/
└── Models/
    ├── detection.onnx
    └── recognition.onnx
```

For complete download instructions, conversion guides, optimization techniques, and troubleshooting, see the full Model Acquisition Guide artifact in the conversation above.