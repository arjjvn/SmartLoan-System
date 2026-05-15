# ==========================================================
# 🔥 MULTI-CLASS DEEPFAKE DETECTOR (DJANGO VERSION)
# ==========================================================

import os
import torch
import torch.nn as nn
import numpy as np
from PIL import Image
from torchvision import transforms, models


# ==========================================================
# 1️⃣ CLASS LABELS (MUST MATCH TRAINING ORDER)
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
# 2️⃣ DEVICE AUTO DETECTION
# ==========================================================

if torch.cuda.is_available():
    device = torch.device("cuda")
else:
    device = torch.device("cpu")

print("Using Device:", device)


# ==========================================================
# 3️⃣ MODEL PATH (FIXED)
# ==========================================================

BASE_DIR = os.path.dirname(__file__)
MODEL_PATH = os.path.join(BASE_DIR, "deepfake_multiclass_best_15.pth")

print("Deepfake Model Path:", MODEL_PATH)


# ==========================================================
# 4️⃣ LOAD MODEL
# ==========================================================

model = models.efficientnet_b4()

model.classifier[1] = nn.Linear(
    model.classifier[1].in_features,
    len(classes)
)

state_dict = torch.load(MODEL_PATH, map_location=device)

# remove DataParallel prefix
new_state_dict = {}

for k, v in state_dict.items():

    if k.startswith("module."):
        new_state_dict[k[7:]] = v
    else:
        new_state_dict[k] = v

model.load_state_dict(new_state_dict)

model.to(device)
model.eval()

print("✅ Deepfake model loaded successfully")


# ==========================================================
# 5️⃣ IMAGE TRANSFORM
# ==========================================================

transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.5]*3, [0.5]*3)
])


# ==========================================================
# 6️⃣ FACE IMAGE DETECTION FUNCTION
# ==========================================================

def detect_face_image(image_path):

    try:
        img = Image.open(image_path).convert("RGB")

    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

    x = transform(img).unsqueeze(0).to(device)

    with torch.no_grad():

        output = model(x)

        probs = torch.softmax(output, dim=1).cpu().numpy()[0]

    pred = np.argmax(probs)

    prediction = classes[pred]

    confidence = float(probs[pred])


    # classify real vs fake
    if prediction == "original":

        status = "Real"

    else:

        status = "Fake"


    return {

        "success": True,

        "prediction": prediction,

        "status": status,

        "confidence": round(confidence * 100, 2)

    }
