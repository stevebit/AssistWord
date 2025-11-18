//
//  ContentView.swift
//  Predict
//
//  Assistive communication app for sentence building
//

import SwiftUI

struct ContentView: View {
    @State private var sentence: String = ""
    @State private var selectedLetter: String = ""
    @State private var updateTrigger: Int = 0
    private let predictionService = WordPredictionService()
    
    private var predictedWords: [WordPrediction] {
        // Force recalculation when sentence or selectedLetter changes
        print("🔄 ContentView: predictedWords computed - sentence: '\(sentence)', selectedLetter: '\(selectedLetter)'")
        let predictions = predictionService.predictWordsWithProbabilities(for: sentence)
        
        // Filter by selected letter if any
        let filtered: [WordPrediction]
        if selectedLetter.isEmpty {
            filtered = predictions
        } else {
            filtered = predictions.filter { $0.word.lowercased().hasPrefix(selectedLetter.lowercased()) }
        }
        
        // BERT predictions are sorted by probability (most likely first)
        // Keep all 15 words in probability order
        let result = Array(filtered.prefix(15))
        
        print("📋 ContentView: returning \(result.count) predictions: \(result.map { "\($0.word) (\(String(format: "%.1f", $0.probability * 100))%)" })")
        return result
    }
    
    private var availableLetters: [String] {
        let words = predictionService.predictWords(for: sentence)
        return predictionService.getStartingLetters(from: words)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Section: Sentence Display
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Sentence:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Text(sentence.isEmpty ? "Start building your sentence..." : sentence)
                        .font(.system(size: 32, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // Middle Section: Word Buttons (15 words)
                VStack(spacing: 15) {
                    Text("Tap a word to add it:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 15) {
                        ForEach(predictedWords, id: \.word) { prediction in
                            Button(action: {
                                addWordToSentence(prediction.word)
                            }) {
                                VStack(spacing: 4) {
                                    Text(prediction.word.capitalized)
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    // Show probability if available (not for hardcoded starters)
                                    if prediction.probability > 0 {
                                        Text(String(format: "%.1f%%", prediction.probability * 100))
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 70)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onAppear {
                                print("🎨 Rendering word button: '\(prediction.word)' (\(String(format: "%.1f", prediction.probability * 100))%)")
                            }
                        }
                    }
                    .padding(.horizontal)
                    .id("words-\(sentence)-\(selectedLetter)-\(updateTrigger)") // Force update when sentence or filter changes
                }
                .padding(.vertical, 20)
                
                Spacer()
                
                // Bottom Section: Letter Filters
                VStack(spacing: 15) {
                    Text("Filter by letter:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        // Clear filter button
                        Button(action: {
                            selectedLetter = ""
                        }) {
                            Text("All")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(selectedLetter.isEmpty ? .white : .blue)
                                .frame(width: 60, height: 60)
                                .background(selectedLetter.isEmpty ? Color.blue : Color(.systemGray5))
                                .cornerRadius(10)
                        }
                        
                        // Letter buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(availableLetters, id: \.self) { letter in
                                    Button(action: {
                                        selectedLetter = selectedLetter == letter ? "" : letter
                                    }) {
                                        Text(letter)
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(selectedLetter == letter ? .white : .blue)
                                            .frame(width: 60, height: 60)
                                            .background(selectedLetter == letter ? Color.blue : Color(.systemGray5))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 20)
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
                    }
                    
                    Button(action: {
                        sentence = ""
                        selectedLetter = ""
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clear All")
                        }
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.orange)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Sentence Builder")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func addWordToSentence(_ word: String) {
        print("➕ Adding word '\(word)' to sentence. Current: '\(sentence)'")
        if sentence.isEmpty {
            sentence = word.capitalized
        } else {
            sentence += " " + word.lowercased()
        }
        selectedLetter = "" // Clear filter after adding word
        updateTrigger += 1 // Force view update
        print("✅ New sentence: '\(sentence)', updateTrigger: \(updateTrigger)")
    }
}

#Preview {
    ContentView()
}
