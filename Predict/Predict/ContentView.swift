//
//  ContentView.swift
//  Predict
//
//  Assistive communication app for sentence building
//

import SwiftUI

struct ContentView: View {
    @State private var sentence: String = ""
    @State private var updateTrigger: Int = 0
    @FocusState private var isTextEditorFocused: Bool
    private let predictionService = WordPredictionService()
    
    // Row 1: Mixed common words (pronouns + conjunctions + verbs)
    private let commonWords = ["a", "and", "can", "for", "I", "in", "is", "to", "we", "you"]
    
    // Row 2: Sentence builders (pronouns + common verbs)
    private let sentenceBuilders = ["am", "are", "do", "have", "he", "not", "she", "was", "will", "with"]
    
    private var predictedWords: [WordPrediction] {
        // Force recalculation when sentence changes
        print("🔄 ContentView: predictedWords computed - sentence: '\(sentence)'")
        let predictions = predictionService.predictWordsWithProbabilities(for: sentence)
        
        // BERT predictions are sorted by probability (most likely first)
        // Keep all 15 words in probability order
        let result = Array(predictions.prefix(15))
        
        print("📋 ContentView: returning \(result.count) predictions: \(result.map { "\($0.word) (\(String(format: "%.1f", $0.probability * 100))%)" })")
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Section: Sentence Display (Editable) - FIXED HEIGHT
            ZStack(alignment: .topLeading) {
                if sentence.isEmpty {
                    Text("Start building your sentence...")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $sentence)
                    .font(.system(size: 32, weight: .medium))
                    .frame(height: 120)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .focused($isTextEditorFocused)
                    .onChange(of: sentence) { _ in
                        updateTrigger += 1
                    }
            }
            .frame(height: 120)
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 20)
            .onTapGesture {
                isTextEditorFocused = true
            }
                
            // Middle Section: Word Buttons (15 words) - FIXED HEIGHT
            VStack(spacing: 15) {
                LazyVGrid(columns: [
                    GridItem(.fixed(190), spacing: 12),
                    GridItem(.fixed(190), spacing: 12),
                    GridItem(.fixed(190), spacing: 12),
                    GridItem(.fixed(190), spacing: 12)
                ], spacing: 15) {
                    ForEach(predictedWords, id: \.word) { prediction in
                        Button(action: {
                            addWordToSentence(prediction.word)
                        }) {
                            VStack(spacing: 4) {
                                Text(prediction.word.capitalized)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                
                                // Show probability if available (not for hardcoded starters)
                                if prediction.probability > 0 {
                                    Text(String(format: "%.1f%%", prediction.probability * 100))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                                .frame(width: 190, height: 70)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
                            }
                        .buttonStyle(PlainButtonStyle())
                        .onAppear {
                            print("🎨 Rendering word button: '\(prediction.word)' (\(String(format: "%.1f", prediction.probability * 100))%)")
                        }
                    }
                }
                .frame(height: 240)
                .padding(.horizontal)
                .id("words-\(sentence)-\(updateTrigger)") // Force update when sentence changes
            }
            .frame(height: 290)
            .padding(.vertical, 10)
            
            Spacer(minLength: 0)
            
            // Bottom Section: Two Rows of Common Words
            VStack(spacing: 12) {
                Text("Quick words:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    
                // Row 1: Mixed common words
                HStack(spacing: 10) {
                    ForEach(commonWords, id: \.self) { word in
                        Button(action: {
                            addWordToSentence(word)
                        }) {
                            Text(word.uppercased())
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(.label))
                                .frame(minWidth: 60, maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(.systemGray5))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                // Row 2: Sentence builders
                HStack(spacing: 10) {
                    ForEach(sentenceBuilders, id: \.self) { word in
                        Button(action: {
                            addWordToSentence(word)
                        }) {
                            Text(word.uppercased())
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(.label))
                                .frame(minWidth: 60, maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(.systemGray5))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 15)
            .background(Color(.systemGray6))
            
            // Action buttons
            HStack(spacing: 20) {
                Button(action: {
                    if !sentence.isEmpty {
                        let words = sentence.components(separatedBy: .whitespaces)
                        if words.count > 1 {
                            sentence = words.dropLast().joined(separator: " ")
                        } else {
                            sentence = ""
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "delete.left.fill")
                        Text("Delete")
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.red)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
                }
                
                Button(action: {
                    sentence = ""
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Clear All")
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
                }
            }
            .padding()
        }
    }
    
    private func addWordToSentence(_ word: String) {
        print("➕ Adding word '\(word)' to sentence. Current: '\(sentence)'")
        if sentence.isEmpty {
            sentence = word.capitalized
        } else {
            sentence += " " + word.lowercased()
        }
        updateTrigger += 1 // Force view update
        print("✅ New sentence: '\(sentence)', updateTrigger: \(updateTrigger)")
    }
}

#Preview {
    ContentView()
}
