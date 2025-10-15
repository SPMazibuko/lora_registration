# Edge Agent (Raspberry Pi)

The edge agent runs on Raspberry Pi hardware to perform on-device face detection, embedding, matching, and event reporting for the biometric access platform.

## Core Capabilities

- Capture frames from the Pi camera using OpenCV with adjustable quality heuristics (lighting, blur, occlusion).
- Detect faces in real time using a YOLOv8n-face model converted to TensorFlow Lite (INT8) for efficient inference.
- Generate embeddings via a MobileFaceNet/ArcFace TFLite model and normalise vectors for cosine similarity matching.
- Maintain a local cache of user embeddings relevant to the device's assigned location; sync periodically via Hasura GraphQL queries.
- Perform local matching with configurable thresholds and multi-sample consensus to minimise false accept/reject rates.
- Report authentication events to Hasura over HTTPS GraphQL using device-scoped JWTs, with an offline queue and exponential backoff.
- Fallback to LPWAN uplinks (LoRaWAN/NB-IoT) using a compact payload format when primary connectivity is unavailable.

## Proposed Directory Structure

```
edge-pi/
├── pyproject.toml
├── poetry.lock
├── src/
│   ├── camera.py
│   ├── detect.py
│   ├── embed.py
│   ├── match.py
│   ├── cache.py
│   ├── comms.py
│   ├── storage.py
│   └── main.py
├── config/
│   ├── default.toml
│   └── secrets/
├── models/
│   ├── yolov8n-face.tflite
│   └── mobilefacenet.tflite
├── scripts/
│   ├── install.sh
│   ├── deploy.sh
│   └── systemd/
│       └── edge-agent.service
└── tests/
    ├── conftest.py
    ├── test_match.py
    ├── test_cache.py
    └── data/
```

## Operational Considerations

- **Environment** — Python 3.11 on Raspberry Pi OS or Ubuntu Server (64-bit). Use `poetry` for locked dependencies.
- **Model Deployment** — Pre-convert models to TFLite and distribute via OTA updates or object storage (signed and versioned).
- **Configuration** — `config/default.toml` holds thresholds, API endpoints, LPWAN options. Device-specific secrets injected via provisioning flow.
- **Resilience** — Local queue persists events while offline. Retry strategy uses exponential backoff with jitter (`tenacity`).
- **Clock Sync** — `chrony` ensures time accuracy for JWT validation and event ordering.
- **Security** — Secrets stored encrypted at rest (e.g., using `cryptography`). Filesystem locked down with minimal attack surface.

Refer to `../docs/solution-architecture.md` for details on communication flows, security posture, and LPWAN integration.
