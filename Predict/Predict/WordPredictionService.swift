//
//  WordPredictionService.swift
//  Predict
//
//  Handles word prediction using Core ML GPT-2 model only
//

import Foundation
import CoreML

// Struct to hold word and its probability
struct WordPrediction {
    let word: String
    let probability: Float
}

class WordPredictionService {
           // Core ML model and tokenizer
           private var wordPredictor: WordPredictor?
           private let tokenizer = BERTTokenizer()
           private let maxSeqLen = BERTTokenizer.maxSeqLen


    // Check if a word is valid for display
    private func isValidWord(_ word: String) -> Bool {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)

        // Skip empty strings
        if trimmed.isEmpty {
            return false
        }

        // Allow single letters "I" and "a"
        let allowedSingleLetters = Set(["i", "a"])
        if trimmed.count == 1 {
            return allowedSingleLetters.contains(trimmed.lowercased())
        }

        // Skip very long words
        if trimmed.count > 25 {
            return false
        }

        // Skip if it's mostly punctuation
        let letterCount = trimmed.filter { $0.isLetter }.count
        if letterCount < trimmed.count / 2 {
            return false
        }

        // Skip punctuation-only tokens
        let punctuationOnly = Set(["\"", "'", ".", ",", "!", "?", ";", ":", "-", "_", "(", ")", "[", "]", "{", "}", "/", "\\", "|", "&", "%", "$", "#", "@", "*", "+", "=", "<", ">", "~", "`"])
        if punctuationOnly.contains(trimmed) {
            return false
        }

        // Skip tokens that are just numbers
        if trimmed.allSatisfy({ $0.isNumber }) {
            return false
        }

