# VibeCheck – Flask Backend Setup

## Folder structure
```
vibecheck_backend/
├── app.py               ← Flask server (main entry point)
├── train_toxicity.py    ← One-time training script
├── download_nltk.py     ← One-time NLTK data download
├── requirements.txt
├── saved_models/        ← Created automatically after training
│   ├── tfidf_vectorizer.joblib
│   ├── clf_toxic.joblib
│   ├── clf_severe_toxic.joblib
│   ├── clf_obscene.joblib
│   ├── clf_threat.joblib
│   ├── clf_insult.joblib
│   └── clf_identity_hate.joblib
└── analyze_screen.dart  ← Drop this into your Flutter lib/ folder
```

---

## Step 1 — Python environment

```bash
cd vibecheck_backend
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

---

## Step 2 — Download NLTK data (once)

```bash
python download_nltk.py
```

---

## Step 3 — Train and save the toxicity model (once)

Replace the paths below with your actual CSV locations:

```bash
python train_toxicity.py \
  --train  "/Users/muskanmanvi/Desktop/sentiment analysis/train(T).csv" \
  --test   "/Users/muskanmanvi/Desktop/sentiment analysis/test(T).csv" \
  --labels "/Users/muskanmanvi/Desktop/sentiment analysis/test_labels(T).csv"
```

Training takes ~2–5 minutes. You'll see F1/Recall scores for each label.
The models are saved to `saved_models/` — you only need to do this once.

---

## Step 4 — Start the server

```bash
python app.py
```

Server starts at **http://0.0.0.0:5000**

First request will also download the RoBERTa model (~500 MB) from HuggingFace
if it's not already cached locally.

---

## Step 5 — Flutter integration

### Add http package
In your Flutter project's `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.2.1
```
Then run `flutter pub get`.

### Replace AnalyzeScreen
Copy `analyze_screen.dart` into your Flutter `lib/` folder and update your
router/navigator to point to the new `AnalyzeScreen` class.

### Network address
Edit the constant at the top of `analyze_screen.dart`:

| Scenario                          | kApiBase                    |
|-----------------------------------|-----------------------------|
| Android emulator                  | `http://10.0.2.2:5000`      |
| iOS simulator (same Mac)          | `http://localhost:5000`     |
| Physical device (same WiFi)       | `http://192.168.x.x:5000`  |

### Android – allow cleartext HTTP
Add to `android/app/src/main/AndroidManifest.xml` inside `<application>`:
```xml
android:usesCleartextTraffic="true"
```

---

## API Reference

### `POST /analyze`
**Request**
```json
{ "text": "I feel really happy today!" }
```

**Response**
```json
{
  "sentiment": {
    "label": "Positive",
    "negative": 0.0123,
    "neutral":  0.1456,
    "positive": 0.8421
  },
  "toxicity": {
    "toxic":         { "detected": false, "confidence": 0.9812 },
    "severe_toxic":  { "detected": false, "confidence": 0.9967 },
    "obscene":       { "detected": false, "confidence": 0.9731 },
    "threat":        { "detected": false, "confidence": 0.9984 },
    "insult":        { "detected": false, "confidence": 0.9752 },
    "identity_hate": { "detected": false, "confidence": 0.9914 }
  },
  "personality": {
    "type": "ENFP",
    "description": "Extrovert, Intuitive, Feeling, Perceiving"
  }
}
```

### `GET /health`
Returns `{ "status": "ok" }` — useful for checking the server is up.