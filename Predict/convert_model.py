#!/usr/bin/env python3
"""
Convert BERT to Core ML format for Masked Language Modeling.
Uses BERT-base for better contextual understanding than GPT-2.
"""

import sys
import os
import json

def convert_model():
    """Convert BERT to Core ML format for MLM"""
    try:
        print("Importing required libraries...")
        from transformers import BertForMaskedLM, BertTokenizer
        import coremltools as ct
        import torch
        import numpy as np

        print("\n📥 Downloading BERT-base model for Masked LM...")
        model_name = "bert-base-uncased"

        tokenizer = BertTokenizer.from_pretrained(model_name)
        model = BertForMaskedLM.from_pretrained(model_name)
        model.eval()

        print("✅ Model downloaded successfully")
        print(f"   Vocabulary size: {tokenizer.vocab_size}")

        # Save tokenizer mappings for Swift to use
        print("\n💾 Saving tokenizer mappings...")
        script_dir = os.path.dirname(os.path.abspath(__file__))
        predict_dir = os.path.join(script_dir, "Predict", "Predict")

        # Save vocab.json for BERT
        vocab_dict = tokenizer.get_vocab()
        vocab_path = os.path.join(predict_dir, "vocab.json")
        with open(vocab_path, 'w') as f:
            json.dump(vocab_dict, f)
        print(f"   ✅ Saved vocab.json ({len(vocab_dict)} tokens)")

        # For BERT, we don't need merges.txt, but let's create a placeholder
        merges_path = os.path.join(predict_dir, "merges.txt")
        with open(merges_path, 'w', encoding='utf-8') as f:
            f.write("# BERT uses WordPiece tokenization, not BPE merges\n")
        print("   ✅ Created placeholder merges.txt")

        print("\n🔄 Converting model to Core ML format...")

        # Create wrapper for BERT MLM
        class BertMLMWrapper(torch.nn.Module):
            def __init__(self, bert_model):
                super().__init__()
                self.model = bert_model

            def forward(self, input_ids, attention_mask):
                # Get predictions for masked tokens
                outputs = self.model(input_ids=input_ids, attention_mask=attention_mask)
                # Return logits for all positions (BERT predicts all tokens)
                return outputs.logits

        wrapped_model = BertMLMWrapper(model)

        # Create example input (batch_size=1, seq_len=128 for BERT)
        example_input_ids = torch.randint(0, tokenizer.vocab_size, (1, 128))
        example_attention_mask = torch.ones(1, 128, dtype=torch.long)

        print("   Tracing model...")
        traced_model = torch.jit.trace(wrapped_model, (example_input_ids, example_attention_mask))

        print("   Converting to Core ML...")
        # Convert to Core ML with proper inputs
        mlmodel = ct.convert(
            traced_model,
            inputs=[
                ct.TensorType(name="input_ids", shape=(1, 128), dtype=np.int32),
                ct.TensorType(name="attention_mask", shape=(1, 128), dtype=np.int32)
            ],
            outputs=[ct.TensorType(name="logits", dtype=np.float32)],
            minimum_deployment_target=ct.target.iOS15
        )

        # Save the model as .mlpackage (required for ML Program format)
        output_path = os.path.join(predict_dir, "WordPredictor.mlpackage")
        mlmodel.save(output_path)

        print(f"✅ Model saved to {output_path}")
        print("🎉 BERT MLM conversion complete!")
        print("\n📋 Model Details:")
        print(f"   - Input shape: [1, 128] (batch_size=1, seq_len=128)")
        print(f"   - Output shape: [1, 128, {tokenizer.vocab_size}]")
        print(f"   - Vocabulary size: {tokenizer.vocab_size}")
        print("\n🔧 Next steps:")
        print("   1. Update WordPredictionService.swift for BERT input format")
        print("   2. Update tokenizer to use BERT tokenizer")
        print("   3. Test the model predictions")

        return True

    except Exception as e:
        print(f"❌ Error: {e}")
        print("\n🔧 Troubleshooting:")
        print("   1. Install dependencies: pip install transformers coremltools torch")
        print("   2. Make sure you have enough disk space (BERT-base is ~400MB)")
        print("   3. Try using a smaller model like 'distilbert-base-uncased'")

        # Fallback to smaller model
        try:
            print("\n🔄 Trying with smaller DistilBERT model...")
            return convert_distilbert_model()
        except Exception as fallback_error:
            print(f"❌ Fallback also failed: {fallback_error}")
            return False

def convert_distilbert_model():
    """Fallback: Convert DistilBERT instead of full BERT"""
    try:
        from transformers import DistilBertForMaskedLM, DistilBertTokenizer
        import coremltools as ct
        import torch
        import numpy as np

        print("📥 Downloading DistilBERT model...")
        model_name = "distilbert-base-uncased"

        tokenizer = DistilBertTokenizer.from_pretrained(model_name)
        model = DistilBertForMaskedLM.from_pretrained(model_name)
        model.eval()

        # Save tokenizer
        script_dir = os.path.dirname(os.path.abspath(__file__))
        predict_dir = os.path.join(script_dir, "Predict", "Predict")

        vocab_dict = tokenizer.get_vocab()
        vocab_path = os.path.join(predict_dir, "vocab.json")
        with open(vocab_path, 'w') as f:
            json.dump(vocab_dict, f)

        # Wrapper for DistilBERT
        class DistilBertMLMWrapper(torch.nn.Module):
            def __init__(self, model):
                super().__init__()
                self.model = model

            def forward(self, input_ids, attention_mask):
                outputs = self.model(input_ids=input_ids, attention_mask=attention_mask)
                return outputs.logits

        wrapped_model = DistilBertMLMWrapper(model)

        # Example input
        example_input_ids = torch.randint(0, tokenizer.vocab_size, (1, 128))
        example_attention_mask = torch.ones(1, 128, dtype=torch.long)

        traced_model = torch.jit.trace(wrapped_model, (example_input_ids, example_attention_mask))

        mlmodel = ct.convert(
            traced_model,
            inputs=[
                ct.TensorType(name="input_ids", shape=(1, 128), dtype=np.int32),
                ct.TensorType(name="attention_mask", shape=(1, 128), dtype=np.int32)
            ],
            outputs=[ct.TensorType(name="logits", dtype=np.float32)],
            minimum_deployment_target=ct.target.iOS15
        )

        output_path = os.path.join(predict_dir, "WordPredictor.mlpackage")
        mlmodel.save(output_path)

        print(f"✅ DistilBERT model saved to {output_path}")
        return True

    except Exception as e:
        print(f"❌ DistilBERT conversion failed: {e}")
        return False

if __name__ == "__main__":
    print("🤖 BERT Core ML Converter")
    print("=" * 50)

    success = convert_model()

    if success:
        print("\n✅ Model ready! Update your Swift code for BERT format.")
    else:
        print("\n❌ Conversion failed. Check error messages above.")
        sys.exit(1)
