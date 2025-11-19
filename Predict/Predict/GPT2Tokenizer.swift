//
//  BERTTokenizer.swift
//  Predict
//
//  BERT tokenizer implementation using WordPiece tokenization
//  Simplified for word prediction with MLM approach
//

import Foundation

class BERTTokenizer {
    static let vocabSize = 30522  // BERT-base vocab size
    static let maxSeqLen = 128     // BERT maximum sequence length
    
    // Token to ID mapping (from vocab.json)
    private let tokenToId: [String: Int]
    
    // ID to Token mapping (reverse lookup)
    private let idToToken: [Int: String]
    
    // Special tokens for BERT
    let padTokenId = 0      // [PAD]
    let maskTokenId = 103   // [MASK]
    let clsTokenId = 101    // [CLS]
    let sepTokenId = 102    // [SEP]
    let unkTokenId = 100    // [UNK]
    
    // Common word mappings (pre-computed for reliability)
    private let commonWordMappings: [String: Int]
    
    init() {
        // Load vocabulary
        guard let vocabURL = Bundle.main.url(forResource: "vocab", withExtension: "json"),
              let vocabData = try? Data(contentsOf: vocabURL),
              let vocabDict = try? JSONSerialization.jsonObject(with: vocabData) as? [String: Int] else {
            fatalError("Failed to load vocab.json")
        }
        
        self.tokenToId = vocabDict
        
        // Build reverse mapping
        var reverseMap: [Int: String] = [:]
        for (token, id) in vocabDict {
            reverseMap[id] = token
        }
        self.idToToken = reverseMap
        
        // Pre-compute common word mappings for reliability
        var commonMappings: [String: Int] = [:]

        // Add direct mappings for common words (BERT uses WordPiece, so many words are direct tokens)
        let commonWords = ["i", "the", "a", "want", "like", "can", "have", "need", "go", "see", "play", "eat", "drink", "help", "to", "and", "or", "but", "is", "am", "are", "was", "were", "be", "do", "does", "did", "will", "would", "could", "should", "this", "that", "it", "you", "we", "they", "he", "she", "me", "my", "your", "our", "their", "his", "her", "some", "more", "many", "much", "most", "all", "in", "on", "at", "with", "for", "from", "by", "as", "if", "when", "where", "what", "who", "why", "how", "yes", "no", "not", "very", "really", "just", "now", "then", "here", "there", "good", "bad", "big", "small", "hot", "cold", "fast", "slow"]
        
        for word in commonWords {
            if let tokenId = vocabDict[word] {
                commonMappings[word] = tokenId
            }
        }

        self.commonWordMappings = commonMappings
        
        print("✅ Loaded BERT vocabulary: \(vocabDict.count) tokens")
        print("✅ Pre-computed \(commonMappings.count) common word mappings")
    }
    
    // BERT tokenization for MLM (Masked Language Modeling)
    func encodeForMLM(_ text: String, maskPosition: Int? = nil) -> ([Int], [Int]) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            // Return minimal sequence: [CLS] [MASK] [SEP] + padding
            let tokens = [clsTokenId, maskTokenId, sepTokenId] + Array(repeating: padTokenId, count: BERTTokenizer.maxSeqLen - 3)
            let attention = Array(repeating: 1, count: 3) + Array(repeating: 0, count: BERTTokenizer.maxSeqLen - 3)
            return (tokens, attention)
        }

        // Simple word-based tokenization for BERT
        let words = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var tokens: [Int] = [clsTokenId] // Start with [CLS]
        
        for word in words {
            let lowerWord = word.lowercased()
            if let tokenId = commonWordMappings[lowerWord] ?? tokenToId[lowerWord] {
                tokens.append(tokenId)
            } else {
                // Fallback to [UNK] for unknown words
                tokens.append(unkTokenId)
            }
        }

        // Add [MASK] token at the end (for next word prediction)
        // Add some context after [MASK] to help BERT understand this is mid-sentence
        // Using common continuation words to provide context
        tokens.append(maskTokenId)
        
        // Add a common word after [MASK] to signal we want a word, not punctuation
        // Let's use "and" (token 1998) or "the" (token 1996) as context
        if let andToken = tokenToId["and"] {
            tokens.append(andToken)
        }
        
        tokens.append(sepTokenId)

        // Truncate if too long (keep [CLS] and [SEP])
        if tokens.count > BERTTokenizer.maxSeqLen {
            tokens = [clsTokenId] + tokens.dropFirst().dropLast().prefix(BERTTokenizer.maxSeqLen - 3) + [maskTokenId, sepTokenId]
        }
        
        // Pad to max length
        while tokens.count < BERTTokenizer.maxSeqLen {
            tokens.append(padTokenId)
    }
    
        // Create attention mask (1 for real tokens, 0 for padding)
        let realTokenCount = tokens.firstIndex(of: padTokenId) ?? BERTTokenizer.maxSeqLen
        let attention = Array(repeating: 1, count: realTokenCount) + Array(repeating: 0, count: BERTTokenizer.maxSeqLen - realTokenCount)

        return (tokens, attention)
        }
        
    // Legacy method for compatibility - returns just tokens
    func encode(_ text: String, maxLength: Int = 20) -> [Int] {
        let (tokens, _) = encodeForMLM(text)
        return Array(tokens.prefix(maxLength))
            }

    // Convert token ID back to word
    func word(from tokenId: Int) -> String? {
        guard let token = idToToken[tokenId] else { return nil }
        
        // Clean up BERT token format
        var word = token

        // Remove ## prefix from subwords (BERT WordPiece)
        if word.hasPrefix("##") {
            word = String(word.dropFirst(2))
        }

        // Handle special tokens
        switch tokenId {
        case clsTokenId: return "[CLS]"
        case sepTokenId: return "[SEP]"
        case maskTokenId: return "[MASK]"
        case padTokenId: return "[PAD]"
        case unkTokenId: return "[UNK]"
        default: break
        }

        return word
    }

}
