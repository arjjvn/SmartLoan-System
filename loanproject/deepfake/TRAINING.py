
import os
import time
import torch
import numpy as np
import torch.nn as nn
from PIL import Image
from collections import Counter

from torch.utils.data import Dataset, DataLoader, random_split, WeightedRandomSampler
from torchvision import transforms, models

from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score
from sklearn.preprocessing import label_binarize

# ==========================================================
# 1️⃣ DEVICE SETUP
# ==========================================================

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print("Device:", device)
print("GPU Count:", torch.cuda.device_count())

# ==========================================================
# 2️⃣ DATASET CLASS (CRASH SAFE)
# ==========================================================

class FrameDataset(Dataset):
    def __init__(self, root_dir):
        self.samples = []
        self.classes = sorted(os.listdir(root_dir))
        self.class_to_idx = {c:i for i,c in enumerate(self.classes)}

        for cls in self.classes:
            class_path = os.path.join(root_dir, cls)
            for img in os.listdir(class_path):
                self.samples.append((os.path.join(class_path, img), self.class_to_idx[cls]))

        self.transform = transforms.Compose([
            transforms.Resize((224,224)),
            transforms.RandomHorizontalFlip(),
            transforms.ColorJitter(0.2,0.2,0.2),
            transforms.ToTensor(),
            transforms.Normalize([0.5]*3,[0.5]*3)
        ])

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        path, label = self.samples[idx]

        try:
            img = Image.open(path).convert("RGB")
        except:
            # handle corrupt image safely
            img = Image.new("RGB", (224,224))

        return self.transform(img), label

# ==========================================================
# 3️⃣ LOAD DATASET
# ==========================================================

DATA_PATH = "/kaggle/working/frames"

dataset = FrameDataset(DATA_PATH)

print("Total Images:", len(dataset))
print("Classes:", dataset.classes)

# ==========================================================
# 4️⃣ TRAIN / VALID SPLIT
# ==========================================================

train_size = int(0.8 * len(dataset))
val_size = len(dataset) - train_size

train_ds, val_ds = random_split(dataset, [train_size, val_size])

# ==========================================================
# 5️⃣ BALANCED SAMPLER (FIXES IMBALANCE)
# ==========================================================

train_targets = [dataset.samples[i][1] for i in train_ds.indices]

class_count = Counter(train_targets)
print("Training class distribution:", class_count)

weights = [1.0 / class_count[t] for t in train_targets]

sampler = WeightedRandomSampler(weights, len(weights))

# ==========================================================
# 6️⃣ DATALOADERS (KAGGLE SAFE)
# ==========================================================

train_loader = DataLoader(
    train_ds,
    batch_size=64,
    sampler=sampler,
    num_workers=4,        # Kaggle recommended
    pin_memory=True,
    persistent_workers=True
)

val_loader = DataLoader(
    val_ds,
    batch_size=64,
    shuffle=False,
    num_workers=4
)

# ==========================================================
# 7️⃣ MODEL SETUP (HIGH ACCURACY)
# ==========================================================

model = models.efficientnet_b4(weights="DEFAULT")

model.classifier[1] = nn.Linear(
    model.classifier[1].in_features,
    len(dataset.classes)
)

# multi-GPU support
if torch.cuda.device_count() > 1:
    model = nn.DataParallel(model)

model = model.to(device)

# ==========================================================
# 8️⃣ LOSS + OPTIMIZER + SCHEDULER
# ==========================================================

criterion = nn.CrossEntropyLoss(label_smoothing=0.1)

optimizer = torch.optim.AdamW(model.parameters(), lr=3e-4)

scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
    optimizer,
    T_max=5
)

# mixed precision scaler (faster)
scaler = torch.amp.GradScaler("cuda")

# ==========================================================
# 9️⃣ TRAINING LOOP
# ==========================================================

EPOCHS = 15
best_auc = 0

for epoch in range(EPOCHS):

    start_time = time.time()

    # ---------------- TRAIN ----------------
    model.train()
    train_loss = 0

    for images, labels in train_loader:

        images = images.to(device)
        labels = labels.to(device)

        optimizer.zero_grad()

        with torch.amp.autocast("cuda"):
            outputs = model(images)
            loss = criterion(outputs, labels)

        scaler.scale(loss).backward()
        scaler.step(optimizer)
        scaler.update()

        train_loss += loss.item()

    scheduler.step()

    train_loss /= len(train_loader)

    # ---------------- VALIDATION ----------------
    model.eval()
    val_loss = 0

    all_labels = []
    all_preds = []
    all_probs = []

    with torch.no_grad():
        for images, labels in val_loader:

            images = images.to(device)
            labels = labels.to(device)

            with torch.amp.autocast("cuda"):
                outputs = model(images)
                loss = criterion(outputs, labels)

            val_loss += loss.item()

            probs = torch.softmax(outputs, dim=1).cpu().numpy()
            preds = np.argmax(probs, axis=1)

            all_probs.extend(probs)
            all_preds.extend(preds)
            all_labels.extend(labels.cpu().numpy())

    val_loss /= len(val_loader)

    # ======================================================
    # 🔟 METRICS
    # ======================================================

    accuracy = accuracy_score(all_labels, all_preds)
    precision = precision_score(all_labels, all_preds, average="weighted", zero_division=0)
    recall = recall_score(all_labels, all_preds, average="weighted", zero_division=0)
    f1 = f1_score(all_labels, all_preds, average="weighted", zero_division=0)

    # Multi-class ROC AUC
    bin_labels = label_binarize(all_labels, classes=list(range(len(dataset.classes))))
    auc = roc_auc_score(bin_labels, np.array(all_probs), multi_class="ovr")

    epoch_time = time.time() - start_time

    # ======================================================
    # 📊 LOG OUTPUT
    # ======================================================

    print("\n==============================================")
    print(f"Epoch {epoch+1}/{EPOCHS}")
    print(f"Time        : {round(epoch_time,2)} sec")
    print("Train Loss  :", round(train_loss,4))
    print("Val Loss    :", round(val_loss,4))
    print("Accuracy    :", round(accuracy,4))
    print("Precision   :", round(precision,4))
    print("Recall      :", round(recall,4))
    print("F1 Score    :", round(f1,4))
    print("AUC-ROC     :", round(auc,4))

    # ======================================================
    # 💾 SAVE BEST MODEL
    # ======================================================

    if auc > best_auc:
        best_auc = auc
        torch.save(model.state_dict(), "deepfake_multiclass_best_15.pth")
        print("🔥 Best model saved!")
    else:
        print("No improvement")

# ==========================================================
# ✅ TRAINING COMPLETE
# ==========================================================

print("\n✅ Training Complete!")
print("Best AUC:", round(best_auc,4))
