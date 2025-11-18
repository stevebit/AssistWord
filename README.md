# 🗣️ BERT Word Prediction - AAC App

An advanced **Augmentative and Alternative Communication (AAC)** app for iPad that uses **BERT (Bidirectional Encoder Representations from Transformers)** to provide intelligent, context-aware word predictions for building sentences.

![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![BERT](https://img.shields.io/badge/Model-BERT--base-green.svg)
![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)

---

## ✨ Features

### 🤖 AI-Powered Predictions
- **BERT-base model** (110M parameters) for contextual understanding
- **15 word suggestions** ranked by probability
- **Bidirectional attention** - sees full sentence context
- **On-device inference** - no internet required, privacy-first

### 📱 User Interface
- **Large, easy-to-tap buttons** for accessibility
- **Probability display** (testing mode) shows model confidence
- **Letter filtering** to narrow down word choices
- **Sentence display** with delete and clear functions
- **Responsive grid layout** optimized for iPad

### 🎯 Technical Highlights
- **Core ML integration** for fast on-device inference (~50-100ms)
- **WordPiece tokenization** compatible with BERT
- **Masked Language Modeling (MLM)** approach
- **Softmax probability calculation** with numerical stability
- **Smart word filtering** removes punctuation and invalid tokens

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SwiftUI Interface                         │
│                   (ContentView.swift)                        │
├─────────────────────────────────────────────────────────────┤
│               Word Prediction Service                        │
│          (WordPredictionService.swift)                       │
│  • Tokenization                                              │
│  • Model inference                                           │
│  • Probability calculation                                   │
│  • Word filtering                                            │
├─────────────────────────────────────────────────────────────┤
│                  BERT Tokenizer                              │
│              (GPT2Tokenizer.swift → BERTTokenizer)          │
│  • WordPiece tokenization                                    │
│  • Special token handling ([CLS], [MASK], [SEP])           │
│  • Attention mask generation                                 │
├─────────────────────────────────────────────────────────────┤
│                Core ML Model                                 │
│            (WordPredictor.mlpackage)                         │
│  • BERT-base-uncased                                         │
│  • Input: [batch_size=1, seq_len=128]                      │
│  • Output: [batch_size=1, seq_len=128, vocab_size=30522]  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Requirements

- **macOS** with Xcode 15.0+
- **iPad** running iOS 15.0 or later
- **Apple ID** (free account works)
- **Python 3.9+** (for model conversion only)

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/stevendisano/bert-word-prediction.git
cd bert-word-prediction
```

### 2. Install Dependencies (for model conversion)

```bash
pip install transformers coremltools torch
```

### 3. Convert BERT Model to Core ML ⚠️ REQUIRED

**The model weights are not included in the repo due to GitHub's 100MB file size limit.**

You must generate the Core ML model before running the app:

```bash
cd Predict
python3 convert_model.py
```

This will:
- Download `bert-base-uncased` from Hugging Face (~440MB)
- Convert it to Core ML format (~420MB)
- Save to `Predict/WordPredictor.mlpackage/`

**First time setup takes ~2-5 minutes** depending on your internet speed.

### 4. Deploy to iPad

Follow the detailed instructions in **[DEPLOYMENT.md](DEPLOYMENT.md)**

**Quick steps:**
1. Open `Predict/Predict.xcodeproj` in Xcode
2. Connect your iPad via USB
3. Select your iPad as the target device
4. Configure code signing with your Apple ID
5. Click Run (▶️)

---

## 📂 Project Structure

```
Ipad/
├── Predict/
│   ├── Predict.xcodeproj/          # Xcode project file
│   ├── Predict/
│   │   ├── PredictApp.swift        # App entry point
│   │   ├── ContentView.swift       # Main UI (SwiftUI)
│   │   ├── WordPredictionService.swift  # Prediction logic
│   │   ├── GPT2Tokenizer.swift     # BERT tokenizer (renamed)
│   │   ├── WordPredictor.mlpackage/     # Core ML BERT model
│   │   ├── vocab.json              # BERT vocabulary (30,522 tokens)
│   │   └── merges.txt              # Placeholder for BERT
│   ├── convert_model.py            # Python script to convert BERT
│   └── MODEL_SETUP.md              # Model conversion guide
├── DEPLOYMENT.md                    # iPad deployment instructions
├── README.md                        # This file
└── .gitignore                       # Git ignore rules
```

---

## 🔬 How It Works

### 1. **Tokenization**
User input "I asked" is converted to token IDs:
```
[CLS] "i" "asked" [MASK] "and" [SEP] [PAD] [PAD] ...
[101]  [1045] [2356] [103] [1998] [102]  [0]   [0]  ...
```

### 2. **BERT Inference**
- Model processes the entire sequence with bidirectional attention
- Generates logits for each position: `[1, 128, 30522]`
- Extracts logits at the `[MASK]` position (position 3)

### 3. **Probability Calculation**
- Apply softmax to convert logits → probabilities
- Sort by probability (highest first)
- Filter out punctuation and invalid tokens

### 4. **Word Display**
- Top 15 words shown with probabilities
- Example for "I asked":
  - **Him** (5.6%)
  - **Her** (2.6%)
  - **Quietly** (0.9%)

### 5. **Context Word Trick**
Adding "and" after `[MASK]` prevents punctuation predictions:
- Without: `[CLS] "i" "asked" [MASK] [SEP]` → predicts `.` (81%)
- With: `[CLS] "i" "asked" [MASK] "and" [SEP]` → predicts `him` (5.6%)

---

## 📊 Model Details

| Property | Value |
|----------|-------|
| **Model** | BERT-base-uncased |
| **Parameters** | 110 million |
| **Vocabulary Size** | 30,522 tokens |
| **Max Sequence Length** | 128 tokens |
| **Tokenization** | WordPiece |
| **Framework** | Core ML (converted from PyTorch) |
| **Inference Time** | ~50-100ms on iPad |
| **Model Size** | ~420MB |

---

## 🎨 UI Screenshots

### Main Interface
- Sentence display area at top
- 15 word prediction buttons (5x3 grid)
- Letter filter buttons at bottom
- Delete and Clear All controls

### Features
- **Probability display**: Shows model confidence (testing mode)
- **Letter filtering**: Tap a letter to filter words
- **Contextual predictions**: Suggestions change based on sentence

---

## 🧪 Testing

### Test BERT Predictions (Python)

```bash
python3 test_bert_prediction.py
```

This shows raw BERT output with probabilities for test sentences.

### Monitor App Logs

```bash
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Predict"' --level debug
```

---

## 🔧 Configuration

### Customize Starting Words

Edit `WordPredictionService.swift` (lines 87-89):

```swift
let words = [
    "I", "The", "It", "You", "We", "What", "This", "Can", 
    "How", "There", "When", "My", "If", "He", "She"
]
```

### Hide Probability Display

Comment out in `ContentView.swift` (lines 86-90):

```swift
// if prediction.probability > 0 {
//     Text(String(format: "%.1f%%", prediction.probability * 100))
//         .font(.system(size: 12, weight: .medium))
//         .foregroundColor(.white.opacity(0.8))
// }
```

### Adjust Number of Predictions

Change in `WordPredictionService.swift` (line 177):

```swift
let result = Array(wordPredictions.prefix(15))  // Change 15 to desired number
```

---

## 🐛 Troubleshooting

### "Core ML model not available"
- Ensure `WordPredictor.mlpackage` exists in `Predict/Predict/`
- Run `python3 convert_model.py` to regenerate the model

### "Failed to code sign"
- Add your Apple ID in Xcode → Settings → Accounts
- Enable "Automatically manage signing" in project settings

### "iPad not detected"
- Connect iPad via USB
- Unlock iPad and trust the computer
- Check: Window → Devices and Simulators in Xcode

### Slow predictions
- First prediction is slower (~200ms) due to model loading
- Subsequent predictions are fast (~50-100ms)
- Performance depends on iPad model (newer = faster)

---

## 🚧 Known Limitations

1. **Vocabulary Coverage**: BERT-base has 30,522 tokens, may not include rare/slang words
2. **Sentence Length**: Limited to 128 tokens (truncated if longer)
3. **Single Word Prediction**: Currently predicts one word at a time
4. **Model Size**: 420MB - requires significant storage
5. **First Launch**: Takes a few seconds to load model

---

## 🔮 Future Enhancements

- [ ] Multi-word phrase predictions
- [ ] User vocabulary customization
- [ ] Prediction history and learning
- [ ] Voice output (text-to-speech)
- [ ] Smaller model option (DistilBERT)
- [ ] Fine-tuning on AAC-specific corpus
- [ ] Dark mode support
- [ ] Accessibility improvements (VoiceOver)

---

## 📚 Technical Details

### Why BERT over GPT-2?

**BERT (Bidirectional):**
- ✅ Sees context before AND after the mask
- ✅ Better for filling in blanks (MLM task)
- ✅ More natural for single-word prediction

**GPT-2 (Causal/Left-to-right):**
- ❌ Only sees context before the current position
- ❌ Designed for continuous text generation
- ❌ Tends to predict low-probability tokens

### Softmax Numerical Stability

```swift
let maxLogit = logits.max() ?? 0.0
let expValues = logits.map { exp($0 - maxLogit) }
let sumExp = expValues.reduce(0, +)
let probability = expValue / sumExp
```

Subtracting `maxLogit` prevents overflow in `exp()` calculation.

---

## 📖 Resources

- [BERT Paper](https://arxiv.org/abs/1810.04805) - Original BERT research
- [Hugging Face BERT](https://huggingface.co/bert-base-uncased) - Pre-trained model
- [Core ML Documentation](https://developer.apple.com/documentation/coreml) - Apple's ML framework
- [AAC Research](https://www.asha.org/practice-portal/professional-issues/augmentative-and-alternative-communication/) - Communication aids

---

## 🤝 Contributing

Contributions are welcome! Areas of interest:

- Model optimization (quantization, pruning)
- UI/UX improvements for accessibility
- Additional language support
- Performance benchmarking
- Bug fixes and testing

---

## 📄 License

This project is licensed under the **Apache License 2.0**.

The BERT model (`bert-base-uncased`) is licensed under Apache 2.0 by Google and Hugging Face.

---

## 👤 Author

**Steven DiSano**
- GitHub: [@stevendisano](https://github.com/stevendisano)

---

## 🙏 Acknowledgments

- **Google Research** - BERT model
- **Hugging Face** - Pre-trained models and transformers library
- **Apple** - Core ML framework
- **AAC Community** - Inspiration and feedback

---

## 📮 Support

For questions or issues:
1. Check [DEPLOYMENT.md](DEPLOYMENT.md) for setup help
2. Review [Troubleshooting](#-troubleshooting) section
3. Open an issue on GitHub

---

**Built with ❤️ for augmentative and alternative communication**
