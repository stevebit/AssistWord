# 📱 iPad Deployment Guide

## Deploy BERT Word Prediction App to Your Physical iPad

This guide will walk you through deploying the word prediction app to your physical iPad device.

---

## 📋 Prerequisites

- ✅ macOS with Xcode installed
- ✅ Physical iPad with USB cable
- ✅ Apple ID (free account works!)
- ✅ iPad running iOS 15.0 or later

---

## 🚀 Deployment Steps

### Step 1: Connect Your iPad

1. **Connect iPad to Mac** via USB cable
2. **Unlock your iPad**
3. **Trust the computer** when prompted on iPad
   - A popup will appear: "Trust This Computer?"
   - Tap **"Trust"**
   - Enter your iPad passcode if requested

### Step 2: Open Project in Xcode

```bash
cd /path/to/Ipad/Predict
open Predict.xcodeproj
```

Or simply double-click `Predict.xcodeproj` in Finder.

### Step 3: Configure Code Signing

#### 3.1 Add Your Apple ID (First Time Only)

1. In Xcode menu: **Xcode → Settings → Accounts**
2. Click the **"+"** button at bottom left
3. Select **"Apple ID"**
4. Sign in with your Apple ID credentials
5. Click **"Done"**

#### 3.2 Set Up Signing for the Project

1. In Xcode's **left sidebar**, click the **"Predict"** project (blue icon at top)
2. Under **"TARGETS"**, select **"Predict"**
3. Click the **"Signing & Capabilities"** tab at the top
4. **Check** ☑️ **"Automatically manage signing"**
5. Under **"Team"**, select your Apple ID from the dropdown
6. (Optional) Change **"Bundle Identifier"** if there's a conflict:
   - Change from: `Word.Predict`
   - Change to: `com.yourname.Predict` (use your name/username)

### Step 4: Verify iPad is Detected

1. In Xcode menu: **Window → Devices and Simulators** (or `Cmd + Shift + 2`)
2. Click **"Devices"** tab
3. Your iPad should appear in the left sidebar
4. Status should show: **"Connected"** and a green dot
5. If not showing:
   - Unplug and replug iPad
   - Make sure iPad is unlocked
   - Check you clicked "Trust" on iPad

### Step 5: Select Your iPad as Target

1. In Xcode's **top toolbar**, find the device dropdown (left of the Play button)
2. It currently shows something like "iPad (A16) Simulator"
3. Click the dropdown
4. Under **"iOS Device"**, select **your iPad's name** (e.g., "Steven's iPad")

### Step 6: Build and Run

1. Click the **Play button (▶️)** in the top toolbar, or press `Cmd + R`
2. Xcode will:
   - ✅ Build the app
   - ✅ Code sign it
   - ✅ Install it on your iPad
   - ✅ Launch it automatically
3. **Wait for build to complete** (first build takes ~30 seconds)

### Step 7: Trust Developer on iPad (First Time Only)

If you see **"Untrusted Developer"** on your iPad:

1. On iPad: **Settings → General → VPN & Device Management**
2. Under **"Developer App"**, tap your Apple ID
3. Tap **"Trust [Your Apple ID]"**
4. Tap **"Trust"** in the confirmation dialog
5. Return to home screen and launch the app again

---

## ✅ Success!

You should now see the **Sentence Builder** app running on your iPad! 🎉

- Tap words to build sentences
- BERT model predicts next words based on context
- Probability percentages shown on each button (for testing)

---

## 🔧 Troubleshooting

### Issue: "Failed to code sign"

**Solution:**
- Make sure "Automatically manage signing" is checked
- Verify your Apple ID is selected under "Team"
- Try changing the Bundle Identifier to something unique

### Issue: "iPad not showing in device list"

**Solution:**
- Unplug and reconnect iPad
- Make sure iPad is unlocked (not in sleep mode)
- Check you clicked "Trust" on the iPad
- In Xcode: Window → Devices and Simulators → Check if it appears
- Restart Xcode if needed

### Issue: "Could not launch 'Predict'"

**Solution:**
- Check iPad storage (needs ~500MB free)
- Make sure iPad is running iOS 15.0 or later
- Try: Product → Clean Build Folder (`Cmd + Shift + K`), then rebuild

### Issue: "Provisioning profile error"

**Solution:**
- Go to Signing & Capabilities
- Uncheck "Automatically manage signing"
- Re-check "Automatically manage signing"
- Select your Team again

### Issue: "The app is already installed"

**Solution:**
- Delete the app from iPad
- Rebuild and run from Xcode

---

## 📊 Model Information

This app uses:
- **BERT-base-uncased** (110M parameters)
- **Core ML** for on-device inference
- **Vocabulary:** 30,522 tokens
- **Max sequence length:** 128 tokens
- **Masked Language Modeling** (MLM) approach

The model runs entirely on-device (no internet required) and provides contextual word predictions based on the sentence so far.

---

## 🔄 Making Changes

After making code changes:

1. Save your changes in Xcode or your editor
2. Select your iPad in Xcode's device dropdown
3. Click Play (▶️) or press `Cmd + R`
4. App will rebuild and deploy to iPad automatically

---

## 📱 App Features

### Word Prediction
- 15 contextual word suggestions
- Probability percentages shown (testing mode)
- Predictions ranked by BERT confidence

### Sentence Building
- Tap words to add to sentence
- Delete last word
- Clear entire sentence
- Filter words by starting letter

### Model Performance
- Fast on-device inference (~50-100ms per prediction)
- No internet connection required
- Privacy-focused (all processing local)

---

## 🎯 Next Steps

### Remove Probability Display (Production)

To hide the probability percentages for end users:

In `Predict/Predict/ContentView.swift`, comment out or remove lines 86-90:

```swift
// Show probability if available (not for hardcoded starters)
if prediction.probability > 0 {
    Text(String(format: "%.1f%%", prediction.probability * 100))
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(.white.opacity(0.8))
}
```

### Customize Starting Words

Edit the starter word list in `WordPredictionService.swift` (lines 87-89):

```swift
let words = [
    "I", "The", "It", "You", "We", "What", "This", "Can", 
    "How", "There", "When", "My", "If", "He", "She"
]
```

### Adjust Prediction Count

Change the number of predictions returned (currently 15) in `WordPredictionService.swift`:

```swift
let result = Array(wordPredictions.prefix(15))  // Change 15 to desired number
```

---

## 📝 License

This project uses the BERT model from Hugging Face (`bert-base-uncased`), which is licensed under Apache 2.0.

---

## 🆘 Need Help?

If you encounter issues:

1. Check the Xcode console for error messages
2. Verify all steps in this guide were followed
3. Try cleaning the build folder: `Product → Clean Build Folder`
4. Restart Xcode and reconnect iPad
5. Check iPad has enough storage space

---

**Happy Testing! 🚀**

