import cv2, os

video_root = "/kaggle/input/ff-c23/FaceForensics++_C23"
save_root = "/kaggle/working/frames"

classes = [
    "DeepFakeDetection",
    "Deepfakes",
    "Face2Face",
    "FaceShifter",
    "FaceSwap",
    "NeuralTextures",
    "original"
]

os.makedirs(save_root, exist_ok=True)

for cls in classes:
    os.makedirs(f"{save_root}/{cls}", exist_ok=True)
    videos = sorted(os.listdir(f"{video_root}/{cls}"))[:300]

    for vid in videos:
        cap = cv2.VideoCapture(f"{video_root}/{cls}/{vid}")
        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        step = max(frame_count // 5, 1)

        saved = 0
        for i in range(0, frame_count, step):
            cap.set(cv2.CAP_PROP_POS_FRAMES, i)
            ret, frame = cap.read()
            if ret:
                cv2.imwrite(f"{save_root}/{cls}/{vid}_{saved}.jpg", frame)
                saved += 1
                if saved == 5:
                    break
        cap.release()

print("✅ Frames extracted")
