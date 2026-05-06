# ==========================================================
# 🔥 IMAGE FORGERY DETECTOR (DJANGO VERSION - FULL AI)
# ==========================================================

import torch
import torch.nn as nn
import numpy as np
import traceback

from PIL import Image
from torchvision import transforms, models
from transformers import pipeline

# Import Gemini sketch detection
from .gemini_ai import check_sketch


# ==========================================================
# CLASS LABELS
# ==========================================================

classes = [
    "DeepFakeDetection",
    "Deepfakes",
    "Face2Face",
    "FaceShifter",
    "FaceSwap",
    "NeuralTextures",
    "original"
]


# ==========================================================
# DEVICE
# ==========================================================

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

print("Using Device:", device)


# ==========================================================
# LOAD DEEPFAKE MODEL
# ==========================================================

MODEL_PATH = r"D:\project_trustify\loanproject\deepfake\deepfake_multiclass_best_15.pth"

model = models.efficientnet_b4()

model.classifier[1] = nn.Linear(
    model.classifier[1].in_features,
    len(classes)
)

state_dict = torch.load(MODEL_PATH, map_location=device)

new_state_dict = {}

for k, v in state_dict.items():
    if k.startswith("module."):
        new_state_dict[k[7:]] = v
    else:
        new_state_dict[k] = v

model.load_state_dict(new_state_dict)

model.to(device)
model.eval()

print("✅ Deepfake model loaded")


# ==========================================================
# IMAGE TRANSFORM
# ==========================================================

transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.5]*3, [0.5]*3)
])


# ==========================================================
# AI GENERATED IMAGE DETECTOR
# ==========================================================

try:

    ai_detector = pipeline(
        "image-classification",
        model="umm-maybe/AI-image-detector"
    )

    print("✅ AI generated detector loaded")

except Exception as e:

    print("⚠️ AI detector failed:", e)

    ai_detector = None


# ==========================================================
# SKETCH DETECTOR (LOCAL MODEL)
# ==========================================================

try:

    sketch_detector = pipeline(
        "image-classification",
        model="Falconsai/sketch-detection"
    )

    print("✅ Sketch detector loaded")

except Exception as e:

    print("⚠️ Sketch detector failed:", e)

    sketch_detector = None


# ==========================================================
# MAIN DETECTION FUNCTION
# ==========================================================

def detect_face_image(image_path):

    try:
        pil_image = Image.open(image_path).convert("RGB")

    except Exception as e:

        return {
            "success": False,
            "error": str(e)
        }


    FAKE_THRESHOLD = 0.30
    AI_THRESHOLD = 0.40


    # ======================================================
    # STEP 1 — GEMINI SKETCH CHECK
    # ======================================================

    if check_sketch(image_path):

        return {
            "success": True,
            "status": "Fake",
            "confidence": 100.0
        }


    # ======================================================
    # STEP 2 — LOCAL SKETCH DETECTOR
    # ======================================================

    if sketch_detector is not None:

        try:

            result = sketch_detector(pil_image)

            label = result[0]["label"].lower()
            score = result[0]["score"]

            if "sketch" in label and score > 0.50:

                return {
                    "success": True,
                    "status": "Fake",
                    "confidence": round(score * 100, 2)
                }

        except Exception:
            pass


    # ======================================================
    # STEP 3 — IMAGE TRANSFORM
    # ======================================================

    try:

        x = transform(pil_image).unsqueeze(0).to(device)

    except Exception:

        return {
            "success": False,
            "error": "transform_error"
        }


    # ======================================================
    # STEP 4 — DEEPFAKE MODEL
    # ======================================================

    try:

        with torch.no_grad():

            output = model(x)

            probs = torch.softmax(output, dim=1).cpu().numpy()[0]

        top_idx = int(np.argmax(probs))
        top_label = classes[top_idx]
        top_prob = float(probs[top_idx])

    except Exception:

        traceback.print_exc()

        return {
            "success": False,
            "error": "inference_error"
        }


    # ======================================================
    # STEP 5 — THRESHOLD LOGIC
    # ======================================================

    REAL_LABELS = ["original", "NeuralTextures"]

    if top_label in REAL_LABELS:

        deepfake_result = "Real"
        confidence = top_prob * 100

    elif top_prob >= FAKE_THRESHOLD:

        deepfake_result = "Fake"
        confidence = top_prob * 100

    else:

        deepfake_result = "Real"
        confidence = (1 - top_prob) * 100


    # ======================================================
    # STEP 6 — AI GENERATED IMAGE CHECK
    # ======================================================

    if deepfake_result == "Real" and ai_detector is not None:

        try:

            ai_results = ai_detector(pil_image)

            scores = {r['label']: r['score'] for r in ai_results}

            artificial_prob = scores.get("artificial", 0.0)

            if artificial_prob >= AI_THRESHOLD:

                return {
                    "success": True,
                    "status": "Fake",
                    "confidence": round(artificial_prob * 100, 2)
                }

        except Exception:
            pass


    # ======================================================
    # FINAL RESULT
    # ======================================================

    return {

        "success": True,

        "status": deepfake_result,

        "confidence": round(confidence, 2)

    }