        return true
    }

    init() {
        print("✅ WordPredictionService initializing...")

        // Try to load Core ML model
        do {
            wordPredictor = try WordPredictor()
            print("✅ Core ML model loaded successfully")
        } catch {
            print("❌ Failed to load Core ML model: \(error)")
            print("   No predictions will be available")
        }
    }

    // Get predicted words with probabilities based on Core ML model only
    func predictWordsWithProbabilities(for sentence: String) -> [WordPrediction] {
        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)

        print("🔍 predictWordsWithProbabilities called with sentence: '\(trimmed)'")

        // If sentence is empty, return top 15 most common sentence starters (no probabilities for hardcoded list)
        if trimmed.isEmpty {
            // Top 15 sentence starters based on English language frequency
            // Includes: pronouns, articles, common verbs, questions, and frequent opening words
            let words = [
                "I", "The", "It", "You", "We", "What", "This", "Can", 
                "How", "There", "When", "My", "If", "He", "She"
            ]
            let predictions = words.map { WordPrediction(word: $0, probability: 0.0) }
            print("📝 Empty sentence, returning top 15 sentence starters: \(words)")
            return predictions
        }

        // Use Core ML predictions only
        guard let coreMLPredictions = predictWithCoreML(sentence: trimmed) else {
            print("❌ Core ML model not available or failed - no predictions available")
            return []
        }

        print("✅ Core ML predictions for '\(trimmed)': \(coreMLPredictions.map { "\($0.word) (\(String(format: "%.1f", $0.probability * 100))%)" })")
        return coreMLPredictions
    }

    // Legacy method for backward compatibility - returns just words
    func predictWords(for sentence: String) -> [String] {
        return predictWordsWithProbabilities(for: sentence).map { $0.word }
    }


           // Predict using Core ML BERT model
           private func predictWithCoreML(sentence: String) -> [WordPrediction]? {
               guard let predictor = wordPredictor else {
                   print("   Core ML model not available")
                   return nil
               }

               do {
                   print("   🔄 Using Core ML BERT prediction for: '\(sentence)'")

                   // Tokenize the input sentence for BERT MLM
                   let (tokenIds, attentionMask) = tokenizer.encodeForMLM(sentence)
                   print("   Tokenized input: \(tokenIds.prefix(10))...")
                   print("   Attention mask: \(attentionMask.prefix(10))...")

                   // Create MLMultiArray from token IDs
                   let inputArray = try MLMultiArray(shape: [1, NSNumber(value: maxSeqLen)], dataType: .int32)
                   for (index, tokenId) in tokenIds.enumerated() {
                       inputArray[index] = NSNumber(value: tokenId)
                   }

                   // Create attention mask array
                   let attentionArray = try MLMultiArray(shape: [1, NSNumber(value: maxSeqLen)], dataType: .int32)
                   for (index, attention) in attentionMask.enumerated() {
                       attentionArray[index] = NSNumber(value: attention)
        }

                   // Make prediction with BERT inputs
                   let input = WordPredictorInput(input_ids: inputArray, attention_mask: attentionArray)
                   let output = try predictor.prediction(input: input)

                   // Get logits and find top predictions
                   let logits = output.logits
                   print("   🤖 Logits shape: \(logits.shape), count: \(logits.count), dataType: \(logits.dataType)")

                   // For BERT MLM, logits shape is [batch_size, seq_len, vocab_size]
                   // We want predictions for the [MASK] token position
                   // Find where [MASK] is in our tokenized sequence
                   let maskPosition = tokenIds.firstIndex(of: tokenizer.maskTokenId) ?? 2
                   print("   📍 [MASK] token found at position: \(maskPosition)")
                   
                   let maskPredictions = getTopPredictionsForMaskWithProbs(logits: logits, maskPosition: maskPosition, count: 20)
                   print("   Top token predictions for [MASK]: \(maskPredictions.prefix(5).map { "\($0.tokenId) (\(String(format: "%.2f", $0.probability * 100))%)" })...")

                   // Convert token IDs to words with probabilities
                   var wordPredictions: [WordPrediction] = []
                   for prediction in maskPredictions {
                       if let word = tokenizer.word(from: prediction.tokenId) {
                           let cleanedWord = cleanPredictedWord(word)
                           if isValidWord(cleanedWord) {
                               // Only add if not already present (case-insensitive)
                               let capitalized = cleanedWord.capitalized
                               if !wordPredictions.contains(where: { $0.word.lowercased() == capitalized.lowercased() }) {
                                   wordPredictions.append(WordPrediction(word: capitalized, probability: prediction.probability))
                               }
                           }
                       }
                   }

                   // Only return predictions if we have at least some valid ones
                   if wordPredictions.isEmpty {
                       print("   ⚠️ No valid word predictions found from BERT model")
                       return nil
                   }

                   let result = Array(wordPredictions.prefix(15))
                   print("   Final BERT word predictions: \(result.map { "\($0.word) (\(String(format: "%.1f", $0.probability * 100))%)" })")
                   return result

               } catch {
                   print("   ❌ Core ML BERT prediction error: \(error)")
                   return nil
               }
           }

           // Struct to hold token prediction with probability
           private struct TokenPrediction {
               let tokenId: Int
               let probability: Float
           }
           
           // Extract predictions with probabilities for the [MASK] token from BERT logits
           private func getTopPredictionsForMaskWithProbs(logits: MLMultiArray, maskPosition: Int, count: Int) -> [TokenPrediction] {
               // BERT logits shape: [batch_size=1, seq_len=128, vocab_size=30522]
               // Our tokenization: [CLS] word1 word2 ... [MASK] [SEP] padding...
               // maskPosition is the index where [MASK] token is located

               // Extract logits for the mask position: shape is [vocab_size]
               let vocabSize = BERTTokenizer.vocabSize
               var maskLogits: [Float] = []

               for vocabIndex in 0..<vocabSize {
                   // Calculate index in flattened logits array
                   // logits[batch=0][position=maskPosition][vocab=vocabIndex]
                   let flatIndex = vocabIndex + (maskPosition * vocabSize)
                   maskLogits.append(logits[flatIndex].floatValue)
               }

               // Apply softmax to get probabilities and return with token IDs
               return applySoftmaxToPredictionsWithProbs(maskLogits, count: count)
    }

           // Legacy method for backward compatibility
           private func getTopPredictionsForMask(logits: MLMultiArray, maskPosition: Int, count: Int) -> [Int] {
               return getTopPredictionsForMaskWithProbs(logits: logits, maskPosition: maskPosition, count: count)
                   .map { $0.tokenId }
           }

           // Apply softmax and return top token indices with probabilities
           private func applySoftmaxToPredictionsWithProbs(_ logits: [Float], count: Int) -> [TokenPrediction] {
               // Find max logit for numerical stability
               let maxLogit = logits.max() ?? 0.0

               // Compute exp(logit - maxLogit)
               let expValues = logits.map { exp($0 - maxLogit) }

               // Compute sum
               let sumExp = expValues.reduce(0, +)

               // Create (probability, index) pairs
               var probPairs: [(prob: Float, index: Int)] = []
               for (index, expValue) in expValues.enumerated() {
                   let prob = expValue / sumExp
                   if prob > 0.00001 {  // Only include meaningful probabilities
                       probPairs.append((prob: prob, index: index))
                   }
               }

               // Sort by probability (highest first)
               probPairs.sort { $0.prob > $1.prob }

               // Return top predictions with probabilities
               return Array(probPairs.prefix(count)).map { 
                   TokenPrediction(tokenId: $0.index, probability: $0.prob)
               }
           }
           
           // Legacy method for backward compatibility
           private func applySoftmaxToPredictions(_ logits: [Float], count: Int) -> [Int] {
               return applySoftmaxToPredictionsWithProbs(logits, count: count).map { $0.tokenId }
           }



    // Clean up predicted words
    private func cleanPredictedWord(_ word: String) -> String {
        var cleaned = word
            .replacingOccurrences(of: "\u{0120}", with: " ")  // Convert special space
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle common contractions and punctuation
        if cleaned.hasPrefix(" ") {
            cleaned = String(cleaned.dropFirst())
        }

        // Remove trailing punctuation for word predictions
        let punctuation: Set<Character> = [".", ",", "!", "?", ";", ":"]
        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: String(punctuation)))

        return cleaned
    }

    // Filter words by starting letter
    func filterWords(_ words: [String], by letter: String) -> [String] {
        guard !letter.isEmpty else { return words }
        let lowerLetter = letter.lowercased()
        return words.filter { $0.lowercased().hasPrefix(lowerLetter) }
    }

    // Get available starting letters from words
    func getStartingLetters(from words: [String]) -> [String] {
        let letters = Set(words.compactMap { word -> String? in
            guard let firstChar = word.lowercased().first, firstChar.isLetter else { return nil }
            return String(firstChar).uppercased()
        })
        return Array(letters).sorted()
    }
}